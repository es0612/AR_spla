import Foundation
import MultipeerConnectivity
import Domain

/// Network message protocol for game communication
public struct NetworkGameMessage: Codable {
    public let id: UUID
    public let type: MessageType
    public let senderId: String
    public let timestamp: Date
    public let data: Data
    
    public init(type: MessageType, senderId: String, data: Data) {
        self.id = UUID()
        self.type = type
        self.senderId = senderId
        self.timestamp = Date()
        self.data = data
    }
    
    /// Message types for different game events
    public enum MessageType: String, Codable, CaseIterable {
        case gameStart = "game_start"
        case gameEnd = "game_end"
        case playerPosition = "player_position"
        case inkShot = "ink_shot"
        case playerHit = "player_hit"
        case scoreUpdate = "score_update"
        case gameState = "game_state"
        case ping = "ping"
        case pong = "pong"
    }
}

// MARK: - Message Data Structures

/// Data structure for game start message
public struct GameStartData: Codable {
    public let gameSessionId: String
    public let duration: TimeInterval
    public let players: [NetworkPlayer]
    
    public init(gameSessionId: String, duration: TimeInterval, players: [NetworkPlayer]) {
        self.gameSessionId = gameSessionId
        self.duration = duration
        self.players = players
    }
}

/// Data structure for player position message
public struct PlayerPositionData: Codable {
    public let playerId: String
    public let position: NetworkPosition3D
    public let isActive: Bool
    
    public init(playerId: String, position: NetworkPosition3D, isActive: Bool) {
        self.playerId = playerId
        self.position = position
        self.isActive = isActive
    }
}

/// Data structure for ink shot message
public struct InkShotData: Codable {
    public let inkSpotId: String
    public let playerId: String
    public let position: NetworkPosition3D
    public let color: NetworkPlayerColor
    
    public init(inkSpotId: String, playerId: String, position: NetworkPosition3D, color: NetworkPlayerColor) {
        self.inkSpotId = inkSpotId
        self.playerId = playerId
        self.position = position
        self.color = color
    }
}

/// Data structure for player hit message
public struct PlayerHitData: Codable {
    public let playerId: String
    public let hitByPlayerId: String
    
    public init(playerId: String, hitByPlayerId: String) {
        self.playerId = playerId
        self.hitByPlayerId = hitByPlayerId
    }
}

/// Data structure for score update message
public struct ScoreUpdateData: Codable {
    public let playerId: String
    public let score: Double
    
    public init(playerId: String, score: Double) {
        self.playerId = playerId
        self.score = score
    }
}

/// Data structure for game state message
public struct GameStateData: Codable {
    public let gameSessionId: String
    public let status: String
    public let remainingTime: TimeInterval
    public let players: [NetworkPlayer]
    public let inkSpots: [NetworkInkSpot]
    
    public init(gameSessionId: String, status: String, remainingTime: TimeInterval, players: [NetworkPlayer], inkSpots: [NetworkInkSpot]) {
        self.gameSessionId = gameSessionId
        self.status = status
        self.remainingTime = remainingTime
        self.players = players
        self.inkSpots = inkSpots
    }
}

// MARK: - Network Data Transfer Objects

/// Network representation of Player entity
public struct NetworkPlayer: Codable {
    public let id: String
    public let name: String
    public let color: NetworkPlayerColor
    public let position: NetworkPosition3D
    public let isActive: Bool
    public let score: Double
    
    public init(id: String, name: String, color: NetworkPlayerColor, position: NetworkPosition3D, isActive: Bool, score: Double) {
        self.id = id
        self.name = name
        self.color = color
        self.position = position
        self.isActive = isActive
        self.score = score
    }
}

/// Network representation of Position3D value object
public struct NetworkPosition3D: Codable {
    public let x: Float
    public let y: Float
    public let z: Float
    
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
}

/// Network representation of PlayerColor value object
public struct NetworkPlayerColor: Codable {
    public let red: Double
    public let green: Double
    public let blue: Double
    public let alpha: Double
    
    public init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

/// Network representation of InkSpot entity
public struct NetworkInkSpot: Codable {
    public let id: String
    public let position: NetworkPosition3D
    public let color: NetworkPlayerColor
    public let playerId: String
    
    public init(id: String, position: NetworkPosition3D, color: NetworkPlayerColor, playerId: String) {
        self.id = id
        self.position = position
        self.color = color
        self.playerId = playerId
    }
}

// MARK: - Message Factory

public struct NetworkGameMessageFactory {
    
