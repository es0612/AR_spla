//
//  ARGameCoordinator.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import ARKit
import Domain
import Foundation
import RealityKit

// MARK: - InkTrajectory

/// Represents an ink trajectory from shooting point to impact
private struct InkTrajectory {
    let startPoint: SIMD3<Float>
    let direction: SIMD3<Float>
    let impactPoint: SIMD4<Float>
    let impactTransform: simd_float4x4
    let size: Float
    let duration: TimeInterval
}

// MARK: - CollisionDetector

/// Handles collision detection between players and ink spots using domain service
private class CollisionDetector {
    private let fieldSize: CGSize
    private let collisionService: CollisionDetectionService
    private var activeInkSpots: [InkSpot] = []
    private var activePlayers: [PlayerId: Player] = [:]

    init(fieldSize: CGSize, gameRules: GameRules = .default) {
        self.fieldSize = fieldSize
        collisionService = CollisionDetectionService(gameRules: gameRules)
    }

    /// Add an ink spot to the collision detection system
    func addInkSpot(_ inkSpot: InkSpot) {
        activeInkSpots.append(inkSpot)

        // Remove old ink spots to maintain performance
        if activeInkSpots.count > 500 {
            activeInkSpots.removeFirst(100) // Remove oldest 100 spots
        }
    }

    /// Update player for collision detection
    func updatePlayer(_ player: Player) {
        activePlayers[player.id] = player
    }

    /// Remove player from collision detection
    func removePlayer(_ playerId: PlayerId) {
        activePlayers.removeValue(forKey: playerId)
    }

    /// Check for player collisions with a new ink spot
    func checkPlayerCollisions(with inkSpot: InkSpot) -> [(PlayerId, PlayerCollisionEffect)] {
        var collisions: [(PlayerId, PlayerCollisionEffect)] = []

        for (playerId, player) in activePlayers {
            let effect = collisionService.calculatePlayerCollisionEffect(player, with: inkSpot)
            if effect.isStunned {
                collisions.append((playerId, effect))
            }
        }

        return collisions
    }

    /// Check for overlapping ink spots with detailed results
    func checkInkSpotOverlaps(with newInkSpot: InkSpot) -> [(InkSpot, InkSpotOverlapResult)] {
        collisionService.findOverlappingInkSpots(newInkSpot, in: activeInkSpots)
    }

    /// Check if a player collides with any existing ink spots
    func checkPlayerWithAllInkSpots(_ player: Player) -> [(InkSpot, PlayerCollisionEffect)] {
        var collisions: [(InkSpot, PlayerCollisionEffect)] = []

        for inkSpot in activeInkSpots {
            let effect = collisionService.calculatePlayerCollisionEffect(player, with: inkSpot)
            if effect.isStunned {
                collisions.append((inkSpot, effect))
            }
        }

        return collisions
    }

    /// Find ink spots at a specific position
    func findInkSpotsAt(_ position: Position3D) -> [InkSpot] {
        collisionService.findInkSpotsContaining(position, in: activeInkSpots)
    }

    /// Remove an ink spot from collision detection
    func removeInkSpot(id: InkSpotId) {
        activeInkSpots.removeAll { $0.id == id }
    }

    /// Clear all collision data
    func clear() {
        activeInkSpots.removeAll()
        activePlayers.removeAll()
    }

    /// Get the number of active ink spots being tracked
    var activeInkSpotCount: Int {
        activeInkSpots.count
    }

    /// Get the number of active players being tracked
    var activePlayerCount: Int {
        activePlayers.count
    }
}

// MARK: - ARGameCoordinator

/// Coordinates AR game functionality between field management and ink rendering
public class ARGameCoordinator: NSObject, ObservableObject {
    // MARK: - Properties

    private let arView: ARView
    private let gameFieldRepository: ARGameFieldRepository
    private let inkRenderer: ARInkRenderer
    private let collisionDetector: CollisionDetector

    @Published public var gameFieldState: GameFieldState = .notDetected
    @Published public var arSessionState: ARSessionState = .notStarted
    @Published public var trackingQuality: ARTrackingQuality.TrackingQuality = .poor

