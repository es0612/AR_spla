//
//  GameBalanceSettings.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import Foundation

/// ゲームバランス調整のための設定クラス
@Observable
public class GameBalanceSettings {
    // MARK: - インク発射関連

    /// インク発射のクールダウン時間（秒）
    public var inkShotCooldown: TimeInterval = 0.3

    /// インクの最大射程距離（メートル）
    public var inkMaxRange: Float = 5.0

    /// インクスポットの基本サイズ
    public var inkSpotBaseSize: Float = 0.4

    /// インクスポットの最大サイズ
    public var inkSpotMaxSize: Float = 0.8

    /// インクの発射速度（メートル/秒）
    public var inkShotVelocity: Float = 8.0

    /// 連続発射時のサイズ減少率
    public var rapidFireSizeReduction: Float = 0.8

    // MARK: - プレイヤー関連

    /// プレイヤーがインクに当たった時のスタン時間（秒）
    public var playerStunDuration: TimeInterval = 2.5

    /// プレイヤーの移動速度（メートル/秒）
    public var playerMoveSpeed: Float = 2.0

    /// プレイヤーの衝突判定半径（メートル）
    public var playerCollisionRadius: Float = 0.4

    /// スタン中の移動速度減少率
    public var stunMovementReduction: Float = 0.3

    // MARK: - ゲーム時間とスコア

    /// ゲーム時間（秒）
    public var gameDuration: TimeInterval = 180

    /// スコア計算の更新間隔（秒）
    public var scoreUpdateInterval: TimeInterval = 1.0

    /// 勝利に必要な最小カバー率の差（%）
    public var minimumWinMargin: Float = 5.0

    /// 同点時の判定基準（インクスポット数で判定）
    public var tieBreakByInkSpots: Bool = true

    // MARK: - ゲームフィールド

    /// ゲームフィールドのサイズ（メートル）
    public var fieldSize: CGSize = .init(width: 4.0, height: 4.0)

    /// フィールド境界からの安全マージン（メートル）
    public var fieldBoundaryMargin: Float = 0.2

    /// 最大インクスポット数（プレイヤーあたり）
    public var maxInkSpotsPerPlayer: Int = 150

    // MARK: - 難易度調整

    /// 難易度レベル
    public enum DifficultyLevel: String, CaseIterable {
        case easy
        case normal
        case hard

        var displayName: String {
            switch self {
            case .easy: return "イージー"
            case .normal: return "ノーマル"
            case .hard: return "ハード"
            }
        }
    }

    /// 現在の難易度レベル
    public var difficultyLevel: DifficultyLevel = .normal {
        didSet {
            applyDifficultySettings()
        }
    }

    // MARK: - 初期化

    public init() {
        loadSettings()
        applyDifficultySettings()
        applyRegionalAdjustments()
    }

    // MARK: - 難易度設定の適用

    private func applyDifficultySettings() {
        switch difficultyLevel {
        case .easy:
            // イージー: より寛容な設定
            inkShotCooldown = 0.2
            inkMaxRange = 6.0
            inkSpotBaseSize = 0.5
            playerStunDuration = 2.0
            maxInkSpotsPerPlayer = 200

        case .normal:
            // ノーマル: バランスの取れた設定
            inkShotCooldown = 0.3
            inkMaxRange = 5.0
            inkSpotBaseSize = 0.4
            playerStunDuration = 2.5
            maxInkSpotsPerPlayer = 150

        case .hard:
            // ハード: より厳しい設定
            inkShotCooldown = 0.4
            inkMaxRange = 4.0
            inkSpotBaseSize = 0.3
            playerStunDuration = 3.0
            maxInkSpotsPerPlayer = 100
        }
    }

    // MARK: - 設定の保存・読み込み

    public func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(inkShotCooldown, forKey: "inkShotCooldown")
        defaults.set(inkMaxRange, forKey: "inkMaxRange")
        defaults.set(inkSpotBaseSize, forKey: "inkSpotBaseSize")
        defaults.set(inkSpotMaxSize, forKey: "inkSpotMaxSize")
        defaults.set(inkShotVelocity, forKey: "inkShotVelocity")
        defaults.set(rapidFireSizeReduction, forKey: "rapidFireSizeReduction")

        defaults.set(playerStunDuration, forKey: "playerStunDuration")
        defaults.set(playerMoveSpeed, forKey: "playerMoveSpeed")
        defaults.set(playerCollisionRadius, forKey: "playerCollisionRadius")
        defaults.set(stunMovementReduction, forKey: "stunMovementReduction")

        defaults.set(gameDuration, forKey: "gameDuration")
        defaults.set(scoreUpdateInterval, forKey: "scoreUpdateInterval")
        defaults.set(minimumWinMargin, forKey: "minimumWinMargin")
        defaults.set(tieBreakByInkSpots, forKey: "tieBreakByInkSpots")

