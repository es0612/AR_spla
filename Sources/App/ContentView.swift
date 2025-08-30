import SwiftUI

struct ContentView: View {
    @State private var gameState = GameState()
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("AR Splatoon")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("ARでスプラトゥーン風対戦ゲーム")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                VStack(spacing: 20) {
                    NavigationLink(destination: MenuView(gameState: gameState)) {
                        Text("ゲーム開始")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: SettingsView(gameState: gameState)) {
                        Text("設定")
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
            .navigationBarHidden(true)
            .alert("エラー", isPresented: $gameState.isShowingError) {
                Button("OK") {
                    gameState.clearError()
                }
            } message: {
                Text(gameState.lastError?.localizedDescription ?? "不明なエラーが発生しました")
            }
        }
    }
}

#Preview {
    ContentView()
}