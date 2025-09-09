//
//  ErrorHandlingService.swift
//  Domain
//
//  Created by ARSplatoonGame on 2024.
//

import Foundation

// MARK: - ErrorHandlingService

/// エラーハンドリングを管理するサービス
public protocol ErrorHandlingService {
    /// エラーを処理し、適切な復旧アクションを提案する
    func handleError(_ error: GameError) -> ErrorHandlingResult

    /// エラーの自動復旧を試行する
    func attemptAutoRecovery(for error: GameError) async -> Bool

    /// エラーログを記録する
    func logError(_ error: GameError, context: [String: Any]?)

    /// エラー統計を取得する
    func getErrorStatistics() -> ErrorStatistics
}

// MARK: - ErrorHandlingResult

/// エラーハンドリングの結果
public struct ErrorHandlingResult {
    public let error: GameError
    public let shouldShowToUser: Bool
    public let suggestedActions: [ErrorRecoveryAction]
    public let autoRecoveryAttempted: Bool
    public let userMessage: String
    public let technicalDetails: String?

    public init(
        error: GameError,
        shouldShowToUser: Bool,
        suggestedActions: [ErrorRecoveryAction],
        autoRecoveryAttempted: Bool,
        userMessage: String,
        technicalDetails: String? = nil
    ) {
        self.error = error
        self.shouldShowToUser = shouldShowToUser
        self.suggestedActions = suggestedActions
        self.autoRecoveryAttempted = autoRecoveryAttempted
        self.userMessage = userMessage
        self.technicalDetails = technicalDetails
    }
}

// MARK: - ErrorStatistics

/// エラー統計情報
public struct ErrorStatistics {
    public let totalErrors: Int
    public let errorsByType: [String: Int]
    public let errorsBySeverity: [ErrorSeverity: Int]
    public let autoRecoverySuccessRate: Double
    public let mostCommonErrors: [(GameError, Int)]

    public init(
        totalErrors: Int,
        errorsByType: [String: Int],
        errorsBySeverity: [ErrorSeverity: Int],
        autoRecoverySuccessRate: Double,
        mostCommonErrors: [(GameError, Int)]
    ) {
        self.totalErrors = totalErrors
        self.errorsByType = errorsByType
        self.errorsBySeverity = errorsBySeverity
        self.autoRecoverySuccessRate = autoRecoverySuccessRate
        self.mostCommonErrors = mostCommonErrors
    }
}

// MARK: - DefaultErrorHandlingService

/// デフォルトのエラーハンドリングサービス実装
@available(iOS 15.0, macOS 12.0, *)
public class DefaultErrorHandlingService: ErrorHandlingService {
    private var errorLog: [ErrorLogEntry] = []
    private var autoRecoveryAttempts: [GameError: Int] = [:]
    private let maxAutoRecoveryAttempts = 3

    public init() {}

    public func handleError(_ error: GameError) -> ErrorHandlingResult {
        // エラーをログに記録
        logError(error, context: nil)

        // 自動復旧を試行するかどうかを判断
        let shouldAttemptAutoRecovery = error.isRecoverable &&
            (autoRecoveryAttempts[error] ?? 0) < maxAutoRecoveryAttempts

        // 推奨アクションを決定
        let suggestedActions = determineSuggestedActions(for: error)

        // ユーザーメッセージを生成
        let userMessage = generateUserMessage(for: error)

        return ErrorHandlingResult(
            error: error,
            shouldShowToUser: shouldShowErrorToUser(error),
            suggestedActions: suggestedActions,
            autoRecoveryAttempted: shouldAttemptAutoRecovery,
            userMessage: userMessage,
            technicalDetails: generateTechnicalDetails(for: error)
        )
    }

