//
//  AccessibilitySettingsView.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/09.
//

import SwiftUI

// MARK: - AccessibilitySettingsView

/// アクセシビリティ設定画面
struct AccessibilitySettingsView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var accessibilityManager = AccessibilityManager()

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                systemStatusSection
                visualAccessibilitySection
                audioHapticSection
                colorBlindnessSection
                switchControlSection
            }
            .navigationTitle("アクセシビリティ")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Sections

    private var systemStatusSection: some View {
        Section("システム状態") {
            AccessibilityStatusRow(
                icon: "speaker.wave.3.fill",
                title: "VoiceOver",
                status: accessibilityManager.isVoiceOverRunning,
                description: "画面読み上げ機能"
            )

            AccessibilityStatusRow(
                icon: "switch.2",
                title: "スイッチコントロール",
                status: accessibilityManager.isSwitchControlRunning,
                description: "外部スイッチでの操作"
            )

            AccessibilityStatusRow(
                icon: "motion.badge.minus",
                title: "視差効果を減らす",
                status: accessibilityManager.isReduceMotionEnabled,
                description: "アニメーション効果の軽減"
            )

            AccessibilityStatusRow(
                icon: "eye.slash.fill",
                title: "透明度を下げる",
                status: accessibilityManager.isReduceTransparencyEnabled,
                description: "背景の透明度軽減"
            )

            AccessibilityStatusRow(
                icon: "circle.lefthalf.filled",
                title: "コントラストを上げる",
                status: accessibilityManager.isDarkerSystemColorsEnabled,
                description: "色のコントラスト強化"
            )
        }
    }

    private var visualAccessibilitySection: some View {
        Section("視覚的アクセシビリティ") {
            // Dynamic Type設定
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "textformat.size")
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    Text("文字サイズ")
                        .font(.headline)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("現在のサイズ: \(contentSizeCategoryDisplayName)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("サンプルテキスト")
                        .font(accessibilityManager.scaledFont(size: 16))
                        .padding(.top, 4)
                }
                .padding(.leading, 32)
            }
            .padding(.vertical, 4)

            // フォントサイズプレビュー
            VStack(alignment: .leading, spacing: 8) {
                Text("フォントサイズプレビュー")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.leading, 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("小さいテキスト")
                        .font(.system(size: accessibilityManager.accessibleFontSize(base: 12)))
                    Text("標準テキスト")
                        .font(.system(size: accessibilityManager.accessibleFontSize(base: 16)))
                    Text("大きいテキスト")
                        .font(.system(size: accessibilityManager.accessibleFontSize(base: 20)))
                }
                .padding(.leading, 32)
            }
        }
    }

    private var audioHapticSection: some View {
        Section("音声・触覚フィードバック") {
            Toggle(isOn: $accessibilityManager.audioFeedbackEnabled) {
                HStack {
                    Image(systemName: "speaker.wave.2.fill")
                        .foregroundColor(.green)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("音声フィードバック")
                            .font(.headline)
                        Text("ゲームアクションの音声通知")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)

            Toggle(isOn: $accessibilityManager.hapticFeedbackEnabled) {
                HStack {
                    Image(systemName: "hand.tap.fill")
                        .foregroundColor(.orange)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("触覚フィードバック")
                            .font(.headline)
                        Text("振動による操作フィードバック")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.vertical, 4)

            // フィードバックテスト
            VStack(alignment: .leading, spacing: 8) {
                Text("フィードバックテスト")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.leading, 32)

                HStack(spacing: 12) {
                    Button("軽い振動") {
                        accessibilityManager.performHapticFeedback(.light)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button("成功音") {
                        accessibilityManager.performAudioFeedback(.gameStart)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
                .padding(.leading, 32)
            }
        }
    }

    private var colorBlindnessSection: some View {
        Section("色覚サポート") {
            Picker("色覚異常対応", selection: $accessibilityManager.colorBlindnessSupport) {
                ForEach(ColorBlindnessType.allCases, id: \.self) { type in
                    Text(type.displayName).tag(type)
                }
            }
            .pickerStyle(.menu)

            // 色見本プレビュー
            VStack(alignment: .leading, spacing: 8) {
                Text("色見本プレビュー")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 4), spacing: 8) {
                    ColorPreviewItem(color: .red, name: "赤", accessibilityManager: accessibilityManager)
                    ColorPreviewItem(color: .blue, name: "青", accessibilityManager: accessibilityManager)
                    ColorPreviewItem(color: .green, name: "緑", accessibilityManager: accessibilityManager)
                    ColorPreviewItem(color: .yellow, name: "黄", accessibilityManager: accessibilityManager)
                    ColorPreviewItem(color: .orange, name: "橙", accessibilityManager: accessibilityManager)
                    ColorPreviewItem(color: .purple, name: "紫", accessibilityManager: accessibilityManager)
                }
            }
            .padding(.vertical, 8)
        }
    }

    private var switchControlSection: some View {
        Section("スイッチコントロール") {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "gamecontroller.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    Text("外部スイッチ対応")
                        .font(.headline)
                }

                Text("このアプリは外部スイッチでの操作に対応しています。以下のアクションが利用可能です:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 32)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• インクを発射")
                    Text("• メニューを開く")
                    Text("• 設定を変更")
                    Text("• ゲームを開始/終了")
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.leading, 40)
            }
            .padding(.vertical, 4)

            if accessibilityManager.isSwitchControlRunning {
                HStack {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.green)
                    Text("スイッチコントロールが有効です")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(.leading, 32)
            } else {
                HStack {
                    Image(systemName: "info.circle")
                        .foregroundColor(.blue)
                    Text("設定アプリでスイッチコントロールを有効にできます")
                        .font(.caption)
                        .foregroundColor(.blue)
                }
                .padding(.leading, 32)
            }
        }
    }

    // MARK: - Computed Properties

    private var contentSizeCategoryDisplayName: String {
        switch accessibilityManager.preferredContentSizeCategory {
        case .extraSmall: return "極小"
        case .small: return "小"
        case .medium: return "標準"
        case .large: return "大"
        case .extraLarge: return "特大"
        case .extraExtraLarge: return "超特大"
        case .extraExtraExtraLarge: return "極特大"
        case .accessibilityMedium: return "アクセシビリティ標準"
        case .accessibilityLarge: return "アクセシビリティ大"
        case .accessibilityExtraLarge: return "アクセシビリティ特大"
        case .accessibilityExtraExtraLarge: return "アクセシビリティ超特大"
        case .accessibilityExtraExtraExtraLarge: return "アクセシビリティ極特大"
        default: return "標準"
        }
    }
}

// MARK: - AccessibilityStatusRow

struct AccessibilityStatusRow: View {
    let icon: String
    let title: String
    let status: Bool
    let description: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(status ? .green : .gray)
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(status ? "有効" : "無効")
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(status ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                .foregroundColor(status ? .green : .gray)
                .clipShape(Capsule())
        }
        .padding(.vertical, 4)
    }
}

// MARK: - ColorPreviewItem

struct ColorPreviewItem: View {
    let color: Color
    let name: String
    let accessibilityManager: AccessibilityManager

    var body: some View {
        VStack(spacing: 4) {
            RoundedRectangle(cornerRadius: 8)
                .fill(accessibilityManager.accessibleColor(for: color))
                .frame(height: 40)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.primary.opacity(0.2), lineWidth: 1)
                )

            Text(name)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .accessibilityLabel("\(name)色のプレビュー")
        .accessibilityHint("色覚サポート設定に応じて調整された色")
    }
}

// MARK: - Preview

#Preview {
    AccessibilitySettingsView()
}
