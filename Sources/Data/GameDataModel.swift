import SwiftData
import Foundation

@Model
class GameHistory {
    var id: UUID
    var date: Date
    var duration: TimeInterval
    var winner: String
    var playerScore: Float
    var opponentScore: Float
    
    init(id: UUID = UUID(), date: Date = Date(), duration: TimeInterval, winner: String, playerScore: Float, opponentScore: Float) {
        self.id = id
        self.date = date
        self.duration = duration
        self.winner = winner
        self.playerScore = playerScore
        self.opponentScore = opponentScore
    }
}

@Model
class PlayerProfile {
    var name: String
    var totalGames: Int
    var wins: Int
    var totalPaintedArea: Float
    var createdAt: Date
    
    init(name: String, totalGames: Int = 0, wins: Int = 0, totalPaintedArea: Float = 0) {
        self.name = name
        self.totalGames = totalGames
        self.wins = wins
        self.totalPaintedArea = totalPaintedArea
        self.createdAt = Date()
    }
    
    var winRate: Double {
        guard totalGames > 0 else { return 0.0 }
        return Double(wins) / Double(totalGames)
    }
}