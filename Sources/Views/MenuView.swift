import SwiftUI

// MARK: - MenuView

struct MenuView: View {
    let gameState: GameState
    let errorManager: ErrorManager
    let tutorialManager: TutorialManager
    @State private var isSearchingForPlayers = false
    @State private var accessibilityManager = AccessibilityManager()

    var body: some View {
        VStack(spacing: 30) {
            Text("ゲームメニュー")
                .font(.system(size: accessibilityManager.accessibleFontSize(base: 34), weight: .bold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("ARスプラトゥーンゲーム メインメニュー")

            // Game Status Display
            if gameState.currentPhase != .waiting {
                GameStatusCard(gameState: gameState)
            }

            VStack(spacing: 20) {
                Button(action: {
                    accessibilityManager.performHapticFeedback(.light)
                    accessibilityManager.performAudioFeedback(.gameStart)

                    if !tutorialManager.isTutorialCompleted(.multiplayer) {
                        tutorialManager.startTutorial(.multiplayer)
                    } else {
                        isSearchingForPlayers = true
                    }
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                            .accessibilityHidden(true)
                        Text("マルチプレイヤー")
                    }
                    .font(.system(size: accessibilityManager.accessibleFontSize(base: 20), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accessibilityManager.accessibleColor(for: gameState.isConnecting ? Color.gray : Color.green))
                    .cornerRadius(12)
                }
                .disabled(gameState.isConnecting || gameState.isGameActive)
                .accessibilityLabel("マルチプレイヤーゲームを開始")
                .accessibilityHint(gameState.isConnecting ? "現在接続中です" : gameState.isGameActive ? "ゲーム中のため利用できません" : "近くのプレイヤーとの対戦を開始します")
                .accessibilityAddTraits(gameState.isConnecting || gameState.isGameActive ? .notEnabled : .isButton)

                Button(action: {
                    // TODO: シングルプレイヤー機能（将来実装）
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                            .accessibilityHidden(true)
                        Text("シングルプレイヤー")
                    }
                    .font(.system(size: accessibilityManager.accessibleFontSize(base: 20), weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .disabled(true)
                .accessibilityLabel("シングルプレイヤーゲーム")
                .accessibilityHint("現在開発中のため利用できません")
                .accessibilityAddTraits(.notEnabled)

                NavigationLink(destination: ARGameView(gameState: gameState, errorManager: errorManager, tutorialManager: tutorialManager)) {
                    HStack {
                        Image(systemName: "arkit")
                            .accessibilityHidden(true)
                        Text(gameState.isGameActive ? "ゲームに戻る" : "ARテスト")
                    }
                    .font(.system(size: accessibilityManager.accessibleFontSize(base: 20), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accessibilityManager.accessibleColor(for: gameState.isGameActive ? Color.blue : Color.orange))
                    .cornerRadius(12)
                }
                .accessibilityLabel(gameState.isGameActive ? "進行中のゲームに戻る" : "ARゲーム機能をテスト")
                .accessibilityHint(gameState.isGameActive ? "現在進行中のゲームに戻ります" : "ARカメラを使用してゲーム機能をテストします")

                if gameState.currentPhase == .finished {
                    Button(action: {
                        gameState.resetGame()
                    }) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("新しいゲーム")
                        }
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(12)
                    }
                }

                // フィードバックボタン
                NavigationLink(destination: GameFeedbackView(feedbackManager: gameState.feedbackManager)) {
                    HStack {
                        Image(systemName: "star.bubble")
                        Text("フィードバック")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.purple)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple.opacity(0.1))
                    .cornerRadius(12)
                }

                // ヘルプボタン
                Button(action: {
                    tutorialManager.showHelp(HelpContent.gameHelp)
                }) {
                    HStack {
                        Image(systemName: "questionmark.circle")
                        Text("ヘルプ")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.blue)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)

            Spacer()
        }
        .padding()
        .navigationTitle("メニュー")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isSearchingForPlayers) {
            MultiplayerConnectionView(gameState: gameState, errorManager: errorManager)
        }
        .overlay(alignment: .center) {
            // チュートリアル表示
            if tutorialManager.isShowingTutorial,
               let currentStep = tutorialManager.currentTutorialStep {
                TutorialView(
                    step: currentStep,
                    onNext: {
                        tutorialManager.nextTutorialStep()
                        if currentStep == .gameStart {
                            isSearchingForPlayers = true
                        }
                    },
                    onPrevious: {
                        tutorialManager.previousTutorialStep()
                    },
                    onSkip: {
                        tutorialManager.skipTutorial()
                    },
                    onComplete: {
                        tutorialManager.completeTutorial()
                        if currentStep.tutorialType == .multiplayer {
                            isSearchingForPlayers = true
                        }
                    }
                )
            }
        }
    }
}

// MARK: - GameStatusCard

/// Card displaying current game status
struct GameStatusCard: View {
    let gameState: GameState

    var body: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(statusColor)
                Spacer()
            }

            if gameState.isGameActive {
                HStack {
                    Text("残り時間: \(gameState.formattedRemainingTime)")
                        .font(.subheadline)
                    Spacer()
                    Text("カバー率: \(gameState.coveragePercentage)%")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
            }

            if !gameState.players.isEmpty {
                HStack {
                    Text("プレイヤー: \(gameState.players.count)人")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
    }

    private var statusIcon: String {
        switch gameState.currentPhase {
        case .waiting:
            return "clock"
        case .connecting:
            return "wifi"
        case .playing:
            return "gamecontroller"
        case .finished:
            return "flag.checkered"
        }
    }

    private var statusColor: Color {
        switch gameState.currentPhase {
        case .waiting:
            return .gray
        case .connecting:
            return .orange
        case .playing:
            return .green
        case .finished:
            return .blue
        }
    }

    private var statusText: String {
        switch gameState.currentPhase {
        case .waiting:
            return "待機中"
        case .connecting:
            return "接続中..."
        case .playing:
            return "ゲーム中"
        case .finished:
            return "ゲーム終了"
        }
    }
}

#Preview {
    NavigationStack {
        MenuView(gameState: GameState(), errorManager: ErrorManager(), tutorialManager: TutorialManager())
    }
}
