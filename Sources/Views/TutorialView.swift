//
//  TutorialView.swift
//  ARSplatoonGame
//
//  Created by ARSplatoonGame on 2024.
//

import SwiftUI

// MARK: - TutorialView

/// チュートリアル表示ビュー
struct TutorialView: View {
    let step: TutorialStep
    let onNext: () -> Void
    let onPrevious: () -> Void
    let onSkip: () -> Void
    let onComplete: () -> Void

    @State private var showAnimation = false

    var body: some View {
        ZStack {
            // 背景
            Color.black.opacity(0.8)
                .ignoresSafeArea()

            VStack(spacing: 24) {
                // アイコンとアニメーション
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.2))
                        .frame(width: 120, height: 120)
                        .scaleEffect(showAnimation ? 1.1 : 1.0)
                        .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: showAnimation)

                    Image(systemName: step.icon)
                        .font(.system(size: 48))
                        .foregroundColor(.blue)
                }

                // タイトル
                Text(step.title)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)

                // コンテンツ
                Text(step.content)
                    .font(.body)
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 20)
                    .lineLimit(nil)

                // プログレスインジケーター
                TutorialProgressView(currentStep: step)

                // ボタン
                VStack(spacing: 12) {
                    HStack(spacing: 16) {
                        // 前へボタン
                        if step.previousStep != nil {
                            Button("前へ") {
                                onPrevious()
                            }
                            .tutorialButtonStyle(.secondary)
                        }

                        // 次へ/完了ボタン
                        Button(step.nextStep != nil ? "次へ" : "完了") {
                            if step.nextStep != nil {
                                onNext()
                            } else {
                                onComplete()
                            }
                        }
                        .tutorialButtonStyle(.primary)
                    }

                    // スキップボタン
                    Button("スキップ") {
                        onSkip()
                    }
                    .tutorialButtonStyle(.tertiary)
                }
                .padding(.top, 8)
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
            )
            .padding(.horizontal, 20)
        }
        .onAppear {
            showAnimation = true
        }
    }
}

// MARK: - TutorialProgressView

/// チュートリアルの進行状況を表示するビュー
struct TutorialProgressView: View {
    let currentStep: TutorialStep

    private var allSteps: [TutorialStep] {
        TutorialStep.allCases.filter { $0.tutorialType == currentStep.tutorialType }
    }

    private var currentIndex: Int {
        allSteps.firstIndex(of: currentStep) ?? 0
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< allSteps.count, id: \.self) { index in
                Circle()
                    .fill(index <= currentIndex ? Color.blue : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(index == currentIndex ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: 0.3), value: currentIndex)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - TutorialButtonStyle

extension View {
    func tutorialButtonStyle(_ style: TutorialButtonStyleType) -> some View {
        modifier(TutorialButtonStyleModifier(style: style))
    }
}

enum TutorialButtonStyleType {
    case primary
    case secondary
    case tertiary
}

struct TutorialButtonStyleModifier: ViewModifier {
    let style: TutorialButtonStyleType

    func body(content: Content) -> some View {
        content
            .font(.headline)
            .foregroundColor(textColor)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)
            .background(backgroundColor)
            .cornerRadius(25)
            .overlay(
                RoundedRectangle(cornerRadius: 25)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
    }

    private var textColor: Color {
        switch style {
        case .primary:
            return .white
        case .secondary:
            return .blue
        case .tertiary:
            return .gray
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .primary:
            return .blue
        case .secondary:
            return .clear
        case .tertiary:
            return .clear
        }
    }

    private var borderColor: Color {
        switch style {
        case .primary:
            return .clear
        case .secondary:
            return .blue
        case .tertiary:
            return .gray.opacity(0.5)
        }
    }

    private var borderWidth: CGFloat {
        switch style {
        case .primary:
            return 0
        case .secondary, .tertiary:
            return 1
        }
    }
}

// MARK: - GuidanceOverlayView

/// ガイダンス表示オーバーレイ
struct GuidanceOverlayView: View {
    let guidance: GuidanceType
    let message: String
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Image(systemName: guidance.icon)
                    .foregroundColor(guidance.color)
                    .font(.title2)

                Text(message)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)

                Spacer()

                if guidance.autoHideDuration == 0 {
                    Button(action: onDismiss) {
                        Image(systemName: "xmark")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal)
    }
}

// MARK: - HelpView

/// ヘルプ表示ビュー
struct HelpView: View {
    let content: HelpContent
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 24) {
                    ForEach(content.sections.indices, id: \.self) { sectionIndex in
                        let section = content.sections[sectionIndex]

                        VStack(alignment: .leading, spacing: 12) {
                            Text(section.title)
                                .font(.title2)
                                .fontWeight(.bold)
                                .foregroundColor(.primary)

                            ForEach(section.items.indices, id: \.self) { itemIndex in
                                let item = section.items[itemIndex]
                                HelpItemView(item: item)
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(content.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") {
                        onDismiss()
                    }
                }
            }
        }
    }
}

// MARK: - HelpItemView

/// ヘルプアイテム表示ビュー
struct HelpItemView: View {
    let item: HelpItem

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(item.title)
                .font(.headline)
                .foregroundColor(.primary)

            Text(item.description)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
}

// MARK: - AR Plane Detection Guidance

/// AR平面検出ガイダンス専用ビュー
struct ARPlaneDetectionGuidanceView: View {
    let onDismiss: () -> Void
    @State private var animationOffset: CGFloat = 0

    var body: some View {
        VStack(spacing: 20) {
            // アニメーション付きアイコン
            ZStack {
                Circle()
                    .stroke(Color.blue.opacity(0.3), lineWidth: 2)
                    .frame(width: 80, height: 80)

                Image(systemName: "viewfinder")
                    .font(.system(size: 32))
                    .foregroundColor(.blue)
                    .offset(y: animationOffset)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: animationOffset)
            }

            VStack(spacing: 8) {
                Text("平面を検出中")
                    .font(.headline)
                    .fontWeight(.semibold)

                Text("デバイスをゆっくりと動かして\n周囲の平面をスキャンしてください")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            // ヒント
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Image(systemName: "lightbulb")
                        .foregroundColor(.yellow)
                    Text("ヒント:")
                        .font(.caption)
                        .fontWeight(.semibold)
                }

                Text("• 明るい場所で行ってください")
                Text("• テクスチャのある平面が検出しやすいです")
                Text("• 床や机などの水平面を狙ってください")
            }
            .font(.caption)
            .foregroundColor(.secondary)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
        .padding(.horizontal)
        .onAppear {
            animationOffset = -5
        }
    }
}

// MARK: - Preview

#Preview("Tutorial") {
    TutorialView(
        step: .welcome,
        onNext: {},
        onPrevious: {},
        onSkip: {},
        onComplete: {}
    )
}

#Preview("Guidance") {
    ZStack {
        Color.gray.ignoresSafeArea()

        VStack {
            Spacer()
            GuidanceOverlayView(
                guidance: .arPlaneDetection,
                message: "デバイスを動かして平面を検出してください",
                onDismiss: {}
            )
            .padding(.bottom, 100)
        }
    }
}

#Preview("Help") {
    HelpView(
        content: HelpContent.gameHelp,
        onDismiss: {}
    )
}

#Preview("AR Guidance") {
    ZStack {
        Color.black.opacity(0.3).ignoresSafeArea()
        ARPlaneDetectionGuidanceView(onDismiss: {})
    }
}
