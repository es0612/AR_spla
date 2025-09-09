import SwiftUI

struct SettingsView: View {
    @Bindable var gameState: GameState
    @Bindable var tutorialManager: TutorialManager

    var body: some View {
        Form {
            Section("プレイヤー設定") {
                HStack {
                    Text("プレイヤー名")
                    Spacer()
                    TextField("名前を入力", text: $gameState.playerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 150)
                        .disabled(gameState.isGameActive)
                }
            }

            Section("ゲーム設定") {
                HStack {
                    Text("ゲーム時間")
                    Spacer()
                    Text("\(Int(gameState.balanceSettings.gameDuration))秒")
                        .foregroundColor(.secondary)
                }

                Slider(value: $gameState.balanceSettings.gameDuration, in: 60 ... 300, step: 30) {
                    Text("ゲーム時間")
                } minimumValueLabel: {
                    Text("1分")
                } maximumValueLabel: {
                    Text("5分")
                }
                .disabled(gameState.isGameActive)

                Text("ゲーム中は設定を変更できません")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .opacity(gameState.isGameActive ? 1 : 0)
            }

            Section("難易度設定") {
                Picker("難易度", selection: $gameState.balanceSettings.difficultyLevel) {
                    ForEach(GameBalanceSettings.DifficultyLevel.allCases, id: \.self) { level in
                        Text(level.displayName).tag(level)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .disabled(gameState.isGameActive)

                HStack {
                    Button("競技用設定") {
                        gameState.balanceSettings.applyCompetitiveSettings()
                    }
                    .buttonStyle(.bordered)
                    .disabled(gameState.isGameActive)

                    Spacer()

                    Button("カジュアル設定") {
                        gameState.balanceSettings.applyCasualSettings()
                    }
                    .buttonStyle(.bordered)
                    .disabled(gameState.isGameActive)
                }

                Button("デフォルトに戻す") {
                    gameState.balanceSettings.resetToDefaults()
                }
                .foregroundColor(.orange)
                .disabled(gameState.isGameActive)
            }

            Section("詳細バランス設定") {
                Group {
                    HStack {
                        Text("インク発射間隔")
                        Spacer()
                        Text(String(format: "%.1f秒", gameState.balanceSettings.inkShotCooldown))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $gameState.balanceSettings.inkShotCooldown, in: 0.1 ... 1.0, step: 0.1) {
                        Text("インク発射間隔")
                    }
                    .disabled(gameState.isGameActive)

                    HStack {
                        Text("インク射程距離")
                        Spacer()
                        Text(String(format: "%.1fm", gameState.balanceSettings.inkMaxRange))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $gameState.balanceSettings.inkMaxRange, in: 2.0 ... 8.0, step: 0.5) {
                        Text("インク射程距離")
                    }
                    .disabled(gameState.isGameActive)

                    HStack {
                        Text("インクスポットサイズ")
                        Spacer()
                        Text(String(format: "%.2f", gameState.balanceSettings.inkSpotBaseSize))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $gameState.balanceSettings.inkSpotBaseSize, in: 0.2 ... 0.8, step: 0.05) {
                        Text("インクスポットサイズ")
                    }
                    .disabled(gameState.isGameActive)

                    HStack {
                        Text("スタン時間")
                        Spacer()
                        Text(String(format: "%.1f秒", gameState.balanceSettings.playerStunDuration))
                            .foregroundColor(.secondary)
                    }

                    Slider(value: $gameState.balanceSettings.playerStunDuration, in: 1.0 ... 5.0, step: 0.5) {
                        Text("スタン時間")
                    }
                    .disabled(gameState.isGameActive)
                }

                Text("詳細設定は上級者向けです。難易度設定を使用することをお勧めします。")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("オーディオ・触覚") {
                Toggle("サウンド", isOn: $gameState.soundEnabled)
                Toggle("触覚フィードバック", isOn: $gameState.hapticEnabled)
            }

            Section("アクセシビリティ・プライバシー") {
                NavigationLink(destination: AccessibilitySettingsView()) {
                    HStack {
                        Image(systemName: "accessibility")
                            .foregroundColor(.blue)
                        Text("アクセシビリティ設定")
                    }
                }

                NavigationLink(destination: PrivacySettingsView()) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .foregroundColor(.green)
                        Text("プライバシー設定")
                    }
                }
            }

            Section("チュートリアル・ヘルプ") {
                Toggle("チュートリアルを表示", isOn: $tutorialManager.showTutorials)
                Toggle("ヒントを表示", isOn: $tutorialManager.showHints)
                Toggle("ガイダンスを表示", isOn: $tutorialManager.showGuidance)

                Button("チュートリアルをリセット") {
                    tutorialManager.resetTutorials()
                }
                .foregroundColor(.orange)

                Button("ヘルプを表示") {
                    tutorialManager.showHelp(HelpContent.gameHelp)
                }
                .foregroundColor(.blue)
            }

            Section("ゲーム統計") {
                if gameState.currentPhase != .waiting {
                    HStack {
                        Text("現在のフェーズ")
                        Spacer()
                        Text(phaseDisplayName)
                            .foregroundColor(.secondary)
                    }

                    if gameState.isGameActive {
                        HStack {
                            Text("残り時間")
                            Spacer()
                            Text(gameState.formattedRemainingTime)
                                .foregroundColor(.secondary)
                        }

                        HStack {
                            Text("カバー率")
                            Spacer()
                            Text("\(gameState.coveragePercentage)%")
                                .foregroundColor(.secondary)
                        }
                    }

                    if let winner = gameState.winner {
                        HStack {
                            Text("勝者")
                            Spacer()
                            Text(winner.name)
                                .foregroundColor(.green)
                                .fontWeight(.semibold)
                        }
                    }
                }
            }

            Section("情報") {
                HStack {
                    Text("バージョン")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }

                HStack {
                    Text("ビルド")
                    Spacer()
                    Text("1")
                        .foregroundColor(.secondary)
                }
            }

            Section {
                Button("設定を保存") {
                    gameState.saveSettings()
                }
                .frame(maxWidth: .infinity)

                if gameState.currentPhase != .waiting {
                    Button("ゲームをリセット", role: .destructive) {
                        gameState.resetGame()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var phaseDisplayName: String {
        switch gameState.currentPhase {
        case .waiting:
            return "待機中"
        case .connecting:
            return "接続中"
        case .playing:
            return "ゲーム中"
        case .finished:
            return "終了"
        }
    }
}

#Preview {
    NavigationStack {
        SettingsView(gameState: GameState(), tutorialManager: TutorialManager())
    }
}
