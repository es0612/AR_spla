import Foundation

// MARK: - GameSession

/// Entity representing a game session
public struct GameSession: Identifiable, Equatable, Codable {
    public let id: GameSessionId
    public let players: [Player]
    public let duration: TimeInterval // Game duration in seconds
    public let status: GameSessionStatus
    public let inkSpots: [InkSpot]
    public let startedAt: Date?
    public let endedAt: Date?

    /// Minimum game duration (1 minute)
    public static let minDuration: TimeInterval = 60
    /// Maximum game duration (10 minutes)
    public static let maxDuration: TimeInterval = 600
    /// Required number of players
    public static let requiredPlayerCount = 2

    /// Create a new game session
    public init(
        id: GameSessionId,
        players: [Player],
        duration: TimeInterval
    ) {
        guard Self.isValidPlayerCount(players.count) else {
            fatalError("Invalid player count: \(players.count). Must be exactly \(Self.requiredPlayerCount)")
        }

        guard Self.isValidDuration(duration) else {
            fatalError("Invalid duration: \(duration). Must be between \(Self.minDuration) and \(Self.maxDuration) seconds")
        }

        self.id = id
        self.players = players
        self.duration = duration
        status = .waiting
        inkSpots = []
        startedAt = nil
        endedAt = nil
    }

    /// Private initializer for internal state changes
    private init(
        id: GameSessionId,
        players: [Player],
        duration: TimeInterval,
        status: GameSessionStatus,
        inkSpots: [InkSpot],
        startedAt: Date?,
        endedAt: Date?
    ) {
        self.id = id
        self.players = players
        self.duration = duration
        self.status = status
        self.inkSpots = inkSpots
        self.startedAt = startedAt
        self.endedAt = endedAt
    }

    /// Start the game session
    public func start() -> GameSession {
        guard status == .waiting else {
            return self // Already started or finished
        }

        return GameSession(
            id: id,
            players: players,
            duration: duration,
            status: .active,
            inkSpots: inkSpots,
            startedAt: Date(),
            endedAt: endedAt
        )
    }

    /// End the game session
    public func end() -> GameSession {
        guard status.isPlayable else {
            return self // Already ended
        }

        return GameSession(
            id: id,
            players: players,
            duration: duration,
            status: .finished,
            inkSpots: inkSpots,
            startedAt: startedAt,
            endedAt: Date()
        )
    }

    /// Add an ink spot to the game session
    public func addInkSpot(_ inkSpot: InkSpot) -> GameSession {
        var newInkSpots = inkSpots
        newInkSpots.append(inkSpot)

        return GameSession(
            id: id,
            players: players,
            duration: duration,
            status: status,
            inkSpots: newInkSpots,
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    /// Remove an ink spot from the game session
    public func removeInkSpot(_ inkSpotId: InkSpotId) -> GameSession {
        let newInkSpots = inkSpots.filter { $0.id != inkSpotId }

        return GameSession(
            id: id,
            players: players,
            duration: duration,
            status: status,
            inkSpots: newInkSpots,
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    /// Update an ink spot in the game session
    public func updateInkSpot(_ updatedInkSpot: InkSpot) -> GameSession {
        let newInkSpots = inkSpots.map { inkSpot in
            inkSpot.id == updatedInkSpot.id ? updatedInkSpot : inkSpot
        }

        return GameSession(
            id: id,
            players: players,
            duration: duration,
            status: status,
            inkSpots: newInkSpots,
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    /// Update a player in the game session
    public func updatePlayer(_ updatedPlayer: Player) -> GameSession {
        let newPlayers = players.map { player in
            player.id == updatedPlayer.id ? updatedPlayer : player
        }

        return GameSession(
            id: id,
            players: newPlayers,
            duration: duration,
            status: status,
            inkSpots: inkSpots,
            startedAt: startedAt,
            endedAt: endedAt
        )
    }

    /// Calculate remaining time in the game
    public var remainingTime: TimeInterval {
        guard let startTime = startedAt else {
            return duration // Not started yet
        }

        let elapsed = Date().timeIntervalSince(startTime)
        return max(0, duration - elapsed)
    }

    /// Determine the winner based on scores
    public var winner: Player? {
        guard status.hasEnded else {
            return nil // Game not finished yet
        }

        let sortedPlayers = players.sorted { $0.score > $1.score }

        // Check for tie
        if sortedPlayers.count >= 2, sortedPlayers[0].score == sortedPlayers[1].score {
            return nil // Tie
        }

        return sortedPlayers.first
    }

    /// Validate player count
    public static func isValidPlayerCount(_ count: Int) -> Bool {
        count == requiredPlayerCount
    }

    /// Validate game duration
    public static func isValidDuration(_ duration: TimeInterval) -> Bool {
        duration >= minDuration && duration <= maxDuration
    }
}

// MARK: - Equatable (by ID only)

public extension GameSession {
    static func == (lhs: GameSession, rhs: GameSession) -> Bool {
        lhs.id == rhs.id
    }
}

// MARK: - CustomStringConvertible

extension GameSession: CustomStringConvertible {
    public var description: String {
        "GameSession(id: \(id), players: \(players.count), status: \(status), duration: \(duration)s)"
    }
}
