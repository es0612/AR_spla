//
//  DeviceCompatibilityManager.swift
//  ARSplatoonGame
//
//  Created by System on 2025-01-27.
//

import ARKit
import Foundation
import UIKit

// MARK: - DeviceCompatibilityManager

/// デバイス互換性を管理するマネージャー
@Observable
public class DeviceCompatibilityManager {
    // MARK: - Properties

    /// 現在のデバイス情報
    private(set) var deviceInfo: DeviceInfo

    /// ARKit対応状況
    private(set) var arKitSupport: ARKitSupport

    /// 画面サイズ情報
    private(set) var screenInfo: ScreenInfo

    // MARK: - Initialization

    init() {
        deviceInfo = Self.detectDeviceInfo()
        arKitSupport = Self.detectARKitSupport()
        screenInfo = Self.detectScreenInfo()
    }

    // MARK: - Public Methods

    /// デバイスがゲームに対応しているかチェック
    func isDeviceSupported() -> Bool {
        deviceInfo.isSupported && arKitSupport.isSupported
    }

    /// LiDARセンサーが利用可能かチェック
    func isLiDARAvailable() -> Bool {
        arKitSupport.hasLiDAR
    }

    /// 推奨設定を取得
    func getRecommendedSettings() -> GamePerformanceSettings {
        switch deviceInfo.performanceTier {
        case .high:
            return GamePerformanceSettings(
                maxInkSpots: 1_000,
                renderQuality: .high,
                particleCount: .high,
                shadowQuality: .high,
                antiAliasing: true
            )
        case .medium:
            return GamePerformanceSettings(
                maxInkSpots: 500,
                renderQuality: .medium,
                particleCount: .medium,
                shadowQuality: .medium,
                antiAliasing: true
            )
        case .low:
            return GamePerformanceSettings(
                maxInkSpots: 250,
                renderQuality: .low,
                particleCount: .low,
                shadowQuality: .low,
                antiAliasing: false
            )
        }
    }

    /// UI調整設定を取得
    func getUIAdjustments() -> UIAdjustments {
        UIAdjustments(
            screenSize: screenInfo.size,
            safeAreaInsets: screenInfo.safeAreaInsets,
            isIPad: deviceInfo.isIPad,
            scaleFactor: screenInfo.scaleFactor,
            buttonSizeMultiplier: deviceInfo.isIPad ? 1.2 : 1.0,
            fontSizeMultiplier: deviceInfo.isIPad ? 1.1 : 1.0
        )
    }

    // MARK: - Private Methods

    private static func detectDeviceInfo() -> DeviceInfo {
        let device = UIDevice.current
        let modelName = getDeviceModelName()

        return DeviceInfo(
            modelName: modelName,
            systemVersion: device.systemVersion,
            isIPad: device.userInterfaceIdiom == .pad,
            performanceTier: getPerformanceTier(for: modelName),
            isSupported: isDeviceSupported(modelName: modelName)
        )
    }

    private static func detectARKitSupport() -> ARKitSupport {
        let isSupported = ARWorldTrackingConfiguration.isSupported
        let hasLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        let supportsPlaneDetection = ARWorldTrackingConfiguration.isSupported // 平面検出は基本的にサポートされている
        let supportsImageTracking = ARImageTrackingConfiguration.isSupported

        return ARKitSupport(
            isSupported: isSupported,
            hasLiDAR: hasLiDAR,
            supportsPlaneDetection: supportsPlaneDetection,
            supportsImageTracking: supportsImageTracking,
            supportedFrameRates: getSupportedFrameRates()
        )
    }

    private static func detectScreenInfo() -> ScreenInfo {
        let screen = UIScreen.main
        let bounds = screen.bounds
        let safeAreaInsets = UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.windows.first?.safeAreaInsets ?? .zero

        return ScreenInfo(
            size: bounds.size,
            scaleFactor: screen.scale,
            safeAreaInsets: safeAreaInsets,
            nativeScale: screen.nativeScale
        )
    }

