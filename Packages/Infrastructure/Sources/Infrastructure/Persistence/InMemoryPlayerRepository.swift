import Domain
import Foundation

/// In-memory implementation of PlayerRepository for testing and development
public class InMemoryPlayerRepository: PlayerRepository {
    private var players: [PlayerId: Player] = [:]

    public init() {}

    // MARK: - PlayerRepository Implementation

    public func save(_ player: Player) async throws {
        players[player.id] = player
    }

    public func findById(_ id: PlayerId) async throws -> Player? {
        players[id]
    }

    public func findAll() async throws -> [Player] {
        Array(players.values).sorted { $0.name < $1.name }
    }

    public func findByColor(_ color: PlayerColor) async throws -> [Player] {
        players.values.filter { $0.color == color }
    }

    public func findActive() async throws -> [Player] {
        players.values.filter(\.isActive)
    }

    public func delete(_ id: PlayerId) async throws {
        players.removeValue(forKey: id)
    }

    public func update(_ player: Player) async throws {
        players[player.id] = player
    }

    // MARK: - Utility Methods

    /// Clear all players (useful for testing)
    public func clearAll() {
        players.removeAll()
    }

    /// Get count of stored players (useful for testing)
    public func getCount() -> Int {
        players.count
    }
}
