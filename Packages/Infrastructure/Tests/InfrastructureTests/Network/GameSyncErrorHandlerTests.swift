//
//  GameSyncErrorHandlerTests.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

@testable import Domain
import Foundation
@testable import Infrastructure
import Testing
@testable import TestSupport

// MARK: - GameSyncErrorHandlerTests

struct GameSyncErrorHandlerTests {
    @Test("エラーハンドラーの初期化")
    func testInitialization() {
        let errorHandler = createErrorHandler()

        let stats = errorHandler.getErrorStats()
        #expect(stats.totalErrors == 0)
        #expect(stats.recentErrors == 0)
        #expect(stats.activeRetries == 0)
    }

    @Test("同期エラーの処理")
    func testHandleSyncError() {
        let errorHandler = createErrorHandler()

        let syncError = SyncError.connectionLost
        errorHandler.handleSyncError(syncError, context: "test")

        let stats = errorHandler.getErrorStats()
        #expect(stats.totalErrors == 1)
    }

    @Test("汎用エラーの処理")
    func testHandleGenericError() {
        let errorHandler = createErrorHandler()

        let genericError = TestError.generic
        errorHandler.handleGenericError(genericError, context: "generic_test")

        let stats = errorHandler.getErrorStats()
        #expect(stats.totalErrors == 1)
    }

    @Test("エラー統計の取得")
    func testGetErrorStats() {
        let errorHandler = createErrorHandler()

        // 複数のエラーを追加
        errorHandler.handleSyncError(.connectionLost, context: "test1")
        errorHandler.handleSyncError(.syncFailed(TestError.generic), context: "test2")
        errorHandler.handleGenericError(TestError.generic, context: "test3")

        let stats = errorHandler.getErrorStats()
        #expect(stats.totalErrors == 3)
        #expect(!stats.errorsByType.isEmpty)
    }

    @Test("最近のエラーの取得")
    func testGetRecentErrors() {
        let errorHandler = createErrorHandler()

        // エラーを追加
        errorHandler.handleSyncError(.connectionLost, context: "test1")
        errorHandler.handleSyncError(.syncFailed(TestError.generic), context: "test2")

        let recentErrors = errorHandler.getRecentErrors(limit: 5)
        #expect(recentErrors.count == 2)
        #expect(recentErrors[0].context == "test1")
        #expect(recentErrors[1].context == "test2")
    }

    @Test("エラー履歴のクリア")
    func testClearErrorHistory() {
        let errorHandler = createErrorHandler()

        // エラーを追加
        errorHandler.handleSyncError(.connectionLost, context: "test")

        let statsBeforeClear = errorHandler.getErrorStats()
        #expect(statsBeforeClear.totalErrors == 1)

        // クリア
        errorHandler.clearErrorHistory()

        let statsAfterClear = errorHandler.getErrorStats()
        #expect(statsAfterClear.totalErrors == 0)
    }

    @Test("クリティカルエラーのコールバック")
    func testCriticalErrorCallback() {
        let errorHandler = createErrorHandler()

        var receivedCriticalErrors: [CriticalSyncError] = []
        errorHandler.onCriticalError = { error in
            receivedCriticalErrors.append(error)
        }

        // クリティカルエラーを発生させる
        errorHandler.handleGenericError(TestError.generic, context: "critical_test")

        // 少し待ってコールバックが呼ばれることを確認
        Thread.sleep(forTimeInterval: 0.1)
        #expect(receivedCriticalErrors.count == 1)
    }

    @Test("エラー復旧のコールバック")
    func testErrorRecoveredCallback() {
        let errorHandler = createErrorHandler()

        var recoveredContexts: [String] = []
        errorHandler.onErrorRecovered = { context in
            recoveredContexts.append(context)
        }

        // 復旧可能なエラーを発生させる
        let syncError = SyncError.syncFailed(TestError.generic)
        errorHandler.handleSyncError(syncError, context: "recoverable_test")

        // 復旧のシミュレーション（実際の実装では自動的に行われる）
        Thread.sleep(forTimeInterval: 1.1) // retryDelayより少し長く待つ

        // 復旧コールバックが呼ばれることを確認
        #expect(recoveredContexts.contains("recoverable_test"))
    }

    @Test("エラーレコードの詳細")
    func testSyncErrorRecord() {
        let error = SyncError.connectionLost
        let context = "test_context"
        let timestamp = Date()
        let retryCount = 2

        let record = SyncErrorRecord(
            error: error,
            context: context,
            timestamp: timestamp,
            retryCount: retryCount
        )

        #expect(record.context == context)
        #expect(record.retryCount == retryCount)
        #expect(record.timestamp == timestamp)
    }

    @Test("クリティカルエラーの説明")
    func testCriticalSyncErrorDescriptions() {
        let errors: [CriticalSyncError] = [
            .connectionRecoveryFailed,
            .connectionTimeout,
            .maxRetriesExceeded(TestError.generic),
            .sessionCreationFailed(TestError.generic),
            .gameStartFailed(TestError.generic),
            .dataCorruption
        ]

        for error in errors {
            #expect(error.errorDescription != nil)
            #expect(!error.errorDescription!.isEmpty)
        }
    }

    // MARK: - Helper Methods

    private func createErrorHandler() -> GameSyncErrorHandler {
        let gameRepository = MultiPeerGameRepository(displayName: "TestPeer")
        let recoveryService = ConnectionRecoveryService(gameRepository: gameRepository)

        return GameSyncErrorHandler(
            recoveryService: recoveryService,
            maxRetryAttempts: 2,
            retryDelay: 1.0
        )
    }
}

// MARK: - TestError

enum TestError: Error {
    case generic
}
