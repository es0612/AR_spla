//
//  PlayTimeManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import Foundation
import SwiftUI

// MARK: - PlayTimeManager

/// プレイ時間管理クラス
@Observable
class PlayTimeManager {
    static let shared = PlayTimeManager()

    // MARK: - プレイ時間追跡

    /// 現在のセッション開始時刻
    private var sessionStartTime: Date?

    /// 現在のセッションのプレイ時間
    var currentSessionDuration: TimeInterval = 0

    /// 今日の累計プレイ時間
    var todayTotalPlayTime: TimeInterval = 0

    /// 今週の累計プレイ時間
    var weekTotalPlayTime: TimeInterval = 0

    /// 今月の累計プレイ時間
    var monthTotalPlayTime: TimeInterval = 0

    /// プレイ時間更新タイマー
    private var updateTimer: Timer?

    // MARK: - 制限と警告

    /// 休憩推奨フラグ
    var shouldRecommendBreak: Bool = false

    /// プレイ時間制限に達したフラグ
    var hasReachedTimeLimit: Bool = false

    /// 最後の休憩推奨時刻
    private var lastBreakRecommendation: Date?

    /// 最後の制限警告時刻
    private var lastLimitWarning: Date?

    // MARK: - 地域別制限設定

    /// 地域別の1日の最大プレイ時間（秒）
    private var dailyPlayTimeLimit: TimeInterval {
        let regionalSettings = RegionalSettingsManager.shared
        let userAge = UserDefaults.standard.integer(forKey: "user_age")

        switch regionalSettings.currentRegion {
        case .china:
            if userAge < 18 {
                // 中国: 未成年者は平日1.5時間、休日3時間
                return isWeekend() ? 3 * 3_600 : 1.5 * 3_600
            }
            return 8 * 3_600 // 成人は8時間

        case .korea:
            if userAge < 16 {
                return 4 * 3_600 // 16歳未満は4時間
            }
            return 8 * 3_600

        default:
            return 6 * 3_600 // デフォルト6時間
        }
    }

    /// 連続プレイ時間の制限（秒）
    private var continuousPlayTimeLimit: TimeInterval {
        let regionalSettings = RegionalSettingsManager.shared
        let userAge = UserDefaults.standard.integer(forKey: "user_age")

        switch regionalSettings.currentRegion {
        case .china:
            if userAge < 18 {
                return 1 * 3_600 // 1時間
            }
            return 2 * 3_600

        case .korea:
            if userAge < 16 {
                return 1 * 3_600 // 1時間
            }
            return 2 * 3_600

        default:
            return regionalSettings.breakRecommendationInterval
        }
    }

    // MARK: - 初期化

    private init() {
        loadPlayTimeData()
        startUpdateTimer()
    }

    deinit {
        stopUpdateTimer()
    }

    // MARK: - セッション管理

    /// ゲームセッションを開始
    func startSession() {
        sessionStartTime = Date()
        currentSessionDuration = 0
        shouldRecommendBreak = false
        hasReachedTimeLimit = false

        // 地域別の制限チェック
        checkRegionalRestrictions()
    }

    /// ゲームセッションを終了
    func endSession() {
        guard let startTime = sessionStartTime else { return }

        let sessionDuration = Date().timeIntervalSince(startTime)
        currentSessionDuration = sessionDuration

        // プレイ時間を記録
        recordPlayTime(duration: sessionDuration)

        sessionStartTime = nil
        savePlayTimeData()
    }

    /// セッションを一時停止
    func pauseSession() {
        guard let startTime = sessionStartTime else { return }

        let pausedDuration = Date().timeIntervalSince(startTime)
        currentSessionDuration += pausedDuration
        sessionStartTime = nil
    }

    /// セッションを再開
    func resumeSession() {
        sessionStartTime = Date()
    }

    // MARK: - プレイ時間更新

