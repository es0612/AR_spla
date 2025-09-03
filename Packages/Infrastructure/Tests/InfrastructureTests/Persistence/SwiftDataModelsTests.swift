@testable import Domain
import Foundation
@testable import Infrastructure
import Testing
import TestSupport

struct SwiftDataModelsTests {
    // MARK: - GameHistory Tests

    @available(iOS 17.0, macOS 14.0, *)
    @Test("GameHistory should initialize with correct properties")
    func testGameHistoryInitialization() {
        let id = UUID().uuidString
        let date = Date()
        let duration: TimeInterval = 180
        let winner = "Player1"
        let playerScore = 75.5
        let opponentScore = 24.5
        let playerNames = ["Player1", "Player2"]
        let gameStatus = "finished"

        let gameHistory = GameHistory(
            id: id,
            date: date,
            duration: duration,
            winner: winner,
            playerScore: playerScore,
            opponentScore: opponentScore,
            playerNames: playerNames,
            gameStatus: gameStatus
        )

        #expect(gameHistory.id == id)
        #expect(gameHistory.date == date)
        #expect(gameHistory.duration == duration)
        #expect(gameHistory.winner == winner)
        #expect(gameHistory.playerScore == playerScore)
        #expect(gameHistory.opponentScore == opponentScore)
        #expect(gameHistory.playerNames == playerNames)
        #expect(gameHistory.gameStatus == gameStatus)
    }

    @available(iOS 17.0, macOS 14.0, *)
    @Test("GameHistory should initialize from GameSession")
    func testGameHistoryFromGameSession() {
        let gameSession = GameSessionBuilder()
            .withDuration(300)
            .build()
            .start()
            .end()

        let gameHistory = GameHistory(from: gameSession)

        #expect(gameHistory.id == gameSession.id.value.uuidString)
        #expect(gameHistory.duration == gameSession.duration)
        #expect(gameHistory.gameStatus == gameSession.status.rawValue)
        #expect(gameHistory.playerNames.count == gameSession.players.count)

        // Check player names match
        for (index, player) in gameSession.players.enumerated() {
            #expect(gameHistory.playerNames[index] == player.name)
        }
    }

    @available(iOS 17.0, macOS 14.0, *)
    @Test("GameHistory should handle winner correctly")
    func testGameHistoryWinner() {
        let player1 = PlayerBuilder().withName("Winner").build()
            .updateScore(GameScore(paintedArea: 80.0))
        let player2 = PlayerBuilder().withName("Loser").build()
            .updateScore(GameScore(paintedArea: 20.0))

        let gameSession = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        ).start().end()

        let gameHistory = GameHistory(from: gameSession)

