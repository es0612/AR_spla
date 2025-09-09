import ARKit
import Domain
import SwiftUI

// MARK: - ARGameView

struct ARGameView: View {
    @Bindable var gameState: GameState
    let errorManager: ErrorManager
    let tutorialManager: TutorialManager
    @Environment(\.dismiss) private var dismiss
    @State private var isARSupported = ARWorldTrackingConfiguration.isSupported
    @State private var showingGameResult = false

    var body: some View {
        ZStack {
            if isARSupported {
                ARGameViewRepresentable(gameState: gameState, errorManager: errorManager)
                    .ignoresSafeArea()

                // Game UI Overlay
                GameUIOverlay(gameState: gameState, tutorialManager: tutorialManager, onEndGame: {
                    Task {
                        await gameState.endGame()
                    }
                }, onExit: {
                    dismiss()
                })

                // Game Status Messages
                if gameState.currentPhase == .connecting {
                    ConnectionStatusOverlay()
                }

                if gameState.currentPhase == .waiting {
                    WaitingStatusOverlay()
                }

                // AR Guidance Overlay
                if tutorialManager.isShowingGuidance,
                   let guidance = tutorialManager.currentGuidance {
                    VStack {
                        if guidance == .arPlaneDetection {
                            ARPlaneDetectionGuidanceView {
                                tutorialManager.hideGuidance()
                            }
                            .padding(.top, 100)
                        } else {
                            GuidanceOverlayView(
                                guidance: guidance,
                                message: tutorialManager.guidanceMessage,
                                onDismiss: {
                                    tutorialManager.hideGuidance()
                                }
                            )
                            .padding(.top, 100)
                        }
                        Spacer()
                    }
                }
            } else {
                ARNotSupportedView()
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showingGameResult) {
            GameResultView(gameState: gameState)
        }
        .overlay(alignment: .center) {
            // チュートリアル表示
            if tutorialManager.isShowingTutorial,
               let currentStep = tutorialManager.currentTutorialStep {
                TutorialView(
                    step: currentStep,
                    onNext: {
                        tutorialManager.nextTutorialStep()
                    },
                    onPrevious: {
                        tutorialManager.previousTutorialStep()
                    },
                    onSkip: {
                        tutorialManager.skipTutorial()
                    },
                    onComplete: {
                        tutorialManager.completeTutorial()
                    }
                )
            }
        }
        .onChange(of: gameState.currentPhase) { _, newPhase in
            if newPhase == .finished {
                showingGameResult = true
            }
        }
        .onAppear {
            // AR設定チュートリアルを表示
            if !tutorialManager.isTutorialCompleted(.arSetup) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    tutorialManager.startTutorial(.arSetup)
                }
            }

            // AR平面検出ガイダンスを表示
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                tutorialManager.showGuidance(.arPlaneDetection)
            }
        }
    }
}

// MARK: - GameUIOverlay

/// Game UI overlay with timer, scores, and controls
struct GameUIOverlay: View {
    let gameState: GameState
    let tutorialManager: TutorialManager
    let onEndGame: () -> Void
    let onExit: () -> Void

    var body: some View {
        VStack {
            // Top UI - Timer and Controls
            HStack {
                Button("終了") {
                    if gameState.isGameActive {
                        onEndGame()
                    } else {
                        onExit()
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .foregroundColor(.white)
                .cornerRadius(8)

                Spacer()

                if gameState.isGameActive {
                    GameTimerView(gameState: gameState)
                }

                // ヘルプボタン
                Button(action: {
                    tutorialManager.showHelp(HelpContent.gameHelp)
                }) {
                    Image(systemName: "questionmark.circle")
                        .foregroundColor(.white)
                        .font(.title2)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
            .padding()

            Spacer()

            // Bottom UI - Scores
            if gameState.isGameActive || gameState.currentPhase == .finished {
                GameScoreView(gameState: gameState)
                    .padding()
            }
        }
    }
}

// MARK: - GameTimerView

/// Timer display component
struct GameTimerView: View {
    let gameState: GameState

    var body: some View {
        VStack(spacing: 4) {
            Text("残り時間")
                .font(.caption)
                .foregroundColor(.white)
            Text(gameState.formattedRemainingTime)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(timeColor)
                .monospacedDigit()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
    }

    private var timeColor: Color {
        if gameState.remainingTime <= 30 {
            return .red
        } else if gameState.remainingTime <= 60 {
            return .orange
        } else {
            return .white
        }
    }
}

// MARK: - GameScoreView

/// Score display component
struct GameScoreView: View {
    let gameState: GameState

    var body: some View {
        HStack(spacing: 20) {
            // Player scores
            ForEach(Array(gameState.players.enumerated()), id: \.element.id) { index, player in
                PlayerScoreCard(
                    player: player,
                    isCurrentPlayer: index == 0,
                    totalCoverage: gameState.totalCoverage
                )
            }

            if gameState.players.count < 2 {
                // Placeholder for missing opponent
                VStack(spacing: 4) {
                    Text("相手")
                        .font(.caption)
                        .foregroundColor(.white)
                    Text("--")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.7))
                .cornerRadius(8)
            }
        }
    }
}

// MARK: - PlayerScoreCard

/// Individual player score card
struct PlayerScoreCard: View {
    let player: Player
    let isCurrentPlayer: Bool
    let totalCoverage: Float

    var body: some View {
        VStack(spacing: 4) {
            Text(isCurrentPlayer ? "自分" : player.name)
                .font(.caption)
                .foregroundColor(.white)
            Text("\(Int(player.score.paintedArea))%")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(playerColor)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.7))
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(playerColor.opacity(0.5), lineWidth: isCurrentPlayer ? 2 : 0)
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

// MARK: - ConnectionStatusOverlay

/// Connection status overlay
struct ConnectionStatusOverlay: View {
    var body: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .tint(.white)

            Text("接続中...")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("相手プレイヤーとの接続を確立しています")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .padding()
    }
}

// MARK: - WaitingStatusOverlay

/// Waiting status overlay
struct WaitingStatusOverlay: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2")
                .font(.system(size: 48))
                .foregroundColor(.white)

            Text("プレイヤーを待機中")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Text("メニューからマルチプレイヤーを選択してゲームを開始してください")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .background(Color.black.opacity(0.8))
        .cornerRadius(16)
        .padding()
    }
}

// MARK: - ARNotSupportedView

/// AR not supported view
struct ARNotSupportedView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.orange)

            Text("ARがサポートされていません")
                .font(.title2)
                .fontWeight(.bold)

            Text("このデバイスはARKitをサポートしていません。ARKit対応デバイス（iPhone 6s以降、iPad Pro、iPad（第5世代）以降）でお試しください。")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            Text("対応デバイス:")
                .font(.headline)
                .padding(.top)

            VStack(alignment: .leading, spacing: 4) {
                Text("• iPhone 6s以降")
                Text("• iPad Pro（全モデル）")
                Text("• iPad（第5世代）以降")
                Text("• iPad Air（第3世代）以降")
                Text("• iPad mini（第5世代）以降")
            }
            .font(.subheadline)
            .foregroundColor(.secondary)
        }
        .padding()
    }
}

#Preview {
    ARGameView(gameState: GameState(), errorManager: ErrorManager(), tutorialManager: TutorialManager())
}
