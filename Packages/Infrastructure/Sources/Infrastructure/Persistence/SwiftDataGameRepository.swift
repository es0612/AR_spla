import Application
import Domain
import Foundation
import SwiftData

// MARK: - SwiftDataGameRepository

/// SwiftData implementation of GameRepository for persistence
@available(iOS 17.0, macOS 14.0, *)
public class SwiftDataGameRepository: GameRepository {
    private let modelContainer: ModelContainer
    private let modelContext: ModelContext

    // MARK: - Initialization

    public init(modelContainer: ModelContainer) {
        self.modelContainer = modelContainer
        modelContext = ModelContext(modelContainer)
    }

    /// Convenience initializer with default configuration
    public convenience init() throws {
        let schema = Schema([
            GameHistory.self,
            PlayerProfile.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )

        self.init(modelContainer: container)
    }

    /// Convenience initializer for in-memory storage (testing)
    public convenience init(inMemory: Bool) throws {
        let schema = Schema([
            GameHistory.self,
            PlayerProfile.self
        ])

        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: inMemory
        )

        let container = try ModelContainer(
            for: schema,
            configurations: [modelConfiguration]
        )

        self.init(modelContainer: container)
    }

    // MARK: - GameRepository Implementation

    public func save(_ gameSession: GameSession) async throws {
        let gameHistory = GameHistory(from: gameSession)

        modelContext.insert(gameHistory)

        // Update player profiles
        for player in gameSession.players {
            try await updatePlayerProfile(player, from: gameSession)
        }

        try modelContext.save()
    }

    public func findById(_ id: GameSessionId) async throws -> GameSession? {
        let predicate = #Predicate<GameHistory> { history in
            history.id == id.value.uuidString
        }

        let descriptor = FetchDescriptor<GameHistory>(predicate: predicate)
        let histories = try modelContext.fetch(descriptor)

        guard let history = histories.first else {
            return nil
        }

