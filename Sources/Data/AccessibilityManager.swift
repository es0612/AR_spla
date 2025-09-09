//
//  AccessibilityManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/09.
//

import SwiftUI
import UIKit

// MARK: - AccessibilityManager

/// アクセシビリティ機能を管理するクラス
@Observable
class AccessibilityManager {
    // MARK: - Properties

    /// VoiceOverが有効かどうか
    var isVoiceOverRunning: Bool {
        UIAccessibility.isVoiceOverRunning
    }

    /// スイッチコントロールが有効かどうか
    var isSwitchControlRunning: Bool {
        UIAccessibility.isSwitchControlRunning
    }

    /// 視覚的アクセシビリティが有効かどうか
    var isReduceMotionEnabled: Bool {
        UIAccessibility.isReduceMotionEnabled
    }

    /// 透明度を下げる設定が有効かどうか
    var isReduceTransparencyEnabled: Bool {
        UIAccessibility.isReduceTransparencyEnabled
    }

    /// コントラストを上げる設定が有効かどうか
    var isDarkerSystemColorsEnabled: Bool {
        UIAccessibility.isDarkerSystemColorsEnabled
    }

    /// Dynamic Typeの現在のサイズ
    @State var preferredContentSizeCategory: ContentSizeCategory = .medium

    /// 色覚異常対応の色設定
    @State var colorBlindnessSupport: ColorBlindnessType = .none

    /// 音声フィードバックの有効/無効
    @State var audioFeedbackEnabled: Bool = true

    /// 触覚フィードバックの有効/無効
    @State var hapticFeedbackEnabled: Bool = true

    // MARK: - Initialization

    init() {
        setupAccessibilityNotifications()
        loadAccessibilitySettings()
    }

    // MARK: - Notification Setup

    private func setupAccessibilityNotifications() {
        NotificationCenter.default.addObserver(
            forName: UIContentSizeCategory.didChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.updateContentSizeCategory()
        }

        NotificationCenter.default.addObserver(
            forName: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            self?.handleVoiceOverStatusChange()
        }
    }

    // MARK: - Settings Management

    private func loadAccessibilitySettings() {
        let defaults = UserDefaults.standard

        if let categoryRawValue = defaults.object(forKey: "accessibility_content_size") as? String,
           let category = ContentSizeCategory(rawValue: categoryRawValue) {
            preferredContentSizeCategory = category
        } else {
            updateContentSizeCategory()
        }

        colorBlindnessSupport = ColorBlindnessType(rawValue: defaults.string(forKey: "accessibility_color_blindness") ?? "none") ?? .none
        audioFeedbackEnabled = defaults.object(forKey: "accessibility_audio_feedback") as? Bool ?? true
        hapticFeedbackEnabled = defaults.object(forKey: "accessibility_haptic_feedback") as? Bool ?? true
    }

    private func saveAccessibilitySettings() {
        let defaults = UserDefaults.standard
        defaults.set(preferredContentSizeCategory.rawValue, forKey: "accessibility_content_size")
        defaults.set(colorBlindnessSupport.rawValue, forKey: "accessibility_color_blindness")
        defaults.set(audioFeedbackEnabled, forKey: "accessibility_audio_feedback")
        defaults.set(hapticFeedbackEnabled, forKey: "accessibility_haptic_feedback")
    }

    // MARK: - Dynamic Type Support

    private func updateContentSizeCategory() {
        preferredContentSizeCategory = ContentSizeCategory(UIApplication.shared.preferredContentSizeCategory)
        saveAccessibilitySettings()
    }

