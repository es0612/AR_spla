import Foundation

// MARK: - ScoreCalculationService

/// Domain service for calculating scores and game results
public struct ScoreCalculationService {
    // MARK: - Balance Parameters

    /// 勝利ボーナスの割合（デフォルト: 10%）
    public let winBonusPercentage: Float

    /// 時間ボーナスの最大割合（デフォルト: 5%）
    public let timeBonusMaxPercentage: Float

    /// 効率性ボーナスの重み（デフォルト: 0.2）
    public let efficiencyBonusWeight: Float

    /// 最小勝利マージン（デフォルト: 3%）
    public let minimumWinMargin: Float

    /// 同点時にインクスポット数で判定するか
    public let tieBreakByInkSpots: Bool

    /// Create a ScoreCalculationService with default balance parameters
    public init() {
        winBonusPercentage = 0.1
        timeBonusMaxPercentage = 0.05
        efficiencyBonusWeight = 0.2
        minimumWinMargin = 3.0
        tieBreakByInkSpots = true
    }

    /// Create a ScoreCalculationService with custom balance parameters
    public init(
        winBonusPercentage: Float = 0.1,
        timeBonusMaxPercentage: Float = 0.05,
        efficiencyBonusWeight: Float = 0.2,
        minimumWinMargin: Float = 3.0,
        tieBreakByInkSpots: Bool = true
    ) {
        self.winBonusPercentage = winBonusPercentage
        self.timeBonusMaxPercentage = timeBonusMaxPercentage
        self.efficiencyBonusWeight = efficiencyBonusWeight
        self.minimumWinMargin = minimumWinMargin
        self.tieBreakByInkSpots = tieBreakByInkSpots
    }

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

    /// Determine the winner from a list of players with enhanced tie-breaking
    public func determineWinner(players: [Player], inkSpots: [InkSpot] = []) -> Player? {
        guard !players.isEmpty else { return nil }

        // Sort players by score (highest first)
        let sortedPlayers = players.sorted { $0.score > $1.score }

        guard sortedPlayers.count >= 2 else {
            return sortedPlayers.first
        }

        let topPlayer = sortedPlayers[0]
        let secondPlayer = sortedPlayers[1]

        // Check if the score difference is significant enough
        let scoreDifference = topPlayer.score.paintedArea - secondPlayer.score.paintedArea

        if scoreDifference < minimumWinMargin {
            // Close game - use tie-breaking rules
            if tieBreakByInkSpots, !inkSpots.isEmpty {
                let topPlayerInkSpots = inkSpots.filter { $0.ownerId == topPlayer.id }.count
                let secondPlayerInkSpots = inkSpots.filter { $0.ownerId == secondPlayer.id }.count

                if topPlayerInkSpots != secondPlayerInkSpots {
                    // Winner determined by ink spot count
                    return topPlayerInkSpots > secondPlayerInkSpots ? topPlayer : secondPlayer
                }
            }

            // Still tied - no winner
            return nil
        }

        return topPlayer
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
            if index > 0, player.score != sortedPlayers[index - 1].score {
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
        !fieldSize.isNaN &&
            !fieldSize.isInfinite &&
            fieldSize > 0
    }

    /// Calculate win bonus for a winning score
    public func calculateWinBonus(_ baseScore: GameScore) -> GameScore {
        let bonusPercentage = baseScore.paintedArea * winBonusPercentage
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
        guard totalTime > 0, remainingTime > 0 else {
            return baseScore
        }

        let timeRatio = Float(remainingTime / totalTime)
        let bonusPercentage = baseScore.paintedArea * timeRatio * timeBonusMaxPercentage
        let newArea = min(100.0, baseScore.paintedArea + bonusPercentage)

        return GameScore(paintedArea: newArea)
    }

    /// Calculate efficiency bonus based on area coverage per ink spot
    public func calculateEfficiencyBonus(
        _ baseScore: GameScore,
        playerId: PlayerId,
        inkSpots: [InkSpot]
    ) -> GameScore {
        let efficiency = calculateAreaEfficiency(playerId: playerId, inkSpots: inkSpots)
        let bonusPercentage = baseScore.paintedArea * efficiency * efficiencyBonusWeight
        let newArea = min(100.0, baseScore.paintedArea + bonusPercentage)

        return GameScore(paintedArea: newArea)
    }

    /// Calculate comprehensive final score with all bonuses
    public func calculateFinalScore(
        baseScore: GameScore,
        playerId: PlayerId,
        inkSpots: [InkSpot],
        isWinner: Bool,
        remainingTime: TimeInterval,
        totalTime: TimeInterval
    ) -> GameScore {
        var finalScore = baseScore

        // Apply efficiency bonus
        finalScore = calculateEfficiencyBonus(finalScore, playerId: playerId, inkSpots: inkSpots)

        // Apply time bonus if there's remaining time
        if remainingTime > 0 {
            finalScore = calculateTimeBonus(finalScore, remainingTime: remainingTime, totalTime: totalTime)
        }

        // Apply win bonus if player is the winner
        if isWinner {
            finalScore = calculateWinBonus(finalScore)
        }

        return finalScore
    }
}

// MARK: CustomStringConvertible

extension ScoreCalculationService: CustomStringConvertible {
    public var description: String {
        "ScoreCalculationService"
    }
}
