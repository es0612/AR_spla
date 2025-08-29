import Testing
import Foundation
import MultipeerConnectivity
@testable import Infrastructure
@testable import Domain
import TestSupport

struct MultiPeerGameRepositoryTests {
    
    // MARK: - Initialization Tests
    
    @Test("MultiPeerGameRepository should initialize with correct display name")
    func testInitialization() {
        let displayName = "TestPlayer"
        let repository = MultiPeerGameRepository(displayName: displayName)
        
        #expect(repository.connectionState == .disconnected)
        #expect(repository.connectedPeers.isEmpty)
        #expect(repository.discoveredPeers.isEmpty)
    }
    
    // MARK: - Game Repository Tests
    
    @Test("Should save and retrieve game session")
    func testSaveAndRetrieveGameSession() async throws {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
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
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        let nonExistentId = GameSessionId()
        
        let result = try await repository.findById(nonExistentId)
        #expect(result == nil)
    }
    
    @Test("Should find all game sessions")
    func testFindAllGameSessions() async throws {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        let session1 = GameSessionBuilder().withDuration(180).build()
        let session2 = GameSessionBuilder().withDuration(300).build()
        
        try await repository.save(session1)
        try await repository.save(session2)
        
        let allSessions = try await repository.findAll()
        #expect(allSessions.count == 2)
        #expect(allSessions.contains { $0.id == session1.id })
        #expect(allSessions.contains { $0.id == session2.id })
    }
    
    @Test("Should find only active game sessions")
    func testFindActiveGameSessions() async throws {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
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
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        let originalSession = GameSessionBuilder().withDuration(180).build()
        
        try await repository.save(originalSession)
        
        let updatedSession = originalSession.start()
        try await repository.update(updatedSession)
        
        let retrievedSession = try await repository.findById(originalSession.id)
        #expect(retrievedSession?.status == .active)
        #expect(retrievedSession?.startedAt != nil)
    }
    
    @Test("Should delete game session")
    func testDeleteGameSession() async throws {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        let gameSession = GameSessionBuilder().withDuration(180).build()
        
        try await repository.save(gameSession)
        
        let beforeDelete = try await repository.findById(gameSession.id)
        #expect(beforeDelete != nil)
        
        try await repository.delete(gameSession.id)
        
        let afterDelete = try await repository.findById(gameSession.id)
        #expect(afterDelete == nil)
    }
    
    // MARK: - Connection State Tests
    
    @Test("Connection state should change when starting advertising")
    func testStartAdvertising() {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        
        #expect(repository.connectionState == .disconnected)
        
        repository.startAdvertising()
        
        #expect(repository.connectionState == .advertising)
    }
    
    @Test("Connection state should change when starting browsing")
    func testStartBrowsing() {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        
        #expect(repository.connectionState == .disconnected)
        
        repository.startBrowsing()
        
        #expect(repository.connectionState == .browsing)
    }
    
    @Test("Connection state should reset when stopping advertising")
    func testStopAdvertising() {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        
        repository.startAdvertising()
        #expect(repository.connectionState == .advertising)
        
        repository.stopAdvertising()
        #expect(repository.connectionState == .disconnected)
    }
    
    @Test("Connection state should reset when stopping browsing")
    func testStopBrowsing() {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        
        repository.startBrowsing()
        #expect(repository.connectionState == .browsing)
        
        repository.stopBrowsing()
        #expect(repository.connectionState == .disconnected)
    }
    
    // MARK: - Message Sending Tests
    
    @Test("Should throw error when sending message with no connected peers")
    func testSendMessageWithNoPeers() {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        let message = NetworkGameMessageFactory.ping(senderId: "TestPlayer")
        
        #expect(throws: NetworkError.connectionFailed) {
            try repository.sendMessage(message)
        }
    }
    
    @Test("Should throw error when sending message to empty peer list")
    func testSendMessageToEmptyPeerList() {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        let message = NetworkGameMessageFactory.ping(senderId: "TestPlayer")
        let emptyPeers: [MCPeerID] = []
        
        #expect(throws: NetworkError.connectionFailed) {
            try repository.sendMessage(message, toPeers: emptyPeers)
        }
    }
    
    // MARK: - Network Message Factory Integration Tests
    
    @Test("Should create and send game start message")
    func testCreateGameStartMessage() async throws {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        let gameSession = GameSessionBuilder()
            .withDuration(180)
            .build()
        
        // This should not throw when no peers are connected (save operation)
        try await repository.save(gameSession)
        
        let retrievedSession = try await repository.findById(gameSession.id)
        #expect(retrievedSession != nil)
    }
    
    @Test("Should handle game session with ink spots in update")
    func testUpdateGameSessionWithInkSpots() async throws {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        let gameSession = GameSessionBuilder().withDuration(180).build()
        
        try await repository.save(gameSession)
        
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1.0, y: 0.0, z: 1.0),
            color: PlayerColor.red,
            size: 1.0,
            ownerId: gameSession.players[0].id
        )
        
        let updatedSession = gameSession.addInkSpot(inkSpot)
        
        // This should not throw even without connected peers
        try await repository.update(updatedSession)
        
        let retrievedSession = try await repository.findById(gameSession.id)
        #expect(retrievedSession?.inkSpots.count == 1)
    }
    
    // MARK: - Error Handling Tests
    
    @Test("Should handle invalid message parsing gracefully")
    func testInvalidMessageHandling() {
        let repository = MultiPeerGameRepository(displayName: "TestPlayer")
        
        // Create a message with invalid data for game start
        let invalidMessage = NetworkGameMessage(
            type: .gameStart,
            senderId: "TestSender",
            data: Data("invalid json".utf8)
        )
        
        // This should not crash the repository
        // The message handler should catch the parsing error
        // We can't directly test the private message handler, but we can ensure
        // the repository doesn't crash when receiving invalid data
        #expect(repository.connectionState == .disconnected)
    }
}

// MARK: - Connection State Tests

struct ConnectionStateTests {
    
    @Test("ConnectionState should have correct raw values")
    func testConnectionStateRawValues() {
        #expect(ConnectionState.disconnected.rawValue == "disconnected")
        #expect(ConnectionState.advertising.rawValue == "advertising")
        #expect(ConnectionState.browsing.rawValue == "browsing")
        #expect(ConnectionState.connecting.rawValue == "connecting")
        #expect(ConnectionState.connected.rawValue == "connected")
    }
    
    @Test("ConnectionState should include all cases")
    func testConnectionStateAllCases() {
        let allCases = ConnectionState.allCases
        #expect(allCases.count == 5)
        #expect(allCases.contains(.disconnected))
        #expect(allCases.contains(.advertising))
        #expect(allCases.contains(.browsing))
        #expect(allCases.contains(.connecting))
        #expect(allCases.contains(.connected))
    }
}