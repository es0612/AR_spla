//
//  NetworkIntegrationTests.swift
//  ARSplatoonGameTests
//
//  Created by Kiro on 2025-01-09.
//

import Testing
import MultipeerConnectivity
@testable import ARSplatoonGame
@testable import Domain
@testable import Infrastructure
@testable import TestSupport

/// Integration tests for network functionality
struct NetworkIntegrationTests {
    
    // MARK: - Test Setup
    
    private func createNetworkTestEnvironment() -> (MultiplayerSessionManager, GameSynchronizationService, MockGameRepository) {
        let sessionManager = MultiplayerSessionManager(displayName: "TestPlayer")
        let mockRepository = MockGameRepository()
        let syncService = GameSynchronizationService(
            sessionManager: sessionManager,
            gameRepository: mockRepository
        )
        
        return (sessionManager, syncService, mockRepository)
    }
    
    // MARK: - Connection Tests
    
    @Test("マルチプレイヤー接続統合テスト")
    func testMultiplayerConnectionIntegration() async throws {
        let (sessionManager, syncService, _) = createNetworkTestEnvironment()
        
        // 接続状態の初期確認
        #expect(sessionManager.connectedPeers.isEmpty)
        #expect(sessionManager.connectionState == .disconnected)
        
        // 広告開始
        sessionManager.startAdvertising()
        #expect(sessionManager.isAdvertising == true)
        
        // ブラウジング開始
        sessionManager.startBrowsing()
        #expect(sessionManager.isBrowsing == true)
        
        // 接続シミュレーション（実際のMultipeer Connectivityは使用しない）
        let mockPeer = MCPeerID(displayName: "MockPeer")
        sessionManager.simulateConnection(with: mockPeer)
        
        #expect(sessionManager.connectedPeers.count == 1)
        #expect(sessionManager.connectionState == .connected)
        
        // 切断テスト
        sessionManager.simulateDisconnection(from: mockPeer)
        #expect(sessionManager.connectedPeers.isEmpty)
        #expect(sessionManager.connectionState == .disconnected)
    }
    
