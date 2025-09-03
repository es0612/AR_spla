import ARKit
import Domain
import Foundation
import RealityKit

// MARK: - ARInkRenderer

/// Manages ink spot rendering in AR space
public class ARInkRenderer {
    // MARK: - Properties

    private let arView: ARView
    private var inkSpotEntities: [InkSpotId: ModelEntity] = [:]
    private var inkSpotAnchors: [InkSpotId: AnchorEntity] = [:]

    // Rendering settings
    private let inkSpotRadius: Float = 0.05
    private let maxInkSpots: Int = 1_000

    weak var delegate: ARInkRendererDelegate?

    // MARK: - Initialization

    public init(arView: ARView) {
        self.arView = arView
    }

    // MARK: - Public Methods

    /// Add a new ink spot to the AR scene
    public func addInkSpot(_ inkSpot: InkSpot, at worldTransform: simd_float4x4) {
        // Check if we've reached the maximum number of ink spots
        if inkSpotEntities.count >= maxInkSpots {
            removeOldestInkSpot()
        }

        // Create ink spot entity
        let entity = createInkSpotEntity(for: inkSpot)

        // Create anchor entity
        let anchorEntity = AnchorEntity(world: worldTransform)
        anchorEntity.addChild(entity)

        // Add to scene
        arView.scene.addAnchor(anchorEntity)

        // Store references
        inkSpotEntities[inkSpot.id] = entity
        inkSpotAnchors[inkSpot.id] = anchorEntity

        // Add animation
        animateInkSpotAppearance(entity)

        delegate?.inkRenderer(self, didAddInkSpot: inkSpot)
    }

    /// Remove an ink spot from the AR scene
    public func removeInkSpot(id: InkSpotId) {
        guard let entity = inkSpotEntities[id],
              let anchor = inkSpotAnchors[id] else { return }

        // Animate removal
        animateInkSpotDisappearance(entity) { [weak self] in
            // Remove from scene
            self?.arView.scene.removeAnchor(anchor)

            // Clean up references
            self?.inkSpotEntities.removeValue(forKey: id)
            self?.inkSpotAnchors.removeValue(forKey: id)

            self?.delegate?.inkRenderer(self!, didRemoveInkSpot: id)
        }
    }

    /// Update an existing ink spot
    public func updateInkSpot(_ inkSpot: InkSpot) {
        guard let entity = inkSpotEntities[inkSpot.id] else { return }

        // Update material based on new ink spot properties
        updateInkSpotMaterial(entity, for: inkSpot)

        delegate?.inkRenderer(self, didUpdateInkSpot: inkSpot)
    }

    /// Remove all ink spots from the scene
    public func clearAllInkSpots() {
        for (id, anchor) in inkSpotAnchors {
            arView.scene.removeAnchor(anchor)
        }

        inkSpotEntities.removeAll()
        inkSpotAnchors.removeAll()

        delegate?.inkRendererDidClearAllInkSpots(self)
    }

    /// Get the number of rendered ink spots
    public var inkSpotCount: Int {
        inkSpotEntities.count
    }

    /// Check if an ink spot is currently rendered
    public func hasInkSpot(id: InkSpotId) -> Bool {
        inkSpotEntities[id] != nil
    }

    // MARK: - Private Methods

    private func createInkSpotEntity(for inkSpot: InkSpot) -> ModelEntity {
        // Create sphere mesh for ink spot
        let mesh = MeshResource.generateSphere(radius: inkSpotRadius * inkSpot.size)

        // Create material based on player color
        let material = createInkMaterial(for: inkSpot.color)

        // Create entity
        let entity = ModelEntity(mesh: mesh)
        entity.model?.materials = [material]

        // Add collision component for interaction
        entity.collision = CollisionComponent(shapes: [.generateSphere(radius: inkSpotRadius * inkSpot.size)])

        // Set name for debugging
        entity.name = "InkSpot_\(inkSpot.id.value.uuidString)"

        return entity
    }

    private func createInkMaterial(for playerColor: PlayerColor) -> Material {
        var material = SimpleMaterial()

        // Set color based on player color
        let uiColor = playerColor.toUIColor()
        material.color = .init(tint: uiColor)

        // Set material properties for ink-like appearance
        material.roughness = .init(floatLiteral: 0.8)
        material.metallic = .init(floatLiteral: 0.1)

        // Add slight emission for visibility
        material.emissiveColor = .init(color: uiColor.withAlphaComponent(0.2))

        return material
    }

    private func updateInkSpotMaterial(_ entity: ModelEntity, for inkSpot: InkSpot) {
        let material = createInkMaterial(for: inkSpot.color)
        entity.model?.materials = [material]
    }

    private func animateInkSpotAppearance(_ entity: ModelEntity) {
        // Start with small scale
        entity.transform.scale = SIMD3<Float>(0.1, 0.1, 0.1)

        // Create scale animation
        let scaleAnimation = FromToByAnimation<Transform>(
            from: Transform(scale: SIMD3<Float>(0.1, 0.1, 0.1)),
            to: Transform(scale: SIMD3<Float>(1.0, 1.0, 1.0)),
            duration: 0.3,
            timing: .easeOut,
            bindTarget: .transform
        )

        // Apply animation
        if let animationResource = try? AnimationResource.generate(with: scaleAnimation) {
            entity.playAnimation(animationResource)
        }
    }

    private func animateInkSpotDisappearance(_ entity: ModelEntity, completion: @escaping () -> Void) {
        // Create fade out animation
        let scaleAnimation = FromToByAnimation<Transform>(
            from: Transform(scale: SIMD3<Float>(1.0, 1.0, 1.0)),
            to: Transform(scale: SIMD3<Float>(0.1, 0.1, 0.1)),
            duration: 0.2,
            timing: .easeIn,
            bindTarget: .transform
        )

        // Apply animation
        if let animationResource = try? AnimationResource.generate(with: scaleAnimation) {
            entity.playAnimation(animationResource)

            // Call completion after animation duration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                completion()
            }
        } else {
            completion()
        }
    }

    private func removeOldestInkSpot() {
        // Find the oldest ink spot (this is a simple implementation)
        // In a more sophisticated version, we could track creation timestamps
        guard let oldestId = inkSpotEntities.keys.first else { return }
        removeInkSpot(id: oldestId)
    }
}

// MARK: - PlayerColor Extension

extension PlayerColor {
    func toUIColor() -> UIColor {
        let rgb = rgbValues
        return UIColor(red: CGFloat(rgb.red), green: CGFloat(rgb.green), blue: CGFloat(rgb.blue), alpha: 1.0)
    }
}

// MARK: - ARInkRendererDelegate

public protocol ARInkRendererDelegate: AnyObject {
    func inkRenderer(_ renderer: ARInkRenderer, didAddInkSpot inkSpot: InkSpot)
    func inkRenderer(_ renderer: ARInkRenderer, didRemoveInkSpot id: InkSpotId)
    func inkRenderer(_ renderer: ARInkRenderer, didUpdateInkSpot inkSpot: InkSpot)
    func inkRendererDidClearAllInkSpots(_ renderer: ARInkRenderer)
}
