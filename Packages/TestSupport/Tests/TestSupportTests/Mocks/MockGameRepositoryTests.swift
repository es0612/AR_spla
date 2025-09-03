import Domain
import Foundation
import Testing
@testable import TestSupport

struct MockGameRepositoryTests {
    @Test("MockGameRepository saves and retrieves game sessions")
    func testSaveAndRetrieve() async throws {
        let repository = MockGameRepository()
        let gameSession = TestData.waitingGameSession

        try await repository.save(gameSession)

        #expect(repository.saveCallCount == 1)
        #expect(repository.lastSavedGameSession?.id == gameSession.id)
        #expect(repository.storedGameSessionCount == 1)

        let retrieved = try await repository.findById(gameSession.id)
        #expect(repository.findByIdCallCount == 1)
        #expect(retrieved?.id == gameSession.id)
    }

    @Test("MockGameRepository finds all game sessions")
    func testFindAll() async throws {
        let repository = MockGameRepository()
        let gameSessions = [TestData.waitingGameSession, TestData.activeGameSession]

        repository.prePopulate(with: gameSessions)

        let allSessions = try await repository.findAll()
        #expect(repository.findAllCallCount == 1)
        #expect(allSessions.count == 2)
    }

    @Test("MockGameRepository finds active game sessions")
    func testFindActive() async throws {
        let repository = MockGameRepository()
        let gameSessions = [
            TestData.waitingGameSession,
            TestData.activeGameSession,
            TestData.finishedGameSession
        ]

        repository.prePopulate(with: gameSessions)

        let activeSessions = try await repository.findActive()
        #expect(repository.findActiveCallCount == 1)
        #expect(activeSessions.count == 1) // Only active session
        #expect(activeSessions.first?.status == .active)
    }

    @Test("MockGameRepository deletes game sessions")
    func testDelete() async throws {
        let repository = MockGameRepository()
        let gameSession = TestData.waitingGameSession

        repository.prePopulate(with: [gameSession])
        #expect(repository.storedGameSessionCount == 1)

        try await repository.delete(gameSession.id)

        #expect(repository.deleteCallCount == 1)
        #expect(repository.lastDeletedId == gameSession.id)
        #expect(repository.storedGameSessionCount == 0)
    }

    @Test("MockGameRepository updates game sessions")
    func testUpdate() async throws {
        let repository = MockGameRepository()
        let originalSession = TestData.waitingGameSession
        let updatedSession = originalSession.start()

        repository.prePopulate(with: [originalSession])

        try await repository.update(updatedSession)

        #expect(repository.updateCallCount == 1)
        #expect(repository.lastUpdatedGameSession?.status == .active)

        let retrieved = try await repository.findById(originalSession.id)
        #expect(retrieved?.status == .active)
    }

    @Test("MockGameRepository simulates errors")
    func testErrorSimulation() async {
        let repository = MockGameRepository()
        repository.shouldThrowError = true
        repository.errorToThrow = MockRepositoryError.notFound

        await #expect(throws: MockRepositoryError.notFound) {
            try await repository.save(TestData.waitingGameSession)
        }

        await #expect(throws: MockRepositoryError.notFound) {
            try await repository.findById(GameSessionId())
        }
    }

    @Test("MockGameRepository reset functionality")
    func testReset() async throws {
        let repository = MockGameRepository()

        // Perform some operations
        try await repository.save(TestData.waitingGameSession)
        _ = try await repository.findAll()

        #expect(repository.saveCallCount == 1)
        #expect(repository.findAllCallCount == 1)
        #expect(repository.storedGameSessionCount == 1)

        // Reset
        repository.reset()

        #expect(repository.saveCallCount == 0)
        #expect(repository.findAllCallCount == 0)
        #expect(repository.storedGameSessionCount == 0)
        #expect(repository.lastSavedGameSession == nil)
    }

    @Test("MockGameRepository contains method")
    func testContains() {
        let repository = MockGameRepository()
        let gameSession = TestData.waitingGameSession

        #expect(repository.contains(gameSession) == false)

        repository.prePopulate(with: [gameSession])

        #expect(repository.contains(gameSession) == true)
    }
}
