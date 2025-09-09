//
//  ErrorHandlingView.swift
//  ARSplatoonGame
//
//  Created by ARSplatoonGame on 2024.
//

import Domain
import SwiftUI

// MARK: - ErrorHandlingView

/// エラー表示とユーザーアクションを提供するビュー
struct ErrorHandlingView: View {
    let error: GameError
    let suggestedActions: [ErrorRecoveryAction]
    let onAction: (ErrorRecoveryAction) -> Void
    let onDismiss: () -> Void

    @State private var showTechnicalDetails = false

    var body: some View {
        VStack(spacing: 20) {
            // エラーアイコン
            Image(systemName: errorIcon)
                .font(.system(size: 50))
                .foregroundColor(errorColor)

            // エラータイトル
            Text(errorTitle)
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            // エラーメッセージ
            Text(error.errorDescription ?? "不明なエラーが発生しました。")
                .font(.body)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            // 復旧提案
            if let suggestion = error.recoverySuggestion {
                Text(suggestion)
                    .font(.callout)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .padding(.top, 5)
            }

            // アクションボタン
            VStack(spacing: 12) {
                ForEach(suggestedActions, id: \.self) { action in
                    ActionButton(action: action) {
                        onAction(action)
                    }
                }
            }
            .padding(.top, 10)

            // 技術的詳細の表示切り替え
            if showTechnicalDetails {
                TechnicalDetailsView(error: error)
                    .transition(.opacity)
            }

            // 技術的詳細の表示切り替えボタン
            Button(showTechnicalDetails ? "詳細を隠す" : "技術的詳細を表示") {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showTechnicalDetails.toggle()
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(24)
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal, 20)
    }

    private var errorIcon: String {
        switch error.severity {
        case .critical:
            return "xmark.circle.fill"
        case .high:
            return "exclamationmark.triangle.fill"
        case .medium:
            return "exclamationmark.circle.fill"
        case .low:
            return "info.circle.fill"
        }
    }

    private var errorColor: Color {
        switch error.severity {
        case .critical:
            return .red
        case .high:
            return .orange
        case .medium:
            return .yellow
        case .low:
            return .blue
        }
    }

    private var errorTitle: String {
        switch error.severity {
        case .critical:
            return "致命的なエラー"
        case .high:
            return "重要なエラー"
        case .medium:
            return "エラーが発生しました"
        case .low:
            return "お知らせ"
        }
    }
}

// MARK: - ActionButton

private struct ActionButton: View {
    let action: ErrorRecoveryAction
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack {
                Image(systemName: actionIcon)
                Text(action.displayName)
            }
            .font(.headline)
            .foregroundColor(actionColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(actionBackgroundColor)
            .cornerRadius(10)
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var actionIcon: String {
        switch action {
        case .retry:
            return "arrow.clockwise"
        case .reconnect:
            return "wifi"
        case .restart:
            return "restart"
        case .settings:
            return "gear"
        case .dismiss:
            return "xmark"
        }
    }

    private var actionColor: Color {
        switch action {
        case .retry, .reconnect, .restart:
            return .white
        case .settings:
            return .white
        case .dismiss:
            return .primary
        }
    }

    private var actionBackgroundColor: Color {
        switch action {
        case .retry, .reconnect, .restart:
            return .blue
        case .settings:
            return .orange
        case .dismiss:
            return Color(.systemGray5)
        }
    }
}

// MARK: - TechnicalDetailsView

private struct TechnicalDetailsView: View {
    let error: GameError

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("技術的詳細")
                .font(.headline)
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 4) {
                DetailRow(label: "エラータイプ", value: String(describing: error))
                DetailRow(label: "重要度", value: error.severity.displayName)
                DetailRow(label: "自動復旧可能", value: error.isRecoverable ? "はい" : "いいえ")
                DetailRow(label: "タイムスタンプ", value: DateFormatter.localizedString(from: Date(), dateStyle: .short, timeStyle: .medium))
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

// MARK: - DetailRow

private struct DetailRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label + ":")
                .font(.caption)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.caption)
                .fontWeight(.medium)
        }
    }
}

// MARK: - ErrorToastView

/// 軽微なエラー用のトースト表示
struct ErrorToastView: View {
    let message: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)

            Text(message)
                .font(.subheadline)
                .multilineTextAlignment(.leading)

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 5, x: 0, y: 2)
        .padding(.horizontal)
    }
}

// MARK: - Preview

#Preview("Critical Error") {
    ErrorHandlingView(
        error: .arUnsupportedDevice,
        suggestedActions: [.settings, .dismiss],
        onAction: { _ in },
        onDismiss: {}
    )
}

#Preview("Network Error") {
    ErrorHandlingView(
        error: .networkConnectionFailed(reason: "接続タイムアウト"),
        suggestedActions: [.retry, .dismiss],
        onAction: { _ in },
        onDismiss: {}
    )
}

#Preview("Error Toast") {
    VStack {
        Spacer()
        ErrorToastView(
            message: "プレイヤーとの接続が一時的に不安定です",
            icon: "wifi.exclamationmark",
            color: .orange
        )
        .padding(.bottom, 100)
    }
    .background(Color(.systemGray6))
}