        return try convertToGameSession(history)
    }

    public func findAll() async throws -> [GameSession] {
        let descriptor = FetchDescriptor<GameHistory>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let histories = try modelContext.fetch(descriptor)

        return try histories.compactMap { history in
            try? convertToGameSession(history)
        }
    }

    public func findActive() async throws -> [GameSession] {
        let predicate = #Predicate<GameHistory> { history in
            history.gameStatus == "active"
        }

        let descriptor = FetchDescriptor<GameHistory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        let histories = try modelContext.fetch(descriptor)

        return try histories.compactMap { history in
            try? convertToGameSession(history)
        }
    }

    public func delete(_ id: GameSessionId) async throws {
        let predicate = #Predicate<GameHistory> { history in
            history.id == id.value.uuidString
        }

        let descriptor = FetchDescriptor<GameHistory>(predicate: predicate)
        let histories = try modelContext.fetch(descriptor)

        for history in histories {
            modelContext.delete(history)
        }

        try modelContext.save()
    }

    public func update(_ gameSession: GameSession) async throws {
        // Delete existing record
        try await delete(gameSession.id)

        // Save updated record
        try await save(gameSession)
    }

    // MARK: - Player Profile Management

    /// Get player profile by name
    public func getPlayerProfile(name: String) async throws -> PlayerProfile? {
        let predicate = #Predicate<PlayerProfile> { profile in
            profile.name == name
        }

        let descriptor = FetchDescriptor<PlayerProfile>(predicate: predicate)
        let profiles = try modelContext.fetch(descriptor)

        return profiles.first
    }

    /// Get all player profiles
    public func getAllPlayerProfiles() async throws -> [PlayerProfile] {
        let descriptor = FetchDescriptor<PlayerProfile>(
            sortBy: [SortDescriptor(\.totalGames, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Update or create player profile
    public func updatePlayerProfile(_ player: Player, from gameSession: GameSession) async throws {
        let existingProfile = try await getPlayerProfile(name: player.name)

        let gameResult: GameResult
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
            let newProfile = PlayerProfile(from: player)
            newProfile.update(from: player, gameResult: gameResult)
            modelContext.insert(newProfile)
        }

        try modelContext.save()
    }

    /// Delete player profile
    public func deletePlayerProfile(name: String) async throws {
        let predicate = #Predicate<PlayerProfile> { profile in
            profile.name == name
        }

        let descriptor = FetchDescriptor<PlayerProfile>(predicate: predicate)
        let profiles = try modelContext.fetch(descriptor)

        for profile in profiles {
            modelContext.delete(profile)
        }

        try modelContext.save()
    }

    // MARK: - Game History Queries

    /// Get recent games for a player
    public func getRecentGames(for playerName: String, limit: Int = 10) async throws -> [GameHistory] {
        let predicate = #Predicate<GameHistory> { history in
            history.playerNames.contains(playerName)
        }

        var descriptor = FetchDescriptor<GameHistory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = limit

        return try modelContext.fetch(descriptor)
    }

    /// Get games within date range
    public func getGames(from startDate: Date, to endDate: Date) async throws -> [GameHistory] {
        let predicate = #Predicate<GameHistory> { history in
            history.date >= startDate && history.date <= endDate
        }

        let descriptor = FetchDescriptor<GameHistory>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )

        return try modelContext.fetch(descriptor)
    }

    /// Get game statistics
    public func getGameStatistics() async throws -> GameStatistics {
        let descriptor = FetchDescriptor<GameHistory>()
        let allGames = try modelContext.fetch(descriptor)

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

    // MARK: - Private Helper Methods

    private func convertToGameSession(_ history: GameHistory) throws -> GameSession {
        // This is a simplified conversion - in a real implementation,
        // you would need to store and reconstruct all game session data
        // For now, we'll create a basic game session with minimal data

        guard let gameSessionId = UUID(uuidString: history.id) else {
            throw SwiftDataError.invalidGameSessionId
        }

        // Create placeholder players based on stored names
        // Ensure we always have exactly 2 players for game session
        var players: [Player] = []

        // Add first player (use default if not available)
        let firstPlayerName = !history.playerNames.isEmpty ? history.playerNames[0] : "Player 1"
        let firstPlayerId = PlayerId()
        let firstPosition = Position3D(x: 0, y: 0, z: 0)
        let firstScore = GameScore(paintedArea: Float(history.playerScore))

        let firstPlayer = Player(id: firstPlayerId, name: firstPlayerName, color: .red, position: firstPosition)
            .updateScore(firstScore)
        players.append(firstPlayer)

        // Add second player (use default if not available)
        let secondPlayerName = history.playerNames.count > 1 ? history.playerNames[1] : "Player 2"
        let secondPlayerId = PlayerId()
        let secondPosition = Position3D(x: 0, y: 0, z: 0)
        let secondScore = GameScore(paintedArea: Float(history.opponentScore))

        let secondPlayer = Player(id: secondPlayerId, name: secondPlayerName, color: .blue, position: secondPosition)
            .updateScore(secondScore)
        players.append(secondPlayer)

        let gameSession = GameSession(
            id: GameSessionId(gameSessionId),
            players: players,
            duration: history.duration
        )

        // Set the appropriate status
        if let status = GameSessionStatus(rawValue: history.gameStatus) {
            switch status {
            case .active:
                return gameSession.start()
            case .finished:
                return gameSession.start().end()
            default:
                return gameSession
            }
        }

        return gameSession
    }
}

// MARK: - GameStatistics

public struct GameStatistics {
    public let totalGames: Int
    public let completedGames: Int
    public let averageDuration: TimeInterval
    public let averagePlayerScore: Double
    public let averageOpponentScore: Double

    public init(
        totalGames: Int,
        completedGames: Int,
        averageDuration: TimeInterval,
        averagePlayerScore: Double,
        averageOpponentScore: Double
    ) {
        self.totalGames = totalGames
        self.completedGames = completedGames
        self.averageDuration = averageDuration
        self.averagePlayerScore = averagePlayerScore
        self.averageOpponentScore = averageOpponentScore
    }
}

// MARK: - SwiftDataError

public enum SwiftDataError: Error, LocalizedError {
    case invalidGameSessionId
    case playerNotFound
    case gameHistoryNotFound
    case persistenceError

    public var errorDescription: String? {
        switch self {
        case .invalidGameSessionId:
            return "Invalid game session ID"
        case .playerNotFound:
            return "Player not found"
        case .gameHistoryNotFound:
            return "Game history not found"
        case .persistenceError:
            return "Persistence error occurred"
        }
    }
}
