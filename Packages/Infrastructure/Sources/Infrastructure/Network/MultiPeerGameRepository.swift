import Foundation
import MultipeerConnectivity
import Domain
import Application

/// Multipeer Connectivity implementation of GameRepository
public class MultiPeerGameRepository: NSObject, GameRepository {
    
    // MARK: - Properties
    
    private let serviceType = "ar-splatoon"
    private let peerID: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser
    
    private var gameSessions: [GameSessionId: GameSession] = [:]
    private var messageHandlers: [NetworkGameMessage.MessageType: (NetworkGameMessage) -> Void] = [:]
    
    // MARK: - State Properties
    
    public private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            // Notify observers if needed
        }
    }
    
    public private(set) var connectedPeers: [MCPeerID] = [] {
        didSet {
            // Notify observers if needed
        }
    }
    
    public private(set) var discoveredPeers: [MCPeerID] = [] {
        didSet {
            // Notify observers if needed
        }
    }
    
    // MARK: - Initialization
    
    public init(displayName: String) {
        self.peerID = MCPeerID(displayName: displayName)
        self.session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        self.advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        self.browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)
        
        super.init()
        
        setupSession()
        setupAdvertiser()
        setupBrowser()
        setupMessageHandlers()
    }
    
    deinit {
        stopAdvertising()
        stopBrowsing()
        session.disconnect()
    }
    
    // MARK: - Setup Methods
    
    private func setupSession() {
        session.delegate = self
    }
    
    private func setupAdvertiser() {
        advertiser.delegate = self
    }
    
    private func setupBrowser() {
        browser.delegate = self
    }
    
    private func setupMessageHandlers() {
        messageHandlers[.ping] = handlePingMessage
        messageHandlers[.pong] = handlePongMessage
        messageHandlers[.gameStart] = handleGameStartMessage
        messageHandlers[.gameEnd] = handleGameEndMessage
        messageHandlers[.playerPosition] = handlePlayerPositionMessage
        messageHandlers[.inkShot] = handleInkShotMessage
        messageHandlers[.playerHit] = handlePlayerHitMessage
        messageHandlers[.scoreUpdate] = handleScoreUpdateMessage
        messageHandlers[.gameState] = handleGameStateMessage
    }
    
    // MARK: - Public Methods
    
    /// Start advertising for nearby peers
    public func startAdvertising() {
        advertiser.startAdvertisingPeer()
        connectionState = .advertising
    }
    
    /// Stop advertising
    public func stopAdvertising() {
        advertiser.stopAdvertisingPeer()
        if connectionState == .advertising {
            connectionState = .disconnected
        }
    }
    
    /// Start browsing for nearby peers
    public func startBrowsing() {
        browser.startBrowsingForPeers()
        connectionState = .browsing
    }
    
    /// Stop browsing
    public func stopBrowsing() {
        browser.stopBrowsingForPeers()
        if connectionState == .browsing {
            connectionState = .disconnected
        }
    }
    
    /// Invite a peer to join the session
    public func invitePeer(_ peerID: MCPeerID, withContext context: Data? = nil, timeout: TimeInterval = 30) {
        browser.invitePeer(peerID, to: session, withContext: context, timeout: timeout)
    }
    
    /// Send a network message to all connected peers
    public func sendMessage(_ message: NetworkGameMessage) throws {
        guard !connectedPeers.isEmpty else {
            throw NetworkError.connectionFailed
        }
        
        let data = try JSONEncoder().encode(message)
        
        do {
            try session.send(data, toPeers: connectedPeers, with: .reliable)
        } catch {
            throw NetworkError.sendingFailed
        }
    }
    
    /// Send a network message to specific peers
    public func sendMessage(_ message: NetworkGameMessage, toPeers peers: [MCPeerID]) throws {
        guard !peers.isEmpty else {
            throw NetworkError.connectionFailed
        }
        
        let data = try JSONEncoder().encode(message)
        
        do {
            try session.send(data, toPeers: peers, with: .reliable)
        } catch {
            throw NetworkError.sendingFailed
        }
    }
    
    // MARK: - GameRepository Implementation
    
    public func save(_ gameSession: GameSession) async throws {
        gameSessions[gameSession.id] = gameSession
        
        // Broadcast game state to connected peers
        if !connectedPeers.isEmpty {
            let message = try NetworkGameMessageFactory.gameStart(
                gameSessionId: gameSession.id,
                duration: gameSession.duration,
                players: gameSession.players,
                senderId: peerID.displayName
            )
            try sendMessage(message)
        }
    }
    
    public func findById(_ id: GameSessionId) async throws -> GameSession? {
        return gameSessions[id]
    }
    
    public func findAll() async throws -> [GameSession] {
        return Array(gameSessions.values)
    }
    
    public func findActive() async throws -> [GameSession] {
        return gameSessions.values.filter { $0.status.isPlayable }
    }
    
    public func delete(_ id: GameSessionId) async throws {
        gameSessions.removeValue(forKey: id)
    }
    
    public func update(_ gameSession: GameSession) async throws {
        gameSessions[gameSession.id] = gameSession
        
        // Broadcast updated game state to connected peers
        if !connectedPeers.isEmpty {
            let networkInkSpots = gameSession.inkSpots.map { inkSpot in
                let rgbValues = inkSpot.color.rgbValues
                return NetworkInkSpot(
                    id: inkSpot.id.value.uuidString,
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
                    ),
                    playerId: inkSpot.ownerId.value.uuidString
                )
            }
            
            let networkPlayers = gameSession.players.map { player in
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
            
            let gameStateData = GameStateData(
                gameSessionId: gameSession.id.value.uuidString,
                status: gameSession.status.rawValue,
                remainingTime: gameSession.remainingTime,
                players: networkPlayers,
                inkSpots: networkInkSpots
            )
            
            let data = try JSONEncoder().encode(gameStateData)
            let message = NetworkGameMessage(type: .gameState, senderId: peerID.displayName, data: data)
            try sendMessage(message)
        }
    }
    
    // MARK: - Message Handlers
    
    private func handlePingMessage(_ message: NetworkGameMessage) {
        // Respond with pong
        let pongMessage = NetworkGameMessageFactory.pong(senderId: peerID.displayName)
        try? sendMessage(pongMessage)
    }
    
    private func handlePongMessage(_ message: NetworkGameMessage) {
        // Handle pong response (could be used for latency measurement)
        print("Received pong from \(message.senderId)")
    }
    
    private func handleGameStartMessage(_ message: NetworkGameMessage) {
        do {
            let gameStartData = try NetworkGameMessageParser.parseGameStart(from: message)
            // Handle game start logic
            print("Game started: \(gameStartData.gameSessionId)")
        } catch {
            print("Failed to parse game start message: \(error)")
        }
    }
    
    private func handleGameEndMessage(_ message: NetworkGameMessage) {
        // Handle game end logic
        print("Game ended from \(message.senderId)")
    }
    
    private func handlePlayerPositionMessage(_ message: NetworkGameMessage) {
        do {
            let positionData = try NetworkGameMessageParser.parsePlayerPosition(from: message)
            // Handle player position update
            print("Player \(positionData.playerId) moved to \(positionData.position)")
        } catch {
            print("Failed to parse player position message: \(error)")
        }
    }
    
    private func handleInkShotMessage(_ message: NetworkGameMessage) {
        do {
            let inkShotData = try NetworkGameMessageParser.parseInkShot(from: message)
            // Handle ink shot
            print("Ink shot from player \(inkShotData.playerId) at \(inkShotData.position)")
        } catch {
            print("Failed to parse ink shot message: \(error)")
        }
    }
    
    private func handlePlayerHitMessage(_ message: NetworkGameMessage) {
        // Handle player hit logic
        print("Player hit message from \(message.senderId)")
    }
    
    private func handleScoreUpdateMessage(_ message: NetworkGameMessage) {
        // Handle score update logic
        print("Score update from \(message.senderId)")
    }
    
    private func handleGameStateMessage(_ message: NetworkGameMessage) {
        do {
            let gameStateData = try JSONDecoder().decode(GameStateData.self, from: message.data)
            // Handle game state synchronization
            print("Game state update: \(gameStateData.gameSessionId)")
        } catch {
            print("Failed to parse game state message: \(error)")
        }
    }
}

