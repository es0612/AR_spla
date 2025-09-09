//
//  GameFeedbackManager.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import Foundation
import SwiftUI

// MARK: - GameFeedbackManager

/// ゲームフィードバック収集と分析のためのマネージャー
@Observable
public class GameFeedbackManager {
    // MARK: - Feedback Data

    /// ゲームセッションのフィードバックデータ
    public struct GameSessionFeedback: Codable, Identifiable {
        public let id = UUID()
        public let sessionId: UUID
        public let date: Date
        public let gameDuration: TimeInterval
        public let playerCount: Int
        public let difficultyLevel: String

        // ゲームバランス評価
        public let inkShotCooldownRating: Int // 1-5
        public let inkRangeRating: Int // 1-5
        public let stunDurationRating: Int // 1-5
        public let gameTimeRating: Int // 1-5
        public let overallBalanceRating: Int // 1-5

        // プレイヤー体験評価
        public let funRating: Int // 1-5
        public let difficultyRating: Int // 1-5 (1=too easy, 3=just right, 5=too hard)
        public let fairnessRating: Int // 1-5
        public let replayabilityRating: Int // 1-5

        // 自由記述フィードバック
        public let comments: String
        public let suggestedImprovements: String

        // ゲーム統計
        public let finalScore: Float
        public let inkSpotsPlaced: Int
        public let timesStunned: Int
        public let averageInkSpotSize: Float

        public init(
            sessionId: UUID,
            date: Date = Date(),
            gameDuration: TimeInterval,
            playerCount: Int,
            difficultyLevel: String,
            inkShotCooldownRating: Int,
            inkRangeRating: Int,
            stunDurationRating: Int,
            gameTimeRating: Int,
            overallBalanceRating: Int,
            funRating: Int,
            difficultyRating: Int,
            fairnessRating: Int,
            replayabilityRating: Int,
            comments: String,
            suggestedImprovements: String,
            finalScore: Float,
            inkSpotsPlaced: Int,
            timesStunned: Int,
            averageInkSpotSize: Float
        ) {
            self.sessionId = sessionId
            self.date = date
            self.gameDuration = gameDuration
            self.playerCount = playerCount
            self.difficultyLevel = difficultyLevel
            self.inkShotCooldownRating = inkShotCooldownRating
            self.inkRangeRating = inkRangeRating
            self.stunDurationRating = stunDurationRating
            self.gameTimeRating = gameTimeRating
            self.overallBalanceRating = overallBalanceRating
            self.funRating = funRating
            self.difficultyRating = difficultyRating
            self.fairnessRating = fairnessRating
            self.replayabilityRating = replayabilityRating
            self.comments = comments
            self.suggestedImprovements = suggestedImprovements
            self.finalScore = finalScore
            self.inkSpotsPlaced = inkSpotsPlaced
            self.timesStunned = timesStunned
            self.averageInkSpotSize = averageInkSpotSize
        }
    }

    /// フィードバック分析結果
    public struct FeedbackAnalysis {
        public let totalFeedbacks: Int
        public let averageRatings: [String: Double]
        public let commonComplaints: [String]
        public let suggestedAdjustments: [String: Double]
        public let playerRetention: Double

        public init(
            totalFeedbacks: Int,
            averageRatings: [String: Double],
            commonComplaints: [String],
            suggestedAdjustments: [String: Double],
            playerRetention: Double
        ) {
            self.totalFeedbacks = totalFeedbacks
            self.averageRatings = averageRatings
            self.commonComplaints = commonComplaints
            self.suggestedAdjustments = suggestedAdjustments
            self.playerRetention = playerRetention
        }
    }

    // MARK: - Properties

    /// 収集されたフィードバックデータ
    public private(set) var feedbacks: [GameSessionFeedback] = []

    /// 現在のフィードバック分析結果
    public private(set) var currentAnalysis: FeedbackAnalysis?

    /// フィードバック収集が有効かどうか
    public var isCollectionEnabled: Bool = true

    /// 自動分析が有効かどうか
    public var isAutoAnalysisEnabled: Bool = true

    // MARK: - Initialization

    public init() {
        loadFeedbacks()
        if isAutoAnalysisEnabled {
            updateAnalysis()
        }
    }

    // MARK: - Feedback Collection

    /// ゲームセッション終了時にフィードバックを収集
    public func collectFeedback(_ feedback: GameSessionFeedback) {
        guard isCollectionEnabled else { return }

        feedbacks.append(feedback)
        saveFeedbacks()

        if isAutoAnalysisEnabled {
            updateAnalysis()
        }

        print("Feedback collected for session \(feedback.sessionId)")
    }

    /// フィードバックを削除
    public func removeFeedback(withId id: UUID) {
        feedbacks.removeAll { $0.id == id }
        saveFeedbacks()

        if isAutoAnalysisEnabled {
            updateAnalysis()
        }
    }

    /// 全フィードバックをクリア
    public func clearAllFeedbacks() {
        feedbacks.removeAll()
        currentAnalysis = nil
        saveFeedbacks()
    }

