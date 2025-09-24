//
//  PlayTimeWarningView.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import SwiftUI

struct PlayTimeWarningView: View {
    @Environment(\.playTimeManager) private var playTimeManager
    @Environment(\.regionalSettings) private var regionalSettings
    @Environment(\.dismiss) private var dismiss

    let warningType: WarningType

    enum WarningType {
        case breakRecommendation
        case timeLimit
        case regionalRestriction
        case dailyLimit
    }

    var body: some View {
        VStack(spacing: 24) {
            warningIcon

            VStack(spacing: 16) {
                Text(warningTitle)
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)

                Text(warningMessage)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }

            playTimeStatistics

            actionButtons
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding()
    }

    // MARK: - 警告アイコン

    private var warningIcon: some View {
        Group {
            switch warningType {
            case .breakRecommendation:
                Image(systemName: "clock.badge.exclamationmark")
                    .font(.system(size: 60))
                    .foregroundColor(.orange)

            case .timeLimit, .dailyLimit:
                Image(systemName: "hourglass.tophalf.filled")
                    .font(.system(size: 60))
                    .foregroundColor(.red)

            case .regionalRestriction:
                Image(systemName: "location.slash")
                    .font(.system(size: 60))
                    .foregroundColor(.purple)
            }
        }
    }

    // MARK: - 警告タイトル

    private var warningTitle: String {
        switch warningType {
        case .breakRecommendation:
            return "休憩をお勧めします"
        case .timeLimit:
            return "連続プレイ時間の制限"
        case .regionalRestriction:
            return "地域制限による利用制限"
        case .dailyLimit:
            return "1日の利用制限に達しました"
        }
    }

    // MARK: - 警告メッセージ

    private var warningMessage: String {
        let statistics = playTimeManager.getPlayTimeStatistics()

        switch warningType {
        case .breakRecommendation:
            let sessionTime = playTimeManager.formatDuration(statistics.currentSession)
            return "連続して\(sessionTime)プレイしています。健康のため、少し休憩を取ることをお勧めします。"

        case .timeLimit:
            let limitTime = playTimeManager.formatDuration(statistics.continuousLimit)
            return "連続プレイ時間が\(limitTime)に達しました。目の疲れや体の負担を軽減するため、休憩を取ってください。"

        case .regionalRestriction:
            return getRegionalRestrictionMessage()

        case .dailyLimit:
            let dailyTime = playTimeManager.formatDuration(statistics.dailyLimit)
            return "本日の推奨プレイ時間\(dailyTime)に達しました。明日また楽しくプレイしましょう。"
        }
    }

    private func getRegionalRestrictionMessage() -> String {
        let userAge = UserDefaults.standard.integer(forKey: "user_age")

        switch regionalSettings.currentRegion {
        case .korea:
            if userAge < 16 {
                return "韓国の青少年保護法により、深夜時間帯（午前0時〜6時）のゲーム利用が制限されています。"
            }

        case .china:
            if userAge < 18 {
                let currentHour = Calendar.current.component(.hour, from: Date())
                let isWeekday = Calendar.current.component(.weekday, from: Date()) >= 2 && Calendar.current.component(.weekday, from: Date()) <= 6

                if isWeekday, currentHour >= 22 || currentHour < 8 {
                    return "中国の未成年者保護規定により、平日の午後10時から翌朝8時までのゲーム利用が制限されています。"
                } else if !isWeekday, currentHour >= 21 || currentHour < 8 {
                    return "中国の未成年者保護規定により、休日の午後9時から翌朝8時までのゲーム利用が制限されています。"
                }
            }

        default:
            break
        }

        return "現在の地域設定により、ゲームの利用が制限されています。"
    }

    // MARK: - プレイ時間統計

    private var playTimeStatistics: some View {
        let statistics = playTimeManager.getPlayTimeStatistics()

        return VStack(spacing: 12) {
            HStack {
                Text("今回のセッション")
                Spacer()
                Text(playTimeManager.formatDuration(statistics.currentSession))
                    .fontWeight(.medium)
            }

            HStack {
                Text("今日の合計")
                Spacer()
                Text(playTimeManager.formatDuration(statistics.todayTotal))
                    .fontWeight(.medium)
            }

            if warningType == .dailyLimit || warningType == .timeLimit {
                HStack {
                    Text("推奨制限時間")
                    Spacer()
                    Text(playTimeManager.formatDuration(statistics.dailyLimit))
                        .fontWeight(.medium)
                        .foregroundColor(.red)
                }
            }

            // プログレスバー
            VStack(alignment: .leading, spacing: 4) {
                Text("今日の利用状況")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ProgressView(value: statistics.todayProgress)
                    .progressViewStyle(LinearProgressViewStyle(tint: progressBarColor(for: statistics.todayProgress)))

                HStack {
                    Text("0%")
                    Spacer()
                    Text("100%")
                }
                .font(.caption2)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }

    private func progressBarColor(for progress: Double) -> Color {
        if progress < 0.7 {
            return .green
        } else if progress < 0.9 {
            return .orange
        } else {
            return .red
        }
    }

    // MARK: - アクションボタン

    private var actionButtons: some View {
        VStack(spacing: 12) {
            switch warningType {
            case .breakRecommendation:
                Button("5分休憩する") {
                    playTimeManager.pauseSession()
                    scheduleBreakReminder(minutes: 5)
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("10分休憩する") {
                    playTimeManager.pauseSession()
                    scheduleBreakReminder(minutes: 10)
                    dismiss()
                }
                .buttonStyle(.bordered)

                Button("続けてプレイする") {
                    dismiss()
                }
                .buttonStyle(.borderless)
                .foregroundColor(.secondary)

            case .timeLimit:
                Button("休憩する") {
                    playTimeManager.pauseSession()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("ゲームを終了") {
                    playTimeManager.endSession()
                    dismiss()
                }
                .buttonStyle(.bordered)

            case .regionalRestriction, .dailyLimit:
                Button("ゲームを終了") {
                    playTimeManager.endSession()
                    dismiss()
                }
                .buttonStyle(.borderedProminent)

                Button("設定を確認") {
                    // 設定画面を開く処理
                    dismiss()
                }
                .buttonStyle(.bordered)
            }
        }
    }

    // MARK: - ヘルパーメソッド

    private func scheduleBreakReminder(minutes: Int) {
        // 休憩リマインダーの実装
        // 実際のアプリでは通知やタイマーを使用
        DispatchQueue.main.asyncAfter(deadline: .now() + TimeInterval(minutes * 60)) {
            // 休憩終了の通知
        }
    }
}

// MARK: - プレビュー

#Preview("休憩推奨") {
    PlayTimeWarningView(warningType: .breakRecommendation)
        .environment(\.playTimeManager, PlayTimeManager.shared)
        .environment(\.regionalSettings, RegionalSettingsManager.shared)
}

#Preview("時間制限") {
    PlayTimeWarningView(warningType: .timeLimit)
        .environment(\.playTimeManager, PlayTimeManager.shared)
        .environment(\.regionalSettings, RegionalSettingsManager.shared)
}

#Preview("地域制限") {
    PlayTimeWarningView(warningType: .regionalRestriction)
        .environment(\.playTimeManager, PlayTimeManager.shared)
        .environment(\.regionalSettings, RegionalSettingsManager.shared)
}

#Preview("1日制限") {
    PlayTimeWarningView(warningType: .dailyLimit)
        .environment(\.playTimeManager, PlayTimeManager.shared)
        .environment(\.regionalSettings, RegionalSettingsManager.shared)
}
