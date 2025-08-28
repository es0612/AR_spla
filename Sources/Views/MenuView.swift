import SwiftUI

struct MenuView: View {
    @State private var isSearchingForPlayers = false
    
    var body: some View {
        VStack(spacing: 30) {
            Text("ゲームメニュー")
                .font(.largeTitle)
                .fontWeight(.bold)
            
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
                    .background(Color.green)
                    .cornerRadius(12)
                }
                
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
                
                NavigationLink(destination: ARGameView()) {
                    HStack {
                        Image(systemName: "arkit")
                        Text("ARテスト")
                    }
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
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
            MultiplayerConnectionView()
        }
    }
}

#Preview {
    NavigationStack {
        MenuView()
    }
}