    /// Create a game start message
    public static func gameStart(gameSessionId: GameSessionId, duration: TimeInterval, players: [Player], senderId: String) throws -> NetworkGameMessage {
        let networkPlayers = players.map { player in
            let rgbValues = player.color.rgbValues
            return NetworkPlayer(
                id: player.id.value.uuidString,
                name: player.name,
                color: NetworkPlayerColor(
                    red: Double(rgbValues.red),
                    green: Double(rgbValues.green),
                    blue: Double(rgbValues.blue),
                    alpha: 1.0
                ),
                position: NetworkPosition3D(
                    x: player.position.x,
                    y: player.position.y,
                    z: player.position.z
                ),
                isActive: player.isActive,
                score: Double(player.score.paintedArea)
            )
        }
        
        let gameStartData = GameStartData(
            gameSessionId: gameSessionId.value.uuidString,
            duration: duration,
            players: networkPlayers
        )
        
        let data = try JSONEncoder().encode(gameStartData)
        return NetworkGameMessage(type: .gameStart, senderId: senderId, data: data)
    }
    
    /// Create a player position message
    public static func playerPosition(player: Player, senderId: String) throws -> NetworkGameMessage {
        let positionData = PlayerPositionData(
            playerId: player.id.value.uuidString,
            position: NetworkPosition3D(
                x: player.position.x,
                y: player.position.y,
                z: player.position.z
            ),
            isActive: player.isActive
        )
        
        let data = try JSONEncoder().encode(positionData)
        return NetworkGameMessage(type: .playerPosition, senderId: senderId, data: data)
    }
    
    /// Create an ink shot message
    public static func inkShot(inkSpot: InkSpot, senderId: String) throws -> NetworkGameMessage {
        let rgbValues = inkSpot.color.rgbValues
        let inkShotData = InkShotData(
            inkSpotId: inkSpot.id.value.uuidString,
            playerId: inkSpot.ownerId.value.uuidString,
            position: NetworkPosition3D(
                x: inkSpot.position.x,
                y: inkSpot.position.y,
                z: inkSpot.position.z
            ),
            color: NetworkPlayerColor(
                red: Double(rgbValues.red),
                green: Double(rgbValues.green),
                blue: Double(rgbValues.blue),
                alpha: 1.0
            )
        )
        
        let data = try JSONEncoder().encode(inkShotData)
        return NetworkGameMessage(type: .inkShot, senderId: senderId, data: data)
    }
    
    /// Create a ping message
    public static func ping(senderId: String) -> NetworkGameMessage {
        return NetworkGameMessage(type: .ping, senderId: senderId, data: Data())
    }
    
    /// Create a pong message
    public static func pong(senderId: String) -> NetworkGameMessage {
        return NetworkGameMessage(type: .pong, senderId: senderId, data: Data())
    }
}

// MARK: - Message Parser

public struct NetworkGameMessageParser {
    
    /// Parse game start data from message
    public static func parseGameStart(from message: NetworkGameMessage) throws -> GameStartData {
        guard message.type == .gameStart else {
            throw NetworkError.invalidMessageType
        }
        return try JSONDecoder().decode(GameStartData.self, from: message.data)
    }
    
    /// Parse player position data from message
    public static func parsePlayerPosition(from message: NetworkGameMessage) throws -> PlayerPositionData {
        guard message.type == .playerPosition else {
            throw NetworkError.invalidMessageType
        }
        return try JSONDecoder().decode(PlayerPositionData.self, from: message.data)
    }
    
    /// Parse ink shot data from message
    public static func parseInkShot(from message: NetworkGameMessage) throws -> InkShotData {
        guard message.type == .inkShot else {
            throw NetworkError.invalidMessageType
        }
        return try JSONDecoder().decode(InkShotData.self, from: message.data)
    }
}

// MARK: - Network Errors

public enum NetworkError: Error, LocalizedError {
    case invalidMessageType
    case encodingFailed
    case decodingFailed
    case connectionFailed
    case peerDisconnected
    case sendingFailed
    case sessionNotFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidMessageType:
            return "Invalid message type"
        case .encodingFailed:
            return "Failed to encode message"
        case .decodingFailed:
            return "Failed to decode message"
        case .connectionFailed:
            return "Connection failed"
        case .peerDisconnected:
            return "Peer disconnected"
        case .sendingFailed:
            return "Failed to send message"
        case .sessionNotFound:
            return "Session not found"
        }
    }
}