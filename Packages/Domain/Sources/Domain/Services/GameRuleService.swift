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

    // MARK: - Balance Adjustments

    /// Check if ink shot is within cooldown period
    public func isInkShotAllowed(
        lastShotTime: Date,
        cooldownDuration: TimeInterval
    ) -> Bool {
        let timeSinceLastShot = Date().timeIntervalSince(lastShotTime)
        return timeSinceLastShot >= cooldownDuration
    }

    /// Calculate ink spot size based on rapid fire penalty
    public func calculateInkSpotSize(
        baseSize: Float,
        consecutiveShots: Int,
        rapidFireReduction: Float
    ) -> Float {
        guard consecutiveShots > 0 else { return baseSize }

        // Apply reduction for rapid fire (diminishing returns)
        let reductionFactor = pow(rapidFireReduction, Float(consecutiveShots - 1))
        let adjustedSize = baseSize * reductionFactor

        // Ensure size doesn't go below minimum
        return max(gameRules.inkSpotMinSize, adjustedSize)
    }

    /// Check if position is within field boundaries
    public func isPositionInField(
        _ position: Position3D,
        fieldSize: CGSize,
        boundaryMargin: Float
    ) -> Bool {
        let halfWidth = Float(fieldSize.width) / 2.0 - boundaryMargin
        let halfHeight = Float(fieldSize.height) / 2.0 - boundaryMargin

        return abs(position.x) <= halfWidth &&
            abs(position.z) <= halfHeight &&
            position.y >= -boundaryMargin
    }

    /// Calculate stun duration based on ink spot properties
    public func calculateStunDuration(
        baseStunDuration: TimeInterval,
        inkSpotSize: Float,
        playerSpeed: Float
    ) -> TimeInterval {
        // Larger ink spots cause longer stuns
        let sizeFactor = inkSpotSize / gameRules.inkSpotMaxSize

        // Faster players recover quicker
        let speedFactor = max(0.5, 2.0 - (playerSpeed / 3.0))

        return baseStunDuration * Double(sizeFactor * speedFactor)
    }

    /// Validate game balance parameters
    public func validateBalanceParameters(
        inkShotCooldown: TimeInterval,
        inkMaxRange: Float,
        inkSpotBaseSize: Float,
        playerStunDuration: TimeInterval,
        maxInkSpotsPerPlayer: Int
    ) -> Bool {
        inkShotCooldown > 0 &&
            inkMaxRange > 0 &&
            inkSpotBaseSize > 0 &&
            inkSpotBaseSize <= gameRules.inkSpotMaxSize &&
            playerStunDuration > 0 &&
            maxInkSpotsPerPlayer > 0
    }

    /// Calculate optimal field size based on player count and game duration
    public func calculateOptimalFieldSize(
        playerCount: Int,
        gameDuration: TimeInterval
    ) -> CGSize {
        // Base field size for 2 players and 3 minutes
        let baseSize: Float = 4.0

        // Adjust for player count (more players need more space)
        let playerFactor = sqrt(Float(playerCount) / 2.0)

        // Adjust for game duration (longer games need more space)
        let timeFactor = sqrt(Float(gameDuration) / 180.0)

        let adjustedSize = baseSize * playerFactor * timeFactor

        // Clamp to reasonable bounds
        let clampedSize = max(3.0, min(8.0, adjustedSize))

        return CGSize(width: Double(clampedSize), height: Double(clampedSize))
    }
}

// MARK: CustomStringConvertible

extension GameRuleService: CustomStringConvertible {
    public var description: String {
        "GameRuleService(rules: \(gameRules))"
    }
}