    // MARK: - Analysis

    /// フィードバック分析を更新
    public func updateAnalysis() {
        guard !feedbacks.isEmpty else {
            currentAnalysis = nil
            return
        }

        let totalFeedbacks = feedbacks.count

        // 平均評価を計算
        let averageRatings = calculateAverageRatings()

        // 共通の不満を特定
        let commonComplaints = identifyCommonComplaints()

        // 調整提案を生成
        let suggestedAdjustments = generateAdjustmentSuggestions()

        // プレイヤー継続率を計算
        let playerRetention = calculatePlayerRetention()

        currentAnalysis = FeedbackAnalysis(
            totalFeedbacks: totalFeedbacks,
            averageRatings: averageRatings,
            commonComplaints: commonComplaints,
            suggestedAdjustments: suggestedAdjustments,
            playerRetention: playerRetention
        )

        print("Feedback analysis updated: \(totalFeedbacks) feedbacks analyzed")
    }

    private func calculateAverageRatings() -> [String: Double] {
        guard !feedbacks.isEmpty else { return [:] }

        let count = Double(feedbacks.count)

        return [
            "inkShotCooldown": feedbacks.map { Double($0.inkShotCooldownRating) }.reduce(0, +) / count,
            "inkRange": feedbacks.map { Double($0.inkRangeRating) }.reduce(0, +) / count,
            "stunDuration": feedbacks.map { Double($0.stunDurationRating) }.reduce(0, +) / count,
            "gameTime": feedbacks.map { Double($0.gameTimeRating) }.reduce(0, +) / count,
            "overallBalance": feedbacks.map { Double($0.overallBalanceRating) }.reduce(0, +) / count,
            "fun": feedbacks.map { Double($0.funRating) }.reduce(0, +) / count,
            "difficulty": feedbacks.map { Double($0.difficultyRating) }.reduce(0, +) / count,
            "fairness": feedbacks.map { Double($0.fairnessRating) }.reduce(0, +) / count,
            "replayability": feedbacks.map { Double($0.replayabilityRating) }.reduce(0, +) / count
        ]
    }

    private func identifyCommonComplaints() -> [String] {
        var complaints: [String] = []
        let averageRatings = calculateAverageRatings()

        // 評価が低い項目を特定（3.0未満）
        if let cooldownRating = averageRatings["inkShotCooldown"], cooldownRating < 3.0 {
            if cooldownRating < 2.5 {
                complaints.append("インク発射間隔が長すぎる")
            } else {
                complaints.append("インク発射間隔の調整が必要")
            }
        }

        if let rangeRating = averageRatings["inkRange"], rangeRating < 3.0 {
            complaints.append("インクの射程距離に不満")
        }

        if let stunRating = averageRatings["stunDuration"], stunRating < 3.0 {
            if stunRating < 2.5 {
                complaints.append("スタン時間が長すぎる")
            } else {
                complaints.append("スタン時間の調整が必要")
            }
        }

        if let difficultyRating = averageRatings["difficulty"] {
            if difficultyRating < 2.0 {
                complaints.append("ゲームが簡単すぎる")
            } else if difficultyRating > 4.0 {
                complaints.append("ゲームが難しすぎる")
            }
        }

        if let fairnessRating = averageRatings["fairness"], fairnessRating < 3.0 {
            complaints.append("ゲームバランスが不公平")
        }

        return complaints
    }

    private func generateAdjustmentSuggestions() -> [String: Double] {
        var suggestions: [String: Double] = [:]
        let averageRatings = calculateAverageRatings()

        // インク発射間隔の調整提案
        if let cooldownRating = averageRatings["inkShotCooldown"] {
            if cooldownRating < 2.5 {
                suggestions["inkShotCooldownMultiplier"] = 0.8 // 20%短縮
            } else if cooldownRating > 4.0 {
                suggestions["inkShotCooldownMultiplier"] = 1.2 // 20%延長
            }
        }

        // スタン時間の調整提案
        if let stunRating = averageRatings["stunDuration"] {
            if stunRating < 2.5 {
                suggestions["stunDurationMultiplier"] = 0.7 // 30%短縮
            } else if stunRating > 4.0 {
                suggestions["stunDurationMultiplier"] = 1.3 // 30%延長
            }
        }

        // 難易度の調整提案
        if let difficultyRating = averageRatings["difficulty"] {
            if difficultyRating < 2.0 {
                suggestions["difficultyIncrease"] = 1.0 // 難易度を上げる
            } else if difficultyRating > 4.0 {
                suggestions["difficultyDecrease"] = 1.0 // 難易度を下げる
            }
        }

        return suggestions
    }

