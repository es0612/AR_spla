//
//  GameFeedbackView.swift
//  ARSplatoonGame
//
//  Created by Kiro on 2025-01-09.
//

import SwiftUI

// MARK: - GameFeedbackView

struct GameFeedbackView: View {
    @Bindable var feedbackManager: GameFeedbackManager
    @State private var showingFeedbackForm = false
    @State private var selectedFeedback: GameFeedbackManager.GameSessionFeedback?

    // フィードバックフォームの状態
    @State private var inkShotCooldownRating = 3
    @State private var inkRangeRating = 3
    @State private var stunDurationRating = 3
    @State private var gameTimeRating = 3
    @State private var overallBalanceRating = 3
    @State private var funRating = 3
    @State private var difficultyRating = 3
    @State private var fairnessRating = 3
    @State private var replayabilityRating = 3
    @State private var comments = ""
    @State private var suggestedImprovements = ""

    var body: some View {
        NavigationView {
            List {
                if let analysis = feedbackManager.currentAnalysis {
                    analysisSection(analysis)
                }

                feedbackListSection

                settingsSection
            }
            .navigationTitle("ゲームフィードバック")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("新規フィードバック") {
                        resetFeedbackForm()
                        showingFeedbackForm = true
                    }
                }
            }
            .sheet(isPresented: $showingFeedbackForm) {
                feedbackFormView
            }
            .sheet(item: $selectedFeedback) { feedback in
                feedbackDetailView(feedback)
            }
        }
    }

    // MARK: - Analysis Section

    @ViewBuilder
    private func analysisSection(_ analysis: GameFeedbackManager.FeedbackAnalysis) -> some View {
        Section("分析結果") {
            HStack {
                Text("総フィードバック数")
                Spacer()
                Text("\(analysis.totalFeedbacks)")
                    .foregroundColor(.secondary)
            }

            HStack {
                Text("プレイヤー継続率")
                Spacer()
                Text("\(Int(analysis.playerRetention * 100))%")
                    .foregroundColor(analysis.playerRetention > 0.7 ? .green : analysis.playerRetention > 0.5 ? .orange : .red)
            }

            if !analysis.commonComplaints.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("主な課題")
                        .font(.subheadline)
                        .fontWeight(.medium)

                    ForEach(analysis.commonComplaints, id: \.self) { complaint in
                        Text("• \(complaint)")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }

            NavigationLink("詳細分析を表示") {
                DetailedAnalysisView(analysis: analysis, feedbackManager: feedbackManager)
            }
        }
    }

    // MARK: - Feedback List Section

    @ViewBuilder private var feedbackListSection: some View {
        Section("フィードバック履歴") {
            if feedbackManager.feedbacks.isEmpty {
                Text("フィードバックがありません")
                    .foregroundColor(.secondary)
                    .italic()
            } else {
                ForEach(feedbackManager.feedbacks.reversed()) { feedback in
                    feedbackRowView(feedback)
                }
                .onDelete(perform: deleteFeedbacks)
            }
        }
    }

    @ViewBuilder
    private func feedbackRowView(_ feedback: GameFeedbackManager.GameSessionFeedback) -> some View {
        Button {
            selectedFeedback = feedback
        } label: {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(DateFormatter.localizedString(from: feedback.date, dateStyle: .short, timeStyle: .short))
                        .font(.subheadline)
                        .fontWeight(.medium)

                    Spacer()

                    Text("総合評価: \(feedback.overallBalanceRating)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("難易度: \(feedback.difficultyLevel)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Spacer()

                    Text("楽しさ: \(feedback.funRating)/5")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if !feedback.comments.isEmpty {
                    Text(feedback.comments)
                        .font(.caption)
                        .lineLimit(2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Settings Section

    @ViewBuilder private var settingsSection: some View {
        Section("設定") {
            Toggle("フィードバック収集", isOn: $feedbackManager.isCollectionEnabled)
            Toggle("自動分析", isOn: $feedbackManager.isAutoAnalysisEnabled)

            Button("分析を更新") {
                feedbackManager.updateAnalysis()
            }
            .disabled(feedbackManager.feedbacks.isEmpty)

            Button("全フィードバックを削除", role: .destructive) {
                feedbackManager.clearAllFeedbacks()
            }
            .disabled(feedbackManager.feedbacks.isEmpty)
        }
    }

    // MARK: - Feedback Form

    @ViewBuilder private var feedbackFormView: some View {
        NavigationView {
            Form {
                Section("ゲームバランス評価") {
                    ratingRow("インク発射間隔", rating: $inkShotCooldownRating)
                    ratingRow("インク射程距離", rating: $inkRangeRating)
                    ratingRow("スタン時間", rating: $stunDurationRating)
                    ratingRow("ゲーム時間", rating: $gameTimeRating)
                    ratingRow("総合バランス", rating: $overallBalanceRating)
                }

                Section("プレイヤー体験評価") {
                    ratingRow("楽しさ", rating: $funRating)
                    difficultyRatingRow
                    ratingRow("公平性", rating: $fairnessRating)
                    ratingRow("リプレイ性", rating: $replayabilityRating)
                }

                Section("コメント") {
                    TextField("ゲームについてのコメント", text: $comments, axis: .vertical)
                        .lineLimit(3 ... 6)

                    TextField("改善提案", text: $suggestedImprovements, axis: .vertical)
                        .lineLimit(3 ... 6)
                }
            }
            .navigationTitle("フィードバック")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        showingFeedbackForm = false
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("送信") {
                        submitFeedback()
                        showingFeedbackForm = false
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ratingRow(_ title: String, rating: Binding<Int>) -> some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 4) {
                ForEach(1 ... 5, id: \.self) { star in
                    Button {
                        rating.wrappedValue = star
                    } label: {
                        Image(systemName: star <= rating.wrappedValue ? "star.fill" : "star")
                            .foregroundColor(star <= rating.wrappedValue ? .yellow : .gray)
                    }
                }
            }
        }
    }

    @ViewBuilder private var difficultyRatingRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("難易度")

            Picker("難易度", selection: $difficultyRating) {
                Text("簡単すぎる").tag(1)
                Text("やや簡単").tag(2)
                Text("ちょうど良い").tag(3)
                Text("やや難しい").tag(4)
                Text("難しすぎる").tag(5)
            }
            .pickerStyle(SegmentedPickerStyle())
        }
    }

    // MARK: - Feedback Detail

    @ViewBuilder
    private func feedbackDetailView(_ feedback: GameFeedbackManager.GameSessionFeedback) -> some View {
        NavigationView {
            List {
                Section("基本情報") {
                    HStack {
                        Text("日時")
                        Spacer()
                        Text(DateFormatter.localizedString(from: feedback.date, dateStyle: .medium, timeStyle: .short))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("ゲーム時間")
                        Spacer()
                        Text("\(Int(feedback.gameDuration))秒")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("難易度")
                        Spacer()
                        Text(feedback.difficultyLevel)
                            .foregroundColor(.secondary)
                    }
                }

                Section("バランス評価") {
                    ratingDisplayRow("インク発射間隔", rating: feedback.inkShotCooldownRating)
                    ratingDisplayRow("インク射程距離", rating: feedback.inkRangeRating)
                    ratingDisplayRow("スタン時間", rating: feedback.stunDurationRating)
                    ratingDisplayRow("ゲーム時間", rating: feedback.gameTimeRating)
                    ratingDisplayRow("総合バランス", rating: feedback.overallBalanceRating)
                }

                Section("体験評価") {
                    ratingDisplayRow("楽しさ", rating: feedback.funRating)
                    ratingDisplayRow("難易度", rating: feedback.difficultyRating)
                    ratingDisplayRow("公平性", rating: feedback.fairnessRating)
                    ratingDisplayRow("リプレイ性", rating: feedback.replayabilityRating)
                }

                Section("ゲーム統計") {
                    HStack {
                        Text("最終スコア")
                        Spacer()
                        Text(String(format: "%.1f%%", feedback.finalScore))
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("インクスポット数")
                        Spacer()
                        Text("\(feedback.inkSpotsPlaced)")
                            .foregroundColor(.secondary)
                    }

                    HStack {
                        Text("スタン回数")
                        Spacer()
                        Text("\(feedback.timesStunned)")
                            .foregroundColor(.secondary)
                    }
                }

                if !feedback.comments.isEmpty {
                    Section("コメント") {
                        Text(feedback.comments)
                    }
                }

                if !feedback.suggestedImprovements.isEmpty {
                    Section("改善提案") {
                        Text(feedback.suggestedImprovements)
                    }
                }
            }
            .navigationTitle("フィードバック詳細")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        selectedFeedback = nil
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func ratingDisplayRow(_ title: String, rating: Int) -> some View {
        HStack {
            Text(title)
            Spacer()
            HStack(spacing: 2) {
                ForEach(1 ... 5, id: \.self) { star in
                    Image(systemName: star <= rating ? "star.fill" : "star")
                        .foregroundColor(star <= rating ? .yellow : .gray)
                        .font(.caption)
                }
            }
        }
    }

    // MARK: - Actions

    private func resetFeedbackForm() {
        inkShotCooldownRating = 3
        inkRangeRating = 3
        stunDurationRating = 3
        gameTimeRating = 3
        overallBalanceRating = 3
        funRating = 3
        difficultyRating = 3
        fairnessRating = 3
        replayabilityRating = 3
        comments = ""
        suggestedImprovements = ""
    }

    private func submitFeedback() {
        let feedback = GameFeedbackManager.GameSessionFeedback(
            sessionId: UUID(),
            gameDuration: 180, // デフォルト値、実際のゲームセッションから取得すべき
            playerCount: 2,
            difficultyLevel: "ノーマル",
            inkShotCooldownRating: inkShotCooldownRating,
            inkRangeRating: inkRangeRating,
            stunDurationRating: stunDurationRating,
            gameTimeRating: gameTimeRating,
            overallBalanceRating: overallBalanceRating,
            funRating: funRating,
            difficultyRating: difficultyRating,
            fairnessRating: fairnessRating,
            replayabilityRating: replayabilityRating,
            comments: comments,
            suggestedImprovements: suggestedImprovements,
            finalScore: 0.0, // 実際のスコアから取得すべき
            inkSpotsPlaced: 0,
            timesStunned: 0,
            averageInkSpotSize: 0.4
        )

        feedbackManager.collectFeedback(feedback)
    }

    private func deleteFeedbacks(offsets: IndexSet) {
        let reversedFeedbacks = Array(feedbackManager.feedbacks.reversed())
        for index in offsets {
            if index < reversedFeedbacks.count {
                let feedbackToDelete = reversedFeedbacks[index]
                feedbackManager.removeFeedback(withId: feedbackToDelete.id)
            }
        }
    }
}

// MARK: - DetailedAnalysisView

struct DetailedAnalysisView: View {
    let analysis: GameFeedbackManager.FeedbackAnalysis
    let feedbackManager: GameFeedbackManager

    var body: some View {
        List {
            Section("平均評価") {
                ForEach(analysis.averageRatings.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                    HStack {
                        Text(displayName(for: key))
                        Spacer()
                        Text(String(format: "%.1f/5.0", value))
                            .foregroundColor(colorForRating(value))
                    }
                }
            }

            if !analysis.commonComplaints.isEmpty {
                Section("主な課題") {
                    ForEach(analysis.commonComplaints, id: \.self) { complaint in
                        Text("• \(complaint)")
                            .foregroundColor(.orange)
                    }
                }
            }

            if !analysis.suggestedAdjustments.isEmpty {
                Section("推奨調整") {
                    ForEach(analysis.suggestedAdjustments.sorted(by: { $0.key < $1.key }), id: \.key) { key, value in
                        HStack {
                            Text(adjustmentDisplayName(for: key))
                            Spacer()
                            Text(adjustmentDescription(for: key, value: value))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }

            let suggestions = feedbackManager.getImprovementSuggestions()
            if !suggestions.isEmpty {
                Section("改善提案") {
                    ForEach(suggestions, id: \.self) { suggestion in
                        Text("• \(suggestion)")
                            .foregroundColor(.green)
                    }
                }
            }

            Section("推奨設定") {
                if let recommendedSettings = feedbackManager.getRecommendedBalanceSettings() {
                    Button("推奨設定を適用") {
                        // 実際の実装では、GameStateに推奨設定を適用する
                        print("Applying recommended settings: \(recommendedSettings)")
                    }
                    .foregroundColor(.blue)
                } else {
                    Text("十分なフィードバックデータがありません（最低5件必要）")
                        .foregroundColor(.secondary)
                        .italic()
                }
            }
        }
        .navigationTitle("詳細分析")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func displayName(for key: String) -> String {
        switch key {
        case "inkShotCooldown": return "インク発射間隔"
        case "inkRange": return "インク射程距離"
        case "stunDuration": return "スタン時間"
        case "gameTime": return "ゲーム時間"
        case "overallBalance": return "総合バランス"
        case "fun": return "楽しさ"
        case "difficulty": return "難易度"
        case "fairness": return "公平性"
        case "replayability": return "リプレイ性"
        default: return key
        }
    }

    private func colorForRating(_ rating: Double) -> Color {
        if rating >= 4.0 {
            return .green
        } else if rating >= 3.0 {
            return .primary
        } else if rating >= 2.0 {
            return .orange
        } else {
            return .red
        }
    }

    private func adjustmentDisplayName(for key: String) -> String {
        switch key {
        case "inkShotCooldownMultiplier": return "インク発射間隔"
        case "stunDurationMultiplier": return "スタン時間"
        case "difficultyIncrease": return "難易度"
        case "difficultyDecrease": return "難易度"
        default: return key
        }
    }

    private func adjustmentDescription(for key: String, value: Double) -> String {
        switch key {
        case "inkShotCooldownMultiplier":
            let percentage = Int((value - 1.0) * 100)
            return percentage > 0 ? "+\(percentage)%" : "\(percentage)%"
        case "stunDurationMultiplier":
            let percentage = Int((value - 1.0) * 100)
            return percentage > 0 ? "+\(percentage)%" : "\(percentage)%"
        case "difficultyIncrease":
            return "上げる"
        case "difficultyDecrease":
            return "下げる"
        default:
            return String(format: "%.2f", value)
        }
    }
}

#Preview {
    GameFeedbackView(feedbackManager: GameFeedbackManager())
}
