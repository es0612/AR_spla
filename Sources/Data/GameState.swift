import Application
import Domain
import Foundation
import Infrastructure
import SwiftUI

// MARK: - GameState

/// Observable game state that manages the overall application state
@Observable
public class GameState {
    // MARK: - Game Coordinator

    private let gameCoordinator: GameCoordinator

    // MARK: - Published Properties

    public var currentPhase: GamePhase = .waiting
    public var players: [Player] = []
    public var currentGameSession: GameSession?
    public var winner: Player?
    // Temporarily removed gameResults to fix compilation issues
    // public var gameResults: [GameResult] = []
    public var remainingTime: TimeInterval = 0
    public var totalCoverage: Float = 0.0
    public var lastError: Error?

    // MARK: - UI State

    public var isShowingError = false
    public var isConnecting = false
    public var isGameActive = false

    // MARK: - Settings

    public var playerName = "プレイヤー1"
    public var gameDuration: TimeInterval = 180
    public var soundEnabled = true
    public var hapticEnabled = true

    // MARK: - Initialization

    public init() {
        // Create repositories
        let gameRepository = InMemoryGameRepository()
        let playerRepository = InMemoryPlayerRepository()

        // Initialize game coordinator
        gameCoordinator = GameCoordinator(
            gameRepository: gameRepository,
            playerRepository: playerRepository
        )

        // Load settings
        loadSettings()
    }

    // MARK: - Game Actions

    /// Start a new game with the specified players
    @MainActor
    public func startGame(with players: [Player]) async {
        do {
            currentPhase = .connecting
            isConnecting = true

            try await gameCoordinator.startGame(with: players, duration: gameDuration)

            // Update state from coordinator
            updateStateFromCoordinator()

            isConnecting = false
            isGameActive = true
        } catch {
            handleError(error)
            isConnecting = false
        }
    }

    /// Shoot ink at the specified position
    @MainActor
    public func shootInk(playerId: PlayerId, at position: Position3D, size: Float = 0.5) async {
        do {
            try await gameCoordinator.shootInk(playerId: playerId, at: position, size: size)
            updateStateFromCoordinator()

            // Send network message for multiplayer synchronization
            await sendInkShotMessage(playerId: playerId, position: position, size: size)
        } catch {
            handleError(error)
        }
    }

    /// Handle ink shot from network (remote player)
    @MainActor
    public func handleRemoteInkShot(playerId: PlayerId, at position: Position3D, size: Float) async {
        do {
            // Add ink spot without triggering network message
            try await gameCoordinator.shootInk(playerId: playerId, at: position, size: size)
            updateStateFromCoordinator()
        } catch {
            handleError(error)
        }
    }

    /// Handle player collision with ink
    @MainActor
    public func handlePlayerInkCollision(playerId: PlayerId, at position: Position3D) async {
        // Find the player and temporarily deactivate them
        if let playerIndex = players.firstIndex(where: { $0.id == playerId }) {
            let player = players[playerIndex]

            // Only deactivate if player is currently active
            guard player.isActive else { return }

            // Deactivate player
            let deactivatedPlayer = player.deactivate()
            players[playerIndex] = deactivatedPlayer

            print("Player \(playerId) deactivated due to ink collision at \(position)")

            // Reactivate player after 3 seconds
            Task {
                try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds

                await MainActor.run {
                    if let currentIndex = self.players.firstIndex(where: { $0.id == playerId }) {
                        let reactivatedPlayer = self.players[currentIndex].activate()
                        self.players[currentIndex] = reactivatedPlayer
                        print("Player \(playerId) reactivated")
                    }
                }
            }
        }
    }

    /// Send ink shot message to network
    private func sendInkShotMessage(playerId: PlayerId, position: Position3D, size: Float) async {
        // This will be implemented when network integration is added
        // For now, this is a placeholder for the network synchronization
        print("Sending ink shot message: player=\(playerId), position=\(position), size=\(size)")
    }

    /// End the current game
    @MainActor
    public func endGame() async {
        do {
            try await gameCoordinator.endGame()
            updateStateFromCoordinator()
            isGameActive = false
        } catch {
            handleError(error)
        }
    }

    /// Reset the game state
    @MainActor
    public func resetGame() {
        gameCoordinator.reset()
        updateStateFromCoordinator()
        isGameActive = false
        isConnecting = false
        clearError()
    }

    // MARK: - Player Management

    /// Get the current player's score
    public func getCurrentPlayerScore() -> GameScore? {
        guard let currentPlayer = players.first else { return nil }
        return gameCoordinator.getPlayerScore(currentPlayer.id)
    }

