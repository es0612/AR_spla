//
//  ErrorManager.swift
//  ARSplatoonGame
//
//  Created by ARSplatoonGame on 2024.
//

import Domain
import Foundation
import SwiftUI

// MARK: - ErrorManager

/// アプリ全体のエラーハンドリングを管理するクラス
@Observable
class ErrorManager {
    // MARK: - Properties

    private let errorHandlingService: ErrorHandlingService

    // 現在表示中のエラー
    var currentError: GameError?
    var currentErrorResult: ErrorHandlingResult?
    var isShowingError = false

    // トースト表示用
    var toastMessage: String?
    var toastIcon: String = "info.circle"
    var toastColor: Color = .blue
    var isShowingToast = false

    // エラー履歴
    var errorHistory: [GameError] = []

    // 自動復旧の状態
    var isAttemptingAutoRecovery = false
    var autoRecoveryProgress: String?

    // MARK: - Initialization

    init(errorHandlingService: ErrorHandlingService = DefaultErrorHandlingService()) {
        self.errorHandlingService = errorHandlingService
    }

    // MARK: - Public Methods

    /// エラーを処理する
    func handleError(_ error: GameError, context _: [String: Any]? = nil) {
        // エラーハンドリングサービスでエラーを処理
        let result = errorHandlingService.handleError(error)

        // エラー履歴に追加
        errorHistory.append(error)

        // 自動復旧を試行する場合
        if result.autoRecoveryAttempted {
            attemptAutoRecovery(for: error)
        }

        // ユーザーに表示する場合
        if result.shouldShowToUser {
            showError(error, result: result)
        } else {
            // 軽微なエラーはトーストで表示
            showToast(message: result.userMessage, severity: error.severity)
        }
    }

    /// エラーダイアログを表示する
    private func showError(_ error: GameError, result: ErrorHandlingResult) {
        currentError = error
        currentErrorResult = result
        isShowingError = true
    }

    /// エラーダイアログを閉じる
    func dismissError() {
        currentError = nil
        currentErrorResult = nil
        isShowingError = false
    }

    /// トーストメッセージを表示する
    func showToast(message: String, severity: ErrorSeverity = .low, duration: TimeInterval = 3.0) {
        toastMessage = message
        toastIcon = iconForSeverity(severity)
        toastColor = colorForSeverity(severity)
        isShowingToast = true

        // 指定時間後に自動的に非表示
        Task {
            try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
            await MainActor.run {
                dismissToast()
            }
        }
    }

    /// トーストメッセージを閉じる
    func dismissToast() {
        isShowingToast = false
        toastMessage = nil
    }

    /// エラーアクションを実行する
    func executeAction(_ action: ErrorRecoveryAction) {
        guard let error = currentError else { return }

        switch action {
        case .retry:
            handleRetryAction(for: error)
        case .reconnect:
            handleReconnectAction(for: error)
        case .restart:
            handleRestartAction(for: error)
        case .settings:
            handleSettingsAction(for: error)
        case .dismiss:
            dismissError()
        }
    }

    /// 自動復旧を試行する
    private func attemptAutoRecovery(for error: GameError) {
        isAttemptingAutoRecovery = true
        autoRecoveryProgress = "自動復旧を試行中..."

        Task {
            let success = await errorHandlingService.attemptAutoRecovery(for: error)

            await MainActor.run {
                isAttemptingAutoRecovery = false
                autoRecoveryProgress = nil

                if success {
                    showToast(message: "問題が自動的に解決されました", severity: .low)
                } else {
                    // 自動復旧に失敗した場合はユーザーに表示
                    let result = errorHandlingService.handleError(error)
                    showError(error, result: result)
                }
            }
        }
    }

    /// エラー統計を取得する
    func getErrorStatistics() -> ErrorStatistics {
        errorHandlingService.getErrorStatistics()
    }

    /// ガイダンスを非表示にする
    func hideGuidance() {
        // ガイダンス関連のトーストやメッセージを非表示にする
        dismissToast()

        // ガイダンス表示中のエラーがあれば閉じる
        if let currentError = currentError,
           case .arPlaneDetectionFailed = currentError {
            dismissError()
        }
    }

    // MARK: - Private Methods

    private func handleRetryAction(for error: GameError) {
        dismissError()

        // エラータイプに応じた再試行処理
        switch error {
        case .arSessionFailed, .arPlaneDetectionFailed:
            NotificationCenter.default.post(name: .retryARSession, object: nil)
        case .networkConnectionFailed, .networkDiscoveryFailed:
            NotificationCenter.default.post(name: .retryNetworkConnection, object: nil)
        default:
            showToast(message: "再試行しています...", severity: .low)
        }
    }

    private func handleReconnectAction(for _: GameError) {
        dismissError()
        NotificationCenter.default.post(name: .reconnectNetwork, object: nil)
        showToast(message: "再接続を試行中...", severity: .low)
    }

    private func handleRestartAction(for _: GameError) {
        dismissError()
        NotificationCenter.default.post(name: .restartGame, object: nil)
        showToast(message: "ゲームを再開始しています...", severity: .low)
    }

    private func handleSettingsAction(for _: GameError) {
        dismissError()

        // 設定アプリを開く
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }

    private func iconForSeverity(_ severity: ErrorSeverity) -> String {
        switch severity {
        case .critical:
            return "xmark.circle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "info.circle.fill"
        }
    }

    private func colorForSeverity(_ severity: ErrorSeverity) -> Color {
        switch severity {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let retryARSession = Notification.Name("retryARSession")
    static let retryNetworkConnection = Notification.Name("retryNetworkConnection")
    static let reconnectNetwork = Notification.Name("reconnectNetwork")
    static let restartGame = Notification.Name("restartGame")
}

// MARK: - ErrorManager Extension for Specific Errors

extension ErrorManager {
    /// ARエラーを処理する
    func handleARError(_ error: Error) {
        let gameError: GameError

        // ARKitのエラーを適切に処理
        if let nsError = error as NSError? {
            switch nsError.code {
            case 102: // ARErrorCodeUnsupportedConfiguration
                gameError = .arUnsupportedDevice
            case 103: // ARErrorCodeSensorUnavailable
                gameError = .arSessionFailed(reason: "センサーが利用できません")
            case 104: // ARErrorCodeSensorFailed
                gameError = .arSessionFailed(reason: "センサーエラー")
            case 105: // ARErrorCodeCameraUnauthorized
                gameError = .arCameraAccessDenied
            case 200: // ARErrorCodeWorldTrackingFailed
                gameError = .arTrackingLimited(reason: "ワールドトラッキングに失敗")
            default:
                gameError = .arSessionFailed(reason: error.localizedDescription)
            }
        } else {
            gameError = .arSessionFailed(reason: error.localizedDescription)
        }

        handleError(gameError)
    }

    /// ネットワークエラーを処理する
    func handleNetworkError(_ error: Error, peerName: String? = nil) {
        let gameError: GameError

        if let peerName = peerName {
            gameError = .networkPeerDisconnected(peerName: peerName)
        } else {
            gameError = .networkConnectionFailed(reason: error.localizedDescription)
        }

        handleError(gameError)
    }

    /// ゲームロジックエラーを処理する
    func handleGameLogicError(_ error: GameError) {
        handleError(error)
    }
}