    private let performanceMonitor = ARPerformanceMonitor()

    weak var delegate: ARGameCoordinatorDelegate?

    // MARK: - Initialization

    public init(arView: ARView, fieldSize: CGSize = CGSize(width: 4.0, height: 4.0), gameRules: GameRules = .default) {
        self.arView = arView
        gameFieldRepository = ARGameFieldRepository(arView: arView, fieldSize: fieldSize)
        inkRenderer = ARInkRenderer(arView: arView)
        collisionDetector = CollisionDetector(fieldSize: fieldSize, gameRules: gameRules)

        super.init()
        setupDelegates()
    }

    // MARK: - Public Methods

    /// Start AR session and begin plane detection
    public func startARSession() {
        guard ARWorldTrackingConfiguration.isSupported else {
            arSessionState = .failed(ARError.unsupportedDevice)
            delegate?.arGameCoordinator(self, didFailWithError: ARError.unsupportedDevice)
            return
        }

        arSessionState = .starting

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal]
        configuration.environmentTexturing = .automatic

        arView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
        arSessionState = .running

        delegate?.arGameCoordinatorDidStartSession(self)
    }

    /// Stop AR session
    public func stopARSession() {
        arView.session.pause()
        arSessionState = .paused
        gameFieldState = .notDetected

        // Clear all AR content
        gameFieldRepository.removeGameField()
        inkRenderer.clearAllInkSpots()

        delegate?.arGameCoordinatorDidStopSession(self)
    }

    /// Handle tap gesture to shoot ink with trajectory calculation
    public func handleTap(at screenPoint: CGPoint, for player: Player) -> Bool {
        guard gameFieldState.isReady else {
            delegate?.arGameCoordinator(self, didFailWithError: ARError.gameFieldNotFound)
            return false
        }

        // Calculate ink trajectory and impact point
        guard let inkTrajectory = calculateInkTrajectory(from: screenPoint, for: player) else {
            return false
        }

        // Validate impact position is within game field
        guard gameFieldRepository.isPositionInField(inkTrajectory.impactPoint) else {
            return false
        }

        // Convert to game coordinates
        guard let gamePosition = gameFieldRepository.worldToGameCoordinates(inkTrajectory.impactPoint) else {
            return false
        }

        // Create ink spot with calculated properties
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: gamePosition,
            color: player.color,
            size: inkTrajectory.size,
            ownerId: player.id
        )

        // Render ink trajectory animation
        renderInkTrajectory(inkTrajectory) { [weak self] in
            // Add ink spot to renderer after trajectory animation
            self?.inkRenderer.addInkSpot(inkSpot, at: inkTrajectory.impactTransform)
        }

        // Notify delegate
        delegate?.arGameCoordinator(self, didShootInk: inkSpot, at: gamePosition)

        return true
    }

    /// Calculate ink trajectory from screen tap to impact point
    private func calculateInkTrajectory(from screenPoint: CGPoint, for _: Player) -> InkTrajectory? {
        // Get camera position and direction
        guard let cameraTransform = arView.session.currentFrame?.camera.transform else { return nil }
        let cameraPosition = SIMD3<Float>(cameraTransform.columns.3.x, cameraTransform.columns.3.y, cameraTransform.columns.3.z)

        // Convert screen point to world ray
        guard let ray = ARCoordinateSystem.screenToWorldRay(screenPoint, in: arView) else { return nil }

        // Perform raycast to find impact point
        let results = arView.raycast(from: screenPoint, allowing: .estimatedPlane, alignment: .horizontal)
        guard let firstResult = results.first else { return nil }

        let impactPoint = SIMD4<Float>(
            firstResult.worldTransform.columns.3.x,
            firstResult.worldTransform.columns.3.y,
            firstResult.worldTransform.columns.3.z,
            1.0
        )

        // Calculate trajectory properties
        let distance = ARCoordinateSystem.distance(
            from: SIMD4<Float>(cameraPosition.x, cameraPosition.y, cameraPosition.z, 1.0),
            to: impactPoint
        )

        // Size based on distance (closer = larger)
        let size = max(0.3, min(1.5, 2.0 - (distance / 3.0)))

        // Create trajectory
        return InkTrajectory(
            startPoint: cameraPosition,
            direction: ray.direction,
            impactPoint: impactPoint,
            impactTransform: firstResult.worldTransform,
            size: size,
            duration: min(0.5, Double(distance / 6.0)) // Animation duration based on distance
        )
    }

    /// Render ink trajectory animation
    private func renderInkTrajectory(_ trajectory: InkTrajectory, completion: @escaping () -> Void) {
        // Create trajectory visualization entity
        let trajectoryEntity = createTrajectoryEntity(trajectory)

        // Add to scene temporarily
        let anchorEntity = AnchorEntity(world: simd_float4x4(
            SIMD4<Float>(1, 0, 0, trajectory.startPoint.x),
            SIMD4<Float>(0, 1, 0, trajectory.startPoint.y),
            SIMD4<Float>(0, 0, 1, trajectory.startPoint.z),
            SIMD4<Float>(0, 0, 0, 1)
        ))
        anchorEntity.addChild(trajectoryEntity)
        arView.scene.addAnchor(anchorEntity)

        // Animate trajectory
        animateTrajectory(trajectoryEntity, trajectory: trajectory) {
            // Remove trajectory entity
            self.arView.scene.removeAnchor(anchorEntity)
            // Call completion to add ink spot
            completion()
        }
    }

    /// Create visual entity for trajectory
    private func createTrajectoryEntity(_: InkTrajectory) -> ModelEntity {
        // Create small sphere for trajectory visualization
        let mesh = MeshResource.generateSphere(radius: 0.01)
        var material = SimpleMaterial()
        material.color = .init(tint: .white)
        // Note: emissiveColor is not available in SimpleMaterial

        let entity = ModelEntity(mesh: mesh)
        entity.model?.materials = [material]

        return entity
    }

    /// Animate trajectory from start to impact point
    private func animateTrajectory(_ entity: ModelEntity, trajectory: InkTrajectory, completion: @escaping () -> Void) {
        // Calculate trajectory path with arc
        let startPos = trajectory.startPoint
        let endPos = SIMD3<Float>(trajectory.impactPoint.x, trajectory.impactPoint.y, trajectory.impactPoint.z)

        // Add arc to trajectory (simulate gravity)
        let midPoint = (startPos + endPos) / 2.0
        let arcHeight: Float = 0.5 // Meters
        let arcMidPoint = SIMD3<Float>(midPoint.x, midPoint.y + arcHeight, midPoint.z)

        // Animate along bezier curve
        let duration = trajectory.duration
        let startTime = CACurrentMediaTime()

        func updatePosition() {
            let elapsed = CACurrentMediaTime() - startTime
            let progress = min(1.0, Float(elapsed / duration))

            if progress >= 1.0 {
                completion()
                return
            }

            // Quadratic bezier curve
            let t = progress
            let oneMinusT = 1.0 - t
            let position = oneMinusT * oneMinusT * startPos +
                2.0 * oneMinusT * t * arcMidPoint +
                t * t * endPos

            entity.transform.translation = position

            // Continue animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.016) { // ~60fps
                updatePosition()
            }
        }

        updatePosition()
    }

    /// Add ink spot from network or game logic
    public func addInkSpot(_ inkSpot: InkSpot) -> Bool {
        guard gameFieldState.isReady else { return false }

        // Convert game position to world position
        guard let worldPosition = gameFieldRepository.gameToWorldCoordinates(inkSpot.position) else {
            return false
        }

        // Check for collisions before adding
        checkInkSpotCollisions(inkSpot)

        // Create world transform
        let worldTransform = simd_float4x4(
            SIMD4<Float>(1, 0, 0, worldPosition.x),
            SIMD4<Float>(0, 1, 0, worldPosition.y),
            SIMD4<Float>(0, 0, 1, worldPosition.z),
            SIMD4<Float>(0, 0, 0, 1)
        )

        // Add to renderer
        inkRenderer.addInkSpot(inkSpot, at: worldTransform)

        return true
    }

    /// Remove ink spot
    public func removeInkSpot(id: InkSpotId) {
        inkRenderer.removeInkSpot(id: id)
    }

    /// Clear all ink spots
    public func clearAllInkSpots() {
        inkRenderer.clearAllInkSpots()
    }

    /// Get current field size in world units
    public var fieldSize: CGSize {
        gameFieldRepository.worldFieldSize
    }

    /// Check if game field is ready for gameplay
    public var isReadyForGameplay: Bool {
        gameFieldState.isReady &&
            arSessionState.isActive &&
            trackingQuality.isGoodEnoughForGameplay
    }

    /// Get the current game field anchor
    public var currentFieldAnchor: ARAnchor? {
        gameFieldRepository.currentFieldAnchor
    }

    // MARK: - ARSessionDelegate

    public func session(_: ARSession, didUpdate frame: ARFrame) {
        // Update tracking quality
        trackingQuality = ARTrackingQuality.assess(frame)

        // Monitor performance
        performanceMonitor.recordFrame()

        // Update player positions for collision detection
        updatePlayerPositions(from: frame)

        // Update delegate
        delegate?.arGameCoordinator(self, didUpdateTrackingQuality: trackingQuality)
    }

    /// Update player positions from AR frame
    private func updatePlayerPositions(from frame: ARFrame) {
        // Get camera position as current player position
        let cameraTransform = frame.camera.transform
        let cameraPosition = SIMD3<Float>(
            cameraTransform.columns.3.x,
            cameraTransform.columns.3.y,
            cameraTransform.columns.3.z
        )

        // Convert to game coordinates if field is available
        guard let gamePosition = gameFieldRepository.worldToGameCoordinates(SIMD4<Float>(cameraPosition.x, cameraPosition.y, cameraPosition.z, 1.0)) else {
            return
        }

        // Update current player position (assuming first player is the current player)
        // In a real multiplayer scenario, this would be handled differently
        delegate?.arGameCoordinator(self, didUpdatePlayerPosition: gamePosition)
    }

    public func session(_: ARSession, didAdd anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor,
               planeAnchor.alignment == .horizontal,
               gameFieldState == .notDetected || gameFieldState == .detecting {
                gameFieldState = .detected(planeAnchor)

                // Try to setup game field
                if gameFieldRepository.setupGameField(on: planeAnchor) {
                    gameFieldState = .setup(planeAnchor)
                    delegate?.arGameCoordinator(self, didSetupGameField: planeAnchor)
                }
            }
        }
    }

    public func session(_: ARSession, didUpdate anchors: [ARAnchor]) {
        for anchor in anchors {
            if let planeAnchor = anchor as? ARPlaneAnchor,
               case let .setup(currentAnchor) = gameFieldState,
               planeAnchor.identifier == currentAnchor.identifier {
                gameFieldRepository.updateGameField(for: planeAnchor)
                delegate?.arGameCoordinator(self, didUpdateGameField: planeAnchor)
            }
        }
    }

    public func session(_: ARSession, didRemove anchors: [ARAnchor]) {
        for anchor in anchors {
            if case let .setup(currentAnchor) = gameFieldState,
               anchor.identifier == currentAnchor.identifier {
                gameFieldState = .lost
                gameFieldRepository.removeGameField()
                delegate?.arGameCoordinatorDidLoseGameField(self)
            }
        }
    }

    public func session(_: ARSession, didFailWithError error: Error) {
        arSessionState = .failed(error)
        delegate?.arGameCoordinator(self, didFailWithError: error)
    }

    public func sessionWasInterrupted(_: ARSession) {
        arSessionState = .interrupted
        delegate?.arGameCoordinatorWasInterrupted(self)
    }

    public func sessionInterruptionEnded(_: ARSession) {
        arSessionState = .running
        delegate?.arGameCoordinatorInterruptionEnded(self)
    }

    // MARK: - Private Methods

    private func setupDelegates() {
        gameFieldRepository.delegate = self
        inkRenderer.delegate = self
        arView.session.delegate = self
    }

    // MARK: - Collision Detection

    /// Check for collisions when a new ink spot is added
    private func checkInkSpotCollisions(_ newInkSpot: InkSpot) {
        // Add ink spot to collision detector
        collisionDetector.addInkSpot(newInkSpot)

        // Check for player collisions with detailed effects
        let playerCollisions = collisionDetector.checkPlayerCollisions(with: newInkSpot)
        for (playerId, effect) in playerCollisions {
            delegate?.arGameCoordinator(self, didDetectPlayerCollision: playerId, at: newInkSpot.position, effect: effect)
        }

        // Check for ink spot overlaps with detailed results
        let inkSpotOverlaps = collisionDetector.checkInkSpotOverlaps(with: newInkSpot)
        if !inkSpotOverlaps.isEmpty {
            delegate?.arGameCoordinator(self, didProcessInkSpotOverlap: newInkSpot, overlaps: inkSpotOverlaps)

            // Handle overlapping ink spots
            handleInkSpotOverlaps(newInkSpot: newInkSpot, overlaps: inkSpotOverlaps)
        }
    }

    /// Update player for collision detection
    public func updatePlayer(_ player: Player) {
        collisionDetector.updatePlayer(player)

        // Check for collisions with existing ink spots when player moves
        let collisions = collisionDetector.checkPlayerWithAllInkSpots(player)
        for (inkSpot, effect) in collisions {
            delegate?.arGameCoordinator(self, didDetectPlayerCollision: player.id, at: inkSpot.position, effect: effect)
        }
    }

    /// Remove player from collision detection
    public func removePlayer(_ playerId: PlayerId) {
        collisionDetector.removePlayer(playerId)
    }

    /// Check for player collisions with all existing ink spots
    public func checkPlayerCollisions(_ player: Player) -> [(InkSpot, PlayerCollisionEffect)] {
        collisionDetector.checkPlayerWithAllInkSpots(player)
    }

    /// Find ink spots at a specific position
    public func findInkSpotsAt(_ position: Position3D) -> [InkSpot] {
        collisionDetector.findInkSpotsAt(position)
    }

    /// Handle overlapping ink spots with detailed overlap information
    private func handleInkSpotOverlaps(newInkSpot: InkSpot, overlaps: [(InkSpot, InkSpotOverlapResult)]) {
        for (overlappingSpot, overlapResult) in overlaps {
            if overlappingSpot.color == newInkSpot.color {
                // Same color - merge ink spots
                handleSameColorOverlap(newInkSpot: newInkSpot, existingSpot: overlappingSpot, overlapResult: overlapResult)
            } else {
                // Different colors - create conflict effect
                handleDifferentColorOverlap(newInkSpot: newInkSpot, existingSpot: overlappingSpot, overlapResult: overlapResult)
            }
        }
    }

    /// Handle overlap between same color ink spots
    private func handleSameColorOverlap(newInkSpot: InkSpot, existingSpot: InkSpot, overlapResult: InkSpotOverlapResult) {
        guard let mergedSize = overlapResult.mergedSize else { return }

        // Create merged ink spot at the center point between the two spots
        let centerPosition = Position3D(
            x: (newInkSpot.position.x + existingSpot.position.x) / 2,
            y: (newInkSpot.position.y + existingSpot.position.y) / 2,
            z: (newInkSpot.position.z + existingSpot.position.z) / 2
        )

        let mergedInkSpot = InkSpot(
            id: InkSpotId(),
            position: centerPosition,
            color: newInkSpot.color,
            size: min(mergedSize, InkSpot.maxSize), // Cap at maximum size
            ownerId: newInkSpot.ownerId
        )

        // Remove the existing overlapping spot
        removeInkSpot(id: existingSpot.id)
        collisionDetector.removeInkSpot(id: existingSpot.id)

        // Add the merged spot
        _ = addInkSpot(mergedInkSpot)

        delegate?.arGameCoordinator(self, didMergeInkSpots: [newInkSpot, existingSpot], into: mergedInkSpot)
    }

    /// Handle overlap between different color ink spots
    private func handleDifferentColorOverlap(newInkSpot: InkSpot, existingSpot: InkSpot, overlapResult: InkSpotOverlapResult) {
        // Different colors create a conflict - could implement various effects:
        // 1. Neutralize both spots in the overlap area
        // 2. Create a special "mixed" color effect
        // 3. Apply damage to both spots

        // For now, we'll create a visual effect and reduce both spots' sizes
        let reductionFactor: Float = 0.8 // Reduce size by 20%

        if existingSpot.size * reductionFactor >= InkSpot.minSize {
            let reducedExistingSpot = InkSpot(
                id: existingSpot.id,
                position: existingSpot.position,
                color: existingSpot.color,
                size: existingSpot.size * reductionFactor,
                ownerId: existingSpot.ownerId,
                createdAt: existingSpot.createdAt
            )

            // Update the existing spot with reduced size
            inkRenderer.updateInkSpot(reducedExistingSpot)
        }

        delegate?.arGameCoordinator(self, didCreateInkConflict: newInkSpot, with: existingSpot, overlapArea: overlapResult.overlapArea)
    }
}