    /// Get players sorted by score
    public var playersByScore: [Player] {
        gameCoordinator.playersByScore
    }

    /// Check if a player is active
    public func isPlayerActive(_ playerId: PlayerId) -> Bool {
        gameCoordinator.isPlayerActive(playerId)
    }

    // MARK: - Settings Management

    /// Save current settings to UserDefaults
    public func saveSettings() {
        UserDefaults.standard.set(playerName, forKey: "playerName")
        UserDefaults.standard.set(gameDuration, forKey: "gameDuration")
        UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled")
        UserDefaults.standard.set(hapticEnabled, forKey: "hapticEnabled")
    }

    /// Load settings from UserDefaults
    private func loadSettings() {
        playerName = UserDefaults.standard.string(forKey: "playerName") ?? "プレイヤー1"
        gameDuration = UserDefaults.standard.double(forKey: "gameDuration")
        if gameDuration == 0 { gameDuration = 180 }
        soundEnabled = UserDefaults.standard.bool(forKey: "soundEnabled")
        hapticEnabled = UserDefaults.standard.bool(forKey: "hapticEnabled")
    }

    // MARK: - Collision Handling

    /// Handle player collision with ink spot
    @MainActor
    public func handlePlayerCollision(playerId: PlayerId, effect: PlayerCollisionEffect) async {
        guard let playerIndex = players.firstIndex(where: { $0.id == playerId }) else { return }
        let player = players[playerIndex]

        switch effect {
        case .none:
            // No effect, player continues normally
            break

        case let .stunned(duration, speedReduction):
            print("Player \(playerId) stunned for \(duration)s with \(speedReduction * 100)% speed reduction")

            // Deactivate player temporarily
            let stunnedPlayer = player.deactivate()
            players[playerIndex] = stunnedPlayer

            // Provide haptic feedback
            if hapticEnabled {
                let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
                impactFeedback.impactOccurred()
            }

            // Reactivate player after stun duration
            Task {
                try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))

                await MainActor.run {
                    if let currentIndex = self.players.firstIndex(where: { $0.id == playerId }) {
                        let reactivatedPlayer = self.players[currentIndex].activate()
                        self.players[currentIndex] = reactivatedPlayer
                        print("Player \(playerId) reactivated after stun")
                    }
                }
            }
        }

        // Update game state
        updateStateFromCoordinator()
    }

    /// Handle ink spot overlap
    @MainActor
    public func handleInkSpotOverlap(inkSpot _: InkSpot, overlaps: [(InkSpot, InkSpotOverlapResult)]) async {
        print("Ink spot overlap detected: \(overlaps.count) overlapping spots")

        // Update game state
        updateStateFromCoordinator()
    }

    /// Handle ink spot merge
    @MainActor
    public func handleInkSpotMerge(originalSpots: [InkSpot], mergedSpot _: InkSpot) async {
        print("Ink spots merged: \(originalSpots.count) spots into 1")

        // Update game state
        updateStateFromCoordinator()
    }

    /// Handle ink spot conflict
    @MainActor
    public func handleInkSpotConflict(newSpot _: InkSpot, existingSpot _: InkSpot, overlapArea: Float) async {
        print("Ink spot conflict detected with overlap area: \(overlapArea)")

        // Update game state
        updateStateFromCoordinator()
    }

    // MARK: - Error Handling

    private func handleError(_ error: Error) {
        lastError = error
        isShowingError = true
        print("GameState Error: \(error.localizedDescription)")
    }

    public func clearError() {
        lastError = nil
        isShowingError = false
    }

    // MARK: - Private Methods

    private func updateStateFromCoordinator() {
        currentPhase = gameCoordinator.gamePhase
        players = gameCoordinator.players
        currentGameSession = gameCoordinator.currentGameSession
        winner = gameCoordinator.winner
        // gameResults = gameCoordinator.gameResults
        remainingTime = gameCoordinator.remainingTime
        totalCoverage = gameCoordinator.totalCoverage

        if let error = gameCoordinator.lastError {
            handleError(error)
        }
    }
}

// MARK: - Computed Properties

public extension GameState {
    /// Formatted remaining time string
    var formattedRemainingTime: String {
        let minutes = Int(remainingTime) / 60
        let seconds = Int(remainingTime) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }

    /// Current game progress (0.0 to 1.0)
    var gameProgress: Double {
        guard gameDuration > 0 else { return 0 }
        return max(0, min(1, (gameDuration - remainingTime) / gameDuration))
    }

    /// Coverage percentage for display
    var coveragePercentage: Int {
        Int(totalCoverage * 100)
    }
}
