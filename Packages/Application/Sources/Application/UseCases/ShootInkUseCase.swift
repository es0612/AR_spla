import Domain
import Foundation

// MARK: - ShootInkUseCase

/// Use case for shooting ink in the game
public struct ShootInkUseCase {
    private let gameRepository: GameRepository
    private let playerRepository: PlayerRepository
    private let gameRuleService: GameRuleService
    private let collisionDetectionService: CollisionDetectionService

    /// Create a ShootInkUseCase
    public init(
        gameRepository: GameRepository,
        playerRepository: PlayerRepository,
        gameRuleService: GameRuleService = GameRuleService(),
        collisionDetectionService: CollisionDetectionService = CollisionDetectionService()
    ) {
        self.gameRepository = gameRepository
        self.playerRepository = playerRepository
        self.gameRuleService = gameRuleService
        self.collisionDetectionService = collisionDetectionService
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

        // Check for player collisions and ink spot overlaps
        let collisionResults = try await processCollisions(
            in: updatedGameSession,
            newInkSpot: inkSpot
        )

        // Update game session with collision results
        var finalGameSession = updatedGameSession

        // Update affected players
        for updatedPlayer in collisionResults.affectedPlayers {
            finalGameSession = finalGameSession.updatePlayer(updatedPlayer)
        }

        // Handle ink spot merges and conflicts
        finalGameSession = processInkSpotInteractions(
            gameSession: finalGameSession,
            newInkSpot: inkSpot,
            overlaps: collisionResults.inkSpotOverlaps
        )

        // Save updated game session
        try await gameRepository.update(finalGameSession)

        // Save updated players
        for updatedPlayer in collisionResults.affectedPlayers {
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

    private func processCollisions(
        in gameSession: GameSession,
        newInkSpot: InkSpot
    ) async throws -> CollisionResults {
        var affectedPlayers: [Player] = []

        // Check player collisions with detailed effects
        for player in gameSession.players {
            let effect = collisionDetectionService.calculatePlayerCollisionEffect(player, with: newInkSpot)

            if effect.isStunned {
                // Apply collision effect to player
                let affectedPlayer = applyCollisionEffect(to: player, effect: effect)
                affectedPlayers.append(affectedPlayer)
            }
        }

        // Check ink spot overlaps
        let inkSpotOverlaps = collisionDetectionService.findOverlappingInkSpots(
            newInkSpot,
            in: gameSession.inkSpots
        )

        return CollisionResults(
            affectedPlayers: affectedPlayers,
            inkSpotOverlaps: inkSpotOverlaps
        )
    }

    private func applyCollisionEffect(to player: Player, effect: PlayerCollisionEffect) -> Player {
        switch effect {
        case .none:
            return player
        case .stunned:
            // Deactivate player (in a real implementation, you might want to track stun duration)
            return player.deactivate()
        }
    }

    private func processInkSpotInteractions(
        gameSession: GameSession,
        newInkSpot: InkSpot,
        overlaps: [(InkSpot, InkSpotOverlapResult)]
    ) -> GameSession {
        var updatedGameSession = gameSession

        for (overlappingSpot, overlapResult) in overlaps {
            if overlappingSpot.color == newInkSpot.color,
               let mergedSize = overlapResult.mergedSize {
                // Merge same color ink spots
                updatedGameSession = mergeSameColorInkSpots(
                    gameSession: updatedGameSession,
                    spot1: newInkSpot,
                    spot2: overlappingSpot,
                    mergedSize: mergedSize
                )
            } else {
                // Handle different color conflicts
                updatedGameSession = handleInkSpotConflict(
                    gameSession: updatedGameSession,
                    newSpot: newInkSpot,
                    existingSpot: overlappingSpot,
                    overlapResult: overlapResult
                )
            }
        }

        return updatedGameSession
    }

    private func mergeSameColorInkSpots(
        gameSession: GameSession,
        spot1: InkSpot,
        spot2: InkSpot,
        mergedSize: Float
    ) -> GameSession {
        // Create merged ink spot at center position
        let centerPosition = Position3D(
            x: (spot1.position.x + spot2.position.x) / 2,
            y: (spot1.position.y + spot2.position.y) / 2,
            z: (spot1.position.z + spot2.position.z) / 2
        )

        let mergedSpot = InkSpot(
            id: InkSpotId(),
            position: centerPosition,
            color: spot1.color,
            size: min(mergedSize, InkSpot.maxSize),
            ownerId: spot1.ownerId
        )

        // Remove original spots and add merged spot
        return gameSession
            .removeInkSpot(spot2.id)
            .addInkSpot(mergedSpot)
    }

    private func handleInkSpotConflict(
        gameSession: GameSession,
        newSpot _: InkSpot,
        existingSpot: InkSpot,
        overlapResult _: InkSpotOverlapResult
    ) -> GameSession {
        // For different colors, reduce the size of the existing spot
        let reductionFactor: Float = 0.8
        let reducedSize = existingSpot.size * reductionFactor

        if reducedSize >= InkSpot.minSize {
            let reducedSpot = InkSpot(
                id: existingSpot.id,
                position: existingSpot.position,
                color: existingSpot.color,
                size: reducedSize,
                ownerId: existingSpot.ownerId,
                createdAt: existingSpot.createdAt
            )

            return gameSession.updateInkSpot(reducedSpot)
        } else {
            // Remove the spot if it becomes too small
            return gameSession.removeInkSpot(existingSpot.id)
        }
    }
}

// MARK: - CollisionResults

/// Results of collision detection when shooting ink
private struct CollisionResults {
    let affectedPlayers: [Player]
    let inkSpotOverlaps: [(InkSpot, InkSpotOverlapResult)]
}

// MARK: - ShootInkError

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
        case let .invalidInkSpotSize(size):
            return "Invalid ink spot size: \(size)"
        case .inkSpotLimitExceeded:
            return "Player has exceeded the maximum number of ink spots"
        }
    }
}
