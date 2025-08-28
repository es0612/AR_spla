import SwiftUI

struct ContentView: View {
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
                    NavigationLink(destination: MenuView()) {
                        Text("ゲーム開始")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    
                    NavigationLink(destination: SettingsView()) {
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
        }
    }
}

#Preview {
    ContentView()
}