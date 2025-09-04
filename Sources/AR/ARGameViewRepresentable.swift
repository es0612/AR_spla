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

            // Provide visual feedback for successful ink shot
            Task { @MainActor in
                // Could trigger UI feedback here
            }
        }

        func arViewController(_: ARViewController, didAddInkSpot position: Position3D, color _: PlayerColor) {
            print("Ink spot added at position: \(position)")

            // Update game state with new ink spot
            Task { @MainActor in
                // The ink spot is already handled by the game coordinator
                // This is mainly for UI feedback and network synchronization
            }
        }

        func arViewController(_: ARViewController, didDetectCollision playerId: PlayerId, at position: Position3D) {
            print("Collision detected for player: \(playerId) at position: \(position)")

            // Handle player collision with ink
            Task { @MainActor in
                await handlePlayerInkCollision(playerId: playerId, at: position)
            }
        }

        /// Handle player collision with ink
        private func handlePlayerInkCollision(playerId: PlayerId, at _: Position3D) async {
            guard let gameState = gameState else { return }

            // Find the player and temporarily deactivate them
            if let playerIndex = gameState.players.firstIndex(where: { $0.id == playerId }) {
                let player = gameState.players[playerIndex]

                // Deactivate player for a short duration (3 seconds)
                let deactivatedPlayer = player.deactivate()
                gameState.players[playerIndex] = deactivatedPlayer

                // Reactivate player after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    Task { @MainActor in
                        if let currentIndex = gameState.players.firstIndex(where: { $0.id == playerId }) {
                            let reactivatedPlayer = gameState.players[currentIndex].activate()
                            gameState.players[currentIndex] = reactivatedPlayer
                        }
                    }
                }

                print("Player \(playerId) deactivated for 3 seconds due to ink collision")
            }
        }

        func arViewController(_: ARViewController, didFailWithError error: Error) {
            print("AR error: \(error.localizedDescription)")
            Task { @MainActor in
                gameState?.lastError = error
                gameState?.isShowingError = true
            }
        }

        // MARK: - Collision Detection Methods

        func arViewController(_: ARViewController, didDetectPlayerCollision playerId: PlayerId, at position: Position3D, effect: PlayerCollisionEffect) {
            print("Player collision detected: \(playerId) at \(position) with effect: \(effect)")

            Task { @MainActor in
                await gameState?.handlePlayerCollision(playerId: playerId, effect: effect)
            }
        }

        func arViewController(_: ARViewController, didProcessInkSpotOverlap inkSpot: InkSpot, overlaps: [(InkSpot, InkSpotOverlapResult)]) {
            print("Ink spot overlap processed: \(overlaps.count) overlaps")

            Task { @MainActor in
                await gameState?.handleInkSpotOverlap(inkSpot: inkSpot, overlaps: overlaps)
            }
        }

        func arViewController(_: ARViewController, didMergeInkSpots originalSpots: [InkSpot], into mergedSpot: InkSpot) {
            print("Ink spots merged: \(originalSpots.count) spots into 1")

            Task { @MainActor in
                await gameState?.handleInkSpotMerge(originalSpots: originalSpots, mergedSpot: mergedSpot)
            }
        }

        func arViewController(_: ARViewController, didCreateInkConflict newSpot: InkSpot, with existingSpot: InkSpot, overlapArea: Float) {
            print("Ink conflict created with overlap area: \(overlapArea)")

            Task { @MainActor in
                await gameState?.handleInkSpotConflict(newSpot: newSpot, existingSpot: existingSpot, overlapArea: overlapArea)
            }
        }

        func arViewController(_: ARViewController, didUpdatePlayerPosition _: Position3D) {
            // Player position is already updated in ARViewController
            // This is mainly for additional UI feedback if needed
        }
    }
}
