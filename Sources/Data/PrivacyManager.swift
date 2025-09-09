//
//  PrivacyManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/09.
//

import AVFoundation
import Foundation
import Network

// MARK: - PrivacyManager

/// プライバシー関連の許可状態を管理するクラス
@Observable
class PrivacyManager {
    // MARK: - Properties

    /// カメラアクセス許可状態
    var cameraAuthorizationStatus: AVAuthorizationStatus = .notDetermined

    /// ローカルネットワーク許可状態
    var localNetworkAuthorized: Bool = false

    /// プライバシーポリシーの同意状態
    var privacyPolicyAccepted: Bool {
        get {
            UserDefaults.standard.bool(forKey: "privacy_policy_accepted")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "privacy_policy_accepted")
        }
    }

    // MARK: - Initialization

    init() {
        updateCameraAuthorizationStatus()
        checkLocalNetworkAuthorization()
    }

    // MARK: - Camera Authorization

    /// カメラアクセス許可をリクエスト
    func requestCameraAccess() async -> Bool {
        let status = await AVCaptureDevice.requestAccess(for: .video)
        await MainActor.run {
            updateCameraAuthorizationStatus()
        }
        return status
    }

    /// カメラ許可状態を更新
    private func updateCameraAuthorizationStatus() {
        cameraAuthorizationStatus = AVCaptureDevice.authorizationStatus(for: .video)
    }

    /// カメラアクセスが許可されているかチェック
    var isCameraAuthorized: Bool {
        cameraAuthorizationStatus == .authorized
    }

    // MARK: - Local Network Authorization

    /// ローカルネットワーク許可状態をチェック
    private func checkLocalNetworkAuthorization() {
        // Multipeer Connectivityの使用時に自動的に許可ダイアログが表示される
        // ここでは基本的な状態管理のみ行う
        localNetworkAuthorized = true // 初期値として設定
    }

    /// ローカルネットワーク使用の説明を表示
    func showLocalNetworkUsageExplanation() -> String {
        "このアプリは近くにいる他のプレイヤーとのリアルタイム対戦ゲームを実現するために、Multipeer Connectivityを通じてローカルネットワークを使用します。ゲームデータのみが送受信され、個人情報は送信されません。"
    }

    // MARK: - Privacy Policy

    /// プライバシーポリシーの内容を取得
    func getPrivacyPolicyContent() -> String? {
        guard let path = Bundle.main.path(forResource: "PrivacyPolicy", ofType: "md"),
              let content = try? String(contentsOfFile: path)
        else {
            return nil
        }
        return content
    }

    /// プライバシーポリシーに同意
    func acceptPrivacyPolicy() {
        privacyPolicyAccepted = true
    }

    /// プライバシーポリシーの同意を取り消し
    func revokePrivacyPolicyAcceptance() {
        privacyPolicyAccepted = false
    }

    // MARK: - Data Management

    /// ユーザーデータの削除
    func deleteAllUserData() {
        // ゲーム履歴の削除
        UserDefaults.standard.removeObject(forKey: "game_history")
        UserDefaults.standard.removeObject(forKey: "player_profile")
        UserDefaults.standard.removeObject(forKey: "privacy_policy_accepted")

        // SwiftDataの削除は別途GameDataModelで実装
    }

    /// データ使用量の概算を取得
    func getDataUsageEstimate() -> String {
        """
        データ使用量の概算:

        • ローカルストレージ: 約1-5MB
          - ゲーム履歴とプレイヤープロファイル

        • ネットワーク通信: 1ゲームあたり約10-50KB
          - ゲーム状態とインク位置の同期

        • カメラデータ: 0KB（保存されません）
          - リアルタイム処理のみ、保存なし
        """
    }

    // MARK: - Compliance Check

    /// 必要な許可がすべて取得されているかチェック
    var hasAllRequiredPermissions: Bool {
        isCameraAuthorized && privacyPolicyAccepted
    }

    /// 許可が不足している項目のリストを取得
    func getMissingPermissions() -> [String] {
        var missing: [String] = []

        if !isCameraAuthorized {
            missing.append("カメラアクセス")
        }

        if !privacyPolicyAccepted {
            missing.append("プライバシーポリシーへの同意")
        }

        return missing
    }
}

// MARK: - Privacy Compliance Extensions

extension PrivacyManager {
    /// GDPR準拠のデータ処理説明
    var gdprDataProcessingDescription: String {
        """
        データ処理の法的根拠:

        1. カメラデータ: 正当な利益（ゲーム機能の提供）
        2. ゲームデータ: 契約の履行（ゲームサービスの提供）
        3. ネットワーク通信: 正当な利益（マルチプレイヤー機能）

        データ保持期間:
        - カメラデータ: 処理後即座に削除
        - ゲームデータ: ユーザーが削除するまで
        - 通信データ: セッション終了後削除
        """
    }

    /// 日本の個人情報保護法準拠の説明
    var japanPrivacyLawCompliance: String {
        """
        個人情報保護法への対応:

        • 個人情報の定義: プレイヤー名のみが該当
        • 利用目的: ゲーム機能の提供に限定
        • 第三者提供: 対戦相手への最小限の情報のみ
        • 安全管理措置: 端末内処理、暗号化通信
        • 開示・訂正・削除: アプリ内で対応可能
        """
    }
}
