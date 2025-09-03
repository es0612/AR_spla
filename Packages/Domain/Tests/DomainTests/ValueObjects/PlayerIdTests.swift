@testable import Domain
import Foundation
import Testing

struct PlayerIdTests {
    @Test("PlayerId should be created with valid UUID")
    func testPlayerIdCreation() {
        let uuid = UUID()
        let playerId = PlayerId(uuid)

        #expect(playerId.value == uuid)
    }

    @Test("PlayerId should generate unique identifiers")
    func testPlayerIdUniqueness() {
        let playerId1 = PlayerId()
        let playerId2 = PlayerId()

        #expect(playerId1.value != playerId2.value)
    }

    @Test("PlayerId should be equatable")
    func testPlayerIdEquality() {
        let uuid = UUID()
        let playerId1 = PlayerId(uuid)
        let playerId2 = PlayerId(uuid)
        let playerId3 = PlayerId()

        #expect(playerId1 == playerId2)
        #expect(playerId1 != playerId3)
    }

    @Test("PlayerId should be hashable")
    func testPlayerIdHashable() {
        let uuid = UUID()
        let playerId1 = PlayerId(uuid)
        let playerId2 = PlayerId(uuid)

        let set: Set<PlayerId> = [playerId1, playerId2]
        #expect(set.count == 1)
    }

    @Test("PlayerId should be codable")
    func testPlayerIdCodable() throws {
        let originalPlayerId = PlayerId()

        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPlayerId)

        let decoder = JSONDecoder()
        let decodedPlayerId = try decoder.decode(PlayerId.self, from: data)

        #expect(originalPlayerId == decodedPlayerId)
    }
}
