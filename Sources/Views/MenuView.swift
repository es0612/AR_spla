import SwiftUI

// MARK: - MenuView

struct MenuView: View {
    let gameState: GameState
    let errorManager: ErrorManager
    let tutorialManager: TutorialManager
    @State private var isSearchingForPlayers = false
    @State private var accessibilityManager = AccessibilityManager()
    @Environment(\.localization) private var localization

    var body: some View {
        RTLVStack(spacing: 30) {
            Text("menu_title".localized)
                .font(.system(size: accessibilityManager.accessibleFontSize(base: 34), weight: .bold))
                .accessibilityAddTraits(.isHeader)
                .accessibilityLabel("app_name".localized + " " + "menu_title".localized)
                .rtlTextAlignment()

            // Game Status Display
            if gameState.currentPhase != .waiting {
                GameStatusCard(gameState: gameState)
            }

            RTLVStack(spacing: 20) {
                Button(action: {
                    accessibilityManager.performHapticFeedback(.light)
                    accessibilityManager.performAudioFeedback(.gameStart)

                    if !tutorialManager.isTutorialCompleted(.multiplayer) {
                        tutorialManager.startTutorial(.multiplayer)
                    } else {
                        isSearchingForPlayers = true
                    }
                }) {
                    RTLHStack {
                        Image(systemName: "person.2.fill")
                            .accessibilityHidden(true)
                            .rtlIconFlip()
                        Text("multiplayer_title".localized)
                    }
                    .font(.system(size: accessibilityManager.accessibleFontSize(base: 20), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accessibilityManager.accessibleColor(for: gameState.isConnecting ? Color.gray : Color.green))
                    .cornerRadius(12)
                }
                .disabled(gameState.isConnecting || gameState.isGameActive)
                .accessibilityLabel("start_game".localized)
                .accessibilityHint(gameState.isConnecting ? "connecting".localized : gameState.isGameActive ? "game_in_progress".localized : "multiplayer_hint".localized)
                .accessibilityAddTraits(gameState.isConnecting || gameState.isGameActive ? .notEnabled : .isButton)

                Button(action: {
                    // TODO: シングルプレイヤー機能（将来実装）
                }) {
                    RTLHStack {
                        Image(systemName: "person.fill")
                            .accessibilityHidden(true)
                            .rtlIconFlip()
                        Text("singleplayer_title".localized)
                    }
                    .font(.system(size: accessibilityManager.accessibleFontSize(base: 20), weight: .semibold))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .disabled(true)
                .accessibilityLabel("singleplayer_title".localized)
                .accessibilityHint("feature_coming_soon".localized)
                .accessibilityAddTraits(.notEnabled)

                NavigationLink(destination: ARGameView(gameState: gameState, errorManager: errorManager, tutorialManager: tutorialManager)) {
                    RTLHStack {
                        Image(systemName: "arkit")
                            .accessibilityHidden(true)
                            .rtlIconFlip()
                        Text(gameState.isGameActive ? "return_to_game".localized : "ar_test".localized)
                    }
                    .font(.system(size: accessibilityManager.accessibleFontSize(base: 20), weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(accessibilityManager.accessibleColor(for: gameState.isGameActive ? Color.blue : Color.orange))
                    .cornerRadius(12)
                }
                .accessibilityLabel(gameState.isGameActive ? "return_to_game".localized : "ar_test".localized)
                .accessibilityHint(gameState.isGameActive ? "return_to_game_hint".localized : "ar_test_hint".localized)

                if gameState.currentPhase == .finished {
                    Button(action: {
                        gameState.resetGame()
                    }) {
                        RTLHStack {
                            Image(systemName: "arrow.clockwise")
                                .rtlIconFlip()
                            Text("new_game".localized)
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
                    RTLHStack {
                        Image(systemName: "star.bubble")
                            .rtlIconFlip()
                        Text("feedback".localized)
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
                    RTLHStack {
                        Image(systemName: "questionmark.circle")
                            .rtlIconFlip()
                        Text("help".localized)
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
        .rtlPadding(leading: 16, trailing: 16, top: 16, bottom: 16)
        .navigationTitle("menu_title".localized)
        .navigationBarTitleDisplayMode(.inline)
        .rtlEnvironment()
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
        RTLVStack(spacing: 8) {
            RTLHStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                    .rtlIconFlip()
                Text(statusText)
                    .font(.headline)
                    .foregroundColor(statusColor)
                    .rtlTextAlignment()
                Spacer()
            }

            if gameState.isGameActive {
                RTLHStack {
                    Text("time_remaining".localized(with: gameState.formattedRemainingTime))
                        .font(.subheadline)
                        .rtlTextAlignment()
                    Spacer()
                    Text("coverage_rate".localized(with: gameState.coveragePercentage))
                        .font(.subheadline)
                        .rtlTextAlignment()
                }
                .foregroundColor(.secondary)
            }

            if !gameState.players.isEmpty {
                RTLHStack {
                    Text("player_count".localized(with: gameState.players.count))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .rtlTextAlignment()
                    Spacer()
                }
            }
        }
        .rtlPadding(leading: 16, trailing: 16, top: 16, bottom: 16)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .rtlPadding(leading: 16, trailing: 16)
        .rtlEnvironment()
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
            return "status_waiting".localized
        case .connecting:
            return "status_connecting".localized
        case .playing:
            return "status_playing".localized
        case .finished:
            return "status_finished".localized
        }
    }
}

#Preview {
    NavigationStack {
        MenuView(gameState: GameState(), errorManager: ErrorManager(), tutorialManager: TutorialManager())
    }
}
