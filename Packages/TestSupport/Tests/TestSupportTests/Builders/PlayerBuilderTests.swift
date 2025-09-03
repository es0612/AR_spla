import Domain
import Foundation
import Testing
@testable import TestSupport

struct PlayerBuilderTests {
    @Test("PlayerBuilder creates player with default values")
    func testDefaultPlayerCreation() {
        let player = PlayerBuilder().build()

        #expect(player.name == "TestPlayer")
        #expect(player.color == .red)
        #expect(player.position == Position3D(x: 0, y: 0, z: 0))
        #expect(player.isActive == true)
        #expect(player.score == .zero)
    }

    @Test("PlayerBuilder creates player with custom values")
    func testCustomPlayerCreation() {
        let customId = PlayerId()
        let customPosition = Position3D(x: 1, y: 2, z: 3)
        let customScore = GameScore(paintedArea: 50.0)

        let player = PlayerBuilder()
            .withId(customId)
            .withName("Custom Player")
            .withColor(.blue)
            .withPosition(customPosition)
            .withActiveStatus(false)
            .withScore(customScore)
            .build()

        #expect(player.id == customId)
        #expect(player.name == "Custom Player")
        #expect(player.color == .blue)
        #expect(player.position == customPosition)
        #expect(player.isActive == false)
        #expect(player.score == customScore)
    }

    @Test("PlayerBuilder convenience methods work correctly")
    func testConvenienceMethods() {
        let redPlayer = PlayerBuilder.redPlayer().build()
        #expect(redPlayer.name == "Red Player")
        #expect(redPlayer.color == .red)

        let bluePlayer = PlayerBuilder.bluePlayer().build()
        #expect(bluePlayer.name == "Blue Player")
        #expect(bluePlayer.color == .blue)

        let inactivePlayer = PlayerBuilder.inactivePlayer().build()
        #expect(inactivePlayer.isActive == false)

        let highScorePlayer = PlayerBuilder.highScorePlayer().build()
        #expect(highScorePlayer.score.paintedArea == 75.0)
    }

    @Test("PlayerBuilder with position coordinates")
    func testPositionCoordinates() {
        let player = PlayerBuilder()
            .withPosition(x: 5.5, y: -2.3, z: 1.0)
            .build()

        #expect(player.position.x == 5.5)
        #expect(player.position.y == -2.3)
        #expect(player.position.z == 1.0)
    }

    @Test("PlayerBuilder with score painted area")
    func testScorePaintedArea() {
        let player = PlayerBuilder()
            .withScore(paintedArea: 85.5)
            .build()

        #expect(player.score.paintedArea == 85.5)
    }
}
