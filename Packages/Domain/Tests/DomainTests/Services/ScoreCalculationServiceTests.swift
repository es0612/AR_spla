import Testing
import Foundation
@testable import Domain

struct ScoreCalculationServiceTests {
    
    @Test("ScoreCalculationService should calculate player score from ink spots")
    func testPlayerScoreCalculation() {
        let service = ScoreCalculationService()
        let playerId = PlayerId()
        let fieldSize = Float(100.0) // 100 square units
        
        let inkSpots = [
            createInkSpot(ownerId: playerId, size: 1.0), // π square units
            createInkSpot(ownerId: playerId, size: 2.0), // 4π square units
            createInkSpot(ownerId: PlayerId(), size: 1.0) // Different owner, should not count
        ]
        
        let score = service.calculatePlayerScore(
            playerId: playerId,
            inkSpots: inkSpots,
            fieldSize: fieldSize
        )
        
        let expectedArea = Float.pi * (1.0 + 4.0) // 5π
        let expectedPercentage = (expectedArea / fieldSize) * 100
        
        #expect(abs(score.paintedArea - expectedPercentage) < 0.1)
    }
    
    @Test("ScoreCalculationService should handle empty ink spots")
    func testEmptyInkSpots() {
        let service = ScoreCalculationService()
        let playerId = PlayerId()
        let fieldSize = Float(100.0)
        
        let score = service.calculatePlayerScore(
            playerId: playerId,
            inkSpots: [],
            fieldSize: fieldSize
        )
        
        #expect(score == GameScore.zero)
    }
    
    @Test("ScoreCalculationService should calculate total field coverage")
    func testTotalFieldCoverage() {
        let service = ScoreCalculationService()
        let fieldSize = Float(100.0)
        
        let inkSpots = [
            createInkSpot(ownerId: PlayerId(), size: 1.0), // π
            createInkSpot(ownerId: PlayerId(), size: 1.0), // π
            createInkSpot(ownerId: PlayerId(), size: 2.0)  // 4π
        ]
        
        let coverage = service.calculateTotalCoverage(
            inkSpots: inkSpots,
            fieldSize: fieldSize
        )
        
        let expectedCoverage = (Float.pi * 6.0 / fieldSize) * 100 // 6π / 100 * 100
        #expect(abs(coverage - expectedCoverage) < 0.1)
    }
    
    @Test("ScoreCalculationService should determine winner correctly")
    func testWinnerDetermination() {
        let service = ScoreCalculationService()
        
        let player1 = createTestPlayer(name: "Player1", color: .red)
            .updateScore(GameScore(paintedArea: 60.0))
        let player2 = createTestPlayer(name: "Player2", color: .blue)
            .updateScore(GameScore(paintedArea: 40.0))
        
        let winner = service.determineWinner(players: [player1, player2])
        #expect(winner?.id == player1.id)
        
        // Test tie
        let player3 = createTestPlayer(name: "Player3", color: .green)
            .updateScore(GameScore(paintedArea: 50.0))
        let player4 = createTestPlayer(name: "Player4", color: .yellow)
            .updateScore(GameScore(paintedArea: 50.0))
        
        let tieWinner = service.determineWinner(players: [player3, player4])
        #expect(tieWinner == nil)
    }
    
    @Test("ScoreCalculationService should calculate game results")
    func testGameResultsCalculation() {
        let service = ScoreCalculationService()
        let fieldSize = Float(100.0)
        
        let player1 = createTestPlayer(name: "Player1", color: .red)
        let player2 = createTestPlayer(name: "Player2", color: .blue)
        
        let inkSpots = [
            createInkSpot(ownerId: player1.id, size: 2.0), // 4π for player1
            createInkSpot(ownerId: player1.id, size: 1.0), // π for player1
            createInkSpot(ownerId: player2.id, size: 1.5)  // 2.25π for player2
        ]
        
        let results = service.calculateGameResults(
            players: [player1, player2],
            inkSpots: inkSpots,
            fieldSize: fieldSize
        )
        
        #expect(results.count == 2)
        
        let player1Result = results.first { $0.playerId == player1.id }
        let player2Result = results.first { $0.playerId == player2.id }
        
        #expect(player1Result != nil)
        #expect(player2Result != nil)
        
        // Player1 should have higher score (5π vs 2.25π)
        #expect(player1Result!.score > player2Result!.score)
    }
    
