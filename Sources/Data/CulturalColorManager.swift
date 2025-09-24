//
//  CulturalColorManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import SwiftUI
import UIKit

// MARK: - CulturalColorManager

/// 文化的配慮に基づいた色管理クラス
@Observable
class CulturalColorManager {
    static let shared = CulturalColorManager()

    // MARK: - 基本色定義

    /// デフォルトのプレイヤー色
    private let defaultPlayerColors: [UIColor] = [
        UIColor.systemBlue,
        UIColor.systemOrange,
        UIColor.systemGreen,
        UIColor.systemPurple,
        UIColor.systemPink,
        UIColor.systemTeal
    ]

    /// 地域別の色制限
    private var regionalColorRestrictions: [RegionalSettingsManager.Region: Set<UIColor>] = [:]

    /// 文化的に敏感な色の組み合わせ
    private var culturallyProblematicCombinations: Set<ColorCombination> = []

    // MARK: - 色の組み合わせ構造体

    struct ColorCombination: Hashable {
        let color1: UIColor
        let color2: UIColor
        let region: RegionalSettingsManager.Region
        let reason: String

        func hash(into hasher: inout Hasher) {
            hasher.combine(color1.cgColor.components)
            hasher.combine(color2.cgColor.components)
            hasher.combine(region)
        }

        static func == (lhs: ColorCombination, rhs: ColorCombination) -> Bool {
            lhs.color1.isEqual(rhs.color1) &&
                lhs.color2.isEqual(rhs.color2) &&
                lhs.region == rhs.region
        }
    }

    // MARK: - 初期化

    private init() {
        setupRegionalColorRestrictions()
        setupCulturallyProblematicCombinations()
    }

    // MARK: - 地域別色制限の設定

    private func setupRegionalColorRestrictions() {
        // 中国: 特定の色に文化的意味がある
        regionalColorRestrictions[.china] = [
            UIColor.systemRed, // 幸運の色だが、ゲームでは血を連想させる可能性
            UIColor.black, // 不吉とされる場合がある
            UIColor.white // 喪の色として使われる
        ]

        // 韓国: 特定の色の組み合わせに注意
        regionalColorRestrictions[.korea] = [
            UIColor.systemRed // 名前を赤で書くことは不吉とされる
        ]

        // 日本: 比較的制限は少ないが、一部配慮が必要
        regionalColorRestrictions[.japan] = []

        // イスラム圏（中東・一部アジア）: 宗教的配慮
        // 注意: 現在のRegionにはないが、将来の拡張を考慮

        // 欧州: GDPR準拠、アクセシビリティ重視
        regionalColorRestrictions[.europe] = []

        // アメリカ: 多様性への配慮
        regionalColorRestrictions[.unitedStates] = []

        // グローバル: 最も制限的
        regionalColorRestrictions[.global] = []
    }

    private func setupCulturallyProblematicCombinations() {
        let redColor = UIColor.systemRed
        let whiteColor = UIColor.white
        let blackColor = UIColor.black
        let greenColor = UIColor.systemGreen

        // 中国での問題のある組み合わせ
        culturallyProblematicCombinations.insert(
            ColorCombination(
                color1: redColor,
                color2: whiteColor,
                region: .china,
                reason: "赤と白の組み合わせは葬儀を連想させる"
            )
        )

        // 韓国での問題のある組み合わせ
        culturallyProblematicCombinations.insert(
            ColorCombination(
                color1: redColor,
                color2: blackColor,
                region: .korea,
                reason: "赤と黒の組み合わせは不吉とされる"
            )
        )

        // イスラム圏での配慮（将来の拡張用）
        // 緑色は神聖な色とされるため、ゲームでの使用に注意が必要
    }

    // MARK: - 色の適切性チェック

    /// 指定された色が現在の地域設定で適切かどうかを判定
    func isColorAppropriate(_ color: UIColor) -> Bool {
        let regionalSettings = RegionalSettingsManager.shared

        // 文化的配慮が無効の場合は全て許可
        guard regionalSettings.culturallyAppropriateColors else {
            return true
        }

        // 地域別の制限色をチェック
        if let restrictedColors = regionalColorRestrictions[regionalSettings.currentRegion] {
            return !restrictedColors.contains { $0.isEqual(color) }
        }

        return true
    }

    /// 色の組み合わせが文化的に適切かどうかを判定
    func areColorsAppropriate(_ color1: UIColor, _ color2: UIColor) -> Bool {
        let regionalSettings = RegionalSettingsManager.shared

        // 文化的配慮が無効の場合は全て許可
        guard regionalSettings.culturallyAppropriateColors else {
            return true
        }

        // 個別の色をチェック
        guard isColorAppropriate(color1), isColorAppropriate(color2) else {
            return false
        }

        // 組み合わせをチェック
        let combination1 = ColorCombination(
            color1: color1,
            color2: color2,
            region: regionalSettings.currentRegion,
            reason: ""
        )

        let combination2 = ColorCombination(
            color1: color2,
            color2: color1,
            region: regionalSettings.currentRegion,
            reason: ""
        )

        return !culturallyProblematicCombinations.contains { combination in
            combination.region == regionalSettings.currentRegion &&
                (combination.color1.isEqual(color1) && combination.color2.isEqual(color2) ||
                    combination.color1.isEqual(color2) && combination.color2.isEqual(color1))
        }
    }

