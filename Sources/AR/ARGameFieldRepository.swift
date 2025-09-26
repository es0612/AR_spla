import ARKit
import Domain
import Foundation
import RealityKit

// MARK: - ARGameFieldRepository

/// Repository for managing game field in AR space
public class ARGameFieldRepository {
    // MARK: - Properties

    private let arView: ARView
    private var gameFieldAnchor: ARAnchor?
    private var gameFieldEntity: ModelEntity?
    private var boundaryEntities: [ModelEntity] = []

    // Field configuration
    private let fieldSize: CGSize
    private let fieldHeight: Float = 0.01 // Thin field plane
    private let boundaryHeight: Float = 0.1
    private let boundaryWidth: Float = 0.02

    weak var delegate: ARGameFieldRepositoryDelegate?

    // MARK: - Initialization

    public init(arView: ARView, fieldSize: CGSize = CGSize(width: 4.0, height: 4.0)) {
        self.arView = arView
        self.fieldSize = fieldSize
    }

    // MARK: - Public Methods

    /// Set up the game field on a detected plane
    public func setupGameField(on planeAnchor: ARPlaneAnchor) -> Bool {
        // Check if plane is suitable for game field
        guard isPlaneSupitable(planeAnchor) else {
            delegate?.gameFieldRepository(self, didFailToSetupField: .planeTooSmall)
            return false
        }

        // Remove existing field if any
        removeGameField()

        // Store anchor reference
        gameFieldAnchor = planeAnchor

        // Create field visualization
        createFieldVisualization(for: planeAnchor)

        // Create field boundaries
        createFieldBoundaries(for: planeAnchor)

        delegate?.gameFieldRepository(self, didSetupField: planeAnchor)
        return true
    }

    /// Remove the current game field
    public func removeGameField() {
        // Remove field entity
        if let fieldEntity = gameFieldEntity,
           let parent = fieldEntity.parent {
            parent.removeChild(fieldEntity)
        }

        // Remove boundary entities
        for boundary in boundaryEntities {
            if let parent = boundary.parent {
                parent.removeChild(boundary)
            }
        }

        gameFieldEntity = nil
        boundaryEntities.removeAll()
        gameFieldAnchor = nil

        delegate?.gameFieldRepositoryDidRemoveField(self)
    }

    /// Update field visualization based on plane updates
    public func updateGameField(for planeAnchor: ARPlaneAnchor) {
        guard planeAnchor.identifier == gameFieldAnchor?.identifier else { return }

        // Update field size if needed
        updateFieldVisualization(for: planeAnchor)

        delegate?.gameFieldRepository(self, didUpdateField: planeAnchor)
    }

    /// Convert AR world coordinates to normalized game field coordinates
    public func worldToGameCoordinates(_ worldPosition: SIMD4<Float>) -> Position3D? {
        guard let anchor = gameFieldAnchor as? ARPlaneAnchor else { return nil }

        return ARCoordinateSystem.arToGame(worldPosition, fieldAnchor: anchor, fieldSize: fieldSize)
    }

    /// Convert normalized game field coordinates to AR world coordinates
    public func gameToWorldCoordinates(_ gamePosition: Position3D) -> SIMD4<Float>? {
        guard let anchor = gameFieldAnchor as? ARPlaneAnchor else { return nil }

        return ARCoordinateSystem.gameToAR(gamePosition, fieldAnchor: anchor, fieldSize: fieldSize)
    }

    /// Convert AR world transform to game field transform
    public func worldToGameTransform(_ worldTransform: simd_float4x4) -> simd_float4x4? {
        guard let anchor = gameFieldAnchor as? ARPlaneAnchor else { return nil }

        return ARCoordinateSystem.arTransformToFieldRelative(worldTransform, fieldAnchor: anchor)
    }

    /// Convert game field transform to AR world transform
    public func gameToWorldTransform(_ gameTransform: simd_float4x4) -> simd_float4x4? {
        guard let anchor = gameFieldAnchor as? ARPlaneAnchor else { return nil }

        return ARCoordinateSystem.fieldRelativeToARTransform(gameTransform, fieldAnchor: anchor)
    }

    /// Check if a world position is within the game field bounds
    public func isPositionInField(_ worldPosition: SIMD4<Float>) -> Bool {
        guard let gamePosition = worldToGameCoordinates(worldPosition) else { return false }
        return ARCoordinateSystem.isWithinGameField(gamePosition)
    }

    /// Get the current game field anchor
    public var currentFieldAnchor: ARAnchor? {
        gameFieldAnchor
    }

    /// Check if game field is currently set up
    public var isFieldSetup: Bool {
        gameFieldAnchor != nil && gameFieldEntity != nil
    }

    /// Get field size in AR world units
    public var worldFieldSize: CGSize {
        fieldSize
    }

