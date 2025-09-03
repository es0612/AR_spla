import Domain
import Foundation
import Testing
@testable import TestSupport

struct TestDataTests {
    @Test("TestData provides consistent player data")
    func testPlayerData() {
        #expect(TestData.redPlayer.color == .red)
        #expect(TestData.redPlayer.name == "Red Player")
        #expect(TestData.bluePlayer.color == .blue)
        #expect(TestData.bluePlayer.name == "Blue Player")
        #expect(TestData.inactivePlayer.isActive == false)
        #expect(TestData.highScorePlayer.score.paintedArea == 85.0)
    }

    @Test("TestData provides consistent game session data")
    func testGameSessionData() {
        #expect(TestData.waitingGameSession.status == .waiting)
        #expect(TestData.activeGameSession.status == .active)
        #expect(TestData.finishedGameSession.status == .finished)
        #expect(TestData.shortGameSession.duration == 60)
        #expect(TestData.longGameSession.duration == 600)
    }

    @Test("TestData provides ink spot data")
    func testInkSpotData() {
        #expect(TestData.redInkSpotAtOrigin.color == .red)
        #expect(TestData.blueInkSpotNearOrigin.color == .blue)
        #expect(TestData.largeRedInkSpot.size == 1.2)
        #expect(TestData.smallBlueInkSpot.size == 0.2)
    }

    @Test("TestData scenario methods work")
    func testScenarios() {
        let competitive = TestData.competitiveGameScenario()
        #expect(competitive.status == .finished)

        let oneSided = TestData.oneSidedGameScenario()
        #expect(oneSided.status == .finished)

        let tie = TestData.tieGameScenario()
        #expect(tie.status == .finished)
        #expect(tie.winner == nil) // Should be a tie
    }
}
