import SwiftUI

struct MultiplayerConnectionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isSearching = false
    @State private var foundPlayers: [String] = []
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                Text("プレイヤーを探しています...")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                if isSearching {
                    ProgressView()
                        .scaleEffect(1.5)
                        .padding()
                    
                    Text("近くのプレイヤーをスキャン中")
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
                }
                
                if !foundPlayers.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("見つかったプレイヤー:")
                            .font(.headline)
                        
                        ForEach(foundPlayers, id: \.self) { player in
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .foregroundColor(.blue)
                                Text(player)
                                Spacer()
                                Button("接続") {
                                    // TODO: 接続処理
                                }
                                .buttonStyle(.borderedProminent)
                            }
                            .padding()
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
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
                        dismiss()
                    }
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
}

#Preview {
    MultiplayerConnectionView()
}