import Testing
import Foundation
@testable import Infrastructure
@testable import Domain
import TestSupport

struct NetworkGameMessageTests {
    
    // MARK: - Message Creation Tests
    
    @Test("NetworkGameMessage should be created with correct properties")
    func testMessageCreation() {
        let messageType = NetworkGameMessage.MessageType.ping
        let senderId = "test-sender"
        let data = Data("test".utf8)
        
        let message = NetworkGameMessage(type: messageType, senderId: senderId, data: data)
        
        #expect(message.type == messageType)
        #expect(message.senderId == senderId)
        #expect(message.data == data)
        #expect(message.timestamp <= Date())
    }
    
    @Test("NetworkGameMessage should be codable")
    func testMessageCodable() throws {
        let originalMessage = NetworkGameMessage(
            type: .gameStart,
            senderId: "test-sender",
            data: Data("test-data".utf8)
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(originalMessage)
        let decodedMessage = try decoder.decode(NetworkGameMessage.self, from: encodedData)
        
        #expect(decodedMessage.id == originalMessage.id)
        #expect(decodedMessage.type == originalMessage.type)
        #expect(decodedMessage.senderId == originalMessage.senderId)
        #expect(decodedMessage.data == originalMessage.data)
        #expect(decodedMessage.timestamp == originalMessage.timestamp)
    }
    
    // MARK: - Message Factory Tests
    
    @Test("NetworkGameMessageFactory should create game start message")
    func testGameStartMessageFactory() throws {
        let gameSessionId = GameSessionId()
        let duration: TimeInterval = 180
        let players = [
            PlayerBuilder().withName("Player1").build(),
            PlayerBuilder().withName("Player2").build()
        ]
        let senderId = "test-sender"
        
        let message = try NetworkGameMessageFactory.gameStart(
            gameSessionId: gameSessionId,
            duration: duration,
            players: players,
            senderId: senderId
        )
        
        #expect(message.type == .gameStart)
        #expect(message.senderId == senderId)
        
        let gameStartData = try NetworkGameMessageParser.parseGameStart(from: message)
        #expect(gameStartData.gameSessionId == gameSessionId.value.uuidString)
        #expect(gameStartData.duration == duration)
        #expect(gameStartData.players.count == 2)
    }
    
    @Test("NetworkGameMessageFactory should create player position message")
    func testPlayerPositionMessageFactory() throws {
        let player = PlayerBuilder()
            .withName("TestPlayer")
            .withPosition(Position3D(x: 1.0, y: 2.0, z: 3.0))
            .build()
        let senderId = "test-sender"
        
        let message = try NetworkGameMessageFactory.playerPosition(
            player: player,
            senderId: senderId
        )
        
        #expect(message.type == .playerPosition)
        #expect(message.senderId == senderId)
        
        let positionData = try NetworkGameMessageParser.parsePlayerPosition(from: message)
        #expect(positionData.playerId == player.id.value.uuidString)
        #expect(positionData.position.x == 1.0)
        #expect(positionData.position.y == 2.0)
        #expect(positionData.position.z == 3.0)
        #expect(positionData.isActive == player.isActive)
    }
    
    @Test("NetworkGameMessageFactory should create ink shot message")
    func testInkShotMessageFactory() throws {
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 5.0, y: 0.0, z: 10.0),
            color: PlayerColor.red,
            size: 1.0,
            ownerId: PlayerId()
        )
        let senderId = "test-sender"
        
        let message = try NetworkGameMessageFactory.inkShot(
            inkSpot: inkSpot,
            senderId: senderId
        )
        
        #expect(message.type == .inkShot)
        #expect(message.senderId == senderId)
        
