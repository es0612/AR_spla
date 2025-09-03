import Foundation

// MARK: - GameRules

/// Value Object representing game rules and configuration
public struct GameRules: Equatable, Codable {
    public let gameDuration: TimeInterval
    public let maxInkSpotsPerPlayer: Int
    public let playerCollisionRadius: Float
    public let inkSpotMinSize: Float
    public let inkSpotMaxSize: Float

    /// Create game rules with specified parameters
    public init(
        gameDuration: TimeInterval,
        maxInkSpotsPerPlayer: Int,
        playerCollisionRadius: Float,
        inkSpotMinSize: Float,
        inkSpotMaxSize: Float
    ) {
        self.gameDuration = gameDuration
        self.maxInkSpotsPerPlayer = maxInkSpotsPerPlayer
        self.playerCollisionRadius = playerCollisionRadius
        self.inkSpotMinSize = inkSpotMinSize
        self.inkSpotMaxSize = inkSpotMaxSize
    }

    /// Default game rules
    public static let `default` = GameRules(
        gameDuration: 180, // 3 minutes
        maxInkSpotsPerPlayer: 100,
        playerCollisionRadius: 0.5,
        inkSpotMinSize: 0.1,
        inkSpotMaxSize: 2.0
    )

    /// Validate if these game rules are valid
    public var isValid: Bool {
        gameDuration > 0 &&
            maxInkSpotsPerPlayer > 0 &&
            playerCollisionRadius > 0 &&
            inkSpotMinSize > 0 &&
            inkSpotMaxSize > inkSpotMinSize
    }
}

// MARK: CustomStringConvertible

extension GameRules: CustomStringConvertible {
    public var description: String {
        "GameRules(duration: \(gameDuration)s, maxInkSpots: \(maxInkSpotsPerPlayer), collision: \(playerCollisionRadius))"
    }
}
