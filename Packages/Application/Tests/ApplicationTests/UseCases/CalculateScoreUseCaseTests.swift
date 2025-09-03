@testable import Application
import Domain
import Foundation
import Testing
import TestSupport

struct CalculateScoreUseCaseTests {
    // MARK: - Test Properties

    private var mockGameRepository: MockGameRepository
    private var mockPlayerRepository: MockPlayerRepository
    private var scoreCalculationService: ScoreCalculationService
    private var useCase: CalculateScoreUseCase
    private let fieldSize: Float = 16.0 // 4m x 4m

    init() {
        mockGameRepository = MockGameRepository()
        mockPlayerRepository = MockPlayerRepository()
        scoreCalculationService = ScoreCalculationService()
        useCase = CalculateScoreUseCase(
            gameRepository: mockGameRepository,
            playerRepository: mockPlayerRepository,
            scoreCalculationService: scoreCalculationService,
            fieldSize: fieldSize
        )
    }

    // MARK: - Single Player Score Tests

    @Test("単一プレイヤーのスコア計算")
    func testCalculateScoreForSinglePlayer() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let inkSpot1 = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(1.0)
            .build()
        let inkSpot2 = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(0.5)
            .build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([inkSpot1, inkSpot2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.prePopulate(with: [player1, player2])

        // When
        let result = try await useCase.executeForPlayer(
            gameSessionId: gameSession.id,
            playerId: player1.id
        )

        // Then
        #expect(result.score.paintedArea > 0)
        #expect(mockPlayerRepository.updateCallCount == 1)
        #expect(mockPlayerRepository.lastUpdatedPlayer?.id == player1.id)
    }

    @Test("インクスポットなしプレイヤーのスコア計算")
    func testCalculateScoreForPlayerWithNoInkSpots() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([]) // No ink spots
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.prePopulate(with: [player1, player2])

        // When
        let result = try await useCase.executeForPlayer(
            gameSessionId: gameSession.id,
            playerId: player1.id
        )

        // Then
        #expect(result.score.paintedArea == 0.0)
        #expect(mockPlayerRepository.updateCallCount == 1)
    }

    // MARK: - All Players Score Tests

    @Test("全プレイヤーのスコア計算")
    func testCalculateScoreForAllPlayers() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let inkSpot1 = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(1.0)
            .build()
        let inkSpot2 = InkSpotBuilder.inkSpotFor(player: player2)
            .withSize(0.8)
            .build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([inkSpot1, inkSpot2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.prePopulate(with: [player1, player2])

        // When
        let result = try await useCase.executeForAllPlayers(gameSessionId: gameSession.id)

        // Then
        #expect(result.players.count == 2)
        #expect(result.players.allSatisfy { $0.score.paintedArea >= 0 })
        #expect(mockPlayerRepository.updateCallCount == 2) // Both players updated
        #expect(mockGameRepository.updateCallCount == 1) // Game session updated
    }

    @Test("インクスポットなしでの全プレイヤースコア計算")
    func testCalculateScoreForAllPlayersWithNoInkSpots() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.prePopulate(with: [player1, player2])

        // When
        let result = try await useCase.executeForAllPlayers(gameSessionId: gameSession.id)

        // Then
        #expect(result.players.allSatisfy { $0.score.paintedArea == 0.0 })
        #expect(mockPlayerRepository.updateCallCount == 2)
        #expect(mockGameRepository.updateCallCount == 1)
    }

    // MARK: - Game Results Tests

    @Test("ゲーム結果の計算")
    func testCalculateGameResults() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let inkSpot1 = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(1.5) // Larger ink spot
            .build()
        let inkSpot2 = InkSpotBuilder.inkSpotFor(player: player2)
            .withSize(0.5) // Smaller ink spot
            .build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([inkSpot1, inkSpot2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])

        // When
        let results = try await useCase.calculateGameResults(gameSessionId: gameSession.id)

