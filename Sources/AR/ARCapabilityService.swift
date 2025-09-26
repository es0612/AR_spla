//
//  ARCapabilityService.swift
//  ARSplatoonGame
//
//  Created by System on 2025-01-27.
//

import ARKit
import Foundation
import RealityKit

// MARK: - ARCapabilityService

/// ARの機能差分を管理するサービス
public class ARCapabilityService: ObservableObject {
    // MARK: - Properties

    @Published private(set) var capabilities: ARCapabilities
    @Published private(set) var currentConfiguration: ARConfiguration?

    private let deviceCompatibility: DeviceCompatibilityManager

    // MARK: - Initialization

    init(deviceCompatibility: DeviceCompatibilityManager) {
        self.deviceCompatibility = deviceCompatibility
        capabilities = Self.detectCapabilities()
    }

    // MARK: - Public Methods

    /// 最適なAR設定を取得
    func getOptimalConfiguration() -> ARWorldTrackingConfiguration {
        let configuration = ARWorldTrackingConfiguration()

        // 平面検出設定
        if capabilities.supportsPlaneDetection {
            configuration.planeDetection = [.horizontal, .vertical]
        }

        // LiDARが利用可能な場合の設定
        if capabilities.hasLiDAR {
            // シーン再構築を有効化
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                configuration.sceneReconstruction = .mesh
            }

            // より高精度な平面検出
            configuration.planeDetection = [.horizontal, .vertical]
        }

        // 環境光推定
        configuration.environmentTexturing = .automatic

        // フレームレート設定
        let performanceSettings = deviceCompatibility.getRecommendedSettings()
        if performanceSettings.renderQuality == .high {
            // 高性能デバイスでは高品質設定
            configuration.videoFormat = getBestVideoFormat()
        }

        return configuration
    }

    /// LiDARの有無に応じたゲームフィールド検出方法を取得
    func getFieldDetectionStrategy() -> FieldDetectionStrategy {
        if capabilities.hasLiDAR {
            return .lidarEnhanced
        } else {
            return .traditional
        }
    }

    /// 衝突判定の精度レベルを取得
    func getCollisionDetectionPrecision() -> CollisionPrecision {
        if capabilities.hasLiDAR {
            return .high // LiDARによる高精度メッシュを利用
        } else {
            return .medium // 平面検出ベース
        }
    }

    /// オクルージョン設定を取得
    func getOcclusionSettings() -> OcclusionSettings {
        if capabilities.hasLiDAR, capabilities.supportsOcclusion {
            return OcclusionSettings(
                enabled: true,
                quality: .high,
                useDepthBuffer: true
            )
        } else {
            return OcclusionSettings(
                enabled: false,
                quality: .low,
                useDepthBuffer: false
            )
        }
    }

    /// パフォーマンス最適化設定を適用
    func applyPerformanceOptimizations(to arView: ARView) {
        let performanceSettings = deviceCompatibility.getRecommendedSettings()

        // レンダリング品質設定
        switch performanceSettings.renderQuality {
        case .high:
            arView.renderOptions.insert(.disableMotionBlur)
        case .medium:
            arView.renderOptions.remove(.disableMotionBlur)
        case .low:
            arView.renderOptions = []
        }

        // アンチエイリアシング設定
        if !performanceSettings.antiAliasing {
            arView.renderOptions.insert(.disableAREnvironmentLighting)
        }
    }

    // MARK: - Private Methods

    private static func detectCapabilities() -> ARCapabilities {
        let hasLiDAR = ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh)
        let supportsPlaneDetection = ARWorldTrackingConfiguration.isSupported
        let supportsImageTracking = ARImageTrackingConfiguration.isSupported
        let supportsObjectDetection = ARObjectScanningConfiguration.isSupported
        let supportsOcclusion = hasLiDAR // LiDARがあればオクルージョンも利用可能

        return ARCapabilities(
            hasLiDAR: hasLiDAR,
            supportsPlaneDetection: supportsPlaneDetection,
            supportsImageTracking: supportsImageTracking,
            supportsObjectDetection: supportsObjectDetection,
            supportsOcclusion: supportsOcclusion,
            maxTrackingImages: 4 // デフォルト値を使用
        )
    }

    private func getBestVideoFormat() -> ARConfiguration.VideoFormat {
        let availableFormats = ARWorldTrackingConfiguration.supportedVideoFormats

        // 高解像度・高フレームレートを優先
        let preferredFormat = availableFormats.first { format in
            format.framesPerSecond >= 60 &&
                format.imageResolution.width >= 1_920
        }

        return preferredFormat ?? availableFormats.first!
    }
}

// MARK: - ARCapabilities

struct ARCapabilities {
    let hasLiDAR: Bool
    let supportsPlaneDetection: Bool
    let supportsImageTracking: Bool
    let supportsObjectDetection: Bool
    let supportsOcclusion: Bool
    let maxTrackingImages: Int
}

// MARK: - FieldDetectionStrategy

enum FieldDetectionStrategy {
    case lidarEnhanced // LiDARを使用した高精度検出
    case traditional // 従来の平面検出
}

// MARK: - CollisionPrecision

enum CollisionPrecision {
    case high // LiDARメッシュベース
    case medium // 平面検出ベース
    case low // 簡易計算
}

// MARK: - OcclusionSettings

struct OcclusionSettings {
    let enabled: Bool
    let quality: OcclusionQuality
    let useDepthBuffer: Bool
}

// MARK: - OcclusionQuality

enum OcclusionQuality {
    case high
    case medium
    case low
}
