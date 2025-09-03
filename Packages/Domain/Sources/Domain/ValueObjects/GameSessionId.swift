import Foundation

// MARK: - GameSessionId

/// Value Object representing a unique game session identifier
public struct GameSessionId: Equatable, Hashable, Codable {
    public let value: UUID

    /// Create a GameSessionId with a specific UUID
    public init(_ uuid: UUID) {
        value = uuid
    }

    /// Create a GameSessionId with a new random UUID
    public init() {
        value = UUID()
    }
}

// MARK: CustomStringConvertible

extension GameSessionId: CustomStringConvertible {
    public var description: String {
        "GameSessionId(\(value.uuidString))"
    }
}