    private func calculatePlayerRetention() -> Double {
        guard feedbacks.count >= 2 else { return 1.0 }

        // 最近のフィードバックの楽しさ評価を基に継続率を推定
        let recentFeedbacks = feedbacks.suffix(min(10, feedbacks.count))
        let averageFunRating = recentFeedbacks.map { Double($0.funRating) }.reduce(0, +) / Double(recentFeedbacks.count)
        let averageReplayRating = recentFeedbacks.map { Double($0.replayabilityRating) }.reduce(0, +) / Double(recentFeedbacks.count)

        // 楽しさとリプレイ性から継続率を推定
        let retentionScore = (averageFunRating + averageReplayRating) / 10.0
        return max(0.0, min(1.0, retentionScore))
    }

    // MARK: - Balance Recommendations

    /// 現在の分析に基づいてバランス設定の推奨値を取得
    public func getRecommendedBalanceSettings() -> GameBalanceSettings? {
        guard let analysis = currentAnalysis,
              analysis.totalFeedbacks >= 5 else { return nil }

        let settings = GameBalanceSettings()

        // 調整提案を適用
        if let cooldownMultiplier = analysis.suggestedAdjustments["inkShotCooldownMultiplier"] {
            settings.inkShotCooldown *= cooldownMultiplier
        }

        if let stunMultiplier = analysis.suggestedAdjustments["stunDurationMultiplier"] {
            settings.playerStunDuration *= stunMultiplier
        }

        // 難易度調整
        if analysis.suggestedAdjustments["difficultyIncrease"] != nil {
            settings.difficultyLevel = .hard
        } else if analysis.suggestedAdjustments["difficultyDecrease"] != nil {
            settings.difficultyLevel = .easy
        }

        return settings
    }

    /// フィードバックに基づく改善提案を取得
    public func getImprovementSuggestions() -> [String] {
        guard let analysis = currentAnalysis else { return [] }

        var suggestions: [String] = []

        // 共通の不満に基づく提案
        for complaint in analysis.commonComplaints {
            switch complaint {
            case "インク発射間隔が長すぎる":
                suggestions.append("インク発射のクールダウン時間を短縮することを検討してください")
            case "スタン時間が長すぎる":
                suggestions.append("プレイヤーのスタン時間を短縮することを検討してください")
            case "ゲームが簡単すぎる":
                suggestions.append("難易度を上げるか、より挑戦的な要素を追加することを検討してください")
            case "ゲームが難しすぎる":
                suggestions.append("難易度を下げるか、プレイヤーに有利な調整を検討してください")
            case "ゲームバランスが不公平":
                suggestions.append("ゲームバランスの全体的な見直しを検討してください")
            default:
                break
            }
        }

        // プレイヤー継続率に基づく提案
        if analysis.playerRetention < 0.6 {
            suggestions.append("プレイヤーの継続率が低いため、ゲーム体験の改善が必要です")
        }

        return suggestions
    }

    // MARK: - Data Persistence

    private func saveFeedbacks() {
        do {
            let data = try JSONEncoder().encode(feedbacks)
            UserDefaults.standard.set(data, forKey: "gameFeedbacks")
        } catch {
            print("Failed to save feedbacks: \(error)")
        }
    }

    private func loadFeedbacks() {
        guard let data = UserDefaults.standard.data(forKey: "gameFeedbacks") else { return }

        do {
            feedbacks = try JSONDecoder().decode([GameSessionFeedback].self, from: data)
        } catch {
            print("Failed to load feedbacks: \(error)")
            feedbacks = []
        }
    }

    // MARK: - Export

    /// フィードバックデータをCSV形式でエクスポート
    public func exportFeedbacksAsCSV() -> String {
        var csv = "Date,SessionId,GameDuration,PlayerCount,DifficultyLevel,InkShotCooldownRating,InkRangeRating,StunDurationRating,GameTimeRating,OverallBalanceRating,FunRating,DifficultyRating,FairnessRating,ReplayabilityRating,FinalScore,InkSpotsPlaced,TimesStunned,AverageInkSpotSize,Comments,SuggestedImprovements\n"

        for feedback in feedbacks {
            let row = [
                DateFormatter.iso8601.string(from: feedback.date),
                feedback.sessionId.uuidString,
                String(feedback.gameDuration),
                String(feedback.playerCount),
                feedback.difficultyLevel,
                String(feedback.inkShotCooldownRating),
                String(feedback.inkRangeRating),
                String(feedback.stunDurationRating),
                String(feedback.gameTimeRating),
                String(feedback.overallBalanceRating),
                String(feedback.funRating),
                String(feedback.difficultyRating),
                String(feedback.fairnessRating),
                String(feedback.replayabilityRating),
                String(feedback.finalScore),
                String(feedback.inkSpotsPlaced),
                String(feedback.timesStunned),
                String(feedback.averageInkSpotSize),
                "\"" + feedback.comments.replacingOccurrences(of: "\"", with: "\"\"") + "\"",
                "\"" + feedback.suggestedImprovements.replacingOccurrences(of: "\"", with: "\"\"") + "\""
            ].joined(separator: ",")

            csv += row + "\n"
        }

        return csv
    }
}

extension DateFormatter {
    static let iso8601: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}
