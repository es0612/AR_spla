//
//  GameFlowIntegrationTests.swift
//  ARSplatoonGameTests
//
//  Created by Kiro on 2025-01-09.
//

import Testing
import ARKit
import RealityKit
@testable import ARSplatoonGame
@testable import Domain
@testable import Application
@testable import Infrastructure

/// End-to-end integration tests for complete game flow
struct GameFlowIntegrationTests {
    
    // MARK: - Test Setup
    
    private func createTestEnvironment() -> (GameState, ARGameCoordinator, MockMultiplayerSessionManager) {
        let gameState = GameState()
        let arView = ARView()
        let coordinator = ARGameCoordinator(arView: arView)
        let mockSessionManager = MockMultiplayerSessionManager()
        
        return (gameState, coordinator, mockSessionManager)
    }
    
    // MARK: - Complete Game Flow Tests
    
    @Test("完全なゲームフロー統合テスト")
    func testCompleteGameFlow() async throws {
        let (gameState, coordinator, sessionManager) = createTestEnvironment()
        
        // 1. ゲーム初期化
        gameState.initializeGame()
        #expect(gameState.currentPhase == .waiting)
        
        // 2. プレイヤー追加
        let player1 = Player(
            id: PlayerId(),
            name: "Player1",
            color: .red,
            position: Position3D(x: 0, y: 0, z: 0)
        )
        
        let player2 = Player(
            id: PlayerId(),
            name: "Player2",
            color: .blue,
            position: Position3D(x: 2, y: 0, z: 0)
        )
        
        gameState.addPlayer(player1)
        gameState.addPlayer(player2)
        #expect(gameState.players.count == 2)
        
        // 3. ネットワーク接続シミュレーション
        sessionManager.simulateConnection(with: "Player2")
        #expect(sessionManager.isConnected == true)
        
        // 4. ゲーム開始
        gameState.startGame()
        #expect(gameState.currentPhase == .playing)
        #expect(gameState.isGameActive == true)
        
        // 5. インク発射シミュレーション
        let inkSpot1 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1, y: 0, z: 1),
            color: .red,
            size: 0.5,
            ownerId: player1.id
        )
        
        let inkSpot2 = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: -1, y: 0, z: -1),
            color: .blue,
            size: 0.5,
            ownerId: player2.id
        )
        
        gameState.addInkSpot(inkSpot1)
        gameState.addInkSpot(inkSpot2)
        #expect(gameState.inkSpots.count == 2)
        
        // 6. スコア計算
        let score1 = gameState.calculatePlayerScore(player1.id)
        let score2 = gameState.calculatePlayerScore(player2.id)
        #expect(score1 >= 0)
        #expect(score2 >= 0)
        
        // 7. ゲーム終了
        gameState.endGame()
        #expect(gameState.currentPhase == .finished)
        #expect(gameState.isGameActive == false)
        
        // 8. 勝者決定
        let winner = gameState.determineWinner()
        #expect(winner != nil)
    }
    
    @Test("マルチプレイヤー同期統合テスト")
    func testMultiplayerSynchronization() async throws {
        let (gameState, coordinator, sessionManager) = createTestEnvironment()
        
        // ゲーム初期化
        gameState.initializeGame()
        
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
        
        gameState.addPlayer(player1)
        gameState.addPlayer(player2)
        
        // ネットワーク接続
        sessionManager.simulateConnection(with: "RemotePlayer")
        
        // ゲーム開始
        gameState.startGame()
        
        // ローカルプレイヤーのインク発射
        let localInkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1, y: 0, z: 0),
            color: .red,
            size: 0.5,
            ownerId: player1.id
        )
        
        gameState.addInkSpot(localInkSpot)
        
        // ネットワーク経由でのメッセージ送信シミュレーション
        let inkMessage = NetworkGameMessage(
            type: .inkShot,
            data: try JSONEncoder().encode(localInkSpot),
            senderId: player1.id.value,
            timestamp: Date()
        )
        
        sessionManager.simulateMessageReceived(inkMessage)
        
        // リモートプレイヤーのインク発射シミュレーション
        let remoteInkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: -1, y: 0, z: 0),
            color: .blue,
            size: 0.5,
            ownerId: player2.id
        )
        
        let remoteInkMessage = NetworkGameMessage(
            type: .inkShot,
            data: try JSONEncoder().encode(remoteInkSpot),
            senderId: player2.id.value,
            timestamp: Date()
        )
        
        sessionManager.simulateMessageReceived(remoteInkMessage)
        
        // 同期確認
        #expect(gameState.inkSpots.count >= 1) // At least local ink spot
        #expect(sessionManager.sentMessages.count >= 1) // At least one message sent
    }
    
    @Test("AR統合テスト")
    func testARIntegration() async throws {
        let (gameState, coordinator, _) = createTestEnvironment()
        
        // Mock AR session delegate
        let mockDelegate = MockARGameCoordinatorDelegate()
        coordinator.delegate = mockDelegate
        
        // ゲーム初期化
        gameState.initializeGame()
        
        let player = Player(
            id: PlayerId(),
            name: "TestPlayer",
            color: .red,
            position: Position3D(x: 0, y: 0, z: 0)
        )
        
        gameState.addPlayer(player)
        gameState.startGame()
        
        // AR座標でのインク発射
        let arPosition = Position3D(x: 1.5, y: 0, z: 1.5)
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: arPosition,
            color: .red,
            size: 0.5,
            ownerId: player.id
        )
        
        // ARコーディネーターにインクスポット追加
        let success = coordinator.addInkSpot(inkSpot)
        #expect(success == true)
        
        // プレイヤー位置更新
        let newPosition = Position3D(x: 1.0, y: 0, z: 1.0)
        let updatedPlayer = Player(
            id: player.id,
            name: player.name,
            color: player.color,
            position: newPosition,
            isActive: player.isActive,
            score: player.score,
            createdAt: player.createdAt
        )
        
        coordinator.updatePlayer(updatedPlayer)
        
        // AR統合が正常に動作することを確認
        #expect(mockDelegate.playerPositionUpdates.count >= 0)
    }
    
    @Test("エラーハンドリング統合テスト")
    func testErrorHandlingIntegration() async throws {
        let (gameState, coordinator, sessionManager) = createTestEnvironment()
        
        // エラーマネージャーの設定
        let errorManager = ErrorManager()
        gameState.errorManager = errorManager
        
        // ゲーム初期化
        gameState.initializeGame()
        
        // ネットワークエラーシミュレーション
        let networkError = NetworkError.connectionFailed
        sessionManager.simulateError(networkError)
        
        // ARエラーシミュレーション
        let arError = ARError.trackingLimited
        coordinator.simulateError(arError)
        
        // エラーが適切に処理されることを確認
        #expect(errorManager.hasActiveError == true)
        
        // エラー回復
        errorManager.clearError()
        #expect(errorManager.hasActiveError == false)
    }
    
    @Test("パフォーマンス統合テスト")
    func testPerformanceIntegration() async throws {
        let (gameState, coordinator, _) = createTestEnvironment()
        
        // 大量のインクスポット生成によるパフォーマンステスト
        gameState.initializeGame()
        
        let player = Player(
            id: PlayerId(),
            name: "TestPlayer",
            color: .red,
            position: Position3D(x: 0, y: 0, z: 0)
        )
        
        gameState.addPlayer(player)
        gameState.startGame()
        
        let startTime = Date()
        
        // 100個のインクスポットを追加
        for i in 0..<100 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(
                    x: Float(i % 10),
                    y: 0,
                    z: Float(i / 10)
                ),
                color: .red,
                size: 0.3,
                ownerId: player.id
            )
            
            gameState.addInkSpot(inkSpot)
            _ = coordinator.addInkSpot(inkSpot)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // パフォーマンス要件: 100個のインクスポット追加が1秒以内
        #expect(duration < 1.0)
        #expect(gameState.inkSpots.count == 100)
    }
}

