@testable import Domain
import Foundation
import simd
import Testing

struct PlayerTests {
    @Test("Player should be created with valid properties")
    func testPlayerCreation() {
        let playerId = PlayerId()
        let name = "TestPlayer"
        let color = PlayerColor.red
        let position = Position3D(x: 1.0, y: 2.0, z: 3.0)

        let player = Player(
            id: playerId,
            name: name,
            color: color,
            position: position
        )

        #expect(player.id == playerId)
        #expect(player.name == name)
        #expect(player.color == color)
        #expect(player.position == position)
        #expect(player.isActive == true) // Default state
        #expect(player.score.paintedArea == 0.0) // Default score
    }

    @Test("Player should update position correctly")
    func testPlayerPositionUpdate() {
        let player = Player(
            id: PlayerId(),
            name: "TestPlayer",
            color: .blue,
            position: Position3D(x: 0.0, y: 0.0, z: 0.0)
        )

        let newPosition = Position3D(x: 5.0, y: 10.0, z: 15.0)
        let updatedPlayer = player.updatePosition(newPosition)

        #expect(updatedPlayer.position == newPosition)
        #expect(updatedPlayer.id == player.id) // ID should remain same
        #expect(updatedPlayer.name == player.name) // Other properties unchanged
    }

    @Test("Player should deactivate and reactivate correctly")
    func testPlayerActivation() {
        let player = Player(
            id: PlayerId(),
            name: "TestPlayer",
            color: .green,
            position: Position3D(x: 0.0, y: 0.0, z: 0.0)
        )

        let deactivatedPlayer = player.deactivate()
        #expect(deactivatedPlayer.isActive == false)

        let reactivatedPlayer = deactivatedPlayer.activate()
        #expect(reactivatedPlayer.isActive == true)
    }

    @Test("Player should update score correctly")
    func testPlayerScoreUpdate() {
        let player = Player(
            id: PlayerId(),
            name: "TestPlayer",
            color: .red,
            position: Position3D(x: 0.0, y: 0.0, z: 0.0)
        )

        let newScore = GameScore(paintedArea: 45.0)
        let updatedPlayer = player.updateScore(newScore)

        #expect(updatedPlayer.score == newScore)
        #expect(updatedPlayer.id == player.id) // ID should remain same
    }

    @Test("Player should be equatable by ID")
    func testPlayerEquality() {
        let playerId = PlayerId()
        let player1 = Player(
            id: playerId,
            name: "Player1",
            color: .red,
            position: Position3D(x: 0.0, y: 0.0, z: 0.0)
        )
        let player2 = Player(
            id: playerId,
            name: "Player2", // Different name
            color: .blue, // Different color
            position: Position3D(x: 10.0, y: 10.0, z: 10.0) // Different position
        )
        let player3 = Player(
            id: PlayerId(), // Different ID
            name: "Player1",
            color: .red,
            position: Position3D(x: 0.0, y: 0.0, z: 0.0)
        )

        #expect(player1 == player2) // Same ID
        #expect(player1 != player3) // Different ID
    }

    @Test("Player should be codable")
    func testPlayerCodable() throws {
        let originalPlayer = Player(
            id: PlayerId(),
            name: "TestPlayer",
            color: .red,
            position: Position3D(x: 1.5, y: 2.5, z: 3.5)
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPlayer)

        let decoder = JSONDecoder()
        let decodedPlayer = try decoder.decode(Player.self, from: data)

        #expect(originalPlayer.id == decodedPlayer.id)
        #expect(originalPlayer.name == decodedPlayer.name)
        #expect(originalPlayer.color == decodedPlayer.color)
        #expect(originalPlayer.position == decodedPlayer.position)
        #expect(originalPlayer.isActive == decodedPlayer.isActive)
        #expect(originalPlayer.score == decodedPlayer.score)
    }

    @Test("Player should validate name")
    func testPlayerNameValidation() {
        let playerId = PlayerId()
        let position = Position3D(x: 0.0, y: 0.0, z: 0.0)

        // Valid names
        #expect(Player.isValidName("Player"))
        #expect(Player.isValidName("Player123"))
        #expect(Player.isValidName("プレイヤー"))

        // Invalid names
        #expect(!Player.isValidName(""))
        #expect(!Player.isValidName("   "))
        #expect(!Player.isValidName(String(repeating: "a", count: 51))) // Too long
    }
}