        // Then
        #expect(results.count == 2)
        #expect(results.allSatisfy { $0.rank > 0 })
        #expect(results.allSatisfy { $0.score.paintedArea >= 0 })

        // Check ranking order (higher score should have lower rank number)
        let sortedResults = results.sorted { $0.rank < $1.rank }
        #expect(sortedResults[0].score >= sortedResults[1].score)
    }

    @Test("同点でのゲーム結果計算")
    func testCalculateGameResultsWithTie() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let inkSpot1 = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(1.0) // Same size
            .build()
        let inkSpot2 = InkSpotBuilder.inkSpotFor(player: player2)
            .withSize(1.0) // Same size
            .build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([inkSpot1, inkSpot2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])

        // When
        let results = try await useCase.calculateGameResults(gameSessionId: gameSession.id)

        // Then
        #expect(results.count == 2)

        // In case of tie, both players should have rank 1
        if results[0].score == results[1].score {
            #expect(results.allSatisfy { $0.rank == 1 })
        }
    }

    // MARK: - Total Coverage Tests

    @Test("総カバレッジ計算")
    func testCalculateTotalCoverage() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let inkSpot1 = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(1.0)
            .build()
        let inkSpot2 = InkSpotBuilder.inkSpotFor(player: player2)
            .withSize(0.5)
            .build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([inkSpot1, inkSpot2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])

        // When
        let coverage = try await useCase.calculateTotalCoverage(gameSessionId: gameSession.id)

        // Then
        #expect(coverage >= 0.0)
        #expect(coverage <= 100.0)
    }

    @Test("インクスポットなしでの総カバレッジ計算")
    func testCalculateTotalCoverageWithNoInkSpots() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])

        // When
        let coverage = try await useCase.calculateTotalCoverage(gameSessionId: gameSession.id)

        // Then
        #expect(coverage == 0.0)
    }

    // MARK: - Winner Determination Tests

    @Test("勝者の決定")
    func testDetermineWinner() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let inkSpot1 = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(1.5) // Larger ink spot for player1
            .build()
        let inkSpot2 = InkSpotBuilder.inkSpotFor(player: player2)
            .withSize(0.5) // Smaller ink spot for player2
            .build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([inkSpot1, inkSpot2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.prePopulate(with: [player1, player2])

        // When
        let winner = try await useCase.determineWinner(gameSessionId: gameSession.id)

        // Then
        #expect(winner != nil)
        #expect(winner?.id == player1.id) // Player1 should win with larger ink spot

        // Verify that scores were calculated
        #expect(mockPlayerRepository.updateCallCount == 2)
        #expect(mockGameRepository.updateCallCount == 1)
    }

    @Test("同点での勝者決定")
    func testDetermineWinnerWithTie() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let inkSpot1 = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(1.0) // Same size
            .build()
        let inkSpot2 = InkSpotBuilder.inkSpotFor(player: player2)
            .withSize(1.0) // Same size
            .build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([inkSpot1, inkSpot2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.prePopulate(with: [player1, player2])

        // When
        let winner = try await useCase.determineWinner(gameSessionId: gameSession.id)

        // Then - In case of tie, winner should be nil
        if player1.score == player2.score {
            #expect(winner == nil)
        }
    }

    // MARK: - Error Tests

    @Test("存在しないゲームセッションでのエラー")
    func testErrorWithNonExistentGameSession() async throws {
        // Given
        let nonExistentGameSessionId = GameSessionId()
        let playerId = PlayerId()

        // When & Then
        await #expect(throws: CalculateScoreError.gameSessionNotFound) {
            try await useCase.executeForPlayer(
                gameSessionId: nonExistentGameSessionId,
                playerId: playerId
            )
        }

        await #expect(throws: CalculateScoreError.gameSessionNotFound) {
            try await useCase.executeForAllPlayers(gameSessionId: nonExistentGameSessionId)
        }

        await #expect(throws: CalculateScoreError.gameSessionNotFound) {
            try await useCase.calculateGameResults(gameSessionId: nonExistentGameSessionId)
        }

        await #expect(throws: CalculateScoreError.gameSessionNotFound) {
            try await useCase.calculateTotalCoverage(gameSessionId: nonExistentGameSessionId)
        }

        await #expect(throws: CalculateScoreError.gameSessionNotFound) {
            try await useCase.determineWinner(gameSessionId: nonExistentGameSessionId)
        }
    }

    @Test("存在しないプレイヤーでのエラー")
    func testErrorWithNonExistentPlayer() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()
        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        // Note: Not adding players to player repository

        let nonExistentPlayerId = PlayerId()

        // When & Then
        await #expect(throws: CalculateScoreError.playerNotFound) {
            try await useCase.executeForPlayer(
                gameSessionId: gameSession.id,
                playerId: nonExistentPlayerId
            )
        }
    }

    @Test("不正なフィールドサイズでのエラー")
    func testErrorWithInvalidFieldSize() async throws {
        // Given
        let invalidFieldSize: Float = -1.0
        let invalidUseCase = CalculateScoreUseCase(
            gameRepository: mockGameRepository,
            playerRepository: mockPlayerRepository,
            scoreCalculationService: scoreCalculationService,
            fieldSize: invalidFieldSize
        )

        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()
        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.prePopulate(with: [player1, player2])

        // When & Then
        await #expect(throws: CalculateScoreError.invalidFieldSize) {
            try await invalidUseCase.executeForPlayer(
                gameSessionId: gameSession.id,
                playerId: player1.id
            )
        }
    }

    // MARK: - Repository Error Tests

    @Test("ゲームリポジトリエラー")
    func testGameRepositoryError() async throws {
        // Given
        mockGameRepository.shouldThrowError = true
        mockGameRepository.errorToThrow = MockRepositoryError.simulatedError

        let gameSessionId = GameSessionId()
        let playerId = PlayerId()

        // When & Then
        await #expect(throws: MockRepositoryError.simulatedError) {
            try await useCase.executeForPlayer(
                gameSessionId: gameSessionId,
                playerId: playerId
            )
        }
    }

    @Test("プレイヤーリポジトリエラー")
    func testPlayerRepositoryError() async throws {
        // Given
        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()
        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.shouldThrowError = true
        mockPlayerRepository.errorToThrow = MockRepositoryError.simulatedError

        // When & Then
        await #expect(throws: MockRepositoryError.simulatedError) {
            try await useCase.executeForPlayer(
                gameSessionId: gameSession.id,
                playerId: player1.id
            )
        }
    }

    // MARK: - Edge Cases

    @Test("極小フィールドサイズでのスコア計算")
    func testScoreCalculationWithTinyFieldSize() async throws {
        // Given
        let tinyFieldSize: Float = 0.1
        let tinyFieldUseCase = CalculateScoreUseCase(
            gameRepository: mockGameRepository,
            playerRepository: mockPlayerRepository,
            scoreCalculationService: scoreCalculationService,
            fieldSize: tinyFieldSize
        )

        let player1 = PlayerBuilder.redPlayer().build()
        let player2 = PlayerBuilder.bluePlayer().build()

        let inkSpot = InkSpotBuilder.inkSpotFor(player: player1)
            .withSize(0.1) // Valid minimum ink spot size
            .build()

        let gameSession = GameSessionBuilder.activeGame()
            .withPlayers([player1, player2])
            .withInkSpots([inkSpot])
            .build()

        mockGameRepository.prePopulate(with: [gameSession])
        mockPlayerRepository.prePopulate(with: [player1, player2])

        // When
        let result = try await tinyFieldUseCase.executeForPlayer(
            gameSessionId: gameSession.id,
            playerId: player1.id
        )

        // Then
        #expect(result.score.paintedArea >= 0.0)
        #expect(result.score.paintedArea <= 100.0)
    }
}