// MARK: - Connection State

public enum ConnectionState: String, CaseIterable {
    case disconnected = "disconnected"
    case advertising = "advertising"
    case browsing = "browsing"
    case connecting = "connecting"
    case connected = "connected"
}

// MARK: - MCSessionDelegate

extension MultiPeerGameRepository: MCSessionDelegate {
    
    public func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if self.connectedPeers.isEmpty {
                    self.connectionState = .disconnected
                }
                
            case .connecting:
                self.connectionState = .connecting
                
            case .connected:
                if !self.connectedPeers.contains(peerID) {
                    self.connectedPeers.append(peerID)
                }
                self.connectionState = .connected
                
                // Send ping to newly connected peer
                let pingMessage = NetworkGameMessageFactory.ping(senderId: self.peerID.displayName)
                try? self.sendMessage(pingMessage, toPeers: [peerID])
                
            @unknown default:
                break
            }
        }
    }
    
    public func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        do {
            let message = try JSONDecoder().decode(NetworkGameMessage.self, from: data)
            
            // Handle message on main queue
            DispatchQueue.main.async {
                if let handler = self.messageHandlers[message.type] {
                    handler(message)
                }
            }
        } catch {
            print("Failed to decode received message: \(error)")
        }
    }
    
    public func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        // Not used in this implementation
    }
    
    public func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        // Not used in this implementation
    }
    
    public func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        // Not used in this implementation
    }
}

// MARK: - MCNearbyServiceAdvertiserDelegate

extension MultiPeerGameRepository: MCNearbyServiceAdvertiserDelegate {
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations for now (in production, this should be user-controlled)
        invitationHandler(true, session)
    }
    
    public func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error)")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
}

// MARK: - MCNearbyServiceBrowserDelegate

extension MultiPeerGameRepository: MCNearbyServiceBrowserDelegate {
    
    public func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }
    
    public func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error)")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
}