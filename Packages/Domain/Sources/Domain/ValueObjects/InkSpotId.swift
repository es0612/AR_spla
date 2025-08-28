import Foundation

/// Value Object representing a unique ink spot identifier
public struct InkSpotId: Equatable, Hashable, Codable {
    public let value: UUID
    
    /// Create an InkSpotId with a specific UUID
    public init(_ uuid: UUID) {
        self.value = uuid
    }
    
    /// Create an InkSpotId with a new random UUID
    public init() {
        self.value = UUID()
    }
}

// MARK: - CustomStringConvertible
extension InkSpotId: CustomStringConvertible {
    public var description: String {
        return "InkSpotId(\(value.uuidString))"
    }
}