    @Test("ScoreCalculationService should handle overlapping ink spots correctly")
    func testOverlappingInkSpotsScoring() {
        let service = ScoreCalculationService()
        let playerId = PlayerId()
        let fieldSize = Float(100.0)
        
        // Two overlapping ink spots at same position
        let position = Position3D(x: 0.0, y: 0.0, z: 0.0)
        let inkSpots = [
            InkSpot(id: InkSpotId(), position: position, color: .red, size: 1.0, ownerId: playerId),
            InkSpot(id: InkSpotId(), position: position, color: .red, size: 1.0, ownerId: playerId)
        ]
        
        let score = service.calculatePlayerScore(
            playerId: playerId,
            inkSpots: inkSpots,
            fieldSize: fieldSize
        )
        
        // Note: Current implementation doesn't handle overlaps, so score will be additive
        // This is a known limitation that could be improved in the future
        let expectedScore = (Float.pi * 2.0 / fieldSize) * 100 // Two spots of radius 1.0
        #expect(abs(score.paintedArea - expectedScore) < 0.1)
    }
    
    @Test("ScoreCalculationService should validate field size")
    func testFieldSizeValidation() {
        let service = ScoreCalculationService()
        
        #expect(service.isValidFieldSize(100.0))
        #expect(service.isValidFieldSize(1.0))
        #expect(!service.isValidFieldSize(0.0))
        #expect(!service.isValidFieldSize(-10.0))
        #expect(!service.isValidFieldSize(Float.nan))
        #expect(!service.isValidFieldSize(Float.infinity))
    }
    
    @Test("ScoreCalculationService should calculate score bonus correctly")
    func testScoreBonus() {
        let service = ScoreCalculationService()
        
        // Test various bonus scenarios
        let baseScore = GameScore(paintedArea: 50.0)
        
        // Win bonus
        let winBonus = service.calculateWinBonus(baseScore)
        #expect(winBonus.paintedArea > baseScore.paintedArea)
        
        // Perfect game bonus (100% coverage)
        let perfectScore = GameScore(paintedArea: 100.0)
        let perfectBonus = service.calculatePerfectGameBonus(perfectScore)
        #expect(perfectBonus.paintedArea >= perfectScore.paintedArea)
        
        // Time bonus (finishing early)
        let timeBonus = service.calculateTimeBonus(baseScore, remainingTime: 60.0, totalTime: 180.0)
        #expect(timeBonus.paintedArea >= baseScore.paintedArea)
    }
    
    @Test("ScoreCalculationService should calculate area efficiency")
    func testAreaEfficiency() {
        let service = ScoreCalculationService()
        let playerId = PlayerId()
        
        let inkSpots = [
            createInkSpot(ownerId: playerId, size: 1.0),
            createInkSpot(ownerId: playerId, size: 2.0),
            createInkSpot(ownerId: playerId, size: 0.5)
        ]
        
        let efficiency = service.calculateAreaEfficiency(
            playerId: playerId,
            inkSpots: inkSpots
        )
        
        // Efficiency should be between 0 and 1
        #expect(efficiency >= 0.0)
        #expect(efficiency <= 1.0)
    }
    
    // MARK: - Helper Methods
    
    private func createTestPlayer(name: String, color: PlayerColor) -> Player {
        return Player(
            id: PlayerId(),
            name: name,
            color: color,
            position: Position3D(x: 0.0, y: 0.0, z: 0.0)
        )
    }
    
    private func createInkSpot(ownerId: PlayerId, size: Float) -> InkSpot {
        return InkSpot(
            id: InkSpotId(),
            position: Position3D(x: Float.random(in: -10...10), y: 0.0, z: Float.random(in: -10...10)),
            color: .red,
            size: size,
            ownerId: ownerId
        )
    }
}