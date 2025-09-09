//
//  PrivacySettingsView.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/09.
//

import AVFoundation
import SwiftUI

// MARK: - PrivacySettingsView

/// プライバシー設定画面
struct PrivacySettingsView: View {
    // MARK: - Properties

    @Environment(\.dismiss) private var dismiss
    @State private var privacyManager = PrivacyManager()
    @State private var showingPrivacyPolicy = false
    @State private var showingDataDeletionAlert = false
    @State private var showingPermissionAlert = false

    // MARK: - Body

    var body: some View {
        NavigationView {
            List {
                permissionsSection
                dataManagementSection
                complianceSection
            }
            .navigationTitle("プライバシー設定")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacyPolicyView(privacyManager: privacyManager)
        }
        .alert("データ削除の確認", isPresented: $showingDataDeletionAlert) {
            Button("削除", role: .destructive) {
                privacyManager.deleteAllUserData()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("すべてのゲームデータとプライバシー設定が削除されます。この操作は取り消せません。")
        }
        .alert("許可が必要", isPresented: $showingPermissionAlert) {
            Button("設定を開く") {
                openAppSettings()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("ゲームを正常に動作させるために、カメラアクセスの許可が必要です。")
        }
    }

    // MARK: - Sections

    private var permissionsSection: some View {
        Section("アクセス許可") {
            // カメラアクセス
            HStack {
                Image(systemName: "camera.fill")
                    .foregroundColor(.blue)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("カメラアクセス")
                        .font(.headline)
                    Text("ARゲームプレイに必要")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Button(cameraPermissionButtonTitle) {
                    handleCameraPermissionTap()
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.vertical, 4)

            // ローカルネットワーク
            HStack {
                Image(systemName: "network")
                    .foregroundColor(.green)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 4) {
                    Text("ローカルネットワーク")
                        .font(.headline)
                    Text("マルチプレイヤー対戦に必要")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Spacer()

                Text(privacyManager.localNetworkAuthorized ? "許可済み" : "未許可")
                    .font(.caption)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(privacyManager.localNetworkAuthorized ? Color.green.opacity(0.2) : Color.orange.opacity(0.2))
                    .foregroundColor(privacyManager.localNetworkAuthorized ? .green : .orange)
                    .clipShape(Capsule())
            }
            .padding(.vertical, 4)
        }
    }

    private var dataManagementSection: some View {
        Section("データ管理") {
            // プライバシーポリシー
            Button {
                showingPrivacyPolicy = true
            } label: {
                HStack {
                    Image(systemName: "doc.text.fill")
                        .foregroundColor(.blue)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("プライバシーポリシー")
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text("データの取り扱いについて")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
            .padding(.vertical, 4)

            // データ使用量
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .foregroundColor(.purple)
                        .frame(width: 24)

                    Text("データ使用量")
                        .font(.headline)
                }

                Text(privacyManager.getDataUsageEstimate())
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.leading, 32)
            }
            .padding(.vertical, 4)

            // データ削除
            Button {
                showingDataDeletionAlert = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .foregroundColor(.red)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("すべてのデータを削除")
                            .font(.headline)
                            .foregroundColor(.red)
                        Text("ゲーム履歴とプライバシー設定")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Spacer()
                }
            }
            .padding(.vertical, 4)
        }
    }

    private var complianceSection: some View {
        Section("コンプライアンス") {
            // 許可状態の概要
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: privacyManager.hasAllRequiredPermissions ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                        .foregroundColor(privacyManager.hasAllRequiredPermissions ? .green : .orange)
                        .frame(width: 24)

                    Text("許可状態")
                        .font(.headline)
                }

                if privacyManager.hasAllRequiredPermissions {
                    Text("すべての必要な許可が取得されています")
                        .font(.caption)
                        .foregroundColor(.green)
                        .padding(.leading, 32)
                } else {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("以下の許可が不足しています:")
                            .font(.caption)
                            .foregroundColor(.orange)

                        ForEach(privacyManager.getMissingPermissions(), id: \.self) { permission in
                            Text("• \(permission)")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                    .padding(.leading, 32)
                }
            }
            .padding(.vertical, 4)

            // 法的準拠情報
            DisclosureGroup("法的準拠情報") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("GDPR準拠")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(privacyManager.gdprDataProcessingDescription)
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text("個人情報保護法準拠")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    Text(privacyManager.japanPrivacyLawCompliance)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 8)
            }
        }
    }

    // MARK: - Computed Properties

    private var cameraPermissionButtonTitle: String {
        switch privacyManager.cameraAuthorizationStatus {
        case .authorized:
            return "許可済み"
        case .denied, .restricted:
            return "設定で許可"
        case .notDetermined:
            return "許可する"
        @unknown default:
            return "確認中"
        }
    }

    // MARK: - Methods

    private func handleCameraPermissionTap() {
        switch privacyManager.cameraAuthorizationStatus {
        case .notDetermined:
            Task {
                await privacyManager.requestCameraAccess()
            }
        case .denied, .restricted:
            showingPermissionAlert = true
        case .authorized:
            break
        @unknown default:
            break
        }
    }

    private func openAppSettings() {
        if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(settingsUrl)
        }
    }
}

// MARK: - PrivacyPolicyView

struct PrivacyPolicyView: View {
    let privacyManager: PrivacyManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if let content = privacyManager.getPrivacyPolicyContent() {
                        Text(content)
                            .font(.body)
                            .padding()
                    } else {
                        Text("プライバシーポリシーを読み込めませんでした")
                            .foregroundColor(.secondary)
                            .padding()
                    }
                }
            }
            .navigationTitle("プライバシーポリシー")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Preview

#Preview {
    PrivacySettingsView()
}
