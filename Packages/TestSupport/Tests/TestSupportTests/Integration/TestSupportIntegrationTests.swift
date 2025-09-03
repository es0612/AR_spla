import Domain
import Foundation
import Testing
@testable import TestSupport

/// Integration tests demonstrating how all TestSupport components work together
struct TestSupportIntegrationTests {
    @Test("Complete game scenario using all test support components")
    func testCompleteGameScenario() async throws {
        // Arrange: Set up repositories and test data
        let gameRepository = MockGameRepository()
        let playerRepository = MockPlayerRepository()

        // Create players using builders
        let player1 = PlayerBuilder.redPlayer()
            .withName("Alice")
            .withPosition(x: -2, y: 0, z: 0)
            .build()

        let player2 = PlayerBuilder.bluePlayer()
            .withName("Bob")
            .withPosition(x: 2, y: 0, z: 0)
            .build()

        // Save players
        try await playerRepository.save(player1)
        try await playerRepository.save(player2)

        // Create game session using builder
        let gameSession = GameSessionBuilder()
            .withPlayers([player1, player2])
            .withDuration(180)
            .withStatus(.waiting)
            .build()

        // Act: Save and start the game
        try await gameRepository.save(gameSession)
        let startedSession = gameSession.start()
        try await gameRepository.update(startedSession)

        // Add some ink spots during the game
        let inkSpot1 = InkSpotBuilder.inkSpotFor(player: player1)
            .withPosition(x: -1, y: 0, z: -1)
            .withSize(0.8)
            .build()

        let inkSpot2 = InkSpotBuilder.inkSpotFor(player: player2)
            .withPosition(x: 1, y: 0, z: 1)
            .withSize(0.6)
            .build()

        let sessionWithInk = startedSession
            .addInkSpot(inkSpot1)
            .addInkSpot(inkSpot2)

        try await gameRepository.update(sessionWithInk)

        // End the game
        let finishedSession = sessionWithInk.end()
        try await gameRepository.update(finishedSession)

        // Assert: Verify the complete scenario
        #expect(gameRepository.saveCallCount == 1)
        #expect(gameRepository.updateCallCount == 3)
        #expect(playerRepository.saveCallCount == 2)

        let retrievedSession = try await gameRepository.findById(gameSession.id)
        #expect(retrievedSession?.status == .finished)
        #expect(retrievedSession?.inkSpots.count == 2)

        let activePlayers = try await playerRepository.findActive()
        #expect(activePlayers.count == 2)
    }

    @Test("Test data consistency across multiple scenarios")
    func testTestDataConsistency() {
        // Verify that TestData provides consistent, reusable test data
        let scenario1 = TestData.competitiveGameScenario()
        let scenario2 = TestData.oneSidedGameScenario()
        let scenario3 = TestData.tieGameScenario()

        // All scenarios should use the same base players
        #expect(scenario1.players.count == 2)
        #expect(scenario2.players.count == 2)
        #expect(scenario3.players.count == 2)

        // But have different outcomes
        let winner1 = scenario1.winner
        let winner2 = scenario2.winner
        let winner3 = scenario3.winner

        #expect(winner1 != nil) // Competitive game has a winner
        #expect(winner2 != nil) // One-sided game has a clear winner
        #expect(winner3 == nil) // Tie game has no winner

        // Verify score differences
        let player1Score1 = scenario1.players[0].score.paintedArea
        let player2Score1 = scenario1.players[1].score.paintedArea
        #expect(abs(player1Score1 - player2Score1) < 10) // Close scores

        let player1Score2 = scenario2.players[0].score.paintedArea
        let player2Score2 = scenario2.players[1].score.paintedArea
        #expect(abs(player1Score2 - player2Score2) > 50) // Large difference

        let player1Score3 = scenario3.players[0].score.paintedArea
        let player2Score3 = scenario3.players[1].score.paintedArea
        #expect(player1Score3 == player2Score3) // Exact tie
    }

    @Test("Builder chaining and fluent interface")
    func testBuilderChaining() {
        // Demonstrate fluent interface of builders
        let complexPlayer = PlayerBuilder()
            .withName("Complex Player")
            .withColor(.purple)
            .withPosition(x: 3.14, y: 2.71, z: 1.41)
            .withScore(paintedArea: 42.0)
            .withActiveStatus(false)
            .build()

        #expect(complexPlayer.name == "Complex Player")
        #expect(complexPlayer.color == .purple)
        #expect(complexPlayer.position.x == 3.14)
        #expect(complexPlayer.score.paintedArea == 42.0)
        #expect(complexPlayer.isActive == false)

        let complexGameSession = GameSessionBuilder()
            .withPlayers([complexPlayer, TestData.redPlayer])
            .withDuration(300)
            .withStatus(.active)
            .addInkSpot(TestData.redInkSpotAtOrigin)
            .addInkSpot(TestData.blueInkSpotNearOrigin)
            .build()

        #expect(complexGameSession.duration == 300)
        #expect(complexGameSession.status == .active)
        #expect(complexGameSession.inkSpots.count == 2)
    }

    @Test("Mock repository error handling and state tracking")
    func testMockRepositoryErrorHandling() async {
        let repository = MockGameRepository()

        // Test normal operation
        let gameSession = TestData.waitingGameSession
        try? await repository.save(gameSession)
        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedGameSession?.id == gameSession.id)

        // Test error simulation
        repository.shouldThrowError = true
        repository.errorToThrow = MockRepositoryError.invalidData

        await #expect(throws: MockRepositoryError.invalidData) {
            try await repository.save(TestData.activeGameSession)
        }

        // Call count should still increment even when throwing
        #expect(repository.saveCallCount == 2)

        // Reset and verify clean state
        repository.reset()
        #expect(repository.saveCallCount == 0)
        #expect(repository.shouldThrowError == false)
        #expect(repository.lastSavedGameSession == nil)
    }

    @Test("Random test data generation for stress testing")
    func testRandomDataGeneration() {
        // Generate multiple random players and verify they're different
        let randomPlayers = (0 ..< 10).map { _ in TestData.randomPlayer() }

        // All should have different IDs
        let uniqueIds = Set(randomPlayers.map(\.id))
        #expect(uniqueIds.count == 10)

        // All should have valid names
        for player in randomPlayers {
            #expect(!player.name.isEmpty)
            #expect(player.name.contains("Random Player"))
        }

        // Generate random game session
        let randomSession = TestData.randomGameSession()
        #expect(randomSession.players.count == 2)
        #expect(randomSession.duration >= GameSession.minDuration)
        #expect(randomSession.duration <= GameSession.maxDuration)
    }

    @Test("Overlapping ink spots scenario")
    func testOverlappingInkSpotsScenario() {
        let overlappingSpots = TestData.overlappingInkSpotsScenario()

        #expect(overlappingSpots.count == 2)

        let spot1 = overlappingSpots[0]
        let spot2 = overlappingSpots[1]

        // Verify they actually overlap
        #expect(spot1.overlaps(with: spot2))
        #expect(spot2.overlaps(with: spot1))

        // Verify they have different colors
        #expect(spot1.color != spot2.color)
    }
}
