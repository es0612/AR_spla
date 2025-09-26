//
//  RegionalSettingsManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import Foundation
import SwiftUI

// MARK: - RegionalSettingsManager

/// 地域別設定を管理するクラス
@Observable
class RegionalSettingsManager {
    static let shared = RegionalSettingsManager()

    // MARK: - 地域設定

    /// 現在の地域設定
    var currentRegion: Region {
        didSet {
            UserDefaults.standard.set(currentRegion.rawValue, forKey: "selected_region")
            applyRegionalSettings()
        }
    }

    /// サポートされている地域
    enum Region: String, CaseIterable {
        case japan = "jp"
        case unitedStates = "us"
        case europe = "eu"
        case korea = "kr"
        case china = "cn"
        case global

        var displayName: String {
            switch self {
            case .japan: return "日本"
            case .unitedStates: return "United States"
            case .europe: return "Europe"
            case .korea: return "한국"
            case .china: return "中国"
            case .global: return "Global"
            }
        }

        var languageCode: String {
            switch self {
            case .japan: return "ja"
            case .unitedStates: return "en"
            case .europe: return "en"
            case .korea: return "ko"
            case .china: return "zh"
            case .global: return "en"
            }
        }
    }

    // MARK: - 文化的配慮設定

    /// 暴力表現の調整レベル
    enum ViolenceLevel: String, CaseIterable {
        case minimal
        case moderate
        case standard

        var displayName: String {
            switch self {
            case .minimal: return "最小限"
            case .moderate: return "控えめ"
            case .standard: return "標準"
            }
        }
    }

    /// 現在の暴力表現レベル
    var violenceLevel: ViolenceLevel = .standard

    /// 色覚配慮設定
    var colorBlindnessSupport: Bool = false

    /// 文化的に適切な色の使用
    var culturallyAppropriateColors: Bool = true

    /// 宗教的配慮（特定の色や形状の回避）
    var religiousConsiderations: Bool = false

    // MARK: - レーティング要件

    /// 年齢レーティング
    enum AgeRating: String, CaseIterable {
        case everyone // 全年齢
        case everyone10Plus = "10+" // 10歳以上
        case teen // 13歳以上
        case mature // 17歳以上

        var displayName: String {
            switch self {
            case .everyone: return "全年齢"
            case .everyone10Plus: return "10歳以上"
            case .teen: return "13歳以上"
            case .mature: return "17歳以上"
            }
        }

        var minimumAge: Int {
            switch self {
            case .everyone: return 0
            case .everyone10Plus: return 10
            case .teen: return 13
            case .mature: return 17
            }
        }
    }

    /// 現在の年齢レーティング
    var ageRating: AgeRating = .everyone10Plus

    /// データ収集の制限（COPPA、GDPR対応）
    var dataCollectionRestricted: Bool = false

    /// 広告表示の制限
    var advertisingRestricted: Bool = false

    /// ソーシャル機能の制限
    var socialFeaturesRestricted: Bool = false

    // MARK: - 地域別ゲーム設定

    /// 地域別のゲームバランス調整
    var regionalGameBalance: GameBalanceSettings?

    /// 地域別の禁止色設定
    var prohibitedColors: Set<UIColor> = []

    /// 地域別の推奨プレイ時間
    var recommendedPlayDuration: TimeInterval = 180

    /// 地域別の休憩推奨間隔
    var breakRecommendationInterval: TimeInterval = 1_800 // 30分

    // MARK: - 初期化

    private init() {
        // 保存された地域設定を読み込み
        let savedRegion = UserDefaults.standard.string(forKey: "selected_region")

        if let saved = savedRegion, let region = Region(rawValue: saved) {
            currentRegion = region
        } else {
            // システムの地域設定から推測
            currentRegion = .global // 一時的にデフォルト値を設定
        }

        // 実際の地域検出は初期化後に実行
        if currentRegion == .global {
            currentRegion = detectSystemRegion()
        }

        loadSettings()
        applyRegionalSettings()
    }

    // MARK: - システム地域の検出

    private func detectSystemRegion() -> Region {
        let locale = Locale.current

        guard let regionCode = locale.region?.identifier else {
            return .global
        }

        switch regionCode.uppercased() {
        case "JP":
            return .japan
        case "US":
            return .unitedStates
        case "KR":
            return .korea
        case "CN", "HK", "TW":
            return .china
        case let code where ["GB", "DE", "FR", "IT", "ES", "NL", "SE", "NO", "DK", "FI"].contains(code):
            return .europe
        default:
            return .global
        }
    }