    /// Dynamic Typeに対応したフォントサイズを取得
    func scaledFont(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight)
    }

    /// アクセシビリティ用の大きなフォントサイズを取得
    func accessibleFontSize(base: CGFloat) -> CGFloat {
        let multiplier: CGFloat

        switch preferredContentSizeCategory {
        case .extraSmall, .small, .medium:
            multiplier = 1.0
        case .large:
            multiplier = 1.1
        case .extraLarge:
            multiplier = 1.2
        case .extraExtraLarge:
            multiplier = 1.3
        case .extraExtraExtraLarge:
            multiplier = 1.4
        case .accessibilityMedium:
            multiplier = 1.6
        case .accessibilityLarge:
            multiplier = 1.8
        case .accessibilityExtraLarge:
            multiplier = 2.0
        case .accessibilityExtraExtraLarge:
            multiplier = 2.2
        case .accessibilityExtraExtraExtraLarge:
            multiplier = 2.4
        default:
            multiplier = 1.0
        }

        return base * multiplier
    }

    // MARK: - VoiceOver Support

    private func handleVoiceOverStatusChange() {
        if isVoiceOverRunning {
            // VoiceOverが有効になった時の処理
            audioFeedbackEnabled = true
            saveAccessibilitySettings()
        }
    }

    /// VoiceOver用のアクセシビリティラベルを生成
    func voiceOverLabel(for gameElement: GameElement) -> String {
        switch gameElement {
        case let .inkSpot(color, position):
            return "\(color.accessibilityName)のインクスポット、位置: \(position.accessibilityDescription)"
        case let .player(name, score):
            return "プレイヤー \(name)、スコア: \(score)点"
        case .gameField:
            return "ARゲームフィールド"
        case .inkGun:
            return "インクガン、タップして発射"
        case let .scoreDisplay(playerScore, opponentScore):
            return "現在のスコア: あなた \(playerScore)点、相手 \(opponentScore)点"
        }
    }

    // MARK: - Color Blindness Support

    /// 色覚異常対応の色を取得
    func accessibleColor(for originalColor: Color, type: ColorBlindnessType = .none) -> Color {
        let supportType = type == .none ? colorBlindnessSupport : type

        switch supportType {
        case .none:
            return originalColor
        case .protanopia, .deuteranopia:
            return adjustColorForRedGreenBlindness(originalColor)
        case .tritanopia:
            return adjustColorForBlueYellowBlindness(originalColor)
        case .monochromacy:
            return convertToGrayscale(originalColor)
        }
    }

    private func adjustColorForRedGreenBlindness(_ color: Color) -> Color {
        // 赤緑色覚異常に対応した色調整
        // 実装では、赤と緑の区別がつきやすい色に変換
        if color == .red {
            return Color(red: 0.8, green: 0.2, blue: 0.2) // より濃い赤
        } else if color == .green {
            return Color(red: 0.2, green: 0.6, blue: 0.8) // 青寄りの緑
        }
        return color
    }

    private func adjustColorForBlueYellowBlindness(_ color: Color) -> Color {
        // 青黄色覚異常に対応した色調整
        if color == .blue {
            return Color(red: 0.3, green: 0.3, blue: 0.8) // より濃い青
        } else if color == .yellow {
            return Color(red: 0.9, green: 0.7, blue: 0.2) // オレンジ寄りの黄色
        }
        return color
    }

    private func convertToGrayscale(_: Color) -> Color {
        // モノクロ対応（全色覚異常）
        Color.gray
    }

    // MARK: - Haptic Feedback

    /// 触覚フィードバックを実行
    func performHapticFeedback(_ type: HapticFeedbackType) {
        guard hapticFeedbackEnabled else { return }

        switch type {
        case .light:
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        case .medium:
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
        case .heavy:
            let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
            impactFeedback.impactOccurred()
        case .success:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.success)
        case .warning:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.warning)
        case .error:
            let notificationFeedback = UINotificationFeedbackGenerator()
            notificationFeedback.notificationOccurred(.error)
        }
    }

    // MARK: - Audio Feedback

    /// 音声フィードバックを実行
    func performAudioFeedback(_ type: AudioFeedbackType) {
        guard audioFeedbackEnabled else { return }

        // システムサウンドを使用した音声フィードバック
        switch type {
        case .inkShot:
            // インク発射音（システムサウンドID: 1104）
            AudioServicesPlaySystemSound(1_104)
        case .hit:
            // ヒット音（システムサウンドID: 1105）
            AudioServicesPlaySystemSound(1_105)
        case .gameStart:
            // ゲーム開始音（システムサウンドID: 1106）
            AudioServicesPlaySystemSound(1_106)
        case .gameEnd:
            // ゲーム終了音（システムサウンドID: 1107）
            AudioServicesPlaySystemSound(1_107)
        case .error:
            // エラー音（システムサウンドID: 1073）
            AudioServicesPlaySystemSound(1_073)
        }
    }

    // MARK: - Switch Control Support

    /// スイッチコントロール用のアクションを設定
    func configureSwitchControlActions(for view: UIView, actions: [SwitchControlAction]) {
        guard isSwitchControlRunning else { return }

        var accessibilityCustomActions: [UIAccessibilityCustomAction] = []

        for action in actions {
            let customAction = UIAccessibilityCustomAction(
                name: action.name,
                target: self,
                selector: #selector(performSwitchControlAction(_:))
            )
            customAction.accessibilityHint = action.hint
            accessibilityCustomActions.append(customAction)
        }

        view.accessibilityCustomActions = accessibilityCustomActions
    }

    @objc private func performSwitchControlAction(_: UIAccessibilityCustomAction) -> Bool {
        // スイッチコントロールアクションの実行
        // 実際の実装では、アクション名に基づいて適切な処理を実行
        true
    }
}

