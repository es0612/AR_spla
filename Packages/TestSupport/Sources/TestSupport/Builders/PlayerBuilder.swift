import Foundation
import Domain

/// Test builder for creating Player instances with sensible defaults
public final class PlayerBuilder {
    private var id: PlayerId = PlayerId()
    private var name: String = "TestPlayer"
    private var color: PlayerColor = .red
    private var position: Position3D = Position3D(x: 0, y: 0, z: 0)
    private var isActive: Bool = true
    private var score: GameScore = .zero
    
    public init() {}
    
    /// Set the player ID
    @discardableResult
    public func withId(_ id: PlayerId) -> PlayerBuilder {
        self.id = id
        return self
    }
    
    /// Set the player name
    @discardableResult
    public func withName(_ name: String) -> PlayerBuilder {
        self.name = name
        return self
    }
    
    /// Set the player color
    @discardableResult
    public func withColor(_ color: PlayerColor) -> PlayerBuilder {
        self.color = color
        return self
    }
    
    /// Set the player position
    @discardableResult
    public func withPosition(_ position: Position3D) -> PlayerBuilder {
        self.position = position
        return self
    }
    
    /// Set the player position with coordinates
    @discardableResult
    public func withPosition(x: Float, y: Float, z: Float) -> PlayerBuilder {
        self.position = Position3D(x: x, y: y, z: z)
        return self
    }
    
    /// Set the player active status
    @discardableResult
    public func withActiveStatus(_ isActive: Bool) -> PlayerBuilder {
        self.isActive = isActive
        return self
    }
    
    /// Set the player score
    @discardableResult
    public func withScore(_ score: GameScore) -> PlayerBuilder {
        self.score = score
        return self
    }
    
    /// Set the player score with painted area
    @discardableResult
    public func withScore(paintedArea: Float) -> PlayerBuilder {
        self.score = GameScore(paintedArea: paintedArea)
        return self
    }
    
    /// Build the Player instance
    public func build() -> Player {
        var player = Player(
            id: id,
            name: name,
            color: color,
            position: position
        )
        
        if !isActive {
            player = player.deactivate()
        }
        
        if score != .zero {
            player = player.updateScore(score)
        }
        
        return player
    }
}

// MARK: - Convenience methods
extension PlayerBuilder {
    /// Create a red player
    public static func redPlayer() -> PlayerBuilder {
        return PlayerBuilder()
            .withName("Red Player")
            .withColor(.red)
    }
    
    /// Create a blue player
    public static func bluePlayer() -> PlayerBuilder {
        return PlayerBuilder()
            .withName("Blue Player")
            .withColor(.blue)
    }
    
    /// Create an inactive player
    public static func inactivePlayer() -> PlayerBuilder {
        return PlayerBuilder()
            .withName("Inactive Player")
            .withActiveStatus(false)
    }
    
    /// Create a player with high score
    public static func highScorePlayer() -> PlayerBuilder {
        return PlayerBuilder()
            .withName("High Score Player")
            .withScore(paintedArea: 75.0)
    }
}