    // MARK: - 地域設定の適用

    private func applyRegionalSettings() {
        switch currentRegion {
        case .japan:
            applyJapanSettings()
        case .unitedStates:
            applyUSSettings()
        case .europe:
            applyEuropeSettings()
        case .korea:
            applyKoreaSettings()
        case .china:
            applyChinaSettings()
        case .global:
            applyGlobalSettings()
        }

        // ローカライゼーション設定も更新
        LocalizationManager.shared.currentLanguage = currentRegion.languageCode
    }

    // MARK: - 地域別設定の実装

    private func applyJapanSettings() {
        // 日本の設定
        ageRating = .everyone10Plus
        violenceLevel = .moderate
        colorBlindnessSupport = true
        culturallyAppropriateColors = true
        religiousConsiderations = false
        dataCollectionRestricted = false
        advertisingRestricted = false
        socialFeaturesRestricted = false
        recommendedPlayDuration = 180
        breakRecommendationInterval = 1_800

        // 日本では赤色の使用に注意（血を連想させる可能性）
        prohibitedColors = []
    }

    private func applyUSSettings() {
        // アメリカの設定
        ageRating = .everyone10Plus
        violenceLevel = .standard
        colorBlindnessSupport = true
        culturallyAppropriateColors = true
        religiousConsiderations = false
        dataCollectionRestricted = true // COPPA対応
        advertisingRestricted = true
        socialFeaturesRestricted = true
        recommendedPlayDuration = 180
        breakRecommendationInterval = 3_600 // 1時間

        prohibitedColors = []
    }

    private func applyEuropeSettings() {
        // ヨーロッパの設定
        ageRating = .everyone10Plus
        violenceLevel = .moderate
        colorBlindnessSupport = true
        culturallyAppropriateColors = true
        religiousConsiderations = true
        dataCollectionRestricted = true // GDPR対応
        advertisingRestricted = true
        socialFeaturesRestricted = false
        recommendedPlayDuration = 180
        breakRecommendationInterval = 1_800

        prohibitedColors = []
    }

    private func applyKoreaSettings() {
        // 韓国の設定
        ageRating = .everyone10Plus
        violenceLevel = .minimal
        colorBlindnessSupport = true
        culturallyAppropriateColors = true
        religiousConsiderations = false
        dataCollectionRestricted = true
        advertisingRestricted = false
        socialFeaturesRestricted = false
        recommendedPlayDuration = 120 // 韓国では短めのセッション推奨
        breakRecommendationInterval = 1_200 // 20分

        prohibitedColors = []
    }

    private func applyChinaSettings() {
        // 中国の設定
        ageRating = .everyone
        violenceLevel = .minimal
        colorBlindnessSupport = true
        culturallyAppropriateColors = true
        religiousConsiderations = true
        dataCollectionRestricted = true
        advertisingRestricted = false
        socialFeaturesRestricted = true // ソーシャル機能制限
        recommendedPlayDuration = 90 // 中国では短いセッション推奨
        breakRecommendationInterval = 900 // 15分

        // 中国では特定の色に文化的意味があるため配慮
        prohibitedColors = []
    }

    private func applyGlobalSettings() {
        // グローバル設定（最も制限的）
        ageRating = .everyone10Plus
        violenceLevel = .moderate
        colorBlindnessSupport = true
        culturallyAppropriateColors = true
        religiousConsiderations = true
        dataCollectionRestricted = true
        advertisingRestricted = true
        socialFeaturesRestricted = false
        recommendedPlayDuration = 180
        breakRecommendationInterval = 1_800

        prohibitedColors = []
    }

    // MARK: - 設定の保存・読み込み

    func saveSettings() {
        let defaults = UserDefaults.standard

        defaults.set(currentRegion.rawValue, forKey: "selected_region")
        defaults.set(violenceLevel.rawValue, forKey: "violence_level")
        defaults.set(colorBlindnessSupport, forKey: "color_blindness_support")
        defaults.set(culturallyAppropriateColors, forKey: "culturally_appropriate_colors")
        defaults.set(religiousConsiderations, forKey: "religious_considerations")
        defaults.set(ageRating.rawValue, forKey: "age_rating")
        defaults.set(dataCollectionRestricted, forKey: "data_collection_restricted")
        defaults.set(advertisingRestricted, forKey: "advertising_restricted")
        defaults.set(socialFeaturesRestricted, forKey: "social_features_restricted")
        defaults.set(recommendedPlayDuration, forKey: "recommended_play_duration")
        defaults.set(breakRecommendationInterval, forKey: "break_recommendation_interval")
    }

