import Testing
import Foundation
@testable import Domain

struct GameSessionTests {
    
    @Test("GameSession should be created with valid properties")
    func testGameSessionCreation() {
        let sessionId = GameSessionId()
        let player1 = createTestPlayer(name: "Player1", color: .red)
        let player2 = createTestPlayer(name: "Player2", color: .blue)
        let players = [player1, player2]
        let duration = TimeInterval(180) // 3 minutes
        
        let gameSession = GameSession(
            id: sessionId,
            players: players,
            duration: duration
        )
        
        #expect(gameSession.id == sessionId)
        #expect(gameSession.players.count == 2)
        #expect(gameSession.players.contains(player1))
        #expect(gameSession.players.contains(player2))
        #expect(gameSession.duration == duration)
        #expect(gameSession.status == .waiting) // Default status
        #expect(gameSession.inkSpots.isEmpty) // No ink spots initially
        #expect(gameSession.startedAt == nil) // Not started yet
        #expect(gameSession.endedAt == nil) // Not ended yet
    }
    
    @Test("GameSession should start correctly")
    func testGameSessionStart() {
        let gameSession = createTestGameSession()
        let startedSession = gameSession.start()
        
        #expect(startedSession.status == .active)
        #expect(startedSession.startedAt != nil)
        #expect(startedSession.endedAt == nil)
        #expect(startedSession.startedAt! <= Date())
    }
    
    @Test("GameSession should end correctly")
    func testGameSessionEnd() {
        let gameSession = createTestGameSession().start()
        let endedSession = gameSession.end()
        
        #expect(endedSession.status == .finished)
        #expect(endedSession.endedAt != nil)
        #expect(endedSession.endedAt! <= Date())
        #expect(endedSession.startedAt != nil) // Should preserve start time
    }
    
    @Test("GameSession should add ink spots correctly")
    func testGameSessionAddInkSpot() {
        let gameSession = createTestGameSession().start()
        let inkSpot = createTestInkSpot()
        
        let updatedSession = gameSession.addInkSpot(inkSpot)
        
        #expect(updatedSession.inkSpots.count == 1)
        #expect(updatedSession.inkSpots.contains(inkSpot))
    }
    
    @Test("GameSession should update player correctly")
    func testGameSessionUpdatePlayer() {
        let player1 = createTestPlayer(name: "Player1", color: .red)
        let player2 = createTestPlayer(name: "Player2", color: .blue)
        let gameSession = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        )
        
        let updatedPlayer1 = player1.updateScore(GameScore(paintedArea: 50.0))
        let updatedSession = gameSession.updatePlayer(updatedPlayer1)
        
        #expect(updatedSession.players.count == 2)
        let foundPlayer = updatedSession.players.first { $0.id == player1.id }
        #expect(foundPlayer?.score.paintedArea == 50.0)
    }
    
    @Test("GameSession should calculate remaining time correctly")
    func testGameSessionRemainingTime() {
        let gameSession = createTestGameSession()
        
        // Not started yet
        #expect(gameSession.remainingTime == gameSession.duration)
        
        // Started session (simulate started 1 minute ago by creating a new session and starting it)
        let startedSession = gameSession.start()
        // For testing purposes, we'll test with the current time since we can't mock the start time easily
        
        let remaining = startedSession.remainingTime
        #expect(remaining <= 180.0) // Should be close to full duration since just started
        #expect(remaining >= 175.0) // Allow for test execution time
    }
    
    @Test("GameSession should determine winner correctly")
    func testGameSessionWinner() {
        let player1 = createTestPlayer(name: "Player1", color: .red)
            .updateScore(GameScore(paintedArea: 60.0))
        let player2 = createTestPlayer(name: "Player2", color: .blue)
            .updateScore(GameScore(paintedArea: 40.0))
        
        let gameSession = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        ).updatePlayer(player1).updatePlayer(player2).start().end() // Update players with scores, then start and end
        
        let winner = gameSession.winner
        #expect(winner?.id == player1.id)
    }
    
    @Test("GameSession should handle tie correctly")
    func testGameSessionTie() {
        let player1 = createTestPlayer(name: "Player1", color: .red)
            .updateScore(GameScore(paintedArea: 50.0))
        let player2 = createTestPlayer(name: "Player2", color: .blue)
            .updateScore(GameScore(paintedArea: 50.0))
        
        let gameSession = GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        ).updatePlayer(player1).updatePlayer(player2).start().end() // Update players with scores, then start and end
        
        let winner = gameSession.winner
        #expect(winner == nil) // Tie
    }
    
    @Test("GameSession should validate player count")
    func testGameSessionPlayerValidation() {
        // Valid player count
        #expect(GameSession.isValidPlayerCount(2))
        
        // Invalid player counts
        #expect(!GameSession.isValidPlayerCount(0))
        #expect(!GameSession.isValidPlayerCount(1))
        #expect(!GameSession.isValidPlayerCount(3))
        #expect(!GameSession.isValidPlayerCount(-1))
    }
    
    @Test("GameSession should validate duration")
    func testGameSessionDurationValidation() {
        // Valid durations
        #expect(GameSession.isValidDuration(60))   // 1 minute
        #expect(GameSession.isValidDuration(180))  // 3 minutes
        #expect(GameSession.isValidDuration(300))  // 5 minutes
        
        // Invalid durations
        #expect(!GameSession.isValidDuration(0))
        #expect(!GameSession.isValidDuration(-60))
        #expect(!GameSession.isValidDuration(601)) // Too long
    }
    
    @Test("GameSession should be equatable by ID")
    func testGameSessionEquality() {
        let sessionId = GameSessionId()
        let players = [
            createTestPlayer(name: "Player1", color: .red),
            createTestPlayer(name: "Player2", color: .blue)
        ]
        let differentPlayers = [
            createTestPlayer(name: "Player3", color: .green),
            createTestPlayer(name: "Player4", color: .yellow)
        ]
        
        let session1 = GameSession(id: sessionId, players: players, duration: 180)
        let session2 = GameSession(id: sessionId, players: differentPlayers, duration: 300) // Different properties
        let session3 = GameSession(id: GameSessionId(), players: players, duration: 180) // Different ID
        
        #expect(session1 == session2) // Same ID
        #expect(session1 != session3) // Different ID
    }
    
    @Test("GameSession should be codable")
    func testGameSessionCodable() throws {
        let originalSession = createTestGameSession()
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalSession)
        
        let decoder = JSONDecoder()
        let decodedSession = try decoder.decode(GameSession.self, from: data)
        
        #expect(originalSession.id == decodedSession.id)
        #expect(originalSession.players.count == decodedSession.players.count)
        #expect(originalSession.duration == decodedSession.duration)
        #expect(originalSession.status == decodedSession.status)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPlayer(name: String, color: PlayerColor) -> Player {
        return Player(
            id: PlayerId(),
            name: name,
            color: color,
            position: Position3D(x: 0.0, y: 0.0, z: 0.0)
        )
    }
    
    private func createTestInkSpot() -> InkSpot {
        return InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1.0, y: 0.0, z: 1.0),
            color: .red,
            size: 0.5,
            ownerId: PlayerId()
        )
    }
    
    private func createTestGameSession() -> GameSession {
        let player1 = createTestPlayer(name: "Player1", color: .red)
        let player2 = createTestPlayer(name: "Player2", color: .blue)
        return GameSession(
            id: GameSessionId(),
            players: [player1, player2],
            duration: 180
        )
    }
}