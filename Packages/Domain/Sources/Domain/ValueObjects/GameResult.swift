import Foundation

/// Value Object representing a player's game result
public struct GameResult: Equatable, Codable {
    public let playerId: PlayerId
    public let playerName: String
    public let score: GameScore
    public let rank: Int
    public let totalInkSpots: Int
    public let areaEfficiency: Float
    
    /// Create a game result
    public init(
        playerId: PlayerId,
        playerName: String,
        score: GameScore,
        rank: Int,
        totalInkSpots: Int,
        areaEfficiency: Float
    ) {
        self.playerId = playerId
        self.playerName = playerName
        self.score = score
        self.rank = rank
        self.totalInkSpots = totalInkSpots
        self.areaEfficiency = areaEfficiency
    }
    
    /// Whether this result represents a winning position
    public var isWinner: Bool {
        return rank == 1
    }
    
    /// Whether this result represents a perfect game (100% coverage)
    public var isPerfectGame: Bool {
        return score.paintedArea >= 100.0
    }
}

// MARK: - Comparable
extension GameResult: Comparable {
    public static func < (lhs: GameResult, rhs: GameResult) -> Bool {
        // Lower rank is better (1st place < 2nd place)
        return lhs.rank < rhs.rank
    }
}

// MARK: - CustomStringConvertible
extension GameResult: CustomStringConvertible {
    public var description: String {
        return "GameResult(player: \(playerName), score: \(score.paintedArea)%, rank: \(rank))"
    }
}