import Foundation
import Domain

/// Mock implementation of GameRepository for testing
public final class MockGameRepository: GameRepository {
    
    // MARK: - Storage
    private var gameSessions: [GameSessionId: GameSession] = [:]
    
    // MARK: - Call tracking
    public private(set) var saveCallCount = 0
    public private(set) var findByIdCallCount = 0
    public private(set) var findAllCallCount = 0
    public private(set) var findActiveCallCount = 0
    public private(set) var deleteCallCount = 0
    public private(set) var updateCallCount = 0
    
    public private(set) var lastSavedGameSession: GameSession?
    public private(set) var lastQueriedId: GameSessionId?
    public private(set) var lastDeletedId: GameSessionId?
    public private(set) var lastUpdatedGameSession: GameSession?
    
    // MARK: - Error simulation
    public var shouldThrowError = false
    public var errorToThrow: Error = MockRepositoryError.simulatedError
    
    public init() {}
    
    // MARK: - GameRepository Implementation
    
    public func save(_ gameSession: GameSession) async throws {
        saveCallCount += 1
        lastSavedGameSession = gameSession
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        gameSessions[gameSession.id] = gameSession
    }
    
    public func findById(_ id: GameSessionId) async throws -> GameSession? {
        findByIdCallCount += 1
        lastQueriedId = id
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return gameSessions[id]
    }
    
    public func findAll() async throws -> [GameSession] {
        findAllCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return Array(gameSessions.values)
    }
    
    public func findActive() async throws -> [GameSession] {
        findActiveCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return gameSessions.values.filter { $0.status.isPlayable }
    }
    
    public func delete(_ id: GameSessionId) async throws {
        deleteCallCount += 1
        lastDeletedId = id
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        gameSessions.removeValue(forKey: id)
    }
    
    public func update(_ gameSession: GameSession) async throws {
        updateCallCount += 1
        lastUpdatedGameSession = gameSession
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        gameSessions[gameSession.id] = gameSession
    }
    
    // MARK: - Test Utilities
    
    /// Reset all call counts and stored data
    public func reset() {
        gameSessions.removeAll()
        saveCallCount = 0
        findByIdCallCount = 0
        findAllCallCount = 0
        findActiveCallCount = 0
        deleteCallCount = 0
        updateCallCount = 0
        lastSavedGameSession = nil
        lastQueriedId = nil
        lastDeletedId = nil
        lastUpdatedGameSession = nil
        shouldThrowError = false
        errorToThrow = MockRepositoryError.simulatedError
    }
    
    /// Pre-populate the repository with game sessions
    public func prePopulate(with gameSessions: [GameSession]) {
        for gameSession in gameSessions {
            self.gameSessions[gameSession.id] = gameSession
        }
    }
    
    /// Get the current count of stored game sessions
    public var storedGameSessionCount: Int {
        return gameSessions.count
    }
    
    /// Check if a specific game session is stored
    public func contains(_ gameSession: GameSession) -> Bool {
        return gameSessions[gameSession.id] != nil
    }
}

/// Errors that can be thrown by mock repositories
public enum MockRepositoryError: Error, LocalizedError {
    case simulatedError
    case notFound
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .simulatedError:
            return "Simulated error for testing"
        case .notFound:
            return "Entity not found"
        case .invalidData:
            return "Invalid data provided"
        }
    }
}