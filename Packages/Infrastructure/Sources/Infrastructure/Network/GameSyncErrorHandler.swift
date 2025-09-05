//
//  GameSyncErrorHandler.swift
//  ARSplatoonGame
//
//  Created by Kiro on 9/5/2025.
//

import Foundation
import MultipeerConnectivity

// MARK: - GameSyncErrorHandler

/// Handler for game synchronization errors
public class GameSyncErrorHandler {
    // MARK: - Properties

    private let recoveryService: ConnectionRecoveryService
    private let maxRetryAttempts: Int
    private let retryDelay: TimeInterval

    // MARK: - Error Tracking

    private var errorHistory: [SyncErrorRecord] = []
    private var retryAttempts: [String: Int] = [:]

    // MARK: - Callbacks

    public var onCriticalError: ((CriticalSyncError) -> Void)?
    public var onErrorRecovered: ((String) -> Void)?

    // MARK: - Initialization

    public init(
        recoveryService: ConnectionRecoveryService,
        maxRetryAttempts: Int = 3,
        retryDelay: TimeInterval = 2.0
    ) {
        self.recoveryService = recoveryService
        self.maxRetryAttempts = maxRetryAttempts
        self.retryDelay = retryDelay
    }

    // MARK: - Error Handling

    /// Handle synchronization error
    public func handleSyncError(_ error: SyncError, context: String = "") {
        let errorRecord = SyncErrorRecord(
            error: error,
            context: context,
            timestamp: Date(),
            retryCount: retryAttempts[context] ?? 0
        )

        errorHistory.append(errorRecord)

        // Keep only last 50 errors
        if errorHistory.count > 50 {
            errorHistory.removeFirst()
        }

        // Determine error severity and handle accordingly
        switch error {
        case .connectionLost:
            handleConnectionLostError(context: context)
        case let .syncFailed(underlyingError):
            handleSyncFailedError(underlyingError, context: context)
        case let .messageDecodingFailed(underlyingError):
            handleMessageDecodingError(underlyingError, context: context)
        }
    }

    /// Handle generic error
    public func handleGenericError(_ error: Error, context: String = "") {
        let errorRecord = SyncErrorRecord(
            error: .syncFailed(error),
            context: context,
            timestamp: Date(),
            retryCount: retryAttempts[context] ?? 0
        )

        errorHistory.append(errorRecord)

        // Handle based on error description
        if error.localizedDescription.contains("timeout") {
            handleConnectionTimeoutError(context: context)
        } else {
            handleSyncFailedError(error, context: context)
        }
    }

    // MARK: - Specific Error Handlers