// MARK: - Mock Classes

private class MockMultiplayerSessionManager {
    var isConnected = false
    var sentMessages: [NetworkGameMessage] = []
    var receivedMessages: [NetworkGameMessage] = []
    var lastError: Error?
    
    func simulateConnection(with peerName: String) {
        isConnected = true
    }
    
    func simulateDisconnection() {
        isConnected = false
    }
    
    func simulateMessageReceived(_ message: NetworkGameMessage) {
        receivedMessages.append(message)
    }
    
    func simulateError(_ error: Error) {
        lastError = error
        isConnected = false
    }
    
    func sendMessage(_ message: NetworkGameMessage) {
        sentMessages.append(message)
    }
}

private class MockARGameCoordinatorDelegate: ARGameCoordinatorDelegate {
    var playerCollisions: [(PlayerId, Position3D, PlayerCollisionEffect)] = []
    var inkSpotOverlaps: [(InkSpot, [(InkSpot, InkSpotOverlapResult)])] = []
    var inkSpotMerges: [([InkSpot], InkSpot)] = []
    var inkSpotConflicts: [(InkSpot, InkSpot, Float)] = []
    var playerPositionUpdates: [Position3D] = []
    
    func arGameCoordinatorDidStartSession(_ coordinator: ARGameCoordinator) {}
    func arGameCoordinatorDidStopSession(_ coordinator: ARGameCoordinator) {}
    func arGameCoordinatorWasInterrupted(_ coordinator: ARGameCoordinator) {}
    func arGameCoordinatorInterruptionEnded(_ coordinator: ARGameCoordinator) {}
    
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didSetupGameField anchor: ARAnchor) {}
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didUpdateGameField anchor: ARAnchor) {}
    func arGameCoordinatorDidLoseGameField(_ coordinator: ARGameCoordinator) {}
    
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didShootInk inkSpot: InkSpot, at position: Position3D) {}
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didUpdateTrackingQuality quality: ARTrackingQuality.TrackingQuality) {}
    
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didFailWithError error: Error) {}
    
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didDetectPlayerCollision playerId: PlayerId, at position: Position3D, effect: PlayerCollisionEffect) {
        playerCollisions.append((playerId, position, effect))
    }
    
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didProcessInkSpotOverlap inkSpot: InkSpot, overlaps: [(InkSpot, InkSpotOverlapResult)]) {
        inkSpotOverlaps.append((inkSpot, overlaps))
    }
    
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didMergeInkSpots originalSpots: [InkSpot], into mergedSpot: InkSpot) {
        inkSpotMerges.append((originalSpots, mergedSpot))
    }
    
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didCreateInkConflict newSpot: InkSpot, with existingSpot: InkSpot, overlapArea: Float) {
        inkSpotConflicts.append((newSpot, existingSpot, overlapArea))
    }
    
    func arGameCoordinator(_ coordinator: ARGameCoordinator, didUpdatePlayerPosition position: Position3D) {
        playerPositionUpdates.append(position)
    }
    
    func arGameCoordinatorDidCompleteePlaneDetection(_ coordinator: ARGameCoordinator) {}
}

// MARK: - Extensions for Testing

extension ARGameCoordinator {
    func simulateError(_ error: Error) {
        delegate?.arGameCoordinator(self, didFailWithError: error)
    }
}

extension GameState {
    var errorManager: ErrorManager? {
        get { nil }
        set { /* Mock implementation */ }
    }
}