// MARK: ARGameFieldRepositoryDelegate

extension ARGameCoordinator: ARGameFieldRepositoryDelegate {
    public func gameFieldRepository(_: ARGameFieldRepository, didSetupField _: ARAnchor) {
        // Handled in session delegate
    }

    public func gameFieldRepository(_: ARGameFieldRepository, didUpdateField _: ARAnchor) {
        // Handled in session delegate
    }

    public func gameFieldRepositoryDidRemoveField(_: ARGameFieldRepository) {
        // Handled in session delegate
    }

    public func gameFieldRepository(_: ARGameFieldRepository, didFailToSetupField error: GameFieldError) {
        delegate?.arGameCoordinator(self, didFailWithError: error)
    }
}

// MARK: ARInkRendererDelegate

extension ARGameCoordinator: ARInkRendererDelegate {
    public func inkRenderer(_: ARInkRenderer, didAddInkSpot _: InkSpot) {
        // Optional: Additional processing when ink spot is added
    }

    public func inkRenderer(_: ARInkRenderer, didRemoveInkSpot _: InkSpotId) {
        // Optional: Additional processing when ink spot is removed
    }

    public func inkRenderer(_: ARInkRenderer, didUpdateInkSpot _: InkSpot) {
        // Optional: Additional processing when ink spot is updated
    }

