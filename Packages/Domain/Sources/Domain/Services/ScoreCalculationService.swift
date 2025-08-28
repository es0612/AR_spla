import Foundation

/// Domain service for calculating scores and game results
public struct ScoreCalculationService {
    
    /// Create a ScoreCalculationService
    public init() {}
    
    /// Calculate a player's score based on their ink spots
    public func calculatePlayerScore(
        playerId: PlayerId,
        inkSpots: [InkSpot],
        fieldSize: Float
    ) -> GameScore {
        guard fieldSize > 0 else {
            return GameScore.zero
        }
        
        // Filter ink spots owned by the player
        let playerInkSpots = inkSpots.filter { $0.ownerId == playerId }
        
        // Calculate total area covered by player's ink spots
        let totalArea = playerInkSpots.reduce(0) { sum, inkSpot in
            sum + inkSpot.area
        }
        
        // Convert to percentage
        let percentage = min(100.0, (totalArea / fieldSize) * 100)
        
        return GameScore(paintedArea: percentage)
    }
    
    /// Calculate total field coverage by all ink spots
    public func calculateTotalCoverage(inkSpots: [InkSpot], fieldSize: Float) -> Float {
        guard fieldSize > 0 else { return 0 }
        
        // Simple approach: sum all areas (ignoring overlaps)
        let totalArea = inkSpots.reduce(0) { sum, inkSpot in
            sum + inkSpot.area
        }
        
        return min(100.0, (totalArea / fieldSize) * 100)
    }
    
    /// Determine the winner from a list of players
    public func determineWinner(players: [Player]) -> Player? {
        guard !players.isEmpty else { return nil }
        
        // Sort players by score (highest first)
        let sortedPlayers = players.sorted { $0.score > $1.score }
        
        // Check for tie between top players
        if sortedPlayers.count >= 2 && sortedPlayers[0].score == sortedPlayers[1].score {
            return nil // Tie
        }
        
        return sortedPlayers.first
    }
    
    /// Calculate game results for all players
    public func calculateGameResults(
        players: [Player],
        inkSpots: [InkSpot],
        fieldSize: Float
    ) -> [GameResult] {
        // Calculate updated scores for all players
        let playersWithScores = players.map { player in
            let score = calculatePlayerScore(
                playerId: player.id,
                inkSpots: inkSpots,
                fieldSize: fieldSize
            )
            return player.updateScore(score)
        }
        
        // Sort by score (highest first)
        let sortedPlayers = playersWithScores.sorted { $0.score > $1.score }
        
        // Create game results with rankings
        var results: [GameResult] = []
        var currentRank = 1
        
        for (index, player) in sortedPlayers.enumerated() {
            // Handle ties - players with same score get same rank
            if index > 0 && player.score != sortedPlayers[index - 1].score {
                currentRank = index + 1
            }
            
            let playerInkSpots = inkSpots.filter { $0.ownerId == player.id }
            let efficiency = calculateAreaEfficiency(playerId: player.id, inkSpots: inkSpots)
            
            let result = GameResult(
                playerId: player.id,
                playerName: player.name,
                score: player.score,
                rank: currentRank,
                totalInkSpots: playerInkSpots.count,
                areaEfficiency: efficiency
            )
            
            results.append(result)
        }
        
        return results
    }
    
    /// Calculate area efficiency for a player (coverage per ink spot)
    public func calculateAreaEfficiency(playerId: PlayerId, inkSpots: [InkSpot]) -> Float {
        let playerInkSpots = inkSpots.filter { $0.ownerId == playerId }
        
        guard !playerInkSpots.isEmpty else { return 0.0 }
        
        let totalArea = playerInkSpots.reduce(0) { sum, inkSpot in
            sum + inkSpot.area
        }
        
        let averageArea = totalArea / Float(playerInkSpots.count)
        let maxPossibleArea = Float.pi * (InkSpot.maxSize * InkSpot.maxSize)
        
        return min(1.0, averageArea / maxPossibleArea)
    }
    
    /// Validate field size
    public func isValidFieldSize(_ fieldSize: Float) -> Bool {
        return !fieldSize.isNaN && 
               !fieldSize.isInfinite && 
               fieldSize > 0
    }
    
    /// Calculate win bonus for a winning score
    public func calculateWinBonus(_ baseScore: GameScore) -> GameScore {
        let bonusPercentage = baseScore.paintedArea * 0.1 // 10% bonus
        let newArea = min(100.0, baseScore.paintedArea + bonusPercentage)
        return GameScore(paintedArea: newArea)
    }
    
    /// Calculate perfect game bonus (100% coverage)
    public func calculatePerfectGameBonus(_ baseScore: GameScore) -> GameScore {
        if baseScore.paintedArea >= 100.0 {
            return baseScore // Already perfect, no additional bonus needed
        }
        return baseScore
    }
    
    /// Calculate time bonus for finishing early
    public func calculateTimeBonus(
        _ baseScore: GameScore,
        remainingTime: TimeInterval,
        totalTime: TimeInterval
    ) -> GameScore {
        guard totalTime > 0 && remainingTime > 0 else {
            return baseScore
        }
        
        let timeRatio = Float(remainingTime / totalTime)
        let bonusPercentage = baseScore.paintedArea * timeRatio * 0.05 // Up to 5% bonus
        let newArea = min(100.0, baseScore.paintedArea + bonusPercentage)
        
        return GameScore(paintedArea: newArea)
    }
}

// MARK: - CustomStringConvertible
extension ScoreCalculationService: CustomStringConvertible {
    public var description: String {
        return "ScoreCalculationService"
    }
}