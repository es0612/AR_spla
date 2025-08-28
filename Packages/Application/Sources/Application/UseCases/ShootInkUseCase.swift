import Foundation
import Domain

/// Use case for shooting ink in the game
public struct ShootInkUseCase {
    private let gameRepository: GameRepository
    private let playerRepository: PlayerRepository
    private let gameRuleService: GameRuleService
    
    /// Create a ShootInkUseCase
    public init(
        gameRepository: GameRepository,
        playerRepository: PlayerRepository,
        gameRuleService: GameRuleService = GameRuleService()
    ) {
        self.gameRepository = gameRepository
        self.playerRepository = playerRepository
        self.gameRuleService = gameRuleService
    }
    
    /// Execute the shoot ink use case
    /// - Parameters:
    ///   - gameSessionId: The ID of the game session
    ///   - playerId: The ID of the player shooting ink
    ///   - position: The position where the ink should be placed
    ///   - size: The size of the ink spot (default: 0.5)
    /// - Returns: The updated game session with the new ink spot
    /// - Throws: ShootInkError if the ink cannot be shot
    public func execute(
        gameSessionId: GameSessionId,
        playerId: PlayerId,
        position: Position3D,
        size: Float = 0.5
    ) async throws -> GameSession {
        // Retrieve game session
        guard let gameSession = try await gameRepository.findById(gameSessionId) else {
            throw ShootInkError.gameSessionNotFound
        }
        
        // Validate game state
        try validateGameState(gameSession)
        
        // Retrieve player
        guard let player = try await playerRepository.findById(playerId) else {
            throw ShootInkError.playerNotFound
        }
        
        // Validate player can shoot ink
        try validatePlayerCanShootInk(player, in: gameSession, at: position, size: size)
        
        // Create ink spot
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: position,
            color: player.color,
            size: size,
            ownerId: playerId
        )
        
        // Add ink spot to game session
        let updatedGameSession = gameSession.addInkSpot(inkSpot)
        
        // Check for player collisions with existing ink spots
        let updatedPlayers = try await checkPlayerCollisions(
            in: updatedGameSession,
            newInkSpot: inkSpot
        )
        
        // Update game session with potentially affected players
        var finalGameSession = updatedGameSession
        for updatedPlayer in updatedPlayers {
            finalGameSession = finalGameSession.updatePlayer(updatedPlayer)
        }
        
        // Save updated game session
        try await gameRepository.update(finalGameSession)
        
        // Save updated players
        for updatedPlayer in updatedPlayers {
            try await playerRepository.update(updatedPlayer)
        }
        
        return finalGameSession
    }
    
    // MARK: - Private Methods
    
    private func validateGameState(_ gameSession: GameSession) throws {
        guard gameSession.status == .active else {
            throw ShootInkError.gameNotActive
        }
        
        guard gameSession.remainingTime > 0 else {
            throw ShootInkError.gameTimeExpired
        }
    }
    
    private func validatePlayerCanShootInk(
        _ player: Player,
        in gameSession: GameSession,
        at position: Position3D,
        size: Float
    ) throws {
        // Check if player is in the game
        guard gameSession.players.contains(where: { $0.id == player.id }) else {
            throw ShootInkError.playerNotInGame
        }
        
        // Check if player is active
        guard player.isActive else {
            throw ShootInkError.playerNotActive
        }
        
        // Check if player can shoot ink at this position (using game rules)
        guard gameRuleService.canPlayerShootInk(player, at: position) else {
            throw ShootInkError.invalidPosition
        }
        
        // Check ink spot size
        guard gameRuleService.isValidInkSpotSize(size) else {
            throw ShootInkError.invalidInkSpotSize(size)
        }
        
        // Check if player has exceeded ink spot limit
        guard !gameRuleService.hasExceededInkSpotLimit(player.id, inkSpots: gameSession.inkSpots) else {
            throw ShootInkError.inkSpotLimitExceeded
        }
    }
    
    private func checkPlayerCollisions(
        in gameSession: GameSession,
        newInkSpot: InkSpot
    ) async throws -> [Player] {
        var updatedPlayers: [Player] = []
        
        for player in gameSession.players {
            // Skip the player who shot the ink
            guard player.id != newInkSpot.ownerId else { continue }
            
            // Check collision with new ink spot
            if gameRuleService.checkPlayerInkCollision(player, with: newInkSpot) {
                // Deactivate the player temporarily
                let deactivatedPlayer = player.deactivate()
                updatedPlayers.append(deactivatedPlayer)
            }
        }
        
        return updatedPlayers
    }
}

/// Errors that can occur when shooting ink
public enum ShootInkError: Error, LocalizedError, Equatable {
    case gameSessionNotFound
    case playerNotFound
    case gameNotActive
    case gameTimeExpired
    case playerNotInGame
    case playerNotActive
    case invalidPosition
    case invalidInkSpotSize(Float)
    case inkSpotLimitExceeded
    
    public var errorDescription: String? {
        switch self {
        case .gameSessionNotFound:
            return "Game session not found"
        case .playerNotFound:
            return "Player not found"
        case .gameNotActive:
            return "Game is not currently active"
        case .gameTimeExpired:
            return "Game time has expired"
        case .playerNotInGame:
            return "Player is not part of this game"
        case .playerNotActive:
            return "Player is not currently active"
        case .invalidPosition:
            return "Invalid position for shooting ink"
        case .invalidInkSpotSize(let size):
            return "Invalid ink spot size: \(size)"
        case .inkSpotLimitExceeded:
            return "Player has exceeded the maximum number of ink spots"
        }
    }
}