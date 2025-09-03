import Domain
import Foundation

// MARK: - InkSpotBuilder

/// Test builder for creating InkSpot instances with sensible defaults
public final class InkSpotBuilder {
    private var id: InkSpotId = .init()
    private var position: Position3D = .init(x: 0, y: 0, z: 0)
    private var color: PlayerColor = .red
    private var size: Float = 0.5
    private var ownerId: PlayerId = .init()
    private var createdAt: Date = .init()

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
        position = Position3D(x: x, y: y, z: z)
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
        InkSpot(
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

public extension InkSpotBuilder {
    /// Create a red ink spot
    static func redInkSpot() -> InkSpotBuilder {
        InkSpotBuilder()
            .withColor(.red)
    }

    /// Create a blue ink spot
    static func blueInkSpot() -> InkSpotBuilder {
        InkSpotBuilder()
            .withColor(.blue)
    }

    /// Create a small ink spot
    static func smallInkSpot() -> InkSpotBuilder {
        InkSpotBuilder()
            .withSize(0.2)
    }

    /// Create a large ink spot
    static func largeInkSpot() -> InkSpotBuilder {
        InkSpotBuilder()
            .withSize(1.5)
    }

    /// Create an old ink spot (created 1 minute ago)
    static func oldInkSpot() -> InkSpotBuilder {
        InkSpotBuilder()
            .withCreatedAt(Date().addingTimeInterval(-60))
    }

    /// Create an ink spot at origin
    static func inkSpotAtOrigin() -> InkSpotBuilder {
        InkSpotBuilder()
            .withPosition(x: 0, y: 0, z: 0)
    }

    /// Create an ink spot for a specific player
    static func inkSpotFor(player: Player) -> InkSpotBuilder {
        InkSpotBuilder()
            .withOwnerId(player.id)
            .withColor(player.color)
    }
}
