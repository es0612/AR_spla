//
//  RegionalSettingsView.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import SwiftUI

// MARK: - RegionalSettingsView

struct RegionalSettingsView: View {
    @Environment(\.regionalSettings) private var regionalSettings
    @Environment(\.dismiss) private var dismiss
    @State private var showingAgeVerification = false
    @State private var userAge: Int = 13

    var body: some View {
        NavigationView {
            Form {
                regionSection
                culturalSection
                ratingSection
                privacySection
                playTimeSection

                if regionalSettings.currentRegion != .global {
                    complianceSection
                }
            }
            .navigationTitle("地域設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        regionalSettings.saveSettings()
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAgeVerification) {
            AgeVerificationView(userAge: $userAge)
        }
    }

    // MARK: - セクション

    private var regionSection: some View {
        Section("地域設定") {
            Picker("地域", selection: $regionalSettings.currentRegion) {
                ForEach(RegionalSettingsManager.Region.allCases, id: \.self) { region in
                    Text(region.displayName)
                        .tag(region)
                }
            }
            .pickerStyle(.menu)

            HStack {
                Text("言語")
                Spacer()
                Text(regionalSettings.currentRegion.languageCode.uppercased())
                    .foregroundColor(.secondary)
            }
        } footer: {
            Text("地域設定により、ゲームの内容や機能が調整されます。")
        }
    }

    private var culturalSection: some View {
        Section("文化的配慮") {
            Picker("暴力表現レベル", selection: $regionalSettings.violenceLevel) {
                ForEach(RegionalSettingsManager.ViolenceLevel.allCases, id: \.self) { level in
                    Text(level.displayName)
                        .tag(level)
                }
            }
            .pickerStyle(.segmented)

            Toggle("色覚配慮", isOn: $regionalSettings.colorBlindnessSupport)

            Toggle("文化的に適切な色の使用", isOn: $regionalSettings.culturallyAppropriateColors)

            Toggle("宗教的配慮", isOn: $regionalSettings.religiousConsiderations)
        } footer: {
            Text("地域の文化や宗教的背景に配慮した設定を行います。")
        }
    }

    private var ratingSection: some View {
        Section("年齢レーティング") {
            Picker("対象年齢", selection: $regionalSettings.ageRating) {
                ForEach(RegionalSettingsManager.AgeRating.allCases, id: \.self) { rating in
                    Text(rating.displayName)
                        .tag(rating)
                }
            }
            .pickerStyle(.menu)

            Button("年齢確認") {
                showingAgeVerification = true
            }
            .foregroundColor(.blue)

            if userAge < regionalSettings.ageRating.minimumAge {
                Label("年齢制限により一部機能が制限されます", systemImage: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                    .font(.caption)
            }
        } footer: {
            Text("年齢レーティングに基づいて適切なコンテンツを提供します。")
        }
    }

    private var privacySection: some View {
        Section("プライバシーとデータ") {
            Toggle("データ収集制限", isOn: $regionalSettings.dataCollectionRestricted)

            Toggle("広告表示制限", isOn: $regionalSettings.advertisingRestricted)

            Toggle("ソーシャル機能制限", isOn: $regionalSettings.socialFeaturesRestricted)

            if let privacyURL = regionalSettings.getPrivacyPolicyURL() {
                Link("プライバシーポリシー", destination: privacyURL)
                    .foregroundColor(.blue)
            }

            if let termsURL = regionalSettings.getTermsOfServiceURL() {
                Link("利用規約", destination: termsURL)
                    .foregroundColor(.blue)
            }
        } footer: {
            Text("地域の法規制に準拠したプライバシー設定を行います。")
        }
    }

    private var playTimeSection: some View {
        Section("プレイ時間管理") {
            VStack(alignment: .leading, spacing: 8) {
                Text("推奨プレイ時間")
                    .font(.subheadline)

                HStack {
                    Text("\(Int(regionalSettings.recommendedPlayDuration / 60))分")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { regionalSettings.recommendedPlayDuration },
                            set: { regionalSettings.recommendedPlayDuration = $0 }
                        ),
                        in: 60 ... 300,
                        step: 30
                    )
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("休憩推奨間隔")
                    .font(.subheadline)

                HStack {
                    Text("\(Int(regionalSettings.breakRecommendationInterval / 60))分")
                    Spacer()
                    Slider(
                        value: Binding(
                            get: { regionalSettings.breakRecommendationInterval },
                            set: { regionalSettings.breakRecommendationInterval = $0 }
                        ),
                        in: 600 ... 3_600,
                        step: 300
                    )
                }
            }
        } footer: {
            Text("健康的なゲームプレイのための時間管理設定です。")
        }
    }

    private var complianceSection: some View {
        Section("コンプライアンス情報") {
            VStack(alignment: .leading, spacing: 12) {
                complianceItem(
                    title: "COPPA準拠",
                    status: regionalSettings.dataCollectionRestricted && regionalSettings.currentRegion == .unitedStates,
                    description: "13歳未満のユーザーのデータ収集を制限"
                )

                complianceItem(
                    title: "GDPR準拠",
                    status: regionalSettings.dataCollectionRestricted && regionalSettings.currentRegion == .europe,
                    description: "EU一般データ保護規則に準拠"
                )

                complianceItem(
                    title: "年齢確認",
                    status: userAge >= regionalSettings.ageRating.minimumAge,
                    description: "適切な年齢レーティングの確認"
                )

                complianceItem(
                    title: "文化的配慮",
                    status: regionalSettings.culturallyAppropriateColors && regionalSettings.religiousConsiderations,
                    description: "地域の文化的背景への配慮"
                )
            }
        }
    }

    private func complianceItem(title: String, status: Bool, description: String) -> some View {
        HStack {
            Image(systemName: status ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(status ? .green : .red)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)

                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()
        }
    }
}

// MARK: - AgeVerificationView

struct AgeVerificationView: View {
    @Binding var userAge: Int
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                Image(systemName: "person.badge.shield.checkmark")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)

                Text("年齢確認")
                    .font(.title)
                    .fontWeight(.bold)

                Text("適切なコンテンツを提供するため、年齢の確認が必要です。")
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                VStack(spacing: 16) {
                    Text("あなたの年齢を選択してください")
                        .font(.headline)

                    Picker("年齢", selection: $userAge) {
                        ForEach(1 ... 100, id: \.self) { age in
                            Text("\(age)歳")
                                .tag(age)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 120)
                }

                Spacer()
            }
            .padding()
            .navigationTitle("年齢確認")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("確認") {
                        UserDefaults.standard.set(userAge, forKey: "user_age")
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RegionalSettingsView()
        .environment(\.regionalSettings, RegionalSettingsManager.shared)
}

#Preview("年齢確認") {
    AgeVerificationView(userAge: .constant(13))
}
