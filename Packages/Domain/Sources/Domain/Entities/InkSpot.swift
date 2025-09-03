import Foundation

// MARK: - InkSpot

/// Entity representing an ink spot in the game
public struct InkSpot: Identifiable, Equatable, Codable {
    public let id: InkSpotId
    public let position: Position3D
    public let color: PlayerColor
    public let size: Float // Radius of the ink spot
    public let ownerId: PlayerId
    public let createdAt: Date

    /// Minimum allowed size
    public static let minSize: Float = 0.1
    /// Maximum allowed size
    public static let maxSize: Float = 2.0

    /// Create a new ink spot
    public init(
        id: InkSpotId,
        position: Position3D,
        color: PlayerColor,
        size: Float,
        ownerId: PlayerId,
        createdAt: Date = Date()
    ) {
        guard Self.isValidSize(size) else {
            fatalError("Invalid ink spot size: \(size). Must be between \(Self.minSize) and \(Self.maxSize)")
        }

        self.id = id
        self.position = position
        self.color = color
        self.size = size
        self.ownerId = ownerId
        self.createdAt = createdAt
    }

    /// Calculate the area covered by this ink spot (π * r²)
    public var area: Float {
        Float.pi * size * size
    }

    /// Calculate the age of this ink spot in seconds
    public var age: TimeInterval {
        Date().timeIntervalSince(createdAt)
    }

    /// Check if this ink spot overlaps with another ink spot
    public func overlaps(with other: InkSpot) -> Bool {
        let distance = position.distance(to: other.position)
        let combinedRadius = size + other.size
        return distance < combinedRadius
    }

    /// Validate ink spot size
    public static func isValidSize(_ size: Float) -> Bool {
        !size.isNaN &&
            !size.isInfinite &&
            size > 0.0 &&
            size >= minSize &&
            size <= maxSize
    }
}

// MARK: - Equatable (by ID only)

public extension InkSpot {
    static func == (lhs: InkSpot, rhs: InkSpot) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CustomStringConvertible

extension InkSpot: CustomStringConvertible {
    public var description: String {
        "InkSpot(id: \(id), color: \(color), size: \(size), owner: \(ownerId))"
    }
}