    public func inkRendererDidClearAllInkSpots(_: ARInkRenderer) {
        // Optional: Additional processing when all ink spots are cleared
    }
}

// MARK: ARSessionDelegate

extension ARGameCoordinator: ARSessionDelegate {
    // Implementation provided above in the class
}

// MARK: - ARGameCoordinatorDelegate

public protocol ARGameCoordinatorDelegate: AnyObject {
    func arGameCoordinatorDidStartSession(_ coordinator: ARGameCoordinator)
    func arGameCoordinatorDidStopSession(_ coordinator: ARGameCoordinator)
    func arGameCoordinatorWasInterrupted(_ coordinator: ARGameCoordinator)
    func arGameCoordinatorInterruptionEnded(_ coordinator: ARGameCoordinator)

    func arGameCoordinator(_ coordinator: ARGameCoordinator, didSetupGameField anchor: ARAnchor)
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didUpdateGameField anchor: ARAnchor)
    func arGameCoordinatorDidLoseGameField(_ coordinator: ARGameCoordinator)

    func arGameCoordinator(_ coordinator: ARGameCoordinator, didShootInk inkSpot: InkSpot, at position: Position3D)
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didUpdateTrackingQuality quality: ARTrackingQuality.TrackingQuality)

    func arGameCoordinator(_ coordinator: ARGameCoordinator, didFailWithError error: Error)

    // Collision detection methods
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didDetectPlayerCollision playerId: PlayerId, at position: Position3D, effect: PlayerCollisionEffect)
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didProcessInkSpotOverlap inkSpot: InkSpot, overlaps: [(InkSpot, InkSpotOverlapResult)])
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didMergeInkSpots originalSpots: [InkSpot], into mergedSpot: InkSpot)
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didCreateInkConflict newSpot: InkSpot, with existingSpot: InkSpot, overlapArea: Float)
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didUpdatePlayerPosition position: Position3D)
}