    private func handleConnectionLostError(context: String) {
        print("Connection lost in context: \(context)")

        // Start recovery process
        recoveryService.forceRecovery()

        // Set timeout for recovery
        DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
            if !self.recoveryService.isConnectionStable() {
                self.handleCriticalError(.connectionRecoveryFailed, context: context)
            }
        }
    }

    private func handleSyncFailedError(_ error: Error, context: String) {
        let currentRetries = retryAttempts[context] ?? 0

        if currentRetries < maxRetryAttempts {
            // Increment retry count
            retryAttempts[context] = currentRetries + 1

            // Schedule retry
            DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                self.retrySyncOperation(context: context)
            }
        } else {
            // Max retries exceeded
            handleCriticalError(.maxRetriesExceeded(error), context: context)
            retryAttempts.removeValue(forKey: context)
        }
    }

    private func handleMessageDecodingError(_ error: Error, context: String) {
        print("Message decoding failed in context: \(context) - \(error)")

        // Log the error for debugging
        let errorDetails = "Decoding error: \(error.localizedDescription)"
        logError(errorDetails, context: context)

        // Request resend of the message if possible
        requestMessageResend(context: context)
    }

    private func handleConnectionTimeoutError(context: String) {
        print("Connection timeout in context: \(context)")

        // Force session cleanup if timeout occurs during critical operations
        if context.contains("session") || context.contains("game") {
            handleCriticalError(.connectionTimeout, context: context)
        } else {
            // Try recovery for non-critical timeouts
            recoveryService.forceRecovery()
        }
    }



    private func handleCriticalError(_ error: CriticalSyncError, context: String) {
        print("Critical error in context: \(context) - \(error)")

        // Log critical error
        logError("CRITICAL: \(error.localizedDescription)", context: context)

        // Notify observers
        onCriticalError?(error)

        // Clean up retry attempts for this context
        retryAttempts.removeValue(forKey: context)
    }

    // MARK: - Recovery Operations

    private func retrySyncOperation(context: String) {
        print("Retrying sync operation for context: \(context)")

        // The actual retry logic would depend on the specific operation
        // For now, we'll simulate a successful retry
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            // Simulate successful recovery
            self.onErrorRecovered?(context)
            self.retryAttempts.removeValue(forKey: context)
        }
    }

    private func requestMessageResend(context: String) {
        // Request the sender to resend the message
        // This would typically involve sending a specific message type
        print("Requesting message resend for context: \(context)")
    }

    private func scheduleRecoveryAttempt(context: String) {
        DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
            if self.recoveryService.isConnectionStable() {
                self.onErrorRecovered?(context)
            } else {
                self.recoveryService.forceRecovery()
            }
        }
    }

    // MARK: - Utility Methods

    private func shouldAttemptRecovery(for error: Error) -> Bool {
        // Simple heuristic based on error description
        let errorDescription = error.localizedDescription.lowercased()
        return errorDescription.contains("network") ||
            errorDescription.contains("connection") ||
            errorDescription.contains("timeout")
    }

    private func logError(_ message: String, context: String) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let logEntry = "[\(timestamp)] ERROR in \(context): \(message)"
        print(logEntry)

        // In a production app, you would write this to a log file or send to analytics
    }

    // MARK: - Public API

    /// Get error statistics
    public func getErrorStats() -> ErrorStats {
        let recentErrors = errorHistory.filter {
            Date().timeIntervalSince($0.timestamp) < 300 // Last 5 minutes
        }

        let errorsByType = Dictionary(grouping: recentErrors) { record in
            String(describing: type(of: record.error))
        }

        return ErrorStats(
            totalErrors: errorHistory.count,
            recentErrors: recentErrors.count,
            errorsByType: errorsByType.mapValues { $0.count },
            activeRetries: retryAttempts.count
        )
    }

    /// Clear error history
    public func clearErrorHistory() {
        errorHistory.removeAll()
        retryAttempts.removeAll()
    }

    /// Get recent errors
    public func getRecentErrors(limit: Int = 10) -> [SyncErrorRecord] {
        Array(errorHistory.suffix(limit))
    }
}

// MARK: - SyncErrorRecord

public struct SyncErrorRecord {
    public let error: SyncError
    public let context: String
    public let timestamp: Date
    public let retryCount: Int

    public init(error: SyncError, context: String, timestamp: Date, retryCount: Int) {
        self.error = error
        self.context = context
        self.timestamp = timestamp
        self.retryCount = retryCount
    }
}

// MARK: - CriticalSyncError

public enum CriticalSyncError: Error, LocalizedError {
    case connectionRecoveryFailed
    case connectionTimeout
    case maxRetriesExceeded(Error)
    case sessionCreationFailed(Error)
    case gameStartFailed(Error)
    case dataCorruption

    public var errorDescription: String? {
        switch self {
        case .connectionRecoveryFailed:
            return "接続の復旧に失敗しました"
        case .connectionTimeout:
            return "接続がタイムアウトしました"
        case let .maxRetriesExceeded(error):
            return "最大再試行回数に達しました: \(error.localizedDescription)"
        case let .sessionCreationFailed(error):
            return "セッション作成に失敗しました: \(error.localizedDescription)"
        case let .gameStartFailed(error):
            return "ゲーム開始に失敗しました: \(error.localizedDescription)"
        case .dataCorruption:
            return "データが破損しています"
        }
    }
}

// MARK: - ErrorStats

public struct ErrorStats {
    public let totalErrors: Int
    public let recentErrors: Int
    public let errorsByType: [String: Int]
    public let activeRetries: Int

    public init(
        totalErrors: Int,
        recentErrors: Int,
        errorsByType: [String: Int],
        activeRetries: Int
    ) {
        self.totalErrors = totalErrors
        self.recentErrors = recentErrors
        self.errorsByType = errorsByType
        self.activeRetries = activeRetries
    }
}
