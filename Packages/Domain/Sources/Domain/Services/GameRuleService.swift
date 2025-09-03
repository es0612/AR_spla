import Foundation

// MARK: - GameRuleService

/// Domain service for managing game rules and validations
public struct GameRuleService {
    private let gameRules: GameRules

    /// Create a GameRuleService with specified rules
    public init(gameRules: GameRules = .default) {
        self.gameRules = gameRules
    }

    /// Validate if a game session is valid according to game rules
    public func isValidGameSession(_ gameSession: GameSession) -> Bool {
        // Check if duration is within valid range
        guard gameSession.duration >= GameSession.minDuration,
              gameSession.duration <= GameSession.maxDuration
        else {
            return false
        }

        // Check if player count is correct
        guard GameSession.isValidPlayerCount(gameSession.players.count) else {
            return false
        }

        // Check if all players have valid names and colors
        let playerNames = Set(gameSession.players.map(\.name))
        let playerColors = Set(gameSession.players.map(\.color))

        guard playerNames.count == gameSession.players.count,
              playerColors.count == gameSession.players.count
        else {
            return false // Duplicate names or colors
        }

        return true
    }

    /// Check if a game should end based on current state
    public func shouldEndGame(_ gameSession: GameSession) -> Bool {
        // Game should end if it's already finished
        if gameSession.status.hasEnded {
            return true
        }

        // Game should end if it's not active
        guard gameSession.status == .active else {
            return false
        }

        // Game should end if time is up
        return gameSession.remainingTime <= 0
    }

    /// Check if a player can shoot ink at the specified position
    public func canPlayerShootInk(_ player: Player, at position: Position3D) -> Bool {
        // Player must be active
        guard player.isActive else {
            return false
        }

        // Position must be valid
        guard position.isValid else {
            return false
        }

        return true
    }

    /// Check if a player collides with an ink spot
    public func checkPlayerInkCollision(_ player: Player, with inkSpot: InkSpot) -> Bool {
        // Players don't collide with their own ink
        guard inkSpot.ownerId != player.id else {
            return false
        }

        // Calculate distance between player and ink spot center
        let distance = player.position.distance(to: inkSpot.position)

        // Collision occurs if distance is less than ink spot radius + player collision radius
        let collisionDistance = inkSpot.size + gameRules.playerCollisionRadius

        return distance < collisionDistance
    }

    /// Calculate field coverage percentage for given ink spots
    public func calculateFieldCoverage(inkSpots: [InkSpot], fieldSize: Float) -> Float {
        guard fieldSize > 0 else { return 0 }

        // Simple approach: sum all ink spot areas (ignoring overlaps for now)
        let totalArea = inkSpots.reduce(0) { sum, inkSpot in
            sum + inkSpot.area
        }

        // Convert to percentage and cap at 100%
        let coverage = min(100.0, (totalArea / fieldSize) * 100)
        return coverage
    }

    /// Validate game rules
    public func areValidGameRules(_ rules: GameRules) -> Bool {
        rules.isValid
    }

    /// Check if a player has exceeded the maximum number of ink spots
    public func hasExceededInkSpotLimit(_ playerId: PlayerId, inkSpots: [InkSpot]) -> Bool {
        let playerInkSpots = inkSpots.filter { $0.ownerId == playerId }
        return playerInkSpots.count >= gameRules.maxInkSpotsPerPlayer
    }

    /// Validate ink spot size according to game rules
    public func isValidInkSpotSize(_ size: Float) -> Bool {
        size >= gameRules.inkSpotMinSize && size <= gameRules.inkSpotMaxSize
    }

    /// Get the current game rules
    public var currentGameRules: GameRules {
        gameRules
    }
}

// MARK: CustomStringConvertible

extension GameRuleService: CustomStringConvertible {
    public var description: String {
        "GameRuleService(rules: \(gameRules))"
    }
}