    private func loadSettings() {
        let defaults = UserDefaults.standard

        if let violenceLevelRaw = defaults.object(forKey: "violence_level") as? String,
           let level = ViolenceLevel(rawValue: violenceLevelRaw) {
            violenceLevel = level
        }

        colorBlindnessSupport = defaults.object(forKey: "color_blindness_support") as? Bool ?? false
        culturallyAppropriateColors = defaults.object(forKey: "culturally_appropriate_colors") as? Bool ?? true
        religiousConsiderations = defaults.object(forKey: "religious_considerations") as? Bool ?? false

        if let ageRatingRaw = defaults.object(forKey: "age_rating") as? String,
           let rating = AgeRating(rawValue: ageRatingRaw) {
            ageRating = rating
        }

        dataCollectionRestricted = defaults.object(forKey: "data_collection_restricted") as? Bool ?? false
        advertisingRestricted = defaults.object(forKey: "advertising_restricted") as? Bool ?? false
        socialFeaturesRestricted = defaults.object(forKey: "social_features_restricted") as? Bool ?? false
        recommendedPlayDuration = defaults.object(forKey: "recommended_play_duration") as? TimeInterval ?? 180
        breakRecommendationInterval = defaults.object(forKey: "break_recommendation_interval") as? TimeInterval ?? 1_800
    }

    // MARK: - ユーティリティメソッド

    /// 現在の地域設定に基づいてゲームバランスを調整
    func adjustGameBalance(_ balance: GameBalanceSettings) {
        // 地域別の推奨プレイ時間を適用
        balance.gameDuration = min(balance.gameDuration, recommendedPlayDuration)

        // 暴力表現レベルに基づく調整
        switch violenceLevel {
        case .minimal:
            // より穏やかな表現に調整
            balance.playerStunDuration = max(balance.playerStunDuration * 0.7, 1.0)
        case .moderate:
            // 中程度の調整
            balance.playerStunDuration = max(balance.playerStunDuration * 0.85, 1.5)
        case .standard:
            // 標準設定のまま
            break
        }
    }

    /// 色が地域的に適切かどうかを判定
    func isColorAppropriate(_ color: UIColor) -> Bool {
        guard culturallyAppropriateColors else { return true }
        return !prohibitedColors.contains(color)
    }

    /// 年齢制限チェック
    func isAgeAppropriate(userAge: Int) -> Bool {
        userAge >= ageRating.minimumAge
    }

    /// データ収集が許可されているかチェック
    func isDataCollectionAllowed(userAge: Int) -> Bool {
        if dataCollectionRestricted, userAge < 13 {
            return false
        }
        return true
    }

    /// ソーシャル機能が利用可能かチェック
    func areSocialFeaturesAvailable(userAge: Int) -> Bool {
        if socialFeaturesRestricted {
            return false
        }
        if userAge < ageRating.minimumAge {
            return false
        }
        return true
    }

    /// 休憩推奨メッセージを表示すべきかチェック
    func shouldShowBreakRecommendation(playTime: TimeInterval) -> Bool {
        playTime >= breakRecommendationInterval
    }

    /// 地域別のプライバシーポリシーURLを取得
    func getPrivacyPolicyURL() -> URL? {
        let baseURL = "https://example.com/privacy"
        let regionCode = currentRegion.rawValue
        return URL(string: "\(baseURL)/\(regionCode)")
    }

    /// 地域別の利用規約URLを取得
    func getTermsOfServiceURL() -> URL? {
        let baseURL = "https://example.com/terms"
        let regionCode = currentRegion.rawValue
        return URL(string: "\(baseURL)/\(regionCode)")
    }
}

// MARK: - RegionalSettingsEnvironmentKey

struct RegionalSettingsEnvironmentKey: EnvironmentKey {
    static let defaultValue = RegionalSettingsManager.shared
}

extension EnvironmentValues {
    var regionalSettings: RegionalSettingsManager {
        get { self[RegionalSettingsEnvironmentKey.self] }
        set { self[RegionalSettingsEnvironmentKey.self] = newValue }
    }
}
