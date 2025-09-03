import Domain
import Foundation

// MARK: - TestData

/// Provides pre-configured test data for consistent testing
public enum TestData {
    // MARK: - Player Test Data

    /// Standard red player for testing
    public static let redPlayer = PlayerBuilder()
        .withId(PlayerId(UUID(uuidString: "11111111-1111-1111-1111-111111111111")!))
        .withName("Red Player")
        .withColor(.red)
        .withPosition(x: -1, y: 0, z: 0)
        .build()

    /// Standard blue player for testing
    public static let bluePlayer = PlayerBuilder()
        .withId(PlayerId(UUID(uuidString: "22222222-2222-2222-2222-222222222222")!))
        .withName("Blue Player")
        .withColor(.blue)
        .withPosition(x: 1, y: 0, z: 0)
        .build()

    /// Inactive player for testing
    public static let inactivePlayer = PlayerBuilder()
        .withId(PlayerId(UUID(uuidString: "33333333-3333-3333-3333-333333333333")!))
        .withName("Inactive Player")
        .withColor(.green)
        .withActiveStatus(false)
        .build()

    /// High score player for testing
    public static let highScorePlayer = PlayerBuilder()
        .withId(PlayerId(UUID(uuidString: "44444444-4444-4444-4444-444444444444")!))
        .withName("High Score Player")
        .withColor(.yellow)
        .withScore(paintedArea: 85.0)
        .build()

    /// Array of standard test players
    public static let standardPlayers = [redPlayer, bluePlayer]

    /// Array of all test players
    public static let allTestPlayers = [redPlayer, bluePlayer, inactivePlayer, highScorePlayer]

    // MARK: - InkSpot Test Data

    /// Red ink spot at origin
    public static let redInkSpotAtOrigin = InkSpotBuilder()
        .withId(InkSpotId(UUID(uuidString: "AAAAAAAA-AAAA-AAAA-AAAA-AAAAAAAAAAAA")!))
        .withPosition(x: 0, y: 0, z: 0)
        .withColor(.red)
        .withSize(0.5)
        .withOwnerId(redPlayer.id)
        .build()

    /// Blue ink spot near origin
    public static let blueInkSpotNearOrigin = InkSpotBuilder()
        .withId(InkSpotId(UUID(uuidString: "BBBBBBBB-BBBB-BBBB-BBBB-BBBBBBBBBBBB")!))
        .withPosition(x: 0.3, y: 0, z: 0.3)
        .withColor(.blue)
        .withSize(0.4)
        .withOwnerId(bluePlayer.id)
        .build()

    /// Large red ink spot
    public static let largeRedInkSpot = InkSpotBuilder()
        .withId(InkSpotId(UUID(uuidString: "CCCCCCCC-CCCC-CCCC-CCCC-CCCCCCCCCCCC")!))
        .withPosition(x: -2, y: 0, z: -2)
        .withColor(.red)
        .withSize(1.2)
        .withOwnerId(redPlayer.id)
        .build()

    /// Small blue ink spot
    public static let smallBlueInkSpot = InkSpotBuilder()
        .withId(InkSpotId(UUID(uuidString: "DDDDDDDD-DDDD-DDDD-DDDD-DDDDDDDDDDDD")!))
        .withPosition(x: 2, y: 0, z: 2)
        .withColor(.blue)
        .withSize(0.2)
        .withOwnerId(bluePlayer.id)
        .build()

    /// Array of standard test ink spots
    public static let standardInkSpots = [redInkSpotAtOrigin, blueInkSpotNearOrigin]

    /// Array of all test ink spots
    public static let allTestInkSpots = [redInkSpotAtOrigin, blueInkSpotNearOrigin, largeRedInkSpot, smallBlueInkSpot]

    // MARK: - GameSession Test Data

    /// Standard waiting game session
    public static let waitingGameSession = GameSessionBuilder()
        .withId(GameSessionId(UUID(uuidString: "99999999-9999-9999-9999-999999999999")!))
        .withPlayers(standardPlayers)
        .withDuration(180)
        .withStatus(.waiting)
        .build()

    /// Active game session
    public static let activeGameSession = GameSessionBuilder()
        .withId(GameSessionId(UUID(uuidString: "88888888-8888-8888-8888-888888888888")!))
        .withPlayers(standardPlayers)
        .withDuration(180)
        .withStatus(.active)
        .withStartedAt(Date().addingTimeInterval(-60)) // Started 1 minute ago
        .withInkSpots(standardInkSpots)
        .build()

    /// Finished game session
    public static let finishedGameSession = GameSessionBuilder()
        .withId(GameSessionId(UUID(uuidString: "77777777-7777-7777-7777-777777777777")!))
        .withPlayers([
            redPlayer.updateScore(GameScore(paintedArea: 60.0)),
            bluePlayer.updateScore(GameScore(paintedArea: 40.0))
        ])
        .withDuration(180)
        .withStatus(.finished)
        .withStartedAt(Date().addingTimeInterval(-240)) // Started 4 minutes ago
        .withEndedAt(Date().addingTimeInterval(-60)) // Ended 1 minute ago
        .withInkSpots(allTestInkSpots)
        .build()

