import SwiftUI

struct SettingsView: View {
    @State private var playerName = "プレイヤー1"
    @State private var gameDuration: Double = 180
    @State private var soundEnabled = true
    @State private var hapticEnabled = true
    
    var body: some View {
        Form {
            Section("プレイヤー設定") {
                HStack {
                    Text("プレイヤー名")
                    Spacer()
                    TextField("名前を入力", text: $playerName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(maxWidth: 150)
                }
            }
            
            Section("ゲーム設定") {
                HStack {
                    Text("ゲーム時間")
                    Spacer()
                    Text("\(Int(gameDuration))秒")
                        .foregroundColor(.secondary)
                }
                
                Slider(value: $gameDuration, in: 60...300, step: 30) {
                    Text("ゲーム時間")
                } minimumValueLabel: {
                    Text("1分")
                } maximumValueLabel: {
                    Text("5分")
                }
            }
            
            Section("オーディオ・触覚") {
                Toggle("サウンド", isOn: $soundEnabled)
                Toggle("触覚フィードバック", isOn: $hapticEnabled)
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
        }
        .navigationTitle("設定")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        SettingsView()
    }
}