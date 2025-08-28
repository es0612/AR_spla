import Foundation

/// Value Object representing a unique game session identifier
public struct GameSessionId: Equatable, Hashable, Codable {
    public let value: UUID
    
    /// Create a GameSessionId with a specific UUID
    public init(_ uuid: UUID) {
        self.value = uuid
    }
    
    /// Create a GameSessionId with a new random UUID
    public init() {
        self.value = UUID()
    }
}

// MARK: - CustomStringConvertible
extension GameSessionId: CustomStringConvertible {
    public var description: String {
        return "GameSessionId(\(value.uuidString))"
    }
}