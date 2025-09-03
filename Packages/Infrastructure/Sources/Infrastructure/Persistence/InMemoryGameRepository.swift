import Application
import Domain
import Foundation

/// In-memory implementation of GameRepository for testing and development
public class InMemoryGameRepository: GameRepository {
    private var gameSessions: [GameSessionId: GameSession] = [:]
    private var gameHistories: [String: SimpleGameHistory] = [:]
    private var playerProfiles: [String: SimplePlayerProfile] = [:]

    public init() {}

    // MARK: - GameRepository Implementation

    public func save(_ gameSession: GameSession) async throws {
        gameSessions[gameSession.id] = gameSession

        // Create game history
        let gameHistory = SimpleGameHistory(from: gameSession)
        gameHistories[gameHistory.id] = gameHistory

        // Update player profiles
        for player in gameSession.players {
            try await updatePlayerProfile(player, from: gameSession)
        }
    }

    public func findById(_ id: GameSessionId) async throws -> GameSession? {
        gameSessions[id]
    }

    public func findAll() async throws -> [GameSession] {
        Array(gameSessions.values).sorted { $0.id.value.uuidString < $1.id.value.uuidString }
    }

    public func findActive() async throws -> [GameSession] {
        gameSessions.values.filter(\.status.isPlayable)
    }

    public func delete(_ id: GameSessionId) async throws {
        gameSessions.removeValue(forKey: id)
        gameHistories.removeValue(forKey: id.value.uuidString)
    }

    public func update(_ gameSession: GameSession) async throws {
        gameSessions[gameSession.id] = gameSession

        // Update game history
        let gameHistory = SimpleGameHistory(from: gameSession)
        gameHistories[gameHistory.id] = gameHistory

        // Update player profiles
        for player in gameSession.players {
            try await updatePlayerProfile(player, from: gameSession)
        }
    }

    // MARK: - Player Profile Management

    /// Get player profile by name
    public func getPlayerProfile(name: String) async throws -> SimplePlayerProfile? {
        playerProfiles[name]
    }

    /// Get all player profiles
    public func getAllPlayerProfiles() async throws -> [SimplePlayerProfile] {
        Array(playerProfiles.values).sorted { $0.totalGames > $1.totalGames }
    }

    /// Update or create player profile
    public func updatePlayerProfile(_ player: Player, from gameSession: GameSession) async throws {
        let existingProfile = playerProfiles[player.name]

        let gameResult: SimpleGameResult
        if let winner = gameSession.winner {
            if winner.id == player.id {
                gameResult = .won
            } else {
                gameResult = .lost
            }
        } else {
            gameResult = .tie
        }

        if let profile = existingProfile {
            profile.update(from: player, gameResult: gameResult)
        } else {
            let newProfile = SimplePlayerProfile(from: player)
            newProfile.update(from: player, gameResult: gameResult)
            playerProfiles[player.name] = newProfile
        }
    }

    /// Delete player profile
    public func deletePlayerProfile(name: String) async throws {
        playerProfiles.removeValue(forKey: name)
    }

    // MARK: - Game History Queries

    /// Get recent games for a player
    public func getRecentGames(for playerName: String, limit: Int = 10) async throws -> [SimpleGameHistory] {
        let filteredGames = gameHistories.values.filter { history in
            history.playerNames.contains(playerName)
        }

        let sortedGames = filteredGames.sorted { $0.date > $1.date }
        return Array(sortedGames.prefix(limit))
    }

    /// Get games within date range
    public func getGames(from startDate: Date, to endDate: Date) async throws -> [SimpleGameHistory] {
        let filteredGames = gameHistories.values.filter { history in
            history.date >= startDate && history.date <= endDate
        }

        return filteredGames.sorted { $0.date > $1.date }
    }

    /// Get game statistics
    public func getGameStatistics() async throws -> GameStatistics {
        let allGames = Array(gameHistories.values)

        let totalGames = allGames.count
        let totalDuration = allGames.reduce(0) { $0 + $1.duration }
        let averageDuration = totalGames > 0 ? totalDuration / Double(totalGames) : 0

        let completedGames = allGames.filter { $0.gameStatus == "finished" }
        let averagePlayerScore = completedGames.isEmpty ? 0 :
            completedGames.reduce(0) { $0 + $1.playerScore } / Double(completedGames.count)
        let averageOpponentScore = completedGames.isEmpty ? 0 :
            completedGames.reduce(0) { $0 + $1.opponentScore } / Double(completedGames.count)

        return GameStatistics(
            totalGames: totalGames,
            completedGames: completedGames.count,
            averageDuration: averageDuration,
            averagePlayerScore: averagePlayerScore,
            averageOpponentScore: averageOpponentScore
        )
    }

    // MARK: - Utility Methods

    /// Clear all data (useful for testing)
    public func clearAll() {
        gameSessions.removeAll()
        gameHistories.removeAll()
        playerProfiles.removeAll()
    }

    /// Get count of stored items (useful for testing)
    public func getCounts() -> (sessions: Int, histories: Int, profiles: Int) {
        (gameSessions.count, gameHistories.count, playerProfiles.count)
    }
}
