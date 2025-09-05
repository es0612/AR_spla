import Application
import Domain
import Foundation
import MultipeerConnectivity

// MARK: - MultiPeerGameRepository

/// Multipeer Connectivity implementation of GameRepository
public class MultiPeerGameRepository: NSObject, GameRepository {
    // MARK: - Properties

    private let serviceType = "ar-splatoon"
    public let peerID: MCPeerID
    private let session: MCSession
    private let advertiser: MCNearbyServiceAdvertiser
    private let browser: MCNearbyServiceBrowser

    private var gameSessions: [GameSessionId: GameSession] = [:]
    private var messageHandlers: [NetworkGameMessage.MessageType: (NetworkGameMessage) -> Void] = [:]

    // MARK: - Synchronization Services

    public private(set) var synchronizationService: GameSynchronizationService?
    public private(set) var connectionRecoveryService: ConnectionRecoveryService?
    public private(set) var inkBatchProcessor: InkDataBatchProcessor?
    public private(set) var sessionManager: MultiplayerSessionManager?
    public private(set) var errorHandler: GameSyncErrorHandler?

    // MARK: - State Properties

    public private(set) var connectionState: ConnectionState = .disconnected {
        didSet {
            // Notify connection state changes
            NotificationCenter.default.post(name: .connectionStateChanged, object: nil)
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
        peerID = MCPeerID(displayName: displayName)
        session = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        advertiser = MCNearbyServiceAdvertiser(peer: peerID, discoveryInfo: nil, serviceType: serviceType)
        browser = MCNearbyServiceBrowser(peer: peerID, serviceType: serviceType)

        super.init()

        setupSession()
        setupAdvertiser()
        setupBrowser()
        setupMessageHandlers()
        setupSynchronizationServices()
    }

    deinit {
        stopAdvertising()
        stopBrowsing()
        session.disconnect()
        synchronizationService?.stopSynchronization()
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
        messageHandlers[.inkBatch] = handleInkBatchMessage
    }

    private func setupSynchronizationServices() {
        synchronizationService = GameSynchronizationService(gameRepository: self)
        connectionRecoveryService = ConnectionRecoveryService(gameRepository: self)

        inkBatchProcessor = InkDataBatchProcessor()
        inkBatchProcessor?.onBatchReady = { [weak self] inkSpots in
            self?.sendInkBatch(inkSpots)
        }

        // Setup session manager and error handler
        if let syncService = synchronizationService,
           let recoveryService = connectionRecoveryService {
            sessionManager = MultiplayerSessionManager(
                gameRepository: self,
                synchronizationService: syncService,
                recoveryService: recoveryService
            )

            errorHandler = GameSyncErrorHandler(
                recoveryService: recoveryService
            )
        }
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

    /// Send ink batch efficiently
    private func sendInkBatch(_ inkSpots: [InkSpot]) {
        guard !connectedPeers.isEmpty else { return }

        do {
            let compressedData = try InkDataBatchProcessor.compressInkSpots(inkSpots)
            let message = NetworkGameMessage(type: .inkBatch, senderId: peerID.displayName, data: compressedData)
            try sendMessage(message)
        } catch {
            print("Failed to send ink batch: \(error)")
        }
    }

    /// Queue ink spot for batch processing
    public func queueInkSpot(_ inkSpot: InkSpot) {
        inkBatchProcessor?.addInkSpot(inkSpot)
    }

    /// Queue player update for synchronization
    public func queuePlayerUpdate(_ player: Player) {
        synchronizationService?.queuePlayerUpdate(player)
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
        gameSessions[id]
    }

    public func findAll() async throws -> [GameSession] {
        Array(gameSessions.values)
    }

    public func findActive() async throws -> [GameSession] {
        gameSessions.values.filter(\.status.isPlayable)
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

    private func handlePingMessage(_: NetworkGameMessage) {
        // Respond with pong
        let pongMessage = NetworkGameMessageFactory.pong(senderId: peerID.displayName)
        try? sendMessage(pongMessage)
    }

    private func handlePongMessage(_ message: NetworkGameMessage) {
        // Handle pong response for latency measurement
        synchronizationService?.handlePongReceived()
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

    private func handleInkBatchMessage(_ message: NetworkGameMessage) {
        do {
            let networkInkSpots = try InkDataBatchProcessor.decompressInkSpots(from: message.data)
            // Handle batch of ink spots
            print("Received ink batch with \(networkInkSpots.count) spots from \(message.senderId)")

            // Convert network ink spots to domain entities and update game state
            // This would typically be handled by a use case
        } catch {
            print("Failed to parse ink batch message: \(error)")
        }
    }
}

// MARK: - ConnectionState

public enum ConnectionState: String, CaseIterable {
    case disconnected
    case advertising
    case browsing
    case connecting
    case connected
}

// MARK: - MultiPeerGameRepository + MCSessionDelegate

extension MultiPeerGameRepository: MCSessionDelegate {
    public func session(_: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        DispatchQueue.main.async {
            switch state {
            case .notConnected:
                self.connectedPeers.removeAll { $0 == peerID }
                if self.connectedPeers.isEmpty {
                    self.connectionState = .disconnected
                }

                // Notify peer disconnection
                NotificationCenter.default.post(
                    name: .peerDisconnected,
                    object: nil,
                    userInfo: ["peerID": peerID]
                )

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

    public func session(_: MCSession, didReceive data: Data, fromPeer _: MCPeerID) {
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

    public func session(_: MCSession, didReceive _: InputStream, withName _: String, fromPeer _: MCPeerID) {
        // Not used in this implementation
    }

    public func session(_: MCSession, didStartReceivingResourceWithName _: String, fromPeer _: MCPeerID, with _: Progress) {
        // Not used in this implementation
    }

    public func session(_: MCSession, didFinishReceivingResourceWithName _: String, fromPeer _: MCPeerID, at _: URL?, withError _: Error?) {
        // Not used in this implementation
    }
}

// MARK: - MultiPeerGameRepository + MCNearbyServiceAdvertiserDelegate

extension MultiPeerGameRepository: MCNearbyServiceAdvertiserDelegate {
    public func advertiser(_: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer _: MCPeerID, withContext _: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
        // Auto-accept invitations for now (in production, this should be user-controlled)
        invitationHandler(true, session)
    }

    public func advertiser(_: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
        print("Failed to start advertising: \(error)")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
}

// MARK: - MultiPeerGameRepository + MCNearbyServiceBrowserDelegate

extension MultiPeerGameRepository: MCNearbyServiceBrowserDelegate {
    public func browser(_: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo _: [String: String]?) {
        DispatchQueue.main.async {
            if !self.discoveredPeers.contains(peerID) {
                self.discoveredPeers.append(peerID)
            }
        }
    }

    public func browser(_: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
        DispatchQueue.main.async {
            self.discoveredPeers.removeAll { $0 == peerID }
        }
    }

    public func browser(_: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
        print("Failed to start browsing: \(error)")
        DispatchQueue.main.async {
            self.connectionState = .disconnected
        }
    }
}
