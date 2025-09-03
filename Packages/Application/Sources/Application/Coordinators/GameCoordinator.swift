import Domain
import Foundation

// MARK: - GameCoordinator

/// Coordinator for managing the overall game flow and state transitions
public class GameCoordinator {
    // MARK: - Dependencies

    private let startGameUseCase: StartGameUseCase
    private let shootInkUseCase: ShootInkUseCase
    private let calculateScoreUseCase: CalculateScoreUseCase
    private let gameRepository: GameRepository
    private let playerRepository: PlayerRepository

    // MARK: - Published State

    public private(set) var currentGameSession: GameSession?
    public private(set) var gamePhase: GamePhase = .waiting
    public private(set) var players: [Player] = []
    public private(set) var winner: Player?
    public private(set) var gameResults: [GameResult] = []
    public private(set) var lastError: Error?

    // MARK: - Game State

    public var isGameActive: Bool {
        currentGameSession?.status == .active
    }

    public var remainingTime: TimeInterval {
        currentGameSession?.remainingTime ?? 0
    }

    public var totalCoverage: Float = 0.0

    // MARK: - Initialization

    /// Create a GameCoordinator
    public init(
        gameRepository: GameRepository,
        playerRepository: PlayerRepository,
        gameRuleService: GameRuleService = GameRuleService(),
        scoreCalculationService: ScoreCalculationService = ScoreCalculationService(),
        fieldSize: Float = 16.0
    ) {
        self.gameRepository = gameRepository
        self.playerRepository = playerRepository

        startGameUseCase = StartGameUseCase(
            gameRepository: gameRepository,
            playerRepository: playerRepository,
            gameRuleService: gameRuleService
        )

        shootInkUseCase = ShootInkUseCase(
            gameRepository: gameRepository,
            playerRepository: playerRepository,
            gameRuleService: gameRuleService
        )

        calculateScoreUseCase = CalculateScoreUseCase(
            gameRepository: gameRepository,
            playerRepository: playerRepository,
            scoreCalculationService: scoreCalculationService,
            fieldSize: fieldSize
        )
    }

    // MARK: - Game Flow Methods

    /// Start a new game with the given players
    /// - Parameters:
    ///   - players: The players to participate in the game
    ///   - duration: Game duration in seconds (default: 180)
    /// - Throws: GameCoordinatorError if the game cannot be started
    public func startGame(with players: [Player], duration: TimeInterval = 180) async throws {
        do {
            clearError()
            gamePhase = .connecting

            // Start the game using the use case
            let gameSession = try await startGameUseCase.execute(players: players, duration: duration)

            // Update state
            currentGameSession = gameSession
            self.players = gameSession.players
            gamePhase = .playing
            winner = nil
            gameResults = []
            totalCoverage = 0.0
        } catch {
            gamePhase = .waiting
            lastError = error
            throw GameCoordinatorError.gameStartFailed(error)
        }
    }

    /// Shoot ink at the specified position
    /// - Parameters:
    ///   - playerId: The ID of the player shooting ink
    ///   - position: The position where the ink should be placed
    ///   - size: The size of the ink spot (default: 0.5)
    /// - Throws: GameCoordinatorError if the ink cannot be shot
    public func shootInk(playerId: PlayerId, at position: Position3D, size: Float = 0.5) async throws {
        guard let gameSession = currentGameSession else {
            throw GameCoordinatorError.noActiveGame
        }

        do {
            clearError()

            // Shoot ink using the use case
            let updatedGameSession = try await shootInkUseCase.execute(
                gameSessionId: gameSession.id,
                playerId: playerId,
                position: position,
                size: size
            )

            // Update state
            currentGameSession = updatedGameSession
            players = updatedGameSession.players

            // Update total coverage
            totalCoverage = try await calculateScoreUseCase.calculateTotalCoverage(
                gameSessionId: updatedGameSession.id
            )

            // Check if game should end
            await checkGameEndConditions()
        } catch {
            lastError = error
            throw GameCoordinatorError.inkShotFailed(error)
        }
    }

    /// End the current game
    /// - Throws: GameCoordinatorError if the game cannot be ended
    public func endGame() async throws {
        guard let gameSession = currentGameSession else {
            throw GameCoordinatorError.noActiveGame
        }

        do {
            clearError()

            // End the game session
            let endedGameSession = gameSession.end()

            // Calculate final scores and results
            let results = try await calculateScoreUseCase.calculateGameResults(
                gameSessionId: gameSession.id
            )

            // Determine winner
            let gameWinner = try await calculateScoreUseCase.determineWinner(
                gameSessionId: gameSession.id
            )

            // Update final state
            currentGameSession = endedGameSession
            gameResults = results
            winner = gameWinner
            gamePhase = .finished

            // Save the ended game session
            try await gameRepository.update(endedGameSession)
        } catch {
            lastError = error
            throw GameCoordinatorError.gameEndFailed(error)
        }
    }

    /// Reset the coordinator to initial state
    public func reset() {
        currentGameSession = nil
        gamePhase = .waiting
        players = []
        winner = nil
        gameResults = []
        totalCoverage = 0.0
        clearError()
    }

    /// Get the current score for a specific player
    /// - Parameter playerId: The ID of the player
    /// - Returns: The player's current score, or nil if player not found
    public func getPlayerScore(_ playerId: PlayerId) -> GameScore? {
        players.first { $0.id == playerId }?.score
    }

    /// Get all players sorted by score (highest first)
    public var playersByScore: [Player] {
        players.sorted { $0.score > $1.score }
    }

    /// Check if a specific player is active
    /// - Parameter playerId: The ID of the player
    /// - Returns: True if the player is active, false otherwise
    public func isPlayerActive(_ playerId: PlayerId) -> Bool {
        players.first { $0.id == playerId }?.isActive ?? false
    }

    // MARK: - Private Methods

    private func checkGameEndConditions() async {
        guard let gameSession = currentGameSession else { return }

        // Check if time is up or game should end for other reasons
        if gameSession.remainingTime <= 0 {
            do {
                try await endGame()
            } catch {
                lastError = error
            }
        }
    }

    private func clearError() {
        lastError = nil
    }
}

// MARK: - GamePhase

/// Game phases representing the current state of the game
public enum GamePhase: String, CaseIterable {
    case waiting
    case connecting
    case playing
    case finished
}

// MARK: - GameCoordinatorError

/// Errors that can occur in the GameCoordinator
public enum GameCoordinatorError: Error, LocalizedError, Equatable {
    case noActiveGame
    case gameStartFailed(Error)
    case inkShotFailed(Error)
    case gameEndFailed(Error)

    public var errorDescription: String? {
        switch self {
        case .noActiveGame:
            return "No active game session"
        case let .gameStartFailed(error):
            return "Failed to start game: \(error.localizedDescription)"
        case let .inkShotFailed(error):
            return "Failed to shoot ink: \(error.localizedDescription)"
        case let .gameEndFailed(error):
            return "Failed to end game: \(error.localizedDescription)"
        }
    }

    public static func == (lhs: GameCoordinatorError, rhs: GameCoordinatorError) -> Bool {
        switch (lhs, rhs) {
        case (.noActiveGame, .noActiveGame):
            return true
        case (.gameStartFailed, .gameStartFailed),
             (.inkShotFailed, .inkShotFailed),
             (.gameEndFailed, .gameEndFailed):
            return true
        default:
            return false
        }
    }
}

// MARK: - GameCoordinator + CustomStringConvertible

extension GameCoordinator: CustomStringConvertible {
    public var description: String {
        "GameCoordinator(phase: \(gamePhase), players: \(players.count), active: \(isGameActive))"
    }
}
