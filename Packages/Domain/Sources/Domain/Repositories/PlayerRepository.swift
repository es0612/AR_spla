import Foundation

/// Repository protocol for managing players
public protocol PlayerRepository {
    /// Save a player
    func save(_ player: Player) async throws
    
    /// Find a player by ID
    func findById(_ id: PlayerId) async throws -> Player?
    
    /// Find all players
    func findAll() async throws -> [Player]
    
    /// Find players by color
    func findByColor(_ color: PlayerColor) async throws -> [Player]
    
    /// Find active players
    func findActive() async throws -> [Player]
    
    /// Delete a player
    func delete(_ id: PlayerId) async throws
    
    /// Update a player
    func update(_ player: Player) async throws
}