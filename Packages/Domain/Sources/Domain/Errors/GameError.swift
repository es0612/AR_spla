//
//  GameError.swift
//  Domain
//
//  Created by ARSplatoonGame on 2024.
//

import Foundation

// MARK: - GameError

/// ゲーム全体で使用される共通エラー型
public enum GameError: Error, LocalizedError, Equatable, Hashable {
    // AR関連エラー
    case arSessionFailed(reason: String)
    case arTrackingLimited(reason: String)
    case arPlaneDetectionFailed
    case arUnsupportedDevice
    case arCameraAccessDenied
    case arSessionInterrupted

    // ネットワーク関連エラー
    case networkConnectionFailed(reason: String)
    case networkPeerDisconnected(peerName: String)
    case networkMessageDecodingFailed
    case networkSendingFailed(message: String)
    case networkDiscoveryFailed
    case networkPermissionDenied

    // ゲームロジック関連エラー
    case gameNotStarted
    case gameAlreadyStarted
    case invalidPlayerAction(reason: String)
    case gameSessionExpired
    case insufficientPlayers

    // データ関連エラー
    case dataCorrupted(description: String)
    case dataSaveFailed
    case dataLoadFailed

    // システム関連エラー
    case systemResourceUnavailable(resource: String)
    case systemPermissionDenied(permission: String)
    case systemLowMemory

    public var errorDescription: String? {
        switch self {
        // AR関連エラー
        case let .arSessionFailed(reason):
            return "ARセッションの開始に失敗しました: \(reason)"
        case let .arTrackingLimited(reason):
            return "ARトラッキングが制限されています: \(reason)"
        case .arPlaneDetectionFailed:
            return "平面の検出に失敗しました。デバイスを動かして周囲をスキャンしてください。"
        case .arUnsupportedDevice:
            return "このデバイスはARをサポートしていません。"
        case .arCameraAccessDenied:
            return "カメラへのアクセスが拒否されました。設定からカメラの使用を許可してください。"
        case .arSessionInterrupted:
            return "ARセッションが中断されました。"

        // ネットワーク関連エラー
        case let .networkConnectionFailed(reason):
            return "ネットワーク接続に失敗しました: \(reason)"
        case let .networkPeerDisconnected(peerName):
            return "\(peerName)との接続が切断されました。"
        case .networkMessageDecodingFailed:
            return "受信したメッセージの解析に失敗しました。"
        case let .networkSendingFailed(message):
            return "メッセージの送信に失敗しました: \(message)"
        case .networkDiscoveryFailed:
            return "近くのプレイヤーの検索に失敗しました。"
        case .networkPermissionDenied:
            return "ローカルネットワークへのアクセスが拒否されました。設定から許可してください。"

        // ゲームロジック関連エラー
        case .gameNotStarted:
            return "ゲームが開始されていません。"
        case .gameAlreadyStarted:
            return "ゲームは既に開始されています。"
        case let .invalidPlayerAction(reason):
            return "無効なプレイヤーアクション: \(reason)"
        case .gameSessionExpired:
            return "ゲームセッションの有効期限が切れました。"
        case .insufficientPlayers:
            return "ゲームを開始するには最低2人のプレイヤーが必要です。"

        // データ関連エラー
        case let .dataCorrupted(description):
            return "データが破損しています: \(description)"
        case .dataSaveFailed:
            return "データの保存に失敗しました。"
        case .dataLoadFailed:
            return "データの読み込みに失敗しました。"

        // システム関連エラー
        case let .systemResourceUnavailable(resource):
            return "システムリソースが利用できません: \(resource)"
        case let .systemPermissionDenied(permission):
            return "システム権限が拒否されました: \(permission)"
        case .systemLowMemory:
            return "メモリ不足です。他のアプリを終了してください。"
        }
    }

    public var recoverySuggestion: String? {
        switch self {
        case .arPlaneDetectionFailed:
            return "明るい場所でデバイスをゆっくりと動かし、テクスチャのある平面を探してください。"
        case .arCameraAccessDenied:
            return "設定 > プライバシーとセキュリティ > カメラ からアプリのカメラアクセスを有効にしてください。"
        case .networkPermissionDenied:
            return "設定 > プライバシーとセキュリティ > ローカルネットワーク からアプリのアクセスを有効にしてください。"
        case .networkPeerDisconnected:
            return "再接続を試すか、新しいゲームを開始してください。"
        case .systemLowMemory:
            return "バックグラウンドで動作している他のアプリを終了してください。"
        default:
            return nil
        }
    }

    /// エラーの重要度レベル
    public var severity: ErrorSeverity {
        switch self {
        case .arUnsupportedDevice, .arCameraAccessDenied, .networkPermissionDenied:
            return .critical
        case .arSessionFailed, .networkConnectionFailed, .systemLowMemory:
            return .high
        case .arTrackingLimited, .networkPeerDisconnected, .gameSessionExpired:
            return .medium
        case .arPlaneDetectionFailed, .networkMessageDecodingFailed, .invalidPlayerAction:
            return .low
        default:
            return .medium
        }
    }

    /// エラーが自動復旧可能かどうか
    public var isRecoverable: Bool {
        switch self {
        case .arUnsupportedDevice, .arCameraAccessDenied, .networkPermissionDenied:
            return false
        case .arSessionInterrupted, .networkPeerDisconnected, .arTrackingLimited:
            return true
        default:
            return false
        }
    }
}

// MARK: - ErrorSeverity

/// エラーの重要度レベル
public enum ErrorSeverity: String, CaseIterable {
    case low
    case medium
    case high
    case critical

    public var displayName: String {
        switch self {
        case .low:
            return "軽微"
        case .medium:
            return "中程度"
        case .high:
            return "重要"
        case .critical:
            return "致命的"
        }
    }
}

// MARK: - ErrorRecoveryAction

/// エラー復旧アクション
public enum ErrorRecoveryAction: String, CaseIterable {
    case retry
    case reconnect
    case restart
    case settings
    case dismiss

    public var displayName: String {
        switch self {
        case .retry:
            return "再試行"
        case .reconnect:
            return "再接続"
        case .restart:
            return "再開始"
        case .settings:
            return "設定を開く"
        case .dismiss:
            return "閉じる"
        }
    }
}