    // MARK: - Private Methods

    private func isPlaneSupitable(_ planeAnchor: ARPlaneAnchor) -> Bool {
        let extent = planeAnchor.planeExtent
        return extent.width >= Float(fieldSize.width) && extent.height >= Float(fieldSize.height)
    }

    private func createFieldVisualization(for planeAnchor: ARPlaneAnchor) {
        // Create field mesh
        let fieldMesh = MeshResource.generatePlane(
            width: Float(fieldSize.width),
            depth: Float(fieldSize.height)
        )

        // Create field material
        var fieldMaterial = SimpleMaterial()
        fieldMaterial.color = .init(tint: .white.withAlphaComponent(0.1))
        fieldMaterial.roughness = .init(floatLiteral: 1.0)

        // Create field entity
        gameFieldEntity = ModelEntity(mesh: fieldMesh)
        gameFieldEntity?.model?.materials = [fieldMaterial]
        gameFieldEntity?.name = "GameField"

        // Create anchor entity and add field
        let anchorEntity = AnchorEntity(.anchor(identifier: planeAnchor.identifier))
        if let fieldEntity = gameFieldEntity {
            anchorEntity.addChild(fieldEntity)
        }

        // Add to scene
        arView.scene.addAnchor(anchorEntity)
    }

    private func createFieldBoundaries(for _: ARPlaneAnchor) {
        let halfWidth = Float(fieldSize.width) / 2
        let halfHeight = Float(fieldSize.height) / 2

        // Create boundary positions (4 sides)
        let boundaryPositions: [(position: SIMD3<Float>, size: SIMD3<Float>)] = [
            // Top boundary
            (SIMD3<Float>(0, boundaryHeight / 2, halfHeight), SIMD3<Float>(Float(fieldSize.width), boundaryHeight, boundaryWidth)),
            // Bottom boundary
            (SIMD3<Float>(0, boundaryHeight / 2, -halfHeight), SIMD3<Float>(Float(fieldSize.width), boundaryHeight, boundaryWidth)),
            // Left boundary
            (SIMD3<Float>(-halfWidth, boundaryHeight / 2, 0), SIMD3<Float>(boundaryWidth, boundaryHeight, Float(fieldSize.height))),
            // Right boundary
            (SIMD3<Float>(halfWidth, boundaryHeight / 2, 0), SIMD3<Float>(boundaryWidth, boundaryHeight, Float(fieldSize.height)))
        ]

        // Create boundary material
        var boundaryMaterial = SimpleMaterial()
        boundaryMaterial.color = .init(tint: .systemBlue.withAlphaComponent(0.3))
        boundaryMaterial.roughness = .init(floatLiteral: 0.8)

        // Create boundary entities
        for (position, size) in boundaryPositions {
            let boundaryMesh = MeshResource.generateBox(size: size)
            let boundaryEntity = ModelEntity(mesh: boundaryMesh)
            boundaryEntity.model?.materials = [boundaryMaterial]
            boundaryEntity.transform.translation = position
            boundaryEntity.name = "GameFieldBoundary"

            // Add collision for boundary detection
            boundaryEntity.collision = CollisionComponent(shapes: [.generateBox(size: size)])

            // Add to field entity
            gameFieldEntity?.addChild(boundaryEntity)
            boundaryEntities.append(boundaryEntity)
        }
    }

    private func updateFieldVisualization(for planeAnchor: ARPlaneAnchor) {
        // For now, we keep the field size constant
        // In a more advanced implementation, we could adapt to plane changes
        delegate?.gameFieldRepository(self, didUpdateField: planeAnchor)
    }
}

// MARK: - ARGameFieldRepositoryDelegate

public protocol ARGameFieldRepositoryDelegate: AnyObject {
    func gameFieldRepository(_ repository: ARGameFieldRepository, didSetupField anchor: ARAnchor)
    func gameFieldRepository(_ repository: ARGameFieldRepository, didUpdateField anchor: ARAnchor)
    func gameFieldRepositoryDidRemoveField(_ repository: ARGameFieldRepository)
    func gameFieldRepository(_ repository: ARGameFieldRepository, didFailToSetupField error: GameFieldError)
}

// MARK: - GameFieldError

public enum GameFieldError: Error, LocalizedError {
    case planeTooSmall
    case planeNotHorizontal
    case setupFailed
    case coordinateConversionFailed

    public var errorDescription: String? {
        switch self {
        case .planeTooSmall:
            return "検出された平面がゲームフィールドには小さすぎます"
        case .planeNotHorizontal:
            return "水平な平面が必要です"
        case .setupFailed:
            return "ゲームフィールドのセットアップに失敗しました"
        case .coordinateConversionFailed:
            return "座標変換に失敗しました"
        }
    }
}