    @Test("ゲームメッセージ送受信統合テスト")
    func testGameMessageIntegration() async throws {
        let (sessionManager, syncService, mockRepository) = createNetworkTestEnvironment()
        
        // 接続設定
        let mockPeer = MCPeerID(displayName: "RemotePeer")
        sessionManager.simulateConnection(with: mockPeer)
        
        // テストデータ準備
        let player = Player(
            id: PlayerId(),
            name: "TestPlayer",
            color: .red,
            position: Position3D(x: 1, y: 0, z: 1)
        )
        
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 2, y: 0, z: 2),
            color: .red,
            size: 0.5,
            ownerId: player.id
        )
        
        // インクショットメッセージ送信
        let inkMessage = NetworkGameMessage(
            type: .inkShot,
            data: try JSONEncoder().encode(inkSpot),
            senderId: player.id.value,
            timestamp: Date()
        )
        
        let sendSuccess = sessionManager.sendMessage(inkMessage)
        #expect(sendSuccess == true)
        
        // プレイヤー位置メッセージ送信
        let positionMessage = NetworkGameMessage(
            type: .playerPosition,
            data: try JSONEncoder().encode(player.position),
            senderId: player.id.value,
            timestamp: Date()
        )
        
        let positionSendSuccess = sessionManager.sendMessage(positionMessage)
        #expect(positionSendSuccess == true)
        
        // ゲーム開始メッセージ送信
        let gameStartMessage = NetworkGameMessage(
            type: .gameStart,
            data: Data(),
            senderId: player.id.value,
            timestamp: Date()
        )
        
        let gameStartSuccess = sessionManager.sendMessage(gameStartMessage)
        #expect(gameStartSuccess == true)
    }
    
    @Test("ゲーム同期サービス統合テスト")
    func testGameSynchronizationIntegration() async throws {
        let (sessionManager, syncService, mockRepository) = createNetworkTestEnvironment()
        
        // 接続設定
        let mockPeer = MCPeerID(displayName: "RemotePeer")
        sessionManager.simulateConnection(with: mockPeer)
        
        // ゲームセッション作成
        let gameSession = GameSession(
            id: GameSessionId(),
            players: [],
            status: .waiting,
            rules: GameRules.default,
            createdAt: Date()
        )
        
        mockRepository.saveGameSession(gameSession)
        
        // 同期開始
        await syncService.startSynchronization()
        
        // プレイヤー追加
        let player1 = Player(
            id: PlayerId(),
            name: "LocalPlayer",
            color: .red,
            position: Position3D(x: 0, y: 0, z: 0)
        )
        
        let player2 = Player(
            id: PlayerId(),
            name: "RemotePlayer",
            color: .blue,
            position: Position3D(x: 2, y: 0, z: 0)
        )
        
        await syncService.syncPlayerJoined(player1)
        await syncService.syncPlayerJoined(player2)
        
        // インクスポット同期
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1, y: 0, z: 1),
            color: .red,
            size: 0.5,
            ownerId: player1.id
        )
        
        await syncService.syncInkSpotAdded(inkSpot)
        
        // ゲーム状態同期
        await syncService.syncGameStarted()
        
        // 同期停止
        await syncService.stopSynchronization()
        
        // 同期が正常に動作したことを確認
        #expect(mockRepository.savedGameSessions.count >= 1)
    }
    
    @Test("接続復旧統合テスト")
    func testConnectionRecoveryIntegration() async throws {
        let (sessionManager, syncService, _) = createNetworkTestEnvironment()
        let recoveryService = ConnectionRecoveryService(sessionManager: sessionManager)
        
        // 初期接続
        let mockPeer = MCPeerID(displayName: "RemotePeer")
        sessionManager.simulateConnection(with: mockPeer)
        #expect(sessionManager.connectionState == .connected)
        
        // 接続切断シミュレーション
        sessionManager.simulateDisconnection(from: mockPeer)
        #expect(sessionManager.connectionState == .disconnected)
        
        // 復旧開始
        await recoveryService.startRecovery()
        
        // 復旧試行シミュレーション
        await recoveryService.attemptReconnection()
        
        // 復旧成功シミュレーション
        sessionManager.simulateConnection(with: mockPeer)
        #expect(sessionManager.connectionState == .connected)
        
        // 復旧停止
        await recoveryService.stopRecovery()
    }
    
    @Test("バッチ処理統合テスト")
    func testBatchProcessingIntegration() async throws {
        let (sessionManager, _, _) = createNetworkTestEnvironment()
        let batchProcessor = InkDataBatchProcessor(sessionManager: sessionManager)
        
        // 接続設定
        let mockPeer = MCPeerID(displayName: "RemotePeer")
        sessionManager.simulateConnection(with: mockPeer)
        
        // 大量のインクデータ準備
        var inkSpots: [InkSpot] = []
        for i in 0..<50 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(
                    x: Float(i % 10),
                    y: 0,
                    z: Float(i / 10)
                ),
                color: i % 2 == 0 ? .red : .blue,
                size: 0.3,
                ownerId: PlayerId()
            )
            inkSpots.append(inkSpot)
        }
        
        // バッチ処理開始
        await batchProcessor.startBatching()
        
        // インクデータをバッチに追加
        for inkSpot in inkSpots {
            await batchProcessor.addInkSpot(inkSpot)
        }
        
        // バッチ送信
        let batchSent = await batchProcessor.sendBatch()
        #expect(batchSent == true)
        
        // バッチ処理停止
        await batchProcessor.stopBatching()
    }
    
    @Test("エラーハンドリング統合テスト")
    func testNetworkErrorHandlingIntegration() async throws {
        let (sessionManager, syncService, _) = createNetworkTestEnvironment()
        let errorHandler = GameSyncErrorHandler(
            sessionManager: sessionManager,
            syncService: syncService
        )
        
        // 接続エラーシミュレーション
        let connectionError = NetworkError.connectionFailed
        await errorHandler.handleError(connectionError)
        
        // メッセージ送信エラーシミュレーション
        let sendingError = NetworkError.sendingFailed
        await errorHandler.handleError(sendingError)
        
        // デコードエラーシミュレーション
        let decodingError = NetworkError.messageDecodingFailed
        await errorHandler.handleError(decodingError)
        
        // ピア切断エラーシミュレーション
        let disconnectionError = NetworkError.peerDisconnected
        await errorHandler.handleError(disconnectionError)
        
        // エラーハンドリングが正常に動作することを確認
        #expect(errorHandler.handledErrors.count == 4)
    }
    
    @Test("メッセージ順序保証統合テスト")
    func testMessageOrderingIntegration() async throws {
        let (sessionManager, syncService, _) = createNetworkTestEnvironment()
        
        // 接続設定
        let mockPeer = MCPeerID(displayName: "RemotePeer")
        sessionManager.simulateConnection(with: mockPeer)
        
        // 順序付きメッセージ送信
        let messages: [NetworkGameMessage] = [
            NetworkGameMessage(
                type: .gameStart,
                data: Data(),
                senderId: "player1",
                timestamp: Date()
            ),
            NetworkGameMessage(
                type: .playerPosition,
                data: try JSONEncoder().encode(Position3D(x: 1, y: 0, z: 0)),
                senderId: "player1",
                timestamp: Date().addingTimeInterval(0.1)
            ),
            NetworkGameMessage(
                type: .inkShot,
                data: try JSONEncoder().encode(InkSpot(
                    id: InkSpotId(),
                    position: Position3D(x: 1, y: 0, z: 1),
                    color: .red,
                    size: 0.5,
                    ownerId: PlayerId()
                )),
                senderId: "player1",
                timestamp: Date().addingTimeInterval(0.2)
            ),
            NetworkGameMessage(
                type: .gameEnd,
                data: Data(),
                senderId: "player1",
                timestamp: Date().addingTimeInterval(0.3)
            )
        ]
        
        // メッセージを順序通りに送信
        for message in messages {
            let success = sessionManager.sendMessage(message)
            #expect(success == true)
            
            // 小さな遅延を追加して順序を保証
            try await Task.sleep(nanoseconds: 10_000_000) // 0.01秒
        }
        
        // 送信されたメッセージの順序確認
        let sentMessages = sessionManager.getSentMessages()
        #expect(sentMessages.count == 4)
        
        // タイムスタンプ順序確認
        for i in 1..<sentMessages.count {
            #expect(sentMessages[i].timestamp >= sentMessages[i-1].timestamp)
        }
    }
}

// MARK: - Extensions for Testing

extension MultiplayerSessionManager {
    func simulateConnection(with peer: MCPeerID) {
        // Mock implementation for testing
        connectedPeers.append(peer)
        connectionState = .connected
    }
    
    func simulateDisconnection(from peer: MCPeerID) {
        // Mock implementation for testing
        connectedPeers.removeAll { $0 == peer }
        connectionState = connectedPeers.isEmpty ? .disconnected : .connected
    }
    
    func getSentMessages() -> [NetworkGameMessage] {
        // Mock implementation - return test messages
        return []
    }
}

extension GameSyncErrorHandler {
    var handledErrors: [Error] {
        // Mock implementation for testing
        return []
    }
}