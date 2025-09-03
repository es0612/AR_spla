import Domain
import Foundation

// MARK: - CalculateScoreUseCase

/// Use case for calculating scores in the game
public struct CalculateScoreUseCase {
    private let gameRepository: GameRepository
    private let playerRepository: PlayerRepository
    private let scoreCalculationService: ScoreCalculationService

    /// Field size for score calculation (in square meters)
    private let fieldSize: Float

    /// Create a CalculateScoreUseCase
    public init(
        gameRepository: GameRepository,
        playerRepository: PlayerRepository,
        scoreCalculationService: ScoreCalculationService = ScoreCalculationService(),
        fieldSize: Float = 16.0 // 4m x 4m default field
    ) {
        self.gameRepository = gameRepository
        self.playerRepository = playerRepository
        self.scoreCalculationService = scoreCalculationService
        self.fieldSize = fieldSize
    }

    /// Execute the calculate score use case for a specific player
    /// - Parameters:
    ///   - gameSessionId: The ID of the game session
    ///   - playerId: The ID of the player to calculate score for
    /// - Returns: The updated player with calculated score
    /// - Throws: CalculateScoreError if the score cannot be calculated
    public func executeForPlayer(
        gameSessionId: GameSessionId,
        playerId: PlayerId
    ) async throws -> Player {
        // Retrieve game session
        guard let gameSession = try await gameRepository.findById(gameSessionId) else {
            throw CalculateScoreError.gameSessionNotFound
        }

        // Retrieve player
        guard let player = try await playerRepository.findById(playerId) else {
            throw CalculateScoreError.playerNotFound
        }

        // Validate field size
        guard scoreCalculationService.isValidFieldSize(fieldSize) else {
            throw CalculateScoreError.invalidFieldSize
        }

        // Calculate player score
        let newScore = scoreCalculationService.calculatePlayerScore(
            playerId: playerId,
            inkSpots: gameSession.inkSpots,
            fieldSize: fieldSize
        )

        // Update player with new score
        let updatedPlayer = player.updateScore(newScore)

        // Save updated player
        try await playerRepository.update(updatedPlayer)

        return updatedPlayer
    }

    /// Execute the calculate score use case for all players in a game
    /// - Parameter gameSessionId: The ID of the game session
    /// - Returns: The updated game session with all players' scores calculated
    /// - Throws: CalculateScoreError if the scores cannot be calculated
    public func executeForAllPlayers(
        gameSessionId: GameSessionId
    ) async throws -> GameSession {
        // Retrieve game session
        guard let gameSession = try await gameRepository.findById(gameSessionId) else {
            throw CalculateScoreError.gameSessionNotFound
        }

        // Validate field size
        guard scoreCalculationService.isValidFieldSize(fieldSize) else {
            throw CalculateScoreError.invalidFieldSize
        }

        // Calculate scores for all players
        var updatedPlayers: [Player] = []

        for player in gameSession.players {
            let newScore = scoreCalculationService.calculatePlayerScore(
                playerId: player.id,
                inkSpots: gameSession.inkSpots,
                fieldSize: fieldSize
            )

            let updatedPlayer = player.updateScore(newScore)
            updatedPlayers.append(updatedPlayer)

            // Save updated player
            try await playerRepository.update(updatedPlayer)
        }

        // Update game session with new player scores
        var updatedGameSession = gameSession
        for updatedPlayer in updatedPlayers {
            updatedGameSession = updatedGameSession.updatePlayer(updatedPlayer)
        }

        // Save updated game session
        try await gameRepository.update(updatedGameSession)

        return updatedGameSession
    }

    /// Calculate final game results
    /// - Parameter gameSessionId: The ID of the game session
    /// - Returns: Array of game results for all players
    /// - Throws: CalculateScoreError if the results cannot be calculated
    public func calculateGameResults(
        gameSessionId: GameSessionId
    ) async throws -> [GameResult] {
        // Retrieve game session
        guard let gameSession = try await gameRepository.findById(gameSessionId) else {
            throw CalculateScoreError.gameSessionNotFound
        }

        // Validate field size
        guard scoreCalculationService.isValidFieldSize(fieldSize) else {
            throw CalculateScoreError.invalidFieldSize
        }

        // Calculate results for all players
        let results = scoreCalculationService.calculateGameResults(
            players: gameSession.players,
            inkSpots: gameSession.inkSpots,
            fieldSize: fieldSize
        )

        return results
    }

    /// Calculate total field coverage
    /// - Parameter gameSessionId: The ID of the game session
    /// - Returns: Total coverage percentage (0-100)
    /// - Throws: CalculateScoreError if the coverage cannot be calculated
    public func calculateTotalCoverage(
        gameSessionId: GameSessionId
    ) async throws -> Float {
        // Retrieve game session
        guard let gameSession = try await gameRepository.findById(gameSessionId) else {
            throw CalculateScoreError.gameSessionNotFound
        }

        // Validate field size
        guard scoreCalculationService.isValidFieldSize(fieldSize) else {
            throw CalculateScoreError.invalidFieldSize
        }

        // Calculate total coverage
        let coverage = scoreCalculationService.calculateTotalCoverage(
            inkSpots: gameSession.inkSpots,
            fieldSize: fieldSize
        )

        return coverage
    }

    /// Determine the winner of a game
    /// - Parameter gameSessionId: The ID of the game session
    /// - Returns: The winning player, or nil if there's a tie
    /// - Throws: CalculateScoreError if the winner cannot be determined
    public func determineWinner(
        gameSessionId: GameSessionId
    ) async throws -> Player? {
        // First calculate scores for all players
        let updatedGameSession = try await executeForAllPlayers(gameSessionId: gameSessionId)

        // Determine winner using score calculation service
        let winner = scoreCalculationService.determineWinner(players: updatedGameSession.players)

        return winner
    }
}

// MARK: - CalculateScoreError

/// Errors that can occur when calculating scores
public enum CalculateScoreError: Error, LocalizedError, Equatable {
    case gameSessionNotFound
    case playerNotFound
    case invalidFieldSize

    public var errorDescription: String? {
        switch self {
        case .gameSessionNotFound:
            return "Game session not found"
        case .playerNotFound:
            return "Player not found"
        case .invalidFieldSize:
            return "Invalid field size for score calculation"
        }
    }
}