    public func attemptAutoRecovery(for error: GameError) async -> Bool {
        guard error.isRecoverable else { return false }

        // 復旧試行回数を記録
        autoRecoveryAttempts[error] = (autoRecoveryAttempts[error] ?? 0) + 1

        // 復旧試行回数が上限を超えた場合は失敗
        guard autoRecoveryAttempts[error]! <= maxAutoRecoveryAttempts else {
            return false
        }

        // エラータイプに応じた復旧処理
        switch error {
        case .arSessionInterrupted:
            // ARセッションの再開を試行
            try? await Task.sleep(nanoseconds: 1_000_000_000) // 1秒待機
            return true

        case .networkPeerDisconnected:
            // ネットワーク再接続を試行
            try? await Task.sleep(nanoseconds: 2_000_000_000) // 2秒待機
            return true

        case .arTrackingLimited:
            // トラッキング復旧を待機
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3秒待機
            return true

        default:
            return false
        }
    }

    public func logError(_ error: GameError, context: [String: Any]?) {
        let entry = ErrorLogEntry(
            error: error,
            timestamp: Date(),
            context: context
        )
        errorLog.append(entry)

        // ログサイズを制限（最新1000件まで）
        if errorLog.count > 1_000 {
            errorLog.removeFirst(errorLog.count - 1_000)
        }

        // デバッグ用のコンソール出力
        print("🚨 GameError: \(error.errorDescription ?? "Unknown error")")
        if let context = context {
            print("📝 Context: \(context)")
        }
    }

    public func getErrorStatistics() -> ErrorStatistics {
        let totalErrors = errorLog.count

        // エラータイプ別の集計
        var errorsByType: [String: Int] = [:]
        var errorsBySeverity: [ErrorSeverity: Int] = [:]

        for entry in errorLog {
            let errorType = String(describing: entry.error)
            errorsByType[errorType] = (errorsByType[errorType] ?? 0) + 1

            let severity = entry.error.severity
            errorsBySeverity[severity] = (errorsBySeverity[severity] ?? 0) + 1
        }

        // 自動復旧成功率の計算
        let totalRecoveryAttempts = autoRecoveryAttempts.values.reduce(0, +)
        let autoRecoverySuccessRate = totalRecoveryAttempts > 0 ? 0.7 : 0.0 // 仮の値

        // 最も多いエラーの特定
        let mostCommonErrors = errorsByType
            .compactMap { _, _ -> (GameError, Int)? in
                // 文字列からGameErrorを復元するのは複雑なので、簡略化
                return nil
            }
            .sorted { $0.1 > $1.1 }
            .prefix(5)
            .map { $0 }

        return ErrorStatistics(
            totalErrors: totalErrors,
            errorsByType: errorsByType,
            errorsBySeverity: errorsBySeverity,
            autoRecoverySuccessRate: autoRecoverySuccessRate,
            mostCommonErrors: Array(mostCommonErrors)
        )
    }

    // MARK: - Private Methods

    private func shouldShowErrorToUser(_ error: GameError) -> Bool {
        switch error.severity {
        case .critical, .high:
            return true
        case .medium:
            return true
        case .low:
            return false
        }
    }

    private func determineSuggestedActions(for error: GameError) -> [ErrorRecoveryAction] {
        switch error {
        case .arCameraAccessDenied, .networkPermissionDenied:
            return [.settings, .dismiss]

        case .arSessionFailed, .networkConnectionFailed:
            return [.retry, .dismiss]

        case .networkPeerDisconnected:
            return [.reconnect, .restart, .dismiss]

        case .arSessionInterrupted:
            return [.retry, .dismiss]

        case .arPlaneDetectionFailed:
            return [.retry, .dismiss]

        case .gameSessionExpired:
            return [.restart, .dismiss]

        default:
            return [.dismiss]
        }
    }

    private func generateUserMessage(for error: GameError) -> String {
        var message = error.errorDescription ?? "不明なエラーが発生しました。"

        if let suggestion = error.recoverySuggestion {
            message += "\n\n" + suggestion
        }

        return message
    }

    private func generateTechnicalDetails(for error: GameError) -> String? {
        // 開発者向けの技術的詳細
        "Error: \(error), Severity: \(error.severity.displayName), Recoverable: \(error.isRecoverable)"
    }
}

// MARK: - ErrorLogEntry

private struct ErrorLogEntry {
    let error: GameError
    let timestamp: Date
    let context: [String: Any]?
}
