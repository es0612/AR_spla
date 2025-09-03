@testable import Domain
import Foundation
import Testing

struct GameScoreTests {
    @Test("GameScore should be created with valid painted area")
    func testGameScoreCreation() {
        let score = GameScore(paintedArea: 50.0)

        #expect(score.paintedArea == 50.0)
        #expect(score.percentage == 50.0)
    }

    @Test("GameScore should validate painted area range", arguments: [
        (0.0, true),
        (50.0, true),
        (100.0, true),
        (-1.0, false),
        (101.0, false)
    ])
    func testGameScoreValidation(paintedArea: Float, isValid: Bool) {
        if isValid {
            let score = try! GameScore.create(paintedArea: paintedArea)
            #expect(score.paintedArea == paintedArea)
        } else {
            #expect(throws: GameScoreError.invalidPaintedArea) {
                _ = try GameScore.create(paintedArea: paintedArea)
            }
        }
    }

    @Test("GameScore should calculate percentage correctly")
    func testGameScorePercentage() {
        let score1 = GameScore(paintedArea: 25.0)
        let score2 = GameScore(paintedArea: 75.0)
        let score3 = GameScore(paintedArea: 0.0)
        let score4 = GameScore(paintedArea: 100.0)

        #expect(score1.percentage == 25.0)
        #expect(score2.percentage == 75.0)
        #expect(score3.percentage == 0.0)
        #expect(score4.percentage == 100.0)
    }

    @Test("GameScore should be comparable")
    func testGameScoreComparable() {
        let score1 = GameScore(paintedArea: 30.0)
        let score2 = GameScore(paintedArea: 70.0)
        let score3 = GameScore(paintedArea: 30.0)

        #expect(score1 < score2)
        #expect(score2 > score1)
        #expect(score1 == score3)
        #expect(score1 <= score3)
        #expect(score2 >= score1)
    }

    @Test("GameScore should determine winner correctly")
    func testGameScoreWinner() {
        let score1 = GameScore(paintedArea: 40.0)
        let score2 = GameScore(paintedArea: 60.0)
        let score3 = GameScore(paintedArea: 50.0)
        let score4 = GameScore(paintedArea: 50.0)

        #expect(GameScore.determineWinner(score1, score2) == .second)
        #expect(GameScore.determineWinner(score2, score1) == .first)
        #expect(GameScore.determineWinner(score3, score4) == .tie)
    }

    @Test("GameScore should add painted area correctly")
    func testGameScoreAddition() {
        let score = GameScore(paintedArea: 30.0)
        let newScore = score.adding(paintedArea: 20.0)

        #expect(newScore.paintedArea == 50.0)
    }

    @Test("GameScore should not exceed maximum when adding")
    func testGameScoreAdditionLimit() {
        let score = GameScore(paintedArea: 90.0)
        let newScore = score.adding(paintedArea: 20.0)

        #expect(newScore.paintedArea == 100.0) // Capped at maximum
    }

    @Test("GameScore should be codable")
    func testGameScoreCodable() throws {
        let originalScore = GameScore(paintedArea: 65.5)

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalScore)

        let decoder = JSONDecoder()
        let decodedScore = try decoder.decode(GameScore.self, from: data)

        #expect(originalScore == decodedScore)
    }

    @Test("GameScore should handle zero painted area")
    func testGameScoreZero() {
        let score = GameScore.zero

        #expect(score.paintedArea == 0.0)
        #expect(score.percentage == 0.0)
    }

    @Test("GameScore should handle maximum painted area")
    func testGameScoreMaximum() {
        let score = GameScore.maximum

        #expect(score.paintedArea == 100.0)
        #expect(score.percentage == 100.0)
    }
}
