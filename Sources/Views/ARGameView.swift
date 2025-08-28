import SwiftUI
import ARKit

struct ARGameView: View {
    @State private var isARSupported = ARWorldTrackingConfiguration.isSupported
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ZStack {
            if isARSupported {
                ARGameViewRepresentable()
                    .ignoresSafeArea()
                
                // ゲームUI オーバーレイ
                VStack {
                    // 上部UI
                    HStack {
                        Button("終了") {
                            // TODO: ゲーム終了処理
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        VStack {
                            Text("残り時間")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("3:00")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // 下部UI
                    HStack {
                        VStack {
                            Text("自分")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("0%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.blue)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                        
                        Spacer()
                        
                        VStack {
                            Text("相手")
                                .font(.caption)
                                .foregroundColor(.white)
                            Text("0%")
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.red)
                        }
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    }
                    .padding()
                }
            } else {
                VStack(spacing: 20) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    
                    Text("ARがサポートされていません")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("このデバイスはARKitをサポートしていません。ARKit対応デバイスでお試しください。")
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .alert("エラー", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
}

#Preview {
    ARGameView()
}