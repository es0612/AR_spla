import Foundation

/// Value Object representing a unique player identifier
public struct PlayerId: Equatable, Hashable, Codable {
    public let value: UUID
    
    /// Create a PlayerId with a specific UUID
    public init(_ uuid: UUID) {
        self.value = uuid
    }
    
    /// Create a PlayerId with a new random UUID
    public init() {
        self.value = UUID()
    }
}

// MARK: - CustomStringConvertible
extension PlayerId: CustomStringConvertible {
    public var description: String {
        return "PlayerId(\(value.uuidString))"
    }
}