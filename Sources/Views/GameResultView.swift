import Domain
import SwiftUI

// MARK: - GameResultView

/// Game result screen showing final scores and winner
struct GameResultView: View {
    let gameState: GameState
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Winner announcement
                    WinnerAnnouncementView(gameState: gameState)

                    // Final scores
                    FinalScoresView(gameState: gameState)

                    // Game statistics
                    GameStatisticsView(gameState: gameState)

                    // Action buttons
                    ActionButtonsView(gameState: gameState, onDismiss: {
                        dismiss()
                    })
                }
                .padding()
            }
            .navigationTitle("ゲーム結果")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - WinnerAnnouncementView

/// Winner announcement section
struct WinnerAnnouncementView: View {
    let gameState: GameState

    var body: some View {
        VStack(spacing: 16) {
            if let winner = gameState.winner {
                // Winner display
                Image(systemName: "crown.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.yellow)

                Text("勝者")
                    .font(.title2)
                    .foregroundColor(.secondary)

                Text(winner.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(winnerColor(for: winner))

                Text("おめでとうございます！")
                    .font(.headline)
                    .foregroundColor(.secondary)
            } else {
                // Draw
                Image(systemName: "equal.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.orange)

                Text("引き分け")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.orange)

                Text("素晴らしい戦いでした！")
                    .font(.headline)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func winnerColor(for player: Player) -> Color {
        switch player.color {
        case .blue:
            return .blue
        case .red:
            return .red
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .purple:
            return .purple
        case .orange:
            return .orange
        }
    }
}

// MARK: - FinalScoresView

/// Final scores section
struct FinalScoresView: View {
    let gameState: GameState

    var body: some View {
        VStack(spacing: 16) {
            Text("最終スコア")
                .font(.title2)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                ForEach(gameState.playersByScore, id: \.id) { player in
                    PlayerResultRow(
                        player: player,
                        isWinner: gameState.winner?.id == player.id,
                        rank: getRank(for: player)
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func getRank(for player: Player) -> Int {
        let sortedPlayers = gameState.playersByScore
        return (sortedPlayers.firstIndex { $0.id == player.id } ?? 0) + 1
    }
}

// MARK: - PlayerResultRow

/// Individual player result row
struct PlayerResultRow: View {
    let player: Player
    let isWinner: Bool
    let rank: Int

    var body: some View {
        HStack {
            // Rank
            Text("\(rank)")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.secondary)
                .frame(width: 30)

            // Player info
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(player.name)
                        .font(.headline)
                        .fontWeight(isWinner ? .bold : .medium)

                    if isWinner {
                        Image(systemName: "crown.fill")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }

                Text("カバー率: \(Int(player.score.paintedArea))%")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            Spacer()

            // Score visualization
            Circle()
                .fill(playerColor)
                .frame(width: 40, height: 40)
                .overlay(
                    Text("\(Int(player.score.paintedArea))%")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
        .padding()
        .background(isWinner ? playerColor.opacity(0.1) : Color.clear)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isWinner ? playerColor : Color.clear, lineWidth: 2)
        )
    }

    private var playerColor: Color {
        switch player.color {
        case .blue:
            return .blue
        case .red:
            return .red
        case .green:
            return .green
        case .yellow:
            return .yellow
        case .purple:
            return .purple
        case .orange:
            return .orange
        }
    }
}

// MARK: - GameStatisticsView

/// Game statistics section
struct GameStatisticsView: View {
    let gameState: GameState

    var body: some View {
        VStack(spacing: 16) {
            Text("ゲーム統計")
                .font(.title2)
                .fontWeight(.semibold)

            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 16) {
                StatisticCard(
                    title: "ゲーム時間",
                    value: formatDuration(gameState.gameDuration),
                    icon: "clock"
                )

                StatisticCard(
                    title: "総カバー率",
                    value: "\(gameState.coveragePercentage)%",
                    icon: "chart.pie"
                )

                StatisticCard(
                    title: "プレイヤー数",
                    value: "\(gameState.players.count)人",
                    icon: "person.2"
                )

                StatisticCard(
                    title: "ゲームフェーズ",
                    value: phaseDisplayName,
                    icon: "flag.checkered"
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(16)
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }

    private var phaseDisplayName: String {
        switch gameState.currentPhase {
        case .waiting:
            return "待機中"
        case .connecting:
            return "接続中"
        case .playing:
            return "プレイ中"
        case .finished:
            return "終了"
        }
    }
}

// MARK: - StatisticCard

/// Individual statistic card
struct StatisticCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)

            Text(value)
                .font(.title3)
                .fontWeight(.bold)

            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - ActionButtonsView

/// Action buttons section
struct ActionButtonsView: View {
    let gameState: GameState
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Button(action: {
                gameState.resetGame()
                onDismiss()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("新しいゲーム")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }

            Button(action: {
                onDismiss()
            }) {
                HStack {
                    Image(systemName: "house")
                    Text("メニューに戻る")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(12)
            }

            // Share results button
            ShareLink(
                item: generateShareText(),
                subject: Text("AR Splatoon ゲーム結果")
            ) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("結果をシェア")
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.green)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.green.opacity(0.1))
                .cornerRadius(12)
            }
        }
    }

    private func generateShareText() -> String {
        var text = "AR Splatoon ゲーム結果\n\n"

        if let winner = gameState.winner {
            text += "🏆 勝者: \(winner.name)\n"
        } else {
            text += "🤝 引き分け\n"
        }

        text += "\n📊 最終スコア:\n"
        for (index, player) in gameState.playersByScore.enumerated() {
            let rank = index + 1
            text += "\(rank). \(player.name): \(Int(player.score.paintedArea))%\n"
        }

        text += "\n⏱️ ゲーム時間: \(formatDuration(gameState.gameDuration))"
        text += "\n📱 総カバー率: \(gameState.coveragePercentage)%"

        return text
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return "\(minutes):\(String(format: "%02d", seconds))"
    }
}

#Preview {
    GameResultView(gameState: {
        // Create sample game state for preview
        let gameState = GameState()

        // Add sample players
        let player1 = Player(
            id: PlayerId(),
            name: "プレイヤー1",
            color: .blue,
            position: Position3D(x: 0, y: 0, z: 0)
        ).updateScore(GameScore(paintedArea: 65.0))

        let player2 = Player(
            id: PlayerId(),
            name: "プレイヤー2",
            color: .red,
            position: Position3D(x: 2, y: 0, z: 0)
        ).updateScore(GameScore(paintedArea: 35.0))

        // Set up game state
        gameState.players = [player1, player2]
        gameState.winner = player1
        gameState.currentPhase = .finished
        gameState.totalCoverage = 1.0

        return gameState
    }())
}
