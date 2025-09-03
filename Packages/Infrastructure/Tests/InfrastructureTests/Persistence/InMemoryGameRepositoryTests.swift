@testable import Domain
import Foundation
@testable import Infrastructure
import Testing
import TestSupport

struct InMemoryGameRepositoryTests {
    // MARK: - Helper Methods

    private func createRepository() -> InMemoryGameRepository {
        InMemoryGameRepository()
    }

    // MARK: - Initialization Tests

    @Test("InMemoryGameRepository should initialize empty")
    func testInitialization() {
        let repository = createRepository()
        let counts = repository.getCounts()

        #expect(counts.sessions == 0)
        #expect(counts.histories == 0)
        #expect(counts.profiles == 0)
    }

    // MARK: - Game Repository Tests

    @Test("Should save and retrieve game session")
    func testSaveAndRetrieveGameSession() async throws {
        let repository = createRepository()
        let gameSession = GameSessionBuilder()
            .withDuration(180)
            .build()

        try await repository.save(gameSession)

        let retrievedSession = try await repository.findById(gameSession.id)
        #expect(retrievedSession?.id == gameSession.id)
        #expect(retrievedSession?.duration == gameSession.duration)
    }

    @Test("Should return nil for non-existent game session")
    func testFindNonExistentGameSession() async throws {
        let repository = createRepository()
        let nonExistentId = GameSessionId()

        let result = try await repository.findById(nonExistentId)
        #expect(result == nil)
    }

    @Test("Should find all game sessions")
    func testFindAllGameSessions() async throws {
        let repository = createRepository()
        let session1 = GameSessionBuilder().withDuration(180).build()
        let session2 = GameSessionBuilder().withDuration(300).build()

        try await repository.save(session1)
        try await repository.save(session2)

        let allSessions = try await repository.findAll()
        #expect(allSessions.count == 2)

        let sessionIds = allSessions.map(\.id)
        #expect(sessionIds.contains(session1.id))
        #expect(sessionIds.contains(session2.id))
    }

    @Test("Should find only active game sessions")
    func testFindActiveGameSessions() async throws {
        let repository = createRepository()
        let activeSession = GameSessionBuilder().withDuration(180).build().start()
        let waitingSession = GameSessionBuilder().withDuration(300).build()
        let finishedSession = GameSessionBuilder().withDuration(120).build().start().end()

        try await repository.save(activeSession)
        try await repository.save(waitingSession)
        try await repository.save(finishedSession)

        let activeSessions = try await repository.findActive()
        #expect(activeSessions.count == 1)
        #expect(activeSessions[0].id == activeSession.id)
    }

    @Test("Should update game session")
    func testUpdateGameSession() async throws {
        let repository = createRepository()
        let originalSession = GameSessionBuilder().withDuration(180).build()

        try await repository.save(originalSession)

        let updatedSession = originalSession.start()
        try await repository.update(updatedSession)

        let retrievedSession = try await repository.findById(originalSession.id)
        #expect(retrievedSession?.status == .active)
    }

    @Test("Should delete game session")
    func testDeleteGameSession() async throws {
        let repository = createRepository()
        let gameSession = GameSessionBuilder().withDuration(180).build()

        try await repository.save(gameSession)

        let beforeDelete = try await repository.findById(gameSession.id)
        #expect(beforeDelete != nil)

        try await repository.delete(gameSession.id)

        let afterDelete = try await repository.findById(gameSession.id)
        #expect(afterDelete == nil)
    }

    // MARK: - Player Profile Tests

    @Test("Should create and retrieve player profile")
    func testCreateAndRetrievePlayerProfile() async throws {
        let repository = createRepository()
        let player1 = PlayerBuilder().withName("TestPlayer").build()
        let player2 = PlayerBuilder().withName("Opponent").build()
        let gameSession = GameSessionBuilder().withPlayers([player1, player2]).build()

        try await repository.save(gameSession)

        let profile = try await repository.getPlayerProfile(name: "TestPlayer")
        #expect(profile?.name == "TestPlayer")
        #expect(profile?.totalGames == 1)
    }

    @Test("Should return nil for non-existent player profile")
    func testGetNonExistentPlayerProfile() async throws {
        let repository = createRepository()

        let profile = try await repository.getPlayerProfile(name: "NonExistent")
        #expect(profile == nil)
    }

