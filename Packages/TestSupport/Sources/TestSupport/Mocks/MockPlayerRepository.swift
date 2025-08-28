import Foundation
import Domain

/// Mock implementation of PlayerRepository for testing
public final class MockPlayerRepository: PlayerRepository {
    
    // MARK: - Storage
    private var players: [PlayerId: Player] = [:]
    
    // MARK: - Call tracking
    public private(set) var saveCallCount = 0
    public private(set) var findByIdCallCount = 0
    public private(set) var findAllCallCount = 0
    public private(set) var findByColorCallCount = 0
    public private(set) var findActiveCallCount = 0
    public private(set) var deleteCallCount = 0
    public private(set) var updateCallCount = 0
    
    public private(set) var lastSavedPlayer: Player?
    public private(set) var lastQueriedId: PlayerId?
    public private(set) var lastQueriedColor: PlayerColor?
    public private(set) var lastDeletedId: PlayerId?
    public private(set) var lastUpdatedPlayer: Player?
    
    // MARK: - Error simulation
    public var shouldThrowError = false
    public var errorToThrow: Error = MockRepositoryError.simulatedError
    
    public init() {}
    
    // MARK: - PlayerRepository Implementation
    
    public func save(_ player: Player) async throws {
        saveCallCount += 1
        lastSavedPlayer = player
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        players[player.id] = player
    }
    
    public func findById(_ id: PlayerId) async throws -> Player? {
        findByIdCallCount += 1
        lastQueriedId = id
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return players[id]
    }
    
    public func findAll() async throws -> [Player] {
        findAllCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return Array(players.values)
    }
    
    public func findByColor(_ color: PlayerColor) async throws -> [Player] {
        findByColorCallCount += 1
        lastQueriedColor = color
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return players.values.filter { $0.color == color }
    }
    
    public func findActive() async throws -> [Player] {
        findActiveCallCount += 1
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        return players.values.filter { $0.isActive }
    }
    
    public func delete(_ id: PlayerId) async throws {
        deleteCallCount += 1
        lastDeletedId = id
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        players.removeValue(forKey: id)
    }
    
    public func update(_ player: Player) async throws {
        updateCallCount += 1
        lastUpdatedPlayer = player
        
        if shouldThrowError {
            throw errorToThrow
        }
        
        players[player.id] = player
    }
    
    // MARK: - Test Utilities
    
    /// Reset all call counts and stored data
    public func reset() {
        players.removeAll()
        saveCallCount = 0
        findByIdCallCount = 0
        findAllCallCount = 0
        findByColorCallCount = 0
        findActiveCallCount = 0
        deleteCallCount = 0
        updateCallCount = 0
        lastSavedPlayer = nil
        lastQueriedId = nil
        lastQueriedColor = nil
        lastDeletedId = nil
        lastUpdatedPlayer = nil
        shouldThrowError = false
        errorToThrow = MockRepositoryError.simulatedError
    }
    
    /// Pre-populate the repository with players
    public func prePopulate(with players: [Player]) {
        for player in players {
            self.players[player.id] = player
        }
    }
    
    /// Get the current count of stored players
    public var storedPlayerCount: Int {
        return players.count
    }
    
    /// Check if a specific player is stored
    public func contains(_ player: Player) -> Bool {
        return players[player.id] != nil
    }
    
    /// Get all stored player colors
    public var storedPlayerColors: Set<PlayerColor> {
        return Set(players.values.map { $0.color })
    }
}