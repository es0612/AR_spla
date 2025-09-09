//
//  LanguageSettingsView.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import SwiftUI

// MARK: - LanguageSettingsView

/// 言語設定画面
struct LanguageSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.localization) private var localization

    var body: some View {
        NavigationView {
            RTLVStack(spacing: 20) {
                // 現在の言語表示
                currentLanguageSection

                // 言語選択リスト
                languageSelectionSection

                // RTL言語についての説明
                rtlInfoSection

                Spacer()
            }
            .rtlPadding(leading: 16, trailing: 16, top: 20)
            .navigationTitle("language_settings".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("done".localized) {
                        dismiss()
                    }
                }
            }
        }
        .rtlEnvironment()
    }

    // MARK: - Current Language Section

    private var currentLanguageSection: some View {
        RTLVStack(alignment: .leading, spacing: 8) {
            Text("current_language")
                .font(.headline)
                .rtlTextAlignment()

            Text(localization.currentLanguageDisplayName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .rtlTextAlignment()
        }
        .rtlFrameAlignment()
    }

    // MARK: - Language Selection Section

    private var languageSelectionSection: some View {
        RTLVStack(alignment: .leading, spacing: 12) {
            Text("available_languages")
                .font(.headline)
                .rtlTextAlignment()

            ForEach(Array(localization.availableLanguages.keys.sorted()), id: \.self) { languageCode in
                languageSelectionRow(for: languageCode)
            }
        }
        .rtlFrameAlignment()
    }

    private func languageSelectionRow(for languageCode: String) -> some View {
        Button(action: {
            localization.currentLanguage = languageCode

            // 言語変更時のハプティックフィードバック
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
        }) {
            RTLHStack {
                // 言語名
                Text(localization.availableLanguages[languageCode] ?? languageCode)
                    .font(.body)
                    .foregroundColor(.primary)
                    .rtlTextAlignment()

                Spacer()

                // 選択インジケーター
                if localization.currentLanguage == languageCode {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.accentColor)
                        .rtlIconFlip()
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(.secondary)
                        .rtlIconFlip()
                }
            }
            .rtlPadding(leading: 16, trailing: 16, top: 12, bottom: 12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(localization.currentLanguage == languageCode ? Color.accentColor.opacity(0.1) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - RTL Info Section

    private var rtlInfoSection: some View {
        RTLVStack(alignment: .leading, spacing: 8) {
            Text("rtl_support_info")
                .font(.headline)
                .rtlTextAlignment()

            Text("rtl_support_description")
                .font(.caption)
                .foregroundColor(.secondary)
                .rtlTextAlignment()

            // RTL言語のデモ
            if localization.isRTL {
                rtlDemoSection
            }
        }
        .rtlFrameAlignment()
    }

    private var rtlDemoSection: some View {
        RTLVStack(alignment: .leading, spacing: 4) {
            Text("rtl_demo")
                .font(.subheadline)
                .fontWeight(.medium)
                .rtlTextAlignment()

            RTLHStack {
                Text("rtl_demo_text")
                    .font(.body)
                    .rtlTextAlignment()

                Spacer()

                Image(systemName: "arrow.left")
                    .rtlIconFlip()
            }
            .rtlPadding(leading: 12, trailing: 12, top: 8, bottom: 8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.secondary.opacity(0.1))
            )
        }
    }
}

// MARK: - Preview

#Preview("Language Settings") {
    LanguageSettingsView()
        .environment(\.localization, LocalizationManager.shared)
}

#Preview("Language Settings - RTL") {
    LanguageSettingsView()
        .environment(\.localization, LocalizationManager.shared)
        .rtlPreview()
}

// MARK: - Additional Localized Strings

extension String {
    static let currentLanguage = "current_language"
    static let availableLanguages = "available_languages"
    static let rtlSupportInfo = "rtl_support_info"
    static let rtlSupportDescription = "rtl_support_description"
    static let rtlDemo = "rtl_demo"
    static let rtlDemoText = "rtl_demo_text"
}
