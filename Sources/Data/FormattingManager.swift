//
//  FormattingManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import Foundation

// MARK: - FormattingManager

/// 数値・日付フォーマットを管理するクラス
class FormattingManager {
    static let shared = FormattingManager()

    private let localizationManager = LocalizationManager.shared

    private init() {}

    // MARK: - Date Formatting

    /// ゲーム履歴用の日付フォーマット
    func formatGameDate(_ date: Date) -> String {
        let formatter = localizationManager.dateFormatter(style: .medium)
        return formatter.string(from: date)
    }

    /// 時間表示用のフォーマット
    func formatTime(_ date: Date) -> String {
        let formatter = localizationManager.timeFormatter()
        return formatter.string(from: date)
    }

    /// ゲーム時間（秒）を分:秒形式でフォーマット
    func formatGameDuration(_ seconds: TimeInterval) -> String {
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60

        if minutes > 0 {
            return "duration_minutes_seconds".localized(with: minutes, remainingSeconds)
        } else {
            return "duration_seconds".localized(with: remainingSeconds)
        }
    }

    /// 残り時間を表示用にフォーマット
    func formatRemainingTime(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds))
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60

        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    // MARK: - Number Formatting

    /// スコアをパーセンテージでフォーマット
    func formatScore(_ score: Float) -> String {
        let formatter = localizationManager.percentageFormatter()
        return formatter.string(from: NSNumber(value: score / 100.0)) ?? "0.0%"
    }

    /// 整数をフォーマット
    func formatInteger(_ value: Int) -> String {
        let formatter = localizationManager.numberFormatter()
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }

    /// 小数点付き数値をフォーマット
    func formatDecimal(_ value: Float, fractionDigits: Int = 1) -> String {
        let formatter = localizationManager.numberFormatter()
        formatter.minimumFractionDigits = fractionDigits
        formatter.maximumFractionDigits = fractionDigits
        return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.1f", value)
    }

    /// 勝率をパーセンテージでフォーマット
    func formatWinRate(wins: Int, totalGames: Int) -> String {
        guard totalGames > 0 else { return "0.0%" }
        let rate = Float(wins) / Float(totalGames) * 100.0
        return formatScore(rate)
    }

    // MARK: - Game-specific Formatting

    /// ゲーム結果のフォーマット
    func formatGameResult(playerScore: Float, opponentScore: Float) -> (playerText: String, opponentText: String, result: String) {
        let playerText = "your_score".localized(with: playerScore)
        let opponentText = "opponent_score".localized(with: opponentScore)

        let result: String
        if playerScore > opponentScore {
            result = "you_win".localized
        } else if playerScore < opponentScore {
            result = "you_lose".localized
        } else {
            result = "draw".localized
        }

        return (playerText, opponentText, result)
    }

    /// ゲーム統計のフォーマット
    func formatGameStats(wins: Int, losses: Int, draws: Int) -> [String] {
        let totalGames = wins + losses + draws
        return [
            "history_wins".localized(with: wins),
            "history_losses".localized(with: losses),
            "history_draws".localized(with: draws),
            "history_total_games".localized(with: totalGames),
            "history_win_rate".localized(with: formatWinRate(wins: wins, totalGames: totalGames))
        ]
    }

    // MARK: - RTL Support Helpers

    /// RTL言語での数値表示を考慮したフォーマット
    func formatNumberForRTL(_ value: Float) -> String {
        let formatted = formatDecimal(value)

        // RTL言語の場合、数値の方向を調整
        if localizationManager.isRTL {
            return "\u{202D}" + formatted + "\u{202C}" // LTR override
        }

        return formatted
    }

    /// RTL言語での時間表示を考慮したフォーマット
    func formatTimeForRTL(_ seconds: TimeInterval) -> String {
        let formatted = formatRemainingTime(seconds)

        // RTL言語の場合、時間の方向を調整
        if localizationManager.isRTL {
            return "\u{202D}" + formatted + "\u{202C}" // LTR override
        }

        return formatted
    }
}

// MARK: - Extensions

extension TimeInterval {
    /// 時間間隔をローカライズされた文字列に変換
    var localizedDuration: String {
        FormattingManager.shared.formatGameDuration(self)
    }

    /// 残り時間をローカライズされた文字列に変換
    var localizedRemainingTime: String {
        FormattingManager.shared.formatRemainingTime(self)
    }
}

extension Float {
    /// スコアをローカライズされたパーセンテージ文字列に変換
    var localizedScore: String {
        FormattingManager.shared.formatScore(self)
    }

    /// 数値をローカライズされた文字列に変換
    var localizedDecimal: String {
        FormattingManager.shared.formatDecimal(self)
    }
}

extension Int {
    /// 整数をローカライズされた文字列に変換
    var localizedInteger: String {
        FormattingManager.shared.formatInteger(self)
    }
}

extension Date {
    /// 日付をローカライズされた文字列に変換
    var localizedDate: String {
        FormattingManager.shared.formatGameDate(self)
    }

    /// 時間をローカライズされた文字列に変換
    var localizedTime: String {
        FormattingManager.shared.formatTime(self)
    }
}