    @Test("Should get all player profiles")
    func testGetAllPlayerProfiles() async throws {
        let repository = createRepository()
        let player1 = PlayerBuilder().withName("Player1").build()
        let player2 = PlayerBuilder().withName("Player2").build()
        let gameSession = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        )

        try await repository.save(gameSession)

        let profiles = try await repository.getAllPlayerProfiles()
        #expect(profiles.count == 2)

        let profileNames = profiles.map(\.name)
        #expect(profileNames.contains("Player1"))
        #expect(profileNames.contains("Player2"))
    }

    @Test("Should update existing player profile")
    func testUpdateExistingPlayerProfile() async throws {
        let repository = createRepository()
        let player = PlayerBuilder()
            .withName("TestPlayer")
            .build()
            .updateScore(GameScore(paintedArea: 75.0))
        let opponent = PlayerBuilder().withName("Opponent").build()

        // First game
        let gameSession1 = GameSessionBuilder().withPlayers([player, opponent]).build()
        try await repository.save(gameSession1)

        let profileAfterFirstGame = try await repository.getPlayerProfile(name: "TestPlayer")
        #expect(profileAfterFirstGame?.totalGames == 1)

        // Second game
        let gameSession2 = GameSessionBuilder().withPlayers([player, opponent]).build()
        try await repository.save(gameSession2)

        let profileAfterSecondGame = try await repository.getPlayerProfile(name: "TestPlayer")
        #expect(profileAfterSecondGame?.totalGames == 2)
    }

    @Test("Should delete player profile")
    func testDeletePlayerProfile() async throws {
        let repository = createRepository()
        let player1 = PlayerBuilder().withName("TestPlayer").build()
        let player2 = PlayerBuilder().withName("Opponent").build()
        let gameSession = GameSessionBuilder().withPlayers([player1, player2]).build()

        try await repository.save(gameSession)

        let beforeDelete = try await repository.getPlayerProfile(name: "TestPlayer")
        #expect(beforeDelete != nil)

        try await repository.deletePlayerProfile(name: "TestPlayer")

        let afterDelete = try await repository.getPlayerProfile(name: "TestPlayer")
        #expect(afterDelete == nil)
    }

    // MARK: - Game History Query Tests

    @Test("Should get recent games for player")
    func testGetRecentGamesForPlayer() async throws {
        let repository = createRepository()
        let player = PlayerBuilder().withName("TestPlayer").build()
        let opponent = PlayerBuilder().withName("Opponent").build()

        // Create multiple games
        for i in 1 ... 5 {
            let gameSession = GameSessionBuilder()
                .withPlayers([player, opponent])
                .withDuration(TimeInterval(i * 60))
                .build()
            try await repository.save(gameSession)
        }

        let recentGames = try await repository.getRecentGames(for: "TestPlayer", limit: 3)
        #expect(recentGames.count == 3)

        // Should be sorted by date (most recent first)
        for i in 0 ..< recentGames.count - 1 {
            #expect(recentGames[i].date >= recentGames[i + 1].date)
        }
    }

    @Test("Should get games within date range")
    func testGetGamesWithinDateRange() async throws {
        let repository = createRepository()
        let player = PlayerBuilder().withName("TestPlayer").build()
        let opponent = PlayerBuilder().withName("Opponent").build()

        let now = Date()
        let oneDayAgo = now.addingTimeInterval(-24 * 60 * 60)
        let twoDaysAgo = now.addingTimeInterval(-48 * 60 * 60)
        let futureTime = now.addingTimeInterval(60) // 1 minute in the future

        // Create a game session (this will use current date)
        let gameSession = GameSessionBuilder().withPlayers([player, opponent]).build()
        try await repository.save(gameSession)

        // Query for games in a range that includes now
        let recentGames = try await repository.getGames(from: oneDayAgo, to: futureTime)
        #expect(recentGames.count == 1)

        // Query for games older than 2 days (should be empty)
        let oldGames = try await repository.getGames(from: twoDaysAgo, to: oneDayAgo)
        #expect(oldGames.isEmpty)
    }

    @Test("Should get game statistics")
    func testGetGameStatistics() async throws {
        let repository = createRepository()

        // Create some finished games with different scores
        let player1 = PlayerBuilder().withName("Player1").build()
            .updateScore(GameScore(paintedArea: 80.0))
        let player2 = PlayerBuilder().withName("Player2").build()
            .updateScore(GameScore(paintedArea: 20.0))

        let finishedGame1 = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        ).start().end()

        let finishedGame2 = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 240
        ).start().end()

        try await repository.save(finishedGame1)
        try await repository.save(finishedGame2)

        let statistics = try await repository.getGameStatistics()

        #expect(statistics.totalGames == 2)
        #expect(statistics.completedGames == 2)
        #expect(statistics.averageDuration == 210.0) // (180 + 240) / 2
        #expect(statistics.averagePlayerScore == 80.0)
        #expect(statistics.averageOpponentScore == 20.0)
    }

    @Test("Should handle empty statistics")
    func testGetEmptyGameStatistics() async throws {
        let repository = createRepository()

        let statistics = try await repository.getGameStatistics()

        #expect(statistics.totalGames == 0)
        #expect(statistics.completedGames == 0)
        #expect(statistics.averageDuration == 0.0)
        #expect(statistics.averagePlayerScore == 0.0)
        #expect(statistics.averageOpponentScore == 0.0)
    }

    // MARK: - Utility Tests

    @Test("Should clear all data")
    func testClearAll() async throws {
        let repository = createRepository()
        let gameSession = GameSessionBuilder().build()

        try await repository.save(gameSession)

        let countsBeforeClear = repository.getCounts()
        #expect(countsBeforeClear.sessions > 0)
        #expect(countsBeforeClear.histories > 0)
        #expect(countsBeforeClear.profiles > 0)

        repository.clearAll()

        let countsAfterClear = repository.getCounts()
        #expect(countsAfterClear.sessions == 0)
        #expect(countsAfterClear.histories == 0)
        #expect(countsAfterClear.profiles == 0)
    }

    @Test("Should track counts correctly")
    func testGetCounts() async throws {
        let repository = createRepository()

        let initialCounts = repository.getCounts()
        #expect(initialCounts.sessions == 0)
        #expect(initialCounts.histories == 0)
        #expect(initialCounts.profiles == 0)

        let player1 = PlayerBuilder().withName("Player1").build()
        let player2 = PlayerBuilder().withName("Player2").build()
        let gameSession = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        )

        try await repository.save(gameSession)

        let countsAfterSave = repository.getCounts()
        #expect(countsAfterSave.sessions == 1)
        #expect(countsAfterSave.histories == 1)
        #expect(countsAfterSave.profiles == 2)
    }

    // MARK: - Integration Tests

    @Test("Should handle complex game scenarios")
    func testComplexGameScenarios() async throws {
        let repository = createRepository()

        // Create players
        let alice = PlayerBuilder().withName("Alice").withColor(.red).build()
        let bob = PlayerBuilder().withName("Bob").withColor(.blue).build()

        // Game 1: Alice wins
        let aliceWins = alice.updateScore(GameScore(paintedArea: 75.0))
        let bobLoses = bob.updateScore(GameScore(paintedArea: 25.0))
        let game1 = GameSession(
            id: GameSessionId(),
            players: [aliceWins, bobLoses],
            duration: 180
        ).start().end()

        try await repository.save(game1)

        // Game 2: Bob wins
        let aliceLoses = alice.updateScore(GameScore(paintedArea: 30.0))
        let bobWins = bob.updateScore(GameScore(paintedArea: 70.0))
        let game2 = GameSession(
            id: GameSessionId(),
            players: [aliceLoses, bobWins],
            duration: 240
        ).start().end()

        try await repository.save(game2)

        // Verify profiles
        let aliceProfile = try await repository.getPlayerProfile(name: "Alice")
        let bobProfile = try await repository.getPlayerProfile(name: "Bob")

        #expect(aliceProfile?.totalGames == 2)
        #expect(aliceProfile?.wins == 1)
        #expect(aliceProfile?.losses == 1)
        #expect(aliceProfile?.winRate == 50.0)

        #expect(bobProfile?.totalGames == 2)
        #expect(bobProfile?.wins == 1)
        #expect(bobProfile?.losses == 1)
        #expect(bobProfile?.winRate == 50.0)

        // Verify game history
        let aliceGames = try await repository.getRecentGames(for: "Alice")
        let bobGames = try await repository.getRecentGames(for: "Bob")

        #expect(aliceGames.count == 2)
        #expect(bobGames.count == 2)

        // Verify statistics
        let statistics = try await repository.getGameStatistics()
        #expect(statistics.totalGames == 2)
        #expect(statistics.completedGames == 2)
        #expect(statistics.averageDuration == 210.0) // (180 + 240) / 2
    }
}
