import Foundation
import Domain

/// Use case for starting a new game session
public struct StartGameUseCase {
    private let gameRepository: GameRepository
    private let playerRepository: PlayerRepository
    private let gameRuleService: GameRuleService
    
    /// Create a StartGameUseCase
    public init(
        gameRepository: GameRepository,
        playerRepository: PlayerRepository,
        gameRuleService: GameRuleService = GameRuleService()
    ) {
        self.gameRepository = gameRepository
        self.playerRepository = playerRepository
        self.gameRuleService = gameRuleService
    }
    
    /// Execute the start game use case
    /// - Parameters:
    ///   - players: The players participating in the game
    ///   - duration: Game duration in seconds (default: 180)
    /// - Returns: The started game session
    /// - Throws: StartGameError if the game cannot be started
    public func execute(
        players: [Player],
        duration: TimeInterval = 180
    ) async throws -> GameSession {
        // Validate input
        try validatePlayers(players)
        try validateDuration(duration)
        
        // Save players to repository
        for player in players {
            try await playerRepository.save(player)
        }
        
        // Create game session
        let gameSession = GameSession(
            id: GameSessionId(),
            players: players,
            duration: duration
        )
        
        // Validate game session according to rules
        guard gameRuleService.isValidGameSession(gameSession) else {
            throw StartGameError.invalidGameSession
        }
        
        // Start the game
        let startedGameSession = gameSession.start()
        
        // Save the started game session
        try await gameRepository.save(startedGameSession)
        
        return startedGameSession
    }
    
    // MARK: - Private Methods
    
    private func validatePlayers(_ players: [Player]) throws {
        guard !players.isEmpty else {
            throw StartGameError.noPlayers
        }
        
        guard GameSession.isValidPlayerCount(players.count) else {
            throw StartGameError.invalidPlayerCount(players.count)
        }
        
        // Check for duplicate player names
        let playerNames = Set(players.map { $0.name })
        guard playerNames.count == players.count else {
            throw StartGameError.duplicatePlayerNames
        }
        
        // Check for duplicate player colors
        let playerColors = Set(players.map { $0.color })
        guard playerColors.count == players.count else {
            throw StartGameError.duplicatePlayerColors
        }
        
        // Validate each player
        for player in players {
            guard Player.isValidName(player.name) else {
                throw StartGameError.invalidPlayerName(player.name)
            }
        }
    }
    
    private func validateDuration(_ duration: TimeInterval) throws {
        guard GameSession.isValidDuration(duration) else {
            throw StartGameError.invalidDuration(duration)
        }
    }
}

/// Errors that can occur when starting a game
public enum StartGameError: Error, LocalizedError, Equatable {
    case noPlayers
    case invalidPlayerCount(Int)
    case duplicatePlayerNames
    case duplicatePlayerColors
    case invalidPlayerName(String)
    case invalidDuration(TimeInterval)
    case invalidGameSession
    
    public var errorDescription: String? {
        switch self {
        case .noPlayers:
            return "At least one player is required to start a game"
        case .invalidPlayerCount(let count):
            return "Invalid player count: \(count). Expected \(GameSession.requiredPlayerCount) players"
        case .duplicatePlayerNames:
            return "All players must have unique names"
        case .duplicatePlayerColors:
            return "All players must have unique colors"
        case .invalidPlayerName(let name):
            return "Invalid player name: \(name)"
        case .invalidDuration(let duration):
            return "Invalid game duration: \(duration) seconds. Must be between \(GameSession.minDuration) and \(GameSession.maxDuration) seconds"
        case .invalidGameSession:
            return "The game session does not meet the required rules"
        }
    }
}