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

// MARK: - ARGameCoordinator

/// Coordinates AR game functionality between field management and ink rendering
public class ARGameCoordinator: ObservableObject {
    // MARK: - Properties

    private let arView: ARView
    private let gameFieldRepository: ARGameFieldRepository
    private let inkRenderer: ARInkRenderer

    @Published public var gameFieldState: GameFieldState = .notDetected
    @Published public var arSessionState: ARSessionState = .notStarted
    @Published public var trackingQuality: ARTrackingQuality.TrackingQuality = .poor

    private let performanceMonitor = ARPerformanceMonitor()

    weak var delegate: ARGameCoordinatorDelegate?

    // MARK: - Initialization

    public init(arView: ARView, fieldSize: CGSize = CGSize(width: 4.0, height: 4.0)) {
        self.arView = arView
        gameFieldRepository = ARGameFieldRepository(arView: arView, fieldSize: fieldSize)
        inkRenderer = ARInkRenderer(arView: arView)

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

    /// Handle tap gesture to shoot ink
    public func handleTap(at screenPoint: CGPoint, for player: Player) -> Bool {
        guard gameFieldState.isReady else {
            delegate?.arGameCoordinator(self, didFailWithError: ARError.gameFieldNotFound)
            return false
        }

        // Convert screen point to world position
        guard let worldPosition = ARCoordinateSystem.screenToWorldPosition(screenPoint, in: arView) else {
            return false
        }

        // Check if position is within game field
        guard gameFieldRepository.isPositionInField(worldPosition) else {
            return false
        }

        // Convert to game coordinates
        guard let gamePosition = gameFieldRepository.worldToGameCoordinates(worldPosition) else {
            return false
        }

        // Create ink spot
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: gamePosition,
            color: player.color,
            size: 1.0, // Default size
            ownerId: player.id
        )

        // Create world transform for rendering
        let worldTransform = simd_float4x4(
            SIMD4<Float>(1, 0, 0, worldPosition.x),
            SIMD4<Float>(0, 1, 0, worldPosition.y),
            SIMD4<Float>(0, 0, 1, worldPosition.z),
            SIMD4<Float>(0, 0, 0, 1)
        )

        // Add ink spot to renderer
        inkRenderer.addInkSpot(inkSpot, at: worldTransform)

        // Notify delegate
        delegate?.arGameCoordinator(self, didShootInk: inkSpot, at: gamePosition)

        return true
    }

    /// Add ink spot from network or game logic
    public func addInkSpot(_ inkSpot: InkSpot) -> Bool {
        guard gameFieldState.isReady else { return false }

        // Convert game position to world position
        guard let worldPosition = gameFieldRepository.gameToWorldCoordinates(inkSpot.position) else {
            return false
        }

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

        // Update delegate
        delegate?.arGameCoordinator(self, didUpdateTrackingQuality: trackingQuality)
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
}