    private func startUpdateTimer() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updatePlayTime()
        }
    }

    private func stopUpdateTimer() {
        updateTimer?.invalidate()
        updateTimer = nil
    }

    private func updatePlayTime() {
        guard let startTime = sessionStartTime else { return }

        currentSessionDuration = Date().timeIntervalSince(startTime)

        // 制限チェック
        checkTimeRestrictions()
    }

    // MARK: - 制限チェック

    private func checkTimeRestrictions() {
        let regionalSettings = RegionalSettingsManager.shared

        // 休憩推奨チェック
        if currentSessionDuration >= regionalSettings.breakRecommendationInterval {
            if !shouldRecommendBreak {
                shouldRecommendBreak = true
                lastBreakRecommendation = Date()
            }
        }

        // 連続プレイ時間制限チェック
        if currentSessionDuration >= continuousPlayTimeLimit {
            if !hasReachedTimeLimit {
                hasReachedTimeLimit = true
                lastLimitWarning = Date()
            }
        }

        // 1日の制限チェック
        let totalToday = todayTotalPlayTime + currentSessionDuration
        if totalToday >= dailyPlayTimeLimit {
            hasReachedTimeLimit = true
        }
    }

    private func checkRegionalRestrictions() {
        let regionalSettings = RegionalSettingsManager.shared
        let userAge = UserDefaults.standard.integer(forKey: "user_age")
        let currentHour = Calendar.current.component(.hour, from: Date())

        switch regionalSettings.currentRegion {
        case .korea:
            // 韓国の셧다운제 (シャットダウン制度) チェック
            if userAge < 16, currentHour >= 0, currentHour < 6 {
                hasReachedTimeLimit = true
            }

        case .china:
            // 中国の防沉迷システムチェック
            if userAge < 18 {
                // 平日22時〜翌8時、休日21時〜翌8時は制限
                let isWeekday = !isWeekend()
                let restrictedHours = isWeekday ? (22 ... 23) + (0 ... 7) : (21 ... 23) + (0 ... 7)

                if restrictedHours.contains(currentHour) {
                    hasReachedTimeLimit = true
                }
            }

        default:
            break
        }
    }

    // MARK: - プレイ時間記録

    private func recordPlayTime(duration: TimeInterval) {
        let now = Date()
        let calendar = Calendar.current

        // 今日の日付キー
        let todayKey = calendar.dateInterval(of: .day, for: now)?.start ?? now
        let todayKeyString = "playTime_\(Int(todayKey.timeIntervalSince1970))"

        // 今日のプレイ時間を更新
        let existingTodayTime = UserDefaults.standard.double(forKey: todayKeyString)
        UserDefaults.standard.set(existingTodayTime + duration, forKey: todayKeyString)

        // 週間・月間プレイ時間を再計算
        updateWeeklyAndMonthlyPlayTime()
    }

    private func updateWeeklyAndMonthlyPlayTime() {
        let calendar = Calendar.current
        let now = Date()

        // 今週の開始日
        guard let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start else { return }

        // 今月の開始日
        guard let monthStart = calendar.dateInterval(of: .month, for: now)?.start else { return }

        var weekTotal: TimeInterval = 0
        var monthTotal: TimeInterval = 0
        var todayTotal: TimeInterval = 0

        // 過去30日分のデータをチェック
        for i in 0 ..< 30 {
            let date = calendar.date(byAdding: .day, value: -i, to: now) ?? now
            let dayStart = calendar.dateInterval(of: .day, for: date)?.start ?? date
            let dayKeyString = "playTime_\(Int(dayStart.timeIntervalSince1970))"
            let dayPlayTime = UserDefaults.standard.double(forKey: dayKeyString)

            // 今日
            if calendar.isDate(date, inSameDayAs: now) {
                todayTotal = dayPlayTime
            }

            // 今週
            if date >= weekStart {
                weekTotal += dayPlayTime
            }

            // 今月
            if date >= monthStart {
                monthTotal += dayPlayTime
            }
        }

        todayTotalPlayTime = todayTotal
        weekTotalPlayTime = weekTotal
        monthTotalPlayTime = monthTotal
    }

    // MARK: - データ永続化

    private func savePlayTimeData() {
        UserDefaults.standard.set(todayTotalPlayTime, forKey: "todayTotalPlayTime")
        UserDefaults.standard.set(weekTotalPlayTime, forKey: "weekTotalPlayTime")
        UserDefaults.standard.set(monthTotalPlayTime, forKey: "monthTotalPlayTime")
    }

    private func loadPlayTimeData() {
        updateWeeklyAndMonthlyPlayTime()
    }

    // MARK: - ユーティリティ

    private func isWeekend() -> Bool {
        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: Date())
        return weekday == 1 || weekday == 7 // 日曜日または土曜日
    }

    /// 時間を読みやすい形式でフォーマット
    func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3_600
        let minutes = (Int(duration) % 3_600) / 60
        let seconds = Int(duration) % 60

        if hours > 0 {
            return String(format: "%d時間%d分", hours, minutes)
        } else if minutes > 0 {
            return String(format: "%d分%d秒", minutes, seconds)
        } else {
            return String(format: "%d秒", seconds)
        }
    }

    /// 残り制限時間を取得
    func getRemainingTimeUntilLimit() -> TimeInterval? {
        let totalToday = todayTotalPlayTime + currentSessionDuration
        let remaining = dailyPlayTimeLimit - totalToday
        return remaining > 0 ? remaining : nil
    }

    /// 次の休憩推奨までの時間を取得
    func getTimeUntilNextBreakRecommendation() -> TimeInterval? {
        let regionalSettings = RegionalSettingsManager.shared
        let remaining = regionalSettings.breakRecommendationInterval - currentSessionDuration
        return remaining > 0 ? remaining : nil
    }

    /// プレイ時間統計を取得
    func getPlayTimeStatistics() -> PlayTimeStatistics {
        PlayTimeStatistics(
            currentSession: currentSessionDuration,
            todayTotal: todayTotalPlayTime,
            weekTotal: weekTotalPlayTime,
            monthTotal: monthTotalPlayTime,
            dailyLimit: dailyPlayTimeLimit,
            continuousLimit: continuousPlayTimeLimit,
            shouldRecommendBreak: shouldRecommendBreak,
            hasReachedTimeLimit: hasReachedTimeLimit
        )
    }
}

// MARK: - PlayTimeStatistics

struct PlayTimeStatistics {
    let currentSession: TimeInterval
    let todayTotal: TimeInterval
    let weekTotal: TimeInterval
    let monthTotal: TimeInterval
    let dailyLimit: TimeInterval
    let continuousLimit: TimeInterval
    let shouldRecommendBreak: Bool
    let hasReachedTimeLimit: Bool

    var todayProgress: Double {
        min(todayTotal / dailyLimit, 1.0)
    }

    var sessionProgress: Double {
        min(currentSession / continuousLimit, 1.0)
    }
}

// MARK: - PlayTimeEnvironmentKey

struct PlayTimeEnvironmentKey: EnvironmentKey {
    static let defaultValue = PlayTimeManager.shared
}

extension EnvironmentValues {
    var playTimeManager: PlayTimeManager {
        get { self[PlayTimeEnvironmentKey.self] }
        set { self[PlayTimeEnvironmentKey.self] = newValue }
    }
}
