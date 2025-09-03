import Domain
import Foundation

// MARK: - GameSessionBuilder

/// Test builder for creating GameSession instances with sensible defaults
public final class GameSessionBuilder {
    private var id: GameSessionId = .init()
    private var players: [Player] = []
    private var duration: TimeInterval = 180 // 3 minutes default
    private var status: GameSessionStatus = .waiting
    private var inkSpots: [InkSpot] = []
    private var startedAt: Date?
    private var endedAt: Date?

    public init() {
        // Set up default players
        players = [
            PlayerBuilder.redPlayer().build(),
            PlayerBuilder.bluePlayer().build()
        ]
    }

    /// Set the game session ID
    @discardableResult
    public func withId(_ id: GameSessionId) -> GameSessionBuilder {
        self.id = id
        return self
    }

    /// Set the players
    @discardableResult
    public func withPlayers(_ players: [Player]) -> GameSessionBuilder {
        self.players = players
        return self
    }

    /// Add a player
    @discardableResult
    public func addPlayer(_ player: Player) -> GameSessionBuilder {
        players.append(player)
        return self
    }

    /// Set the game duration
    @discardableResult
    public func withDuration(_ duration: TimeInterval) -> GameSessionBuilder {
        self.duration = duration
        return self
    }

    /// Set the game status
    @discardableResult
    public func withStatus(_ status: GameSessionStatus) -> GameSessionBuilder {
        self.status = status
        return self
    }

    /// Set the ink spots
    @discardableResult
    public func withInkSpots(_ inkSpots: [InkSpot]) -> GameSessionBuilder {
        self.inkSpots = inkSpots
        return self
    }

    /// Add an ink spot
    @discardableResult
    public func addInkSpot(_ inkSpot: InkSpot) -> GameSessionBuilder {
        inkSpots.append(inkSpot)
        return self
    }

    /// Set the start time
    @discardableResult
    public func withStartedAt(_ startedAt: Date?) -> GameSessionBuilder {
        self.startedAt = startedAt
        return self
    }

    /// Set the end time
    @discardableResult
    public func withEndedAt(_ endedAt: Date?) -> GameSessionBuilder {
        self.endedAt = endedAt
        return self
    }

    /// Build the GameSession instance
    public func build() -> GameSession {
        var gameSession = GameSession(
            id: id,
            players: players,
            duration: duration
        )

        // Apply status changes
        switch status {
        case .waiting:
            break // Already in waiting state
        case .active:
            gameSession = gameSession.start()
        case .paused:
            gameSession = gameSession.start() // Start first, then would need pause method
        case .finished:
            gameSession = gameSession.start().end()
        case .cancelled:
            gameSession = gameSession.start().end() // Start then end for cancelled
        }

        // Add ink spots
        for inkSpot in inkSpots {
            gameSession = gameSession.addInkSpot(inkSpot)
        }

        return gameSession
    }
}

// MARK: - Convenience methods

public extension GameSessionBuilder {
    /// Create a waiting game session
    static func waitingGame() -> GameSessionBuilder {
        GameSessionBuilder()
            .withStatus(.waiting)
    }

    /// Create an active game session
    static func activeGame() -> GameSessionBuilder {
        GameSessionBuilder()
            .withStatus(.active)
            .withStartedAt(Date())
    }

    /// Create a finished game session
    static func finishedGame() -> GameSessionBuilder {
        let now = Date()
        return GameSessionBuilder()
            .withStatus(.finished)
            .withStartedAt(now.addingTimeInterval(-180))
            .withEndedAt(now)
    }

    /// Create a short game session (1 minute)
    static func shortGame() -> GameSessionBuilder {
        GameSessionBuilder()
            .withDuration(60)
    }

    /// Create a long game session (10 minutes)
    static func longGame() -> GameSessionBuilder {
        GameSessionBuilder()
            .withDuration(600)
    }

    /// Create a game with many ink spots
    static func gameWithInkSpots() -> GameSessionBuilder {
        let builder = GameSessionBuilder()
        let players = builder.players

        // Add some ink spots for each player
        for (index, player) in players.enumerated() {
            for i in 0 ..< 5 {
                let inkSpot = InkSpotBuilder()
                    .withOwnerId(player.id)
                    .withColor(player.color)
                    .withPosition(x: Float(index * 2 + i), y: 0, z: Float(i))
                    .build()
                builder.addInkSpot(inkSpot)
            }
        }

        return builder
    }
}
