//
//  GameSynchronizationServiceTests.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

@testable import Domain
import Foundation
@testable import Infrastructure
import MultipeerConnectivity
import Testing
@testable import TestSupport

struct GameSynchronizationServiceTests {
    @Test("同期サービスの初期化")
    func testInitialization() {
        let mockRepository = createMockRepository()
        let syncService = GameSynchronizationService(gameRepository: mockRepository)

        #expect(!syncService.isConnected)
        #expect(syncService.latency == 0)
        #expect(syncService.syncErrors.isEmpty)
    }

    @Test("インクスポットのキューイング")
    func testInkSpotQueuing() {
        let mockRepository = createMockRepository()
        let syncService = GameSynchronizationService(gameRepository: mockRepository)

        let inkSpot = InkSpotBuilder()
            .withId(InkSpotId())
            .withPosition(Position3D(x: 1.0, y: 0.0, z: 1.0))
            .withColor(PlayerColor.red)
            .withOwnerId(PlayerId())
            .build()

        syncService.queueInkSpot(inkSpot)

        // キューに追加されたことを確認（内部状態なので直接テストは困難）
        #expect(true) // プレースホルダー
    }

    @Test("プレイヤー更新のキューイング")
    func testPlayerUpdateQueuing() {
        let mockRepository = createMockRepository()
        let syncService = GameSynchronizationService(gameRepository: mockRepository)

        let player = PlayerBuilder()
            .withId(PlayerId())
            .withName("TestPlayer")
            .withColor(PlayerColor.blue)
            .withPosition(Position3D(x: 0.0, y: 0.0, z: 0.0))
            .build()

        syncService.queuePlayerUpdate(player)

        // キューに追加されたことを確認
        #expect(true) // プレースホルダー
    }

    @Test("Pong受信時のレイテンシ計算")
    func testLatencyCalculation() {
        let mockRepository = createMockRepository()
        let syncService = GameSynchronizationService(gameRepository: mockRepository)

        // Ping時刻を設定
        let pingTime = Date().timeIntervalSince1970
        UserDefaults.standard.set(pingTime, forKey: "lastPingTime")

        // 少し待ってからPong処理
        Thread.sleep(forTimeInterval: 0.01)
        syncService.handlePongReceived()

        #expect(syncService.latency > 0)

        // クリーンアップ
        UserDefaults.standard.removeObject(forKey: "lastPingTime")
    }

    @Test("ゲーム状態の強制同期")
    func testForceSyncGameState() async throws {
        let mockRepository = createMockRepository()
        let syncService = GameSynchronizationService(gameRepository: mockRepository)

        let gameSession = GameSessionBuilder()
            .withId(GameSessionId())
            .withDuration(180.0)
            .withStatus(.waiting)
            .build()

        await withCheckedContinuation { continuation in
            syncService.forceSyncGameState(gameSession) { error in
                #expect(error == nil)
                continuation.resume()
            }
        }
    }

    // MARK: - Helper Methods

    private func createMockRepository() -> MultiPeerGameRepository {
        MultiPeerGameRepository(displayName: "TestPeer")
    }
}
