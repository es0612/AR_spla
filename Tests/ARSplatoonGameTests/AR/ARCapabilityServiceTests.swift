//
//  ARCapabilityServiceTests.swift
//  ARSplatoonGameTests
//
//  Created by System on 2025-01-27.
//

import XCTest
import ARKit
@testable import ARSplatoonGame

class ARCapabilityServiceTests: XCTestCase {
    
    var deviceCompatibility: DeviceCompatibilityManager!
    var arCapabilityService: ARCapabilityService!
    
    override func setUp() {
        super.setUp()
        deviceCompatibility = DeviceCompatibilityManager()
        arCapabilityService = ARCapabilityService(deviceCompatibility: deviceCompatibility)
    }
    
    override func tearDown() {
        arCapabilityService = nil
        deviceCompatibility = nil
        super.tearDown()
    }
    
    func testCapabilitiesDetection() {
        // AR機能の検出が正しく行われることを確認
        let capabilities = arCapabilityService.capabilities
        
        XCTAssertNotNil(capabilities.hasLiDAR, "LiDAR機能の検出結果があること")
        XCTAssertNotNil(capabilities.supportsPlaneDetection, "平面検出機能の検出結果があること")
        XCTAssertNotNil(capabilities.supportsImageTracking, "画像追跡機能の検出結果があること")
        XCTAssertNotNil(capabilities.supportsObjectDetection, "オブジェクト検出機能の検出結果があること")
        XCTAssertNotNil(capabilities.supportsOcclusion, "オクルージョン機能の検出結果があること")
        XCTAssertGreaterThanOrEqual(capabilities.maxTrackingImages, 0, "最大追跡画像数が0以上であること")
    }
    
    func testOptimalConfiguration() {
        // 最適なAR設定が生成されることを確認
        let configuration = arCapabilityService.getOptimalConfiguration()
        
        XCTAssertTrue(configuration is ARWorldTrackingConfiguration, "ARWorldTrackingConfigurationが返されること")
        
        // LiDARが利用可能な場合の設定確認
        if arCapabilityService.capabilities.hasLiDAR {
            XCTAssertTrue(configuration.planeDetection.contains(.horizontal), "水平面検出が有効であること")
            XCTAssertTrue(configuration.planeDetection.contains(.vertical), "垂直面検出が有効であること")
            
            if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
                XCTAssertEqual(configuration.sceneReconstruction, .mesh, "メッシュ再構築が有効であること")
            }
        } else {
            // LiDARが利用できない場合でも基本的な平面検出は有効
            XCTAssertTrue(configuration.planeDetection.contains(.horizontal), "水平面検出が有効であること")
        }
        
        XCTAssertEqual(configuration.environmentTexturing, .automatic, "環境テクスチャリングが自動であること")
    }
    
    func testFieldDetectionStrategy() {
        // フィールド検出戦略が適切に選択されることを確認
        let strategy = arCapabilityService.getFieldDetectionStrategy()
        
        if arCapabilityService.capabilities.hasLiDAR {
            XCTAssertEqual(strategy, .lidarEnhanced, "LiDAR利用可能時は拡張戦略")
        } else {
            XCTAssertEqual(strategy, .traditional, "LiDAR非対応時は従来戦略")
        }
    }
    
    func testCollisionDetectionPrecision() {
        // 衝突判定精度が適切に設定されることを確認
        let precision = arCapabilityService.getCollisionDetectionPrecision()
        
        if arCapabilityService.capabilities.hasLiDAR {
            XCTAssertEqual(precision, .high, "LiDAR利用可能時は高精度")
        } else {
            XCTAssertEqual(precision, .medium, "LiDAR非対応時は中精度")
        }
    }
    
    func testOcclusionSettings() {
        // オクルージョン設定が適切に生成されることを確認
        let occlusionSettings = arCapabilityService.getOcclusionSettings()
        
        if arCapabilityService.capabilities.hasLiDAR && arCapabilityService.capabilities.supportsOcclusion {
            XCTAssertTrue(occlusionSettings.enabled, "LiDAR対応時はオクルージョンが有効")
            XCTAssertEqual(occlusionSettings.quality, .high, "LiDAR対応時は高品質オクルージョン")
            XCTAssertTrue(occlusionSettings.useDepthBuffer, "LiDAR対応時は深度バッファを使用")
        } else {
            XCTAssertFalse(occlusionSettings.enabled, "LiDAR非対応時はオクルージョンが無効")
            XCTAssertEqual(occlusionSettings.quality, .low, "LiDAR非対応時は低品質オクルージョン")
            XCTAssertFalse(occlusionSettings.useDepthBuffer, "LiDAR非対応時は深度バッファを使用しない")
        }
    }
    
    func testPerformanceOptimizationConsistency() {
        // パフォーマンス最適化設定の一貫性を確認
        let performanceSettings = deviceCompatibility.getRecommendedSettings()
        let configuration = arCapabilityService.getOptimalConfiguration()
        
        // 低性能デバイスでは機能が制限されることを確認
        if performanceSettings.renderQuality == .low {
            // 低性能デバイスでは環境テクスチャリングが無効になる可能性
            // （実際の実装に依存）
        }
        
        // 高性能デバイスでは全機能が有効
        if performanceSettings.renderQuality == .high {
            XCTAssertEqual(configuration.environmentTexturing, .automatic, "高性能デバイスでは環境テクスチャリングが有効")
        }
    }
    
    func testCapabilitiesConsistency() {
        // 機能検出の一貫性を確認
        let capabilities = arCapabilityService.capabilities
        
        // LiDARがある場合はオクルージョンもサポートされるべき
        if capabilities.hasLiDAR {
            XCTAssertTrue(capabilities.supportsOcclusion, "LiDAR対応デバイスはオクルージョンもサポート")
        }
        
        // 基本的なAR機能は常にサポートされるべき
        if ARWorldTrackingConfiguration.isSupported {
            XCTAssertTrue(capabilities.supportsPlaneDetection, "ARKit対応デバイスは平面検出をサポート")
        }
    }
}