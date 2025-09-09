//
//  RTLLayoutManager.swift
//  ARSplatoonGame
//
//  Created by Developer on 2024/12/19.
//

import SwiftUI

// MARK: - RTLLayoutManager

/// RTL（右から左）言語対応のレイアウト管理クラス
@Observable
class RTLLayoutManager {
    static let shared = RTLLayoutManager()

    private let localizationManager = LocalizationManager.shared

    private init() {}

    /// 現在の言語がRTLかどうか
    var isRTL: Bool {
        localizationManager.isRTL
    }

    /// RTL対応のテキスト配置を取得
    var textAlignment: TextAlignment {
        isRTL ? .trailing : .leading
    }

    /// RTL対応のHStack配置を取得
    var hStackAlignment: HorizontalAlignment {
        isRTL ? .trailing : .leading
    }

    /// RTL対応のアライメントを取得
    var alignment: Alignment {
        isRTL ? .trailing : .leading
    }

    /// RTL対応のエッジセットを取得（左右反転）
    func edgeSet(leading: CGFloat = 0, trailing: CGFloat = 0, top: CGFloat = 0, bottom: CGFloat = 0) -> EdgeInsets {
        if isRTL {
            return EdgeInsets(top: top, leading: trailing, bottom: bottom, trailing: leading)
        } else {
            return EdgeInsets(top: top, leading: leading, bottom: bottom, trailing: trailing)
        }
    }

    /// RTL対応のパディングを取得
    func padding(leading: CGFloat = 0, trailing: CGFloat = 0) -> EdgeInsets {
        edgeSet(leading: leading, trailing: trailing)
    }

    /// RTL対応の回転角度を取得（アイコンなどの反転用）
    var rotationAngle: Angle {
        isRTL ? .degrees(180) : .degrees(0)
    }

    /// RTL対応のスケール変換を取得（水平反転用）
    var scaleEffect: CGSize {
        isRTL ? CGSize(width: -1, height: 1) : CGSize(width: 1, height: 1)
    }
}

// MARK: - SwiftUI Extensions

extension View {
    /// RTL対応のテキスト配置を適用
    func rtlTextAlignment() -> some View {
        multilineTextAlignment(RTLLayoutManager.shared.textAlignment)
    }

    /// RTL対応のフレーム配置を適用
    func rtlFrameAlignment() -> some View {
        frame(maxWidth: .infinity, alignment: RTLLayoutManager.shared.alignment)
    }

    /// RTL対応のパディングを適用
    func rtlPadding(leading: CGFloat = 0, trailing: CGFloat = 0, top: CGFloat = 0, bottom: CGFloat = 0) -> some View {
        let edgeInsets = RTLLayoutManager.shared.edgeSet(leading: leading, trailing: trailing, top: top, bottom: bottom)
        return padding(edgeInsets)
    }

    /// RTL対応のアイコン反転を適用
    func rtlIconFlip() -> some View {
        scaleEffect(RTLLayoutManager.shared.scaleEffect)
    }

    /// RTL対応の環境値を設定
    func rtlEnvironment() -> some View {
        environment(\.layoutDirection, RTLLayoutManager.shared.isRTL ? .rightToLeft : .leftToRight)
    }
}

// MARK: - RTL対応のカスタムレイアウト

/// RTL対応のHStack
struct RTLHStack<Content: View>: View {
    let alignment: VerticalAlignment
    let spacing: CGFloat?
    let content: Content

    init(alignment: VerticalAlignment = .center, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        HStack(alignment: alignment, spacing: spacing) {
            content
        }
        .rtlEnvironment()
    }
}

/// RTL対応のVStack
struct RTLVStack<Content: View>: View {
    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let content: Content

    init(alignment: HorizontalAlignment? = nil, spacing: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.alignment = alignment ?? RTLLayoutManager.shared.hStackAlignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        VStack(alignment: alignment, spacing: spacing) {
            content
        }
        .rtlEnvironment()
    }
}

/// RTL対応のナビゲーションバー
struct RTLNavigationBar<Leading: View, Trailing: View, Title: View>: View {
    let leading: Leading
    let trailing: Trailing
    let title: Title

    init(@ViewBuilder leading: () -> Leading, @ViewBuilder trailing: () -> Trailing, @ViewBuilder title: () -> Title) {
        self.leading = leading()
        self.trailing = trailing()
        self.title = title()
    }

    var body: some View {
        HStack {
            if RTLLayoutManager.shared.isRTL {
                trailing
                Spacer()
                title
                Spacer()
                leading
            } else {
                leading
                Spacer()
                title
                Spacer()
                trailing
            }
        }
        .rtlEnvironment()
    }
}

// MARK: - RTL対応のプレビューヘルパー

#if DEBUG
    extension View {
        /// RTL言語でのプレビューを生成
        func rtlPreview() -> some View {
            environment(\.locale, Locale(identifier: "ar")) // アラビア語でテスト
                .environment(\.layoutDirection, .rightToLeft)
        }

        /// 複数言語でのプレビューを生成
        func multiLanguagePreview() -> some View {
            Group {
                self
                    .environment(\.locale, Locale(identifier: "ja"))
                    .previewDisplayName("Japanese")

                self
                    .environment(\.locale, Locale(identifier: "en"))
                    .previewDisplayName("English")

                self
                    .environment(\.locale, Locale(identifier: "ar"))
                    .environment(\.layoutDirection, .rightToLeft)
                    .previewDisplayName("Arabic (RTL)")
            }
        }
    }
#endif