// MARK: - ColorBlindnessType

enum ColorBlindnessType: String, CaseIterable {
    case none
    case protanopia // 1型色覚（赤色盲）
    case deuteranopia // 2型色覚（緑色盲）
    case tritanopia // 3型色覚（青色盲）
    case monochromacy // 全色盲

    var displayName: String {
        switch self {
        case .none: return "なし"
        case .protanopia: return "1型色覚（赤色盲）"
        case .deuteranopia: return "2型色覚（緑色盲）"
        case .tritanopia: return "3型色覚（青色盲）"
        case .monochromacy: return "全色盲"
        }
    }
}

// MARK: - HapticFeedbackType

enum HapticFeedbackType {
    case light, medium, heavy
    case success, warning, error
}

// MARK: - AudioFeedbackType

enum AudioFeedbackType {
    case inkShot, hit, gameStart, gameEnd, error
}

// MARK: - GameElement

enum GameElement {
    case inkSpot(color: Color, position: String)
    case player(name: String, score: Int)
    case gameField
    case inkGun
    case scoreDisplay(playerScore: Int, opponentScore: Int)
}

// MARK: - SwitchControlAction

struct SwitchControlAction {
    let name: String
    let hint: String
    let action: () -> Void
}

// MARK: - Extensions

extension Color {
    var accessibilityName: String {
        if self == .red { return "赤" }
        if self == .blue { return "青" }
        if self == .green { return "緑" }
        if self == .yellow { return "黄" }
        if self == .orange { return "オレンジ" }
        if self == .purple { return "紫" }
        return "色"
    }
}

extension String {
    var accessibilityDescription: String {
        // 位置情報をアクセシビリティ用に変換
        self
    }
}

extension ContentSizeCategory {
    init(_ uiContentSizeCategory: UIContentSizeCategory) {
        switch uiContentSizeCategory {
        case .extraSmall: self = .extraSmall
        case .small: self = .small
        case .medium: self = .medium
        case .large: self = .large
        case .extraLarge: self = .extraLarge
        case .extraExtraLarge: self = .extraExtraLarge
        case .extraExtraExtraLarge: self = .extraExtraExtraLarge
        case .accessibilityMedium: self = .accessibilityMedium
        case .accessibilityLarge: self = .accessibilityLarge
        case .accessibilityExtraLarge: self = .accessibilityExtraLarge
        case .accessibilityExtraExtraLarge: self = .accessibilityExtraExtraLarge
        case .accessibilityExtraExtraExtraLarge: self = .accessibilityExtraExtraExtraLarge
        default: self = .medium
        }
    }
}

import AudioToolbox
