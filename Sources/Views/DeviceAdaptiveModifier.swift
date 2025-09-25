//
//  DeviceAdaptiveModifier.swift
//  ARSplatoonGame
//
//  Created by System on 2025-01-27.
//

import SwiftUI

// MARK: - DeviceAdaptiveModifier

/// デバイスに応じたUI調整を行うビューモディファイア
struct DeviceAdaptiveModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let deviceCompatibility: DeviceCompatibilityManager
    private let uiAdjustments: UIAdjustments

    init(deviceCompatibility: DeviceCompatibilityManager) {
        self.deviceCompatibility = deviceCompatibility
        uiAdjustments = deviceCompatibility.getUIAdjustments()
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(getScaleFactor())
            .padding(getAdaptivePadding())
    }

    private func getScaleFactor() -> CGFloat {
        if uiAdjustments.isIPad {
            return 1.2 // iPadでは少し大きく表示
        }

        // 画面サイズに応じた調整
        let screenWidth = uiAdjustments.screenSize.width
        if screenWidth < 375 { // iPhone SE等の小さい画面
            return 0.9
        } else if screenWidth > 414 { // iPhone Pro Max等の大きい画面
            return 1.1
        }

        return 1.0
    }

    private func getAdaptivePadding() -> EdgeInsets {
        let safeArea = uiAdjustments.safeAreaInsets

        return EdgeInsets(
            top: max(safeArea.top, 8),
            leading: max(safeArea.left, 16),
            bottom: max(safeArea.bottom, 8),
            trailing: max(safeArea.right, 16)
        )
    }
}

// MARK: - AdaptiveButtonModifier

/// ボタンサイズを調整するモディファイア
struct AdaptiveButtonModifier: ViewModifier {
    private let deviceCompatibility: DeviceCompatibilityManager
    private let uiAdjustments: UIAdjustments

    init(deviceCompatibility: DeviceCompatibilityManager) {
        self.deviceCompatibility = deviceCompatibility
        uiAdjustments = deviceCompatibility.getUIAdjustments()
    }

    func body(content: Content) -> some View {
        content
            .frame(minHeight: getMinButtonHeight())
            .scaleEffect(uiAdjustments.buttonSizeMultiplier)
    }

    private func getMinButtonHeight() -> CGFloat {
        if uiAdjustments.isIPad {
            return 60 // iPadでは大きなボタン
        }
        return 44 // iPhoneでは標準サイズ
    }
}

// MARK: - AdaptiveFontModifier

/// フォントサイズを調整するモディファイア
struct AdaptiveFontModifier: ViewModifier {
    private let baseSize: CGFloat
    private let deviceCompatibility: DeviceCompatibilityManager
    private let uiAdjustments: UIAdjustments

    init(baseSize: CGFloat, deviceCompatibility: DeviceCompatibilityManager) {
        self.baseSize = baseSize
        self.deviceCompatibility = deviceCompatibility
        uiAdjustments = deviceCompatibility.getUIAdjustments()
    }

    func body(content: Content) -> some View {
        content
            .font(.system(size: getAdaptiveSize()))
    }

    private func getAdaptiveSize() -> CGFloat {
        let adjustedSize = baseSize * uiAdjustments.fontSizeMultiplier

        // 画面サイズに応じた微調整
        let screenWidth = uiAdjustments.screenSize.width
        if screenWidth < 375 { // 小さい画面
            return adjustedSize * 0.9
        } else if screenWidth > 414 { // 大きい画面
            return adjustedSize * 1.1
        }

        return adjustedSize
    }
}

// MARK: - AdaptiveLayoutModifier

/// レイアウト方向を調整するモディファイア
struct AdaptiveLayoutModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    private let deviceCompatibility: DeviceCompatibilityManager

    init(deviceCompatibility: DeviceCompatibilityManager) {
        self.deviceCompatibility = deviceCompatibility
    }

    func body(content: Content) -> some View {
        if shouldUseHorizontalLayout() {
            HStack {
                content
            }
        } else {
            VStack {
                content
            }
        }
    }

    private func shouldUseHorizontalLayout() -> Bool {
        let uiAdjustments = deviceCompatibility.getUIAdjustments()

        // iPadの場合は横向きレイアウトを優先
        if uiAdjustments.isIPad, horizontalSizeClass == .regular {
            return true
        }

        // iPhone横向きの場合
        if !uiAdjustments.isIPad,
           horizontalSizeClass == .compact,
           verticalSizeClass == .compact {
            return true
        }

        return false
    }
}

// MARK: - View Extensions

extension View {
    /// デバイスに応じたUI調整を適用
    func deviceAdaptive(_ deviceCompatibility: DeviceCompatibilityManager) -> some View {
        modifier(DeviceAdaptiveModifier(deviceCompatibility: deviceCompatibility))
    }

    /// デバイスに応じたボタンサイズ調整を適用
    func adaptiveButton(_ deviceCompatibility: DeviceCompatibilityManager) -> some View {
        modifier(AdaptiveButtonModifier(deviceCompatibility: deviceCompatibility))
    }

    /// デバイスに応じたフォントサイズ調整を適用
    func adaptiveFont(size: CGFloat, deviceCompatibility: DeviceCompatibilityManager) -> some View {
        modifier(AdaptiveFontModifier(baseSize: size, deviceCompatibility: deviceCompatibility))
    }

    /// デバイスに応じたレイアウト調整を適用
    func adaptiveLayout(_ deviceCompatibility: DeviceCompatibilityManager) -> some View {
        modifier(AdaptiveLayoutModifier(deviceCompatibility: deviceCompatibility))
    }
}
