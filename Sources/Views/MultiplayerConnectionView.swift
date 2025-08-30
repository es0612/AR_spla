import SwiftUI
import Domain

struct MultiplayerConnectionView: View {
    let gameState: GameState
    @Environment(\.dismiss) private var dismiss
    @State private var isSearching = false
    @State private var foundPlayers: [String] = []
    @State private var isConnecting = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("プレイヤーを探しています...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if isSearching || gameState.isConnecting {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text(gameState.isConnecting ? "ゲームを開始中..." : "近くのプレイヤーをスキャン中")
                        .foregroundColor(.secondary)
                } else {
                    Button("検索開始") {
                        startSearching()
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                    .padding(.horizontal)
                    .disabled(isConnecting)
                }
                
                if !foundPlayers.isEmpty && !gameState.isConnecting {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("見つかったプレイヤー:")
                            .font(.headline)
                        
                        ForEach(foundPlayers, id: \.self) { playerName in
                            PlayerConnectionRow(
                                playerName: playerName,
                                isConnecting: isConnecting,
                                onConnect: {
                                    connectToPlayer(playerName)
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                
                // Connection Status
                if gameState.currentPhase == .connecting {
                    VStack(spacing: 10) {
                        Text("接続中...")
                            .font(.headline)
                            .foregroundColor(.orange)
                        
                        Text("相手プレイヤーとの接続を確立しています")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("マルチプレイヤー")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("キャンセル") {
                        if gameState.currentPhase == .connecting {
                            gameState.resetGame()
                        }
                        dismiss()
                    }
                }
            }
            .onChange(of: gameState.currentPhase) { _, newPhase in
                if newPhase == .playing {
                    dismiss()
                }
            }
        }
    }
    
    private func startSearching() {
        isSearching = true
        // TODO: 実際のMultipeer Connectivity実装
        
        // デモ用のシミュレーション
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            foundPlayers = ["プレイヤー2", "プレイヤー3"]
            isSearching = false
        }
    }
    
    private func connectToPlayer(_ playerName: String) {
        isConnecting = true
        
        Task {
            // Create demo players for testing
            let currentPlayer = Player(
                id: PlayerId(),
                name: gameState.playerName,
                color: PlayerColor.blue,
                position: Position3D(x: 0, y: 0, z: 0),
                isActive: true,
                score: GameScore(value: 0)
            )
            
            let opponentPlayer = Player(
                id: PlayerId(),
                name: playerName,
                color: PlayerColor.red,
                position: Position3D(x: 2, y: 0, z: 0),
                isActive: true,
                score: GameScore(value: 0)
            )
            
            await gameState.startGame(with: [currentPlayer, opponentPlayer])
            isConnecting = false
        }
    }
}

struct PlayerConnectionRow: View {
    let playerName: String
    let isConnecting: Bool
    let onConnect: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: "person.circle.fill")
                .foregroundColor(.blue)
            Text(playerName)
            Spacer()
            
            if isConnecting {
                ProgressView()
                    .scaleEffect(0.8)
            } else {
                Button("接続") {
                    onConnect()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    MultiplayerConnectionView(gameState: GameState())
}