        defaults.set(fieldSize.width, forKey: "fieldSizeWidth")
        defaults.set(fieldSize.height, forKey: "fieldSizeHeight")
        defaults.set(fieldBoundaryMargin, forKey: "fieldBoundaryMargin")
        defaults.set(maxInkSpotsPerPlayer, forKey: "maxInkSpotsPerPlayer")

        defaults.set(difficultyLevel.rawValue, forKey: "difficultyLevel")
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        inkShotCooldown = defaults.object(forKey: "inkShotCooldown") as? TimeInterval ?? 0.3
        inkMaxRange = defaults.object(forKey: "inkMaxRange") as? Float ?? 5.0
        inkSpotBaseSize = defaults.object(forKey: "inkSpotBaseSize") as? Float ?? 0.4
        inkSpotMaxSize = defaults.object(forKey: "inkSpotMaxSize") as? Float ?? 0.8
        inkShotVelocity = defaults.object(forKey: "inkShotVelocity") as? Float ?? 8.0
        rapidFireSizeReduction = defaults.object(forKey: "rapidFireSizeReduction") as? Float ?? 0.8

        playerStunDuration = defaults.object(forKey: "playerStunDuration") as? TimeInterval ?? 2.5
        playerMoveSpeed = defaults.object(forKey: "playerMoveSpeed") as? Float ?? 2.0
        playerCollisionRadius = defaults.object(forKey: "playerCollisionRadius") as? Float ?? 0.4
        stunMovementReduction = defaults.object(forKey: "stunMovementReduction") as? Float ?? 0.3

        gameDuration = defaults.object(forKey: "gameDuration") as? TimeInterval ?? 180
        scoreUpdateInterval = defaults.object(forKey: "scoreUpdateInterval") as? TimeInterval ?? 1.0
        minimumWinMargin = defaults.object(forKey: "minimumWinMargin") as? Float ?? 5.0
        tieBreakByInkSpots = defaults.object(forKey: "tieBreakByInkSpots") as? Bool ?? true

        let width = defaults.object(forKey: "fieldSizeWidth") as? Double ?? 4.0
        let height = defaults.object(forKey: "fieldSizeHeight") as? Double ?? 4.0
        fieldSize = CGSize(width: width, height: height)
        fieldBoundaryMargin = defaults.object(forKey: "fieldBoundaryMargin") as? Float ?? 0.2
        maxInkSpotsPerPlayer = defaults.object(forKey: "maxInkSpotsPerPlayer") as? Int ?? 150

        let difficultyRawValue = defaults.string(forKey: "difficultyLevel") ?? "normal"
        difficultyLevel = DifficultyLevel(rawValue: difficultyRawValue) ?? .normal
    }

    // MARK: - プリセット設定

    /// 競技用バランス設定を適用
    public func applyCompetitiveSettings() {
        inkShotCooldown = 0.35
        inkMaxRange = 4.5
        inkSpotBaseSize = 0.35
        playerStunDuration = 2.8
        gameDuration = 180
        maxInkSpotsPerPlayer = 120
        minimumWinMargin = 3.0
        saveSettings()
    }

    /// カジュアル用バランス設定を適用
    public func applyCasualSettings() {
        inkShotCooldown = 0.25
        inkMaxRange = 5.5
        inkSpotBaseSize = 0.45
        playerStunDuration = 2.0
        gameDuration = 120
        maxInkSpotsPerPlayer = 180
        minimumWinMargin = 8.0
        saveSettings()
    }

    /// 設定をデフォルトにリセット
    public func resetToDefaults() {
        difficultyLevel = .normal
        applyDifficultySettings()
        applyRegionalAdjustments()
        saveSettings()
    }

    // MARK: - 地域別調整

    /// 地域設定に基づいてゲームバランスを調整
    private func applyRegionalAdjustments() {
        let regionalSettings = RegionalSettingsManager.shared
        regionalSettings.adjustGameBalance(self)
    }

    /// 地域設定の変更を反映
    public func updateForRegionalSettings() {
        applyRegionalAdjustments()
        saveSettings()
    }

    // MARK: - バランス検証

    /// 現在の設定が有効かどうかを検証
    public var isValid: Bool {
        inkShotCooldown > 0 &&
            inkMaxRange > 0 &&
            inkSpotBaseSize > 0 &&
            inkSpotMaxSize > inkSpotBaseSize &&
            inkShotVelocity > 0 &&
            rapidFireSizeReduction > 0 && rapidFireSizeReduction <= 1.0 &&
            playerStunDuration > 0 &&
            playerMoveSpeed > 0 &&
            playerCollisionRadius > 0 &&
            stunMovementReduction > 0 && stunMovementReduction <= 1.0 &&
            gameDuration > 0 &&
            scoreUpdateInterval > 0 &&
            minimumWinMargin >= 0 &&
            fieldSize.width > 0 && fieldSize.height > 0 &&
            fieldBoundaryMargin >= 0 &&
            maxInkSpotsPerPlayer > 0
    }
}
