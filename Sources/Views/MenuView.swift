import SwiftUI

struct MenuView: View {
    let gameState: GameState
    @State private var isSearchingForPlayers = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("ゲームメニュー")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            // Game Status Display
            if gameState.currentPhase != .waiting {
                GameStatusCard(gameState: gameState)
            }
            
            VStack(spacing: 20) {
                Button(action: {
                    isSearchingForPlayers = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("マルチプレイヤー")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(gameState.isConnecting ? Color.gray : Color.green)
                    .cornerRadius(12)
                }
                .disabled(gameState.isConnecting || gameState.isGameActive)
                
                Button(action: {
                    // TODO: シングルプレイヤー機能（将来実装）
                }) {
                    HStack {
                        Image(systemName: "person.fill")
                        Text("シングルプレイヤー")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(12)
                }
                .disabled(true)
                
                NavigationLink(destination: ARGameView(gameState: gameState)) {
                    HStack {
                        Image(systemName: "arkit")
                        Text(gameState.isGameActive ? "ゲームに戻る" : "ARテスト")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(gameState.isGameActive ? Color.blue : Color.orange)
                    .cornerRadius(12)
                }
                
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
            }
            .padding(.horizontal)
            
            Spacer()
        }
        .padding()
        .navigationTitle("メニュー")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $isSearchingForPlayers) {
            MultiplayerConnectionView(gameState: gameState)
        }
    }
}

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
        MenuView(gameState: GameState())
    }
}