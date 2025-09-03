import Domain
import Foundation

// MARK: - SimpleGameHistory

/// Simple data model for game history (not SwiftData dependent)
public class SimpleGameHistory {
    public var id: String
    public var date: Date
    public var duration: TimeInterval
    public var winner: String?
    public var playerScore: Double
    public var opponentScore: Double
    public var playerNames: [String]
    public var gameStatus: String

    public init(
        id: String = UUID().uuidString,
        date: Date = Date(),
        duration: TimeInterval,
        winner: String? = nil,
        playerScore: Double,
        opponentScore: Double,
        playerNames: [String],
        gameStatus: String
    ) {
        self.id = id
        self.date = date
        self.duration = duration
        self.winner = winner
        self.playerScore = playerScore
        self.opponentScore = opponentScore
        self.playerNames = playerNames
        self.gameStatus = gameStatus
    }
}

// MARK: - SimplePlayerProfile

/// Simple data model for player profile (not SwiftData dependent)
public class SimplePlayerProfile {
    public var name: String
    public var totalGames: Int
    public var wins: Int
    public var losses: Int
    public var totalPaintedArea: Double
    public var averageScore: Double
    public var lastPlayedDate: Date?
    public var preferredColor: String

    public init(
        name: String,
        totalGames: Int = 0,
        wins: Int = 0,
        losses: Int = 0,
        totalPaintedArea: Double = 0.0,
        averageScore: Double = 0.0,
        lastPlayedDate: Date? = nil,
        preferredColor: String = "red"
    ) {
        self.name = name
        self.totalGames = totalGames
        self.wins = wins
        self.losses = losses
        self.totalPaintedArea = totalPaintedArea
        self.averageScore = averageScore
        self.lastPlayedDate = lastPlayedDate
        self.preferredColor = preferredColor
    }

    /// Calculate win rate as percentage
    public var winRate: Double {
        guard totalGames > 0 else { return 0.0 }
        return (Double(wins) / Double(totalGames)) * 100.0
    }

    /// Update statistics after a game
    public func updateAfterGame(score: Double, won: Bool) {
        totalGames += 1
        totalPaintedArea += score
        averageScore = totalPaintedArea / Double(totalGames)
        lastPlayedDate = Date()

        if won {
            wins += 1
        } else {
            losses += 1
        }
    }
}

// MARK: - Domain Model Conversion Extensions

public extension SimpleGameHistory {
    /// Create SimpleGameHistory from Domain GameSession
    convenience init(from gameSession: GameSession) {
        let playerScores = gameSession.players.map(\.score.paintedArea)
        let playerNames = gameSession.players.map(\.name)

        let playerScore = playerScores.first ?? 0.0
        let opponentScore = playerScores.count > 1 ? playerScores[1] : 0.0

        let winner = gameSession.winner?.name

        self.init(
            id: gameSession.id.value.uuidString,
            date: gameSession.startedAt ?? Date(),
            duration: gameSession.duration,
            winner: winner,
            playerScore: Double(playerScore),
            opponentScore: Double(opponentScore),
            playerNames: playerNames,
            gameStatus: gameSession.status.rawValue
        )
    }
}

public extension SimplePlayerProfile {
    /// Create SimplePlayerProfile from Domain Player
    convenience init(from player: Player) {
        self.init(
            name: player.name,
            preferredColor: player.color.rawValue
        )
    }

    /// Update profile from Domain Player
    func update(from player: Player, gameResult: SimpleGameResult) {
        let score = Double(player.score.paintedArea)
        let won = gameResult == .won

        updateAfterGame(score: score, won: won)
        preferredColor = player.color.rawValue
    }
}

/// Game result enumeration for simple profile updates
public enum SimpleGameResult {
    case won
    case lost
    case tie
}
