import SwiftUI

struct SettingsView: View {
    @Bindable var gameState: GameState

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
                    Text("\(Int(gameState.gameDuration))秒")
                        .foregroundColor(.secondary)
                }

                Slider(value: $gameState.gameDuration, in: 60 ... 300, step: 30) {
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

            Section("オーディオ・触覚") {
                Toggle("サウンド", isOn: $gameState.soundEnabled)
                Toggle("触覚フィードバック", isOn: $gameState.hapticEnabled)
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
        SettingsView(gameState: GameState())
    }
}
