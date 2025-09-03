import Foundation

// MARK: - Player

/// Entity representing a player in the game
public struct Player: Identifiable, Equatable, Codable {
    public let id: PlayerId
    public let name: String
    public let color: PlayerColor
    public let position: Position3D
    public let isActive: Bool
    public let score: GameScore

    /// Maximum allowed name length
    public static let maxNameLength = 50

    /// Create a new player
    public init(
        id: PlayerId,
        name: String,
        color: PlayerColor,
        position: Position3D
    ) {
        guard Self.isValidName(name) else {
            fatalError("Invalid player name: \(name)")
        }

        self.id = id
        self.name = name
        self.color = color
        self.position = position
        isActive = true
        score = GameScore.zero
    }

    /// Private initializer for internal state changes
    private init(
        id: PlayerId,
        name: String,
        color: PlayerColor,
        position: Position3D,
        isActive: Bool,
        score: GameScore
    ) {
        self.id = id
        self.name = name
        self.color = color
        self.position = position
        self.isActive = isActive
        self.score = score
    }

    /// Update player position
    public func updatePosition(_ newPosition: Position3D) -> Player {
        Player(
            id: id,
            name: name,
            color: color,
            position: newPosition,
            isActive: isActive,
            score: score
        )
    }

    /// Deactivate player (e.g., when hit by ink)
    public func deactivate() -> Player {
        Player(
            id: id,
            name: name,
            color: color,
            position: position,
            isActive: false,
            score: score
        )
    }

    /// Activate player
    public func activate() -> Player {
        Player(
            id: id,
            name: name,
            color: color,
            position: position,
            isActive: true,
            score: score
        )
    }

    /// Update player score
    public func updateScore(_ newScore: GameScore) -> Player {
        Player(
            id: id,
            name: name,
            color: color,
            position: position,
            isActive: isActive,
            score: newScore
        )
    }

    /// Validate player name
    public static func isValidName(_ name: String) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmedName.isEmpty && trimmedName.count <= maxNameLength
    }
}

// MARK: - Equatable (by ID only)

public extension Player {
    static func == (lhs: Player, rhs: Player) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CustomStringConvertible

extension Player: CustomStringConvertible {
    public var description: String {
        "Player(id: \(id), name: \(name), color: \(color), active: \(isActive))"
    }
}