    // MARK: - 適切な色の取得

    /// 現在の地域設定に適した色のリストを取得
    func getApproprateColors() -> [UIColor] {
        defaultPlayerColors.filter { isColorAppropriate($0) }
    }

    /// 2つのプレイヤー用の適切な色の組み合わせを取得
    func getAppropriateTwoPlayerColors() -> (UIColor, UIColor)? {
        let appropriateColors = getApproprateColors()

        // 全ての組み合わせをチェック
        for i in 0 ..< appropriateColors.count {
            for j in (i + 1) ..< appropriateColors.count {
                let color1 = appropriateColors[i]
                let color2 = appropriateColors[j]

                if areColorsAppropriate(color1, color2) {
                    return (color1, color2)
                }
            }
        }

        // 適切な組み合わせが見つからない場合はデフォルト
        return (UIColor.systemBlue, UIColor.systemOrange)
    }

    /// 色覚配慮を考慮した色の組み合わせを取得
    func getColorBlindFriendlyColors() -> (UIColor, UIColor) {
        let regionalSettings = RegionalSettingsManager.shared

        if regionalSettings.colorBlindnessSupport {
            // 色覚配慮用の色（形状や明度で区別しやすい）
            let color1 = UIColor.systemBlue // 青系
            let color2 = UIColor.systemOrange // オレンジ系（赤緑色覚異常でも区別可能）

            if areColorsAppropriate(color1, color2) {
                return (color1, color2)
            }
        }

        // 通常の色選択にフォールバック
        return getAppropriateTwoPlayerColors() ?? (UIColor.systemBlue, UIColor.systemOrange)
    }

    // MARK: - 色の代替案提供

    /// 不適切な色の代替案を提供
    func getAlternativeColor(for color: UIColor) -> UIColor {
        if isColorAppropriate(color) {
            return color
        }

        // 適切な色から最も近い色を選択
        let appropriateColors = getApproprateColors()

        if appropriateColors.isEmpty {
            return UIColor.systemBlue // フォールバック
        }

        // 色相の近さで判定（簡易実装）
        return appropriateColors.first ?? UIColor.systemBlue
    }

    /// 文化的配慮に関する説明を取得
    func getCulturalConsiderationMessage() -> String? {
        let regionalSettings = RegionalSettingsManager.shared

        guard regionalSettings.culturallyAppropriateColors else {
            return nil
        }

        switch regionalSettings.currentRegion {
        case .china:
            return "中国の文化的背景を考慮し、一部の色の使用を制限しています。"
        case .korea:
            return "韓国の文化的背景を考慮し、特定の色の組み合わせを避けています。"
        case .japan:
            return "日本の文化的背景を考慮した色選択を行っています。"
        case .europe:
            return "ヨーロッパのアクセシビリティ基準に準拠した色選択を行っています。"
        case .unitedStates:
            return "多様性への配慮を考慮した色選択を行っています。"
        case .global:
            return "グローバルな文化的配慮を考慮した色選択を行っています。"
        }
    }

    // MARK: - デバッグ・テスト用

    /// 現在の制限情報を取得（デバッグ用）
    func getCurrentRestrictions() -> (restrictedColors: Set<UIColor>, problematicCombinations: [ColorCombination]) {
        let regionalSettings = RegionalSettingsManager.shared
        let restrictedColors = regionalColorRestrictions[regionalSettings.currentRegion] ?? []
        let problematicCombinations = culturallyProblematicCombinations.filter {
            $0.region == regionalSettings.currentRegion
        }

        return (restrictedColors, Array(problematicCombinations))
    }
}

// MARK: - UIColor拡張

extension UIColor {
    /// 色の等価性を判定
    func isEqual(_ other: UIColor) -> Bool {
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0

        getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        other.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)

        let tolerance: CGFloat = 0.01
        return abs(r1 - r2) < tolerance &&
            abs(g1 - g2) < tolerance &&
            abs(b1 - b2) < tolerance &&
            abs(a1 - a2) < tolerance
    }
}

// MARK: - SwiftUI Environment

struct CulturalColorEnvironmentKey: EnvironmentKey {
    static let defaultValue = CulturalColorManager.shared
}

extension EnvironmentValues {
    var culturalColors: CulturalColorManager {
        get { self[CulturalColorEnvironmentKey.self] }
        set { self[CulturalColorEnvironmentKey.self] = newValue }
    }
}
