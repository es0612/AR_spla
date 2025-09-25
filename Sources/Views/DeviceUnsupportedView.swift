//
//  DeviceUnsupportedView.swift
//  ARSplatoonGame
//
//  Created by System on 2025-01-27.
//

import SwiftUI

/// デバイス非対応時の表示ビュー
struct DeviceUnsupportedView: View {
    private let deviceCompatibility: DeviceCompatibilityManager

    init(deviceCompatibility: DeviceCompatibilityManager) {
        self.deviceCompatibility = deviceCompatibility
    }

    var body: some View {
        VStack(spacing: 30) {
            // アイコン
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 80))
                .foregroundColor(.orange)

            // タイトル
            Text("device_unsupported_title".localized)
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // 説明文
            VStack(spacing: 16) {
                Text("device_unsupported_description".localized)
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)

                if !deviceCompatibility.arKitSupport.isSupported {
                    Text("arkit_not_supported".localized)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                }

                if !deviceCompatibility.deviceInfo.isSupported {
                    Text("device_too_old".localized)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.red)
                }
            }

            // 推奨デバイス情報
            VStack(alignment: .leading, spacing: 8) {
                Text("recommended_devices".localized)
                    .font(.headline)
                    .fontWeight(.semibold)

                VStack(alignment: .leading, spacing: 4) {
                    Text("• iPhone 12以降")
                    Text("• iPad Pro (2020年以降)")
                    Text("• iOS 17.0以降")
                }
                .font(.callout)
                .foregroundColor(.secondary)
            }
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(12)

            Spacer()

            // 詳細情報ボタン
            Button("show_device_info".localized) {
                // デバイス情報を表示（デバッグ用）
                showDeviceInfo()
            }
            .font(.callout)
            .foregroundColor(.blue)
        }
        .padding()
        .navigationBarHidden(true)
    }

    private func showDeviceInfo() {
        let deviceInfo = deviceCompatibility.deviceInfo
        let arSupport = deviceCompatibility.arKitSupport

        let alert = """
        デバイス情報:
        モデル: \(deviceInfo.modelName)
        システム: iOS \(deviceInfo.systemVersion)
        iPad: \(deviceInfo.isIPad ? "はい" : "いいえ")
        パフォーマンス: \(deviceInfo.performanceTier)

        AR対応:
        ARKit: \(arSupport.isSupported ? "対応" : "非対応")
        LiDAR: \(arSupport.hasLiDAR ? "あり" : "なし")
        平面検出: \(arSupport.supportsPlaneDetection ? "対応" : "非対応")
        """

        print(alert) // デバッグ用
    }
}

#Preview {
    DeviceUnsupportedView(deviceCompatibility: DeviceCompatibilityManager())
}
