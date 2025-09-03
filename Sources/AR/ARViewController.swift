import ARKit
import Domain
import RealityKit
import UIKit

// MARK: - ARViewController

/// ARViewController manages the AR session and game field setup
class ARViewController: UIViewController {
    // MARK: - Properties

    private var arView: ARView!
    private var arGameCoordinator: ARGameCoordinator!
    private weak var gameState: GameState?

    // Delegates
    weak var delegate: ARViewControllerDelegate?

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        setupARView()
        setupARGameCoordinator()
        setupGestures()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        arGameCoordinator.stopARSession()
    }

    // MARK: - Public Methods

    /// Configure the AR controller with game state
    func configure(with gameState: GameState) {
        self.gameState = gameState
    }

    /// Start the AR session
    func startARSession() {
        arGameCoordinator.startARSession()
    }

    /// Stop the AR session
    func stopARSession() {
        arGameCoordinator.stopARSession()
    }

    /// Handle tap gesture for ink shooting
    func handleTap(at location: CGPoint) {
        guard let gameState = gameState,
              gameState.isGameActive,
              let currentPlayer = gameState.players.first else { return }

        // Use AR game coordinator to handle tap
        let success = arGameCoordinator.handleTap(at: location, for: currentPlayer)

        if success {
            // Update game state
            Task { @MainActor in
                // The actual ink spot creation is handled by the coordinator delegate
            }
        }
    }

    // MARK: - Private Methods

    private func setupARView() {
        arView = ARView(frame: view.bounds)
        arView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(arView)
    }

    private func setupARGameCoordinator() {
        arGameCoordinator = ARGameCoordinator(arView: arView)
        arGameCoordinator.delegate = self
    }

    private func setupGestures() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        arView.addGestureRecognizer(tapGesture)
    }

    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: arView)
        handleTap(at: location)
    }

    /// Get the AR game coordinator for external access
    var gameCoordinator: ARGameCoordinator {
        arGameCoordinator
    }
}

// MARK: ARGameCoordinatorDelegate

extension ARViewController: ARGameCoordinatorDelegate {
    func arGameCoordinatorDidStartSession(_: ARGameCoordinator) {
        delegate?.arViewControllerDidStartSession(self)
    }

    func arGameCoordinatorDidStopSession(_: ARGameCoordinator) {
        delegate?.arViewControllerDidStopSession(self)
    }

    func arGameCoordinatorWasInterrupted(_: ARGameCoordinator) {
        delegate?.arViewControllerWasInterrupted(self)
    }

    func arGameCoordinatorInterruptionEnded(_: ARGameCoordinator) {
        delegate?.arViewControllerInterruptionEnded(self)
    }

    func arGameCoordinator(_: ARGameCoordinator, didSetupGameField anchor: ARAnchor) {
        delegate?.arViewController(self, didSetupGameField: anchor)
    }

    func arGameCoordinator(_: ARGameCoordinator, didUpdateGameField _: ARAnchor) {
        // Optional: Handle field updates
    }

    func arGameCoordinatorDidLoseGameField(_ coordinator: ARGameCoordinator) {
        delegate?.arViewController(self, didLoseGameField: coordinator.currentFieldAnchor ?? ARPlaneAnchor())
    }

    func arGameCoordinator(_: ARGameCoordinator, didShootInk inkSpot: InkSpot, at position: Position3D) {
        delegate?.arViewController(self, didShootInkAt: position, color: inkSpot.color)

        // Update game state
        Task { @MainActor in
            await gameState?.shootInk(
                playerId: inkSpot.ownerId,
                at: position,
                size: inkSpot.size
            )
        }
    }

    func arGameCoordinator(_: ARGameCoordinator, didUpdateTrackingQuality quality: ARTrackingQuality.TrackingQuality) {
        // Optional: Handle tracking quality updates
        if let message = quality.userMessage {
            // Could show tracking quality message to user
        }
    }

    func arGameCoordinator(_: ARGameCoordinator, didFailWithError error: Error) {
        delegate?.arViewController(self, didFailWithError: error)
    }
}

// MARK: - ARViewControllerDelegate

protocol ARViewControllerDelegate: AnyObject {
    func arViewControllerDidStartSession(_ controller: ARViewController)
    func arViewControllerDidStopSession(_ controller: ARViewController)
    func arViewControllerWasInterrupted(_ controller: ARViewController)
    func arViewControllerInterruptionEnded(_ controller: ARViewController)

    func arViewController(_ controller: ARViewController, didDetectGameField anchor: ARAnchor)
    func arViewController(_ controller: ARViewController, didSetupGameField anchor: ARAnchor)
    func arViewController(_ controller: ARViewController, didLoseGameField anchor: ARAnchor)
    func arViewController(_ controller: ARViewController, didUpdateCoverage coverage: Float)

    func arViewController(_ controller: ARViewController, didShootInkAt position: Position3D, color: PlayerColor)
    func arViewController(_ controller: ARViewController, didAddInkSpot position: Position3D, color: PlayerColor)
    func arViewController(_ controller: ARViewController, didDetectCollision playerId: PlayerId, at position: Position3D)

    func arViewController(_ controller: ARViewController, didFailWithError error: Error)
}