        #expect(gameHistory.winner == "Winner")
        #expect(gameHistory.playerScore == 80.0)
        #expect(gameHistory.opponentScore == 20.0)
    }

    // MARK: - PlayerProfile Tests

    @Test("PlayerProfile should initialize with correct properties")
    func testPlayerProfileInitialization() {
        let name = "TestPlayer"
        let totalGames = 10
        let wins = 7
        let losses = 3
        let totalPaintedArea = 650.0
        let averageScore = 65.0
        let preferredColor = "blue"

        let profile = PlayerProfile(
            name: name,
            totalGames: totalGames,
            wins: wins,
            losses: losses,
            totalPaintedArea: totalPaintedArea,
            averageScore: averageScore,
            preferredColor: preferredColor
        )

        #expect(profile.name == name)
        #expect(profile.totalGames == totalGames)
        #expect(profile.wins == wins)
        #expect(profile.losses == losses)
        #expect(profile.totalPaintedArea == totalPaintedArea)
        #expect(profile.averageScore == averageScore)
        #expect(profile.preferredColor == preferredColor)
    }

    @Test("PlayerProfile should calculate win rate correctly")
    func testPlayerProfileWinRate() {
        let profile = PlayerProfile(
            name: "TestPlayer",
            totalGames: 10,
            wins: 7,
            losses: 3
        )

        #expect(profile.winRate == 70.0)
    }

    @Test("PlayerProfile should handle zero games for win rate")
    func testPlayerProfileWinRateZeroGames() {
        let profile = PlayerProfile(name: "NewPlayer")

        #expect(profile.winRate == 0.0)
    }

    @Test("PlayerProfile should update after game correctly")
    func testPlayerProfileUpdateAfterGame() {
        let profile = PlayerProfile(
            name: "TestPlayer",
            totalGames: 5,
            wins: 3,
            losses: 2,
            totalPaintedArea: 300.0,
            averageScore: 60.0
        )

        let initialDate = profile.lastPlayedDate

        // Simulate winning a game with score 80
        profile.updateAfterGame(score: 80.0, won: true)

        #expect(profile.totalGames == 6)
        #expect(profile.wins == 4)
        #expect(profile.losses == 2)
        #expect(profile.totalPaintedArea == 380.0)
        #expect(abs(profile.averageScore - 63.33) < 0.01) // 380/6 ≈ 63.33
        #expect(profile.lastPlayedDate != initialDate)
        #expect(profile.lastPlayedDate != nil)
    }

    @Test("PlayerProfile should update after losing game correctly")
    func testPlayerProfileUpdateAfterLosingGame() {
        let profile = PlayerProfile(
            name: "TestPlayer",
            totalGames: 5,
            wins: 3,
            losses: 2,
            totalPaintedArea: 300.0,
            averageScore: 60.0
        )

        // Simulate losing a game with score 40
        profile.updateAfterGame(score: 40.0, won: false)

        #expect(profile.totalGames == 6)
        #expect(profile.wins == 3)
        #expect(profile.losses == 3)
        #expect(profile.totalPaintedArea == 340.0)
        #expect(abs(profile.averageScore - 56.67) < 0.01) // 340/6 ≈ 56.67
    }

    @available(iOS 17.0, macOS 14.0, *)
    @Test("PlayerProfile should initialize from Player")
    func testPlayerProfileFromPlayer() {
        let player = PlayerBuilder()
            .withName("TestPlayer")
            .withColor(.blue)
            .build()

        let profile = PlayerProfile(from: player)

        #expect(profile.name == "TestPlayer")
        #expect(profile.preferredColor == "blue")
        #expect(profile.totalGames == 0)
        #expect(profile.wins == 0)
        #expect(profile.losses == 0)
        #expect(profile.totalPaintedArea == 0.0)
        #expect(profile.averageScore == 0.0)
    }

    @available(iOS 17.0, macOS 14.0, *)
    @Test("PlayerProfile should update from Player and GameResult")
    func testPlayerProfileUpdateFromPlayer() {
        let profile = PlayerProfile(name: "TestPlayer")
        let player = PlayerBuilder()
            .withName("TestPlayer")
            .withColor(.green)
            .build()
            .updateScore(GameScore(paintedArea: 75.0))

        profile.update(from: player, gameResult: .won)

        #expect(profile.totalGames == 1)
        #expect(profile.wins == 1)
        #expect(profile.losses == 0)
        #expect(profile.totalPaintedArea == 75.0)
        #expect(profile.averageScore == 75.0)
        #expect(profile.preferredColor == "green")
        #expect(profile.lastPlayedDate != nil)
    }

    // MARK: - GameResult Tests

    @Test("SimpleGameResult should have correct cases")
    func testSimpleGameResultCases() {
        let results: [SimpleGameResult] = [.won, .lost, .tie]
        #expect(results.count == 3)
    }

    // MARK: - Integration Tests

    @available(iOS 17.0, macOS 14.0, *)
    @Test("GameHistory and PlayerProfile should work together")
    func testGameHistoryPlayerProfileIntegration() {
        // Create a game session with two players
        let player1 = PlayerBuilder()
            .withName("Alice")
            .withColor(.red)
            .build()
            .updateScore(GameScore(paintedArea: 70.0))

        let player2 = PlayerBuilder()
            .withName("Bob")
            .withColor(.blue)
            .build()
            .updateScore(GameScore(paintedArea: 30.0))

        let gameSession = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        ).start().end()

        // Create game history
        let gameHistory = GameHistory(from: gameSession)

        // Create player profiles
        let aliceProfile = PlayerProfile(from: player1)
        let bobProfile = PlayerProfile(from: player2)

        // Update profiles based on game result
        aliceProfile.update(from: player1, gameResult: .won)
        bobProfile.update(from: player2, gameResult: .lost)

        // Verify game history
        #expect(gameHistory.winner == "Alice")
        #expect(gameHistory.playerScore == 70.0)
        #expect(gameHistory.opponentScore == 30.0)
        #expect(gameHistory.playerNames.contains("Alice"))
        #expect(gameHistory.playerNames.contains("Bob"))

        // Verify Alice's profile
        #expect(aliceProfile.name == "Alice")
        #expect(aliceProfile.wins == 1)
        #expect(aliceProfile.losses == 0)
        #expect(aliceProfile.totalPaintedArea == 70.0)
        #expect(aliceProfile.winRate == 100.0)

        // Verify Bob's profile
        #expect(bobProfile.name == "Bob")
        #expect(bobProfile.wins == 0)
        #expect(bobProfile.losses == 1)
        #expect(bobProfile.totalPaintedArea == 30.0)
        #expect(bobProfile.winRate == 0.0)
    }
}
