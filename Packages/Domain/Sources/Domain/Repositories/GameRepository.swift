import Foundation

/// Repository protocol for managing game sessions
public protocol GameRepository {
    /// Save a game session
    func save(_ gameSession: GameSession) async throws
    
    /// Find a game session by ID
    func findById(_ id: GameSessionId) async throws -> GameSession?
    
    /// Find all game sessions
    func findAll() async throws -> [GameSession]
    
    /// Find active game sessions
    func findActive() async throws -> [GameSession]
    
    /// Delete a game session
    func delete(_ id: GameSessionId) async throws
    
    /// Update a game session
    func update(_ gameSession: GameSession) async throws
}