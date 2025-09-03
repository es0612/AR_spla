import Foundation

// MARK: - PlayerId

/// Value Object representing a unique player identifier
public struct PlayerId: Equatable, Hashable, Codable {
    public let value: UUID

    /// Create a PlayerId with a specific UUID
    public init(_ uuid: UUID) {
        value = uuid
    }

    /// Create a PlayerId with a new random UUID
    public init() {
        value = UUID()
    }
}

// MARK: CustomStringConvertible

extension PlayerId: CustomStringConvertible {
    public var description: String {
        "PlayerId(\(value.uuidString))"
    }
}
