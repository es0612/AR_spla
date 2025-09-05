//
//  ConnectionRecoveryServiceTests.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

import Foundation
@testable import Infrastructure
import MultipeerConnectivity
import Testing

struct ConnectionRecoveryServiceTests {
    @Test("復旧サービスの初期化")
    func testInitialization() {
        let mockRepository = createMockRepository()
        let recoveryService = ConnectionRecoveryService(
            gameRepository: mockRepository,
            maxRetryAttempts: 3,
            retryInterval: 1.0
        )

        #expect(!recoveryService.isRecovering)
        #expect(recoveryService.retryAttempts == 0)
        #expect(recoveryService.lastRecoveryError == nil)
    }

    @Test("接続統計の取得")
    func testGetConnectionStats() {
        let mockRepository = createMockRepository()
        let recoveryService = ConnectionRecoveryService(gameRepository: mockRepository)

        let stats = recoveryService.getConnectionStats()

        #expect(!stats.isConnected)
        #expect(stats.connectedPeersCount == 0)
        #expect(stats.retryAttempts == 0)
        #expect(!stats.isRecovering)
        #expect(stats.disconnectionDuration == nil)
    }

    @Test("接続安定性の確認")
    func testIsConnectionStable() {
        let mockRepository = createMockRepository()
        let recoveryService = ConnectionRecoveryService(gameRepository: mockRepository)

        // 初期状態では不安定
        #expect(!recoveryService.isConnectionStable())
    }

    @Test("強制復旧の実行")
    func testForceRecovery() {
        let mockRepository = createMockRepository()
        let recoveryService = ConnectionRecoveryService(
            gameRepository: mockRepository,
            maxRetryAttempts: 1,
            retryInterval: 0.1
        )

        recoveryService.forceRecovery()

        // 復旧処理が開始されることを確認
        #expect(recoveryService.isRecovering)
    }

    @Test("復旧エラーの種類")
    func testRecoveryErrorTypes() {
        let maxRetriesError = RecoveryError.maxRetriesExceeded
        let networkError = RecoveryError.networkUnavailable
        let attemptError = RecoveryError.recoveryAttemptFailed(NSError(domain: "test", code: 1))

        #expect(maxRetriesError.errorDescription?.contains("最大再試行回数") == true)
        #expect(networkError.errorDescription?.contains("ネットワーク") == true)
        #expect(attemptError.errorDescription?.contains("復旧試行") == true)
    }

    @Test("接続統計の詳細情報")
    func testConnectionStatsDetails() {
        let stats = ConnectionStats(
            isConnected: true,
            connectedPeersCount: 2,
            retryAttempts: 3,
            isRecovering: false,
            disconnectionDuration: 5.0
        )

        #expect(stats.isConnected)
        #expect(stats.connectedPeersCount == 2)
        #expect(stats.retryAttempts == 3)
        #expect(!stats.isRecovering)
        #expect(stats.disconnectionDuration == 5.0)
    }

    // MARK: - Helper Methods

    private func createMockRepository() -> MultiPeerGameRepository {
        MultiPeerGameRepository(displayName: "TestPeer")
    }
}