    /// Short game session (1 minute)
    public static let shortGameSession = GameSessionBuilder()
        .withId(GameSessionId(UUID(uuidString: "66666666-6666-6666-6666-666666666666")!))
        .withPlayers(standardPlayers)
        .withDuration(60)
        .withStatus(.waiting)
        .build()

    /// Long game session (10 minutes)
    public static let longGameSession = GameSessionBuilder()
        .withId(GameSessionId(UUID(uuidString: "55555555-5555-5555-5555-555555555555")!))
        .withPlayers(standardPlayers)
        .withDuration(600)
        .withStatus(.waiting)
        .build()

    /// Array of all test game sessions
    public static let allTestGameSessions = [
        waitingGameSession,
        activeGameSession,
        finishedGameSession,
        shortGameSession,
        longGameSession
    ]

    // MARK: - Value Object Test Data

    /// Standard test positions
    public static let positions = [
        Position3D(x: 0, y: 0, z: 0), // Origin
        Position3D(x: 1, y: 0, z: 0), // X-axis
        Position3D(x: 0, y: 1, z: 0), // Y-axis
        Position3D(x: 0, y: 0, z: 1), // Z-axis
        Position3D(x: -1, y: -1, z: -1), // Negative coordinates
        Position3D(x: 2.5, y: 1.5, z: 0.5) // Decimal coordinates
    ]

    /// Standard test scores
    public static let scores = [
        GameScore.zero,
        GameScore(paintedArea: 25.0),
        GameScore(paintedArea: 50.0),
        GameScore(paintedArea: 75.0),
        GameScore.maximum
    ]

    /// All player colors
    public static let allPlayerColors = PlayerColor.allCases

    /// All game session statuses
    public static let allGameSessionStatuses = GameSessionStatus.allCases

    // MARK: - Test Scenarios

    /// Create a competitive game scenario (close scores)
    public static func competitiveGameScenario() -> GameSession {
        let player1 = redPlayer.updateScore(GameScore(paintedArea: 52.0))
        let player2 = bluePlayer.updateScore(GameScore(paintedArea: 48.0))

        return GameSessionBuilder()
            .withPlayers([player1, player2])
            .withStatus(.finished)
            .withInkSpots(allTestInkSpots)
            .build()
    }

    /// Create a one-sided game scenario (clear winner)
    public static func oneSidedGameScenario() -> GameSession {
        let player1 = redPlayer.updateScore(GameScore(paintedArea: 85.0))
        let player2 = bluePlayer.updateScore(GameScore(paintedArea: 15.0))

        return GameSessionBuilder()
            .withPlayers([player1, player2])
            .withStatus(.finished)
            .withInkSpots(allTestInkSpots)
            .build()
    }

    /// Create a tie game scenario
    public static func tieGameScenario() -> GameSession {
        let player1 = redPlayer.updateScore(GameScore(paintedArea: 50.0))
        let player2 = bluePlayer.updateScore(GameScore(paintedArea: 50.0))

        return GameSessionBuilder()
            .withPlayers([player1, player2])
            .withStatus(.finished)
            .withInkSpots(standardInkSpots)
            .build()
    }

    /// Create overlapping ink spots scenario
    public static func overlappingInkSpotsScenario() -> [InkSpot] {
        [
            InkSpotBuilder()
                .withPosition(x: 0, y: 0, z: 0)
                .withSize(1.0)
                .withColor(.red)
                .withOwnerId(redPlayer.id)
                .build(),
            InkSpotBuilder()
                .withPosition(x: 0.5, y: 0, z: 0.5)
                .withSize(1.0)
                .withColor(.blue)
                .withOwnerId(bluePlayer.id)
                .build()
        ]
    }
}

// MARK: - Test Data Extensions

public extension TestData {
    /// Generate random test data for stress testing
    static func randomPlayer() -> Player {
        let colors = PlayerColor.allCases
        let randomColor = colors.randomElement()!

        return PlayerBuilder()
            .withName("Random Player \(Int.random(in: 1 ... 1_000))")
            .withColor(randomColor)
            .withPosition(
                x: Float.random(in: -10 ... 10),
                y: Float.random(in: -1 ... 1),
                z: Float.random(in: -10 ... 10)
            )
            .withScore(paintedArea: Float.random(in: 0 ... 100))
            .build()
    }

    /// Generate random ink spot
    static func randomInkSpot(ownerId: PlayerId, color: PlayerColor) -> InkSpot {
        InkSpotBuilder()
            .withPosition(
                x: Float.random(in: -5 ... 5),
                y: 0,
                z: Float.random(in: -5 ... 5)
            )
            .withSize(Float.random(in: InkSpot.minSize ... InkSpot.maxSize))
            .withColor(color)
            .withOwnerId(ownerId)
            .build()
    }

    /// Generate a game session with random data
    static func randomGameSession() -> GameSession {
        let player1 = randomPlayer()
        let player2 = randomPlayer()
        let duration = TimeInterval.random(in: GameSession.minDuration ... GameSession.maxDuration)

        return GameSessionBuilder()
            .withPlayers([player1, player2])
            .withDuration(duration)
            .build()
    }
}
