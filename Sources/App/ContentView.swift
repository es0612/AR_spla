import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    @State private var errorManager = ErrorManager()
    @State private var tutorialManager = TutorialManager()
    @State private var localizationManager = LocalizationManager.shared

    var body: some View {
        NavigationStack {
            RTLVStack(spacing: 30) {
                Text("app_name".localized)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .rtlTextAlignment()

                Text("app_description".localized)
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .rtlTextAlignment()

                RTLVStack(spacing: 20) {
                    NavigationLink(destination: MenuView(gameState: gameState, errorManager: errorManager, tutorialManager: tutorialManager)) {
                        Text("start_game".localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                            .rtlTextAlignment()
                    }

                    NavigationLink(destination: SettingsView(gameState: gameState, tutorialManager: tutorialManager)) {
                        Text("settings".localized)
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.blue)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue.opacity(0.1))
                            .cornerRadius(12)
                            .rtlTextAlignment()
                    }

                    Button("tutorial".localized) {
                        tutorialManager.startTutorial(.firstLaunch)
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }
                .rtlPadding(leading: 16, trailing: 16)

                Spacer()
            }
            .rtlPadding(leading: 16, trailing: 16, top: 16, bottom: 16)
            .navigationBarHidden(true)
            .rtlEnvironment()
        }
        .environment(\.localization, localizationManager)
        .overlay(alignment: .center) {
            // エラーダイアログ
            if errorManager.isShowingError,
               let error = errorManager.currentError,
               let result = errorManager.currentErrorResult {
                Color.black.opacity(0.4)
                    .ignoresSafeArea()
                    .onTapGesture {
                        // 背景タップでは閉じない
                    }

                ErrorHandlingView(
                    error: error,
                    suggestedActions: result.suggestedActions,
                    onAction: { action in
                        errorManager.executeAction(action)
                    },
                    onDismiss: {
                        errorManager.dismissError()
                    }
                )
            }
        }
        .overlay(alignment: .top) {
            // トーストメッセージ
            if errorManager.isShowingToast,
               let message = errorManager.toastMessage {
                ErrorToastView(
                    message: message,
                    icon: errorManager.toastIcon,
                    color: errorManager.toastColor
                )
                .padding(.top, 50)
                .transition(.move(edge: .top).combined(with: .opacity))
                .onTapGesture {
                    errorManager.dismissToast()
                }
            }
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
        .sheet(isPresented: $tutorialManager.isShowingHelp) {
            if let helpContent = tutorialManager.helpContent {
                HelpView(content: helpContent) {
                    tutorialManager.hideHelp()
                }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: errorManager.isShowingError)
        .animation(.easeInOut(duration: 0.3), value: errorManager.isShowingToast)
        .animation(.easeInOut(duration: 0.3), value: tutorialManager.isShowingTutorial)
        .onAppear {
            // 初回起動時にチュートリアルを表示
            if !tutorialManager.isTutorialCompleted(.firstLaunch) {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    tutorialManager.startTutorial(.firstLaunch)
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
