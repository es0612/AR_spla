import ARKit
import Domain
import RealityKit
import SwiftUI

struct ARGameViewRepresentable: UIViewControllerRepresentable {
    let gameState: GameState?

    init(gameState: GameState? = nil) {
        self.gameState = gameState
    }

    func makeUIViewController(context: Context) -> ARViewController {
        let arViewController = ARViewController()
        arViewController.delegate = context.coordinator

        if let gameState = gameState {
            arViewController.configure(with: gameState)
        }

        return arViewController
    }

    func updateUIViewController(_ uiViewController: ARViewController, context _: Context) {
        if let gameState = gameState {
            uiViewController.configure(with: gameState)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, ARViewControllerDelegate {
        var gameState: GameState?
        private var isGameFieldReady = false
        private var arGameCoordinator: ARGameCoordinator?

        // MARK: - ARViewControllerDelegate

        func arViewControllerDidStartSession(_: ARViewController) {
            print("AR session started")
        }

        func arViewControllerDidStopSession(_: ARViewController) {
            print("AR session stopped")
            isGameFieldReady = false
        }

        func arViewControllerWasInterrupted(_: ARViewController) {
            print("AR session was interrupted")
        }

        func arViewControllerInterruptionEnded(_: ARViewController) {
            print("AR session interruption ended")
        }

        func arViewController(_: ARViewController, didDetectGameField _: ARAnchor) {
            print("Game field detected")
            // Notify user that game field is ready
        }

        func arViewController(_ controller: ARViewController, didSetupGameField _: ARAnchor) {
            print("Game field setup complete")
            isGameFieldReady = true
            arGameCoordinator = controller.gameCoordinator
        }

        func arViewController(_: ARViewController, didLoseGameField _: ARAnchor) {
            print("Game field lost")
            isGameFieldReady = false
        }

        func arViewController(_: ARViewController, didUpdateCoverage _: Float) {
            // Update game state with coverage information
            Task { @MainActor in
                // Coverage calculation will be handled by the game coordinator
            }
        }

        func arViewController(_: ARViewController, didShootInkAt position: Position3D, color _: PlayerColor) {
            print("Ink shot at position: \(position)")
        }

        func arViewController(_: ARViewController, didAddInkSpot position: Position3D, color _: PlayerColor) {
            print("Ink spot added at position: \(position)")
        }

        func arViewController(_: ARViewController, didDetectCollision playerId: PlayerId, at position: Position3D) {
            print("Collision detected for player: \(playerId) at position: \(position)")
            // Handle player collision (e.g., temporary disable)
        }

        func arViewController(_: ARViewController, didFailWithError error: Error) {
            print("AR error: \(error.localizedDescription)")
            Task { @MainActor in
                gameState?.lastError = error
                gameState?.isShowingError = true
            }
        }
    }
}