    private static func getDeviceModelName() -> String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)) ?? UnicodeScalar(0)!)
        }
        return identifier
    }

    private static func getPerformanceTier(for modelName: String) -> PerformanceTier {
        // iPhone 15 Pro/Pro Max, iPhone 14 Pro/Pro Max - High tier
        if modelName.contains("iPhone16,1") || modelName.contains("iPhone16,2") ||
            modelName.contains("iPhone15,2") || modelName.contains("iPhone15,3") {
            return .high
        }

        // iPhone 15/15 Plus, iPhone 14/14 Plus, iPhone 13 series - Medium tier
        if modelName.contains("iPhone15,4") || modelName.contains("iPhone15,5") ||
            modelName.contains("iPhone14,7") || modelName.contains("iPhone14,8") ||
            modelName.contains("iPhone14,2") || modelName.contains("iPhone14,3") ||
            modelName.contains("iPhone14,4") || modelName.contains("iPhone14,5") {
            return .medium
        }

        // iPhone 12 series and older supported devices - Low tier
        if modelName.contains("iPhone13,") {
            return .medium // iPhone 12 series is still capable
        }

        // iPad Pro models - High tier
        if modelName.contains("iPad13,") || modelName.contains("iPad14,") {
            return .high
        }

        // Other iPad models - Medium tier
        if modelName.contains("iPad") {
            return .medium
        }

        return .low
    }

    private static func isDeviceSupported(modelName: String) -> Bool {
        // iPhone 12以降をサポート
        if modelName.contains("iPhone13,") || // iPhone 12 series
            modelName.contains("iPhone14,") || // iPhone 13/14 series
            modelName.contains("iPhone15,") || // iPhone 15 series
            modelName.contains("iPhone16,") { // iPhone 16 series (future)
            return true
        }

        // iPad Pro (2020以降)をサポート
        if modelName.contains("iPad13,") || modelName.contains("iPad14,") {
            return true
        }

        return false
    }

    private static func getSupportedFrameRates() -> [Int] {
        // デバイスの性能に応じてサポートするフレームレートを決定
        [30, 60] // 基本的に30fps、高性能デバイスでは60fps
    }
}

// MARK: - DeviceInfo

struct DeviceInfo {
    let modelName: String
    let systemVersion: String
    let isIPad: Bool
    let performanceTier: PerformanceTier
    let isSupported: Bool
}

// MARK: - ARKitSupport

struct ARKitSupport {
    let isSupported: Bool
    let hasLiDAR: Bool
    let supportsPlaneDetection: Bool
    let supportsImageTracking: Bool
    let supportedFrameRates: [Int]
}

// MARK: - ScreenInfo

struct ScreenInfo {
    let size: CGSize
    let scaleFactor: CGFloat
    let safeAreaInsets: UIEdgeInsets
    let nativeScale: CGFloat
}

// MARK: - PerformanceTier

enum PerformanceTier {
    case high
    case medium
    case low
}

// MARK: - GamePerformanceSettings

struct GamePerformanceSettings {
    let maxInkSpots: Int
    let renderQuality: RenderQuality
    let particleCount: ParticleCount
    let shadowQuality: ShadowQuality
    let antiAliasing: Bool
}

// MARK: - RenderQuality

enum RenderQuality {
    case high
    case medium
    case low
}

// MARK: - ParticleCount

enum ParticleCount {
    case high
    case medium
    case low
}

// MARK: - ShadowQuality

enum ShadowQuality {
    case high
    case medium
    case low
}

// MARK: - UIAdjustments

struct UIAdjustments {
    let screenSize: CGSize
    let safeAreaInsets: UIEdgeInsets
    let isIPad: Bool
    let scaleFactor: CGFloat
    let buttonSizeMultiplier: CGFloat
    let fontSizeMultiplier: CGFloat
}