        let inkShotData = try NetworkGameMessageParser.parseInkShot(from: message)
        #expect(inkShotData.inkSpotId == inkSpot.id.value.uuidString)
        #expect(inkShotData.playerId == inkSpot.ownerId.value.uuidString)
        #expect(inkShotData.position.x == 5.0)
        #expect(inkShotData.position.y == 0.0)
        #expect(inkShotData.position.z == 10.0)
    }
    
    @Test("NetworkGameMessageFactory should create ping message")
    func testPingMessageFactory() {
        let senderId = "test-sender"
        
        let message = NetworkGameMessageFactory.ping(senderId: senderId)
        
        #expect(message.type == .ping)
        #expect(message.senderId == senderId)
        #expect(message.data.isEmpty)
    }
    
    @Test("NetworkGameMessageFactory should create pong message")
    func testPongMessageFactory() {
        let senderId = "test-sender"
        
        let message = NetworkGameMessageFactory.pong(senderId: senderId)
        
        #expect(message.type == .pong)
        #expect(message.senderId == senderId)
        #expect(message.data.isEmpty)
    }
    
    // MARK: - Message Parser Tests
    
    @Test("NetworkGameMessageParser should parse game start message")
    func testParseGameStartMessage() throws {
        let gameSessionId = GameSessionId()
        let duration: TimeInterval = 300
        let players = [PlayerBuilder().withName("Player1").build()]
        let senderId = "test-sender"
        
        let message = try NetworkGameMessageFactory.gameStart(
            gameSessionId: gameSessionId,
            duration: duration,
            players: players,
            senderId: senderId
        )
        
        let parsedData = try NetworkGameMessageParser.parseGameStart(from: message)
        
        #expect(parsedData.gameSessionId == gameSessionId.value.uuidString)
        #expect(parsedData.duration == duration)
        #expect(parsedData.players.count == 1)
        #expect(parsedData.players[0].name == "Player1")
    }
    
    @Test("NetworkGameMessageParser should throw error for invalid message type")
    func testParseInvalidMessageType() {
        let message = NetworkGameMessage(type: .ping, senderId: "test", data: Data())
        
        #expect(throws: NetworkError.invalidMessageType) {
            try NetworkGameMessageParser.parseGameStart(from: message)
        }
    }
    
    // MARK: - Network Data Transfer Object Tests
    
    @Test("NetworkPlayer should be codable")
    func testNetworkPlayerCodable() throws {
        let networkPlayer = NetworkPlayer(
            id: "test-id",
            name: "TestPlayer",
            color: NetworkPlayerColor(red: 1.0, green: 0.0, blue: 0.0),
            position: NetworkPosition3D(x: 1.0, y: 2.0, z: 3.0),
            isActive: true,
            score: 100.0
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(networkPlayer)
        let decodedPlayer = try decoder.decode(NetworkPlayer.self, from: encodedData)
        
        #expect(decodedPlayer.id == networkPlayer.id)
        #expect(decodedPlayer.name == networkPlayer.name)
        #expect(decodedPlayer.color.red == networkPlayer.color.red)
        #expect(decodedPlayer.position.x == networkPlayer.position.x)
        #expect(decodedPlayer.isActive == networkPlayer.isActive)
        #expect(decodedPlayer.score == networkPlayer.score)
    }
    
    @Test("NetworkPosition3D should be codable")
    func testNetworkPosition3DCodable() throws {
        let position = NetworkPosition3D(x: 10.5, y: -5.2, z: 0.0)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(position)
        let decodedPosition = try decoder.decode(NetworkPosition3D.self, from: encodedData)
        
        #expect(decodedPosition.x == position.x)
        #expect(decodedPosition.y == position.y)
        #expect(decodedPosition.z == position.z)
    }
    
    @Test("NetworkPlayerColor should be codable")
    func testNetworkPlayerColorCodable() throws {
        let color = NetworkPlayerColor(red: 0.5, green: 0.8, blue: 0.2, alpha: 0.9)
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(color)
        let decodedColor = try decoder.decode(NetworkPlayerColor.self, from: encodedData)
        
        #expect(decodedColor.red == color.red)
        #expect(decodedColor.green == color.green)
        #expect(decodedColor.blue == color.blue)
        #expect(decodedColor.alpha == color.alpha)
    }
    
    @Test("NetworkInkSpot should be codable")
    func testNetworkInkSpotCodable() throws {
        let inkSpot = NetworkInkSpot(
            id: "test-ink-id",
            position: NetworkPosition3D(x: 1.0, y: 2.0, z: 3.0),
            color: NetworkPlayerColor(red: 1.0, green: 0.0, blue: 0.0),
            playerId: "test-player-id"
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(inkSpot)
        let decodedInkSpot = try decoder.decode(NetworkInkSpot.self, from: encodedData)
        
        #expect(decodedInkSpot.id == inkSpot.id)
        #expect(decodedInkSpot.position.x == inkSpot.position.x)
        #expect(decodedInkSpot.color.red == inkSpot.color.red)
        #expect(decodedInkSpot.playerId == inkSpot.playerId)
    }
    
    // MARK: - Error Tests
    
    @Test("NetworkError should have correct descriptions")
    func testNetworkErrorDescriptions() {
        let errors: [(NetworkError, String)] = [
            (.invalidMessageType, "Invalid message type"),
            (.encodingFailed, "Failed to encode message"),
            (.decodingFailed, "Failed to decode message"),
            (.connectionFailed, "Connection failed"),
            (.peerDisconnected, "Peer disconnected"),
            (.sendingFailed, "Failed to send message"),
            (.sessionNotFound, "Session not found")
        ]
        
        for (error, expectedDescription) in errors {
            #expect(error.errorDescription == expectedDescription)
        }
    }
}