import Foundation
import Domain

/// Test builder for creating InkSpot instances with sensible defaults
public final class InkSpotBuilder {
    private var id: InkSpotId = InkSpotId()
    private var position: Position3D = Position3D(x: 0, y: 0, z: 0)
    private var color: PlayerColor = .red
    private var size: Float = 0.5
    private var ownerId: PlayerId = PlayerId()
    private var createdAt: Date = Date()
    
    public init() {}
    
    /// Set the ink spot ID
    @discardableResult
    public func withId(_ id: InkSpotId) -> InkSpotBuilder {
        self.id = id
        return self
    }
    
    /// Set the ink spot position
    @discardableResult
    public func withPosition(_ position: Position3D) -> InkSpotBuilder {
        self.position = position
        return self
    }
    
    /// Set the ink spot position with coordinates
    @discardableResult
    public func withPosition(x: Float, y: Float, z: Float) -> InkSpotBuilder {
        self.position = Position3D(x: x, y: y, z: z)
        return self
    }
    
    /// Set the ink spot color
    @discardableResult
    public func withColor(_ color: PlayerColor) -> InkSpotBuilder {
        self.color = color
        return self
    }
    
    /// Set the ink spot size
    @discardableResult
    public func withSize(_ size: Float) -> InkSpotBuilder {
        self.size = size
        return self
    }
    
    /// Set the owner ID
    @discardableResult
    public func withOwnerId(_ ownerId: PlayerId) -> InkSpotBuilder {
        self.ownerId = ownerId
        return self
    }
    
    /// Set the creation time
    @discardableResult
    public func withCreatedAt(_ createdAt: Date) -> InkSpotBuilder {
        self.createdAt = createdAt
        return self
    }
    
    /// Build the InkSpot instance
    public func build() -> InkSpot {
        return InkSpot(
            id: id,
            position: position,
            color: color,
            size: size,
            ownerId: ownerId,
            createdAt: createdAt
        )
    }
}

// MARK: - Convenience methods
extension InkSpotBuilder {
    /// Create a red ink spot
    public static func redInkSpot() -> InkSpotBuilder {
        return InkSpotBuilder()
            .withColor(.red)
    }
    
    /// Create a blue ink spot
    public static func blueInkSpot() -> InkSpotBuilder {
        return InkSpotBuilder()
            .withColor(.blue)
    }
    
    /// Create a small ink spot
    public static func smallInkSpot() -> InkSpotBuilder {
        return InkSpotBuilder()
            .withSize(0.2)
    }
    
    /// Create a large ink spot
    public static func largeInkSpot() -> InkSpotBuilder {
        return InkSpotBuilder()
            .withSize(1.5)
    }
    
    /// Create an old ink spot (created 1 minute ago)
    public static func oldInkSpot() -> InkSpotBuilder {
        return InkSpotBuilder()
            .withCreatedAt(Date().addingTimeInterval(-60))
    }
    
    /// Create an ink spot at origin
    public static func inkSpotAtOrigin() -> InkSpotBuilder {
        return InkSpotBuilder()
            .withPosition(x: 0, y: 0, z: 0)
    }
    
    /// Create an ink spot for a specific player
    public static func inkSpotFor(player: Player) -> InkSpotBuilder {
        return InkSpotBuilder()
            .withOwnerId(player.id)
            .withColor(player.color)
    }
}