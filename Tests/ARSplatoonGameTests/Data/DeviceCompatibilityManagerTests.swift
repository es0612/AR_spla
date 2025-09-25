//
//  DeviceCompatibilityManagerTests.swift
//  ARSplatoonGameTests
//
//  Created by System on 2025-01-27.
//

import XCTest
@testable import ARSplatoonGame

class DeviceCompatibilityManagerTests: XCTestCase {
    
    var deviceCompatibility: DeviceCompatibilityManager!
    
    override func setUp() {
        super.setUp()
        deviceCompatibility = DeviceCompatibilityManager()
    }
    
    override func tearDown() {
        deviceCompatibility = nil
        super.tearDown()
    }
    
    func testDeviceInfoDetection() {
        // デバイス情報が正しく検出されることを確認
        let deviceInfo = deviceCompatibility.deviceInfo
        
        XCTAssertFalse(deviceInfo.modelName.isEmpty, "デバイスモデル名が空でないこと")
        XCTAssertFalse(deviceInfo.systemVersion.isEmpty, "システムバージョンが空でないこと")
        
        // パフォーマンスティアが有効な値であることを確認
        let validTiers: [PerformanceTier] = [.high, .medium, .low]
        XCTAssertTrue(validTiers.contains(deviceInfo.performanceTier), "有効なパフォーマンスティアであること")
    }
    
    func testARKitSupportDetection() {
        // ARKitサポート情報が正しく検出されることを確認
        let arSupport = deviceCompatibility.arKitSupport
        
        // ARKitサポートは実際のデバイス能力に基づく
        XCTAssertNotNil(arSupport.isSupported, "ARKitサポート状況が判定されていること")
        XCTAssertNotNil(arSupport.hasLiDAR, "LiDARサポート状況が判定されていること")
        XCTAssertNotNil(arSupport.supportsPlaneDetection, "平面検出サポート状況が判定されていること")
        XCTAssertFalse(arSupport.supportedFrameRates.isEmpty, "サポートフレームレートが設定されていること")
    }
    
    func testScreenInfoDetection() {
        // 画面情報が正しく検出されることを確認
        let screenInfo = deviceCompatibility.screenInfo
        
        XCTAssertGreaterThan(screenInfo.size.width, 0, "画面幅が0より大きいこと")
        XCTAssertGreaterThan(screenInfo.size.height, 0, "画面高さが0より大きいこと")
        XCTAssertGreaterThan(screenInfo.scaleFactor, 0, "スケールファクターが0より大きいこと")
    }
    
    func testRecommendedSettings() {
        // 推奨設定が適切に生成されることを確認
        let settings = deviceCompatibility.getRecommendedSettings()
        
        XCTAssertGreaterThan(settings.maxInkSpots, 0, "最大インクスポット数が0より大きいこと")
        
        // パフォーマンスティアに応じた設定値の確認
        switch deviceCompatibility.deviceInfo.performanceTier {
        case .high:
            XCTAssertEqual(settings.maxInkSpots, 1000, "高性能デバイスでは1000スポット")
            XCTAssertEqual(settings.renderQuality, .high, "高性能デバイスでは高品質レンダリング")
        case .medium:
            XCTAssertEqual(settings.maxInkSpots, 500, "中性能デバイスでは500スポット")
            XCTAssertEqual(settings.renderQuality, .medium, "中性能デバイスでは中品質レンダリング")
        case .low:
            XCTAssertEqual(settings.maxInkSpots, 250, "低性能デバイスでは250スポット")
            XCTAssertEqual(settings.renderQuality, .low, "低性能デバイスでは低品質レンダリング")
        }
    }
    
    func testUIAdjustments() {
        // UI調整設定が適切に生成されることを確認
        let adjustments = deviceCompatibility.getUIAdjustments()
        
        XCTAssertGreaterThan(adjustments.scaleFactor, 0, "スケールファクターが0より大きいこと")
        XCTAssertGreaterThan(adjustments.buttonSizeMultiplier, 0, "ボタンサイズ倍率が0より大きいこと")
        XCTAssertGreaterThan(adjustments.fontSizeMultiplier, 0, "フォントサイズ倍率が0より大きいこと")
        
        // iPadの場合の調整確認
        if deviceCompatibility.deviceInfo.isIPad {
            XCTAssertEqual(adjustments.buttonSizeMultiplier, 1.2, "iPadではボタンサイズが1.2倍")
            XCTAssertEqual(adjustments.fontSizeMultiplier, 1.1, "iPadではフォントサイズが1.1倍")
        } else {
            XCTAssertEqual(adjustments.buttonSizeMultiplier, 1.0, "iPhoneではボタンサイズが1.0倍")
            XCTAssertEqual(adjustments.fontSizeMultiplier, 1.0, "iPhoneではフォントサイズが1.0倍")
        }
    }
    
    func testLiDARAvailability() {
        // LiDAR利用可能性の確認
        let isLiDARAvailable = deviceCompatibility.isLiDARAvailable()
        let arSupport = deviceCompatibility.arKitSupport
        
        XCTAssertEqual(isLiDARAvailable, arSupport.hasLiDAR, "LiDAR利用可能性が一致していること")
    }
    
    func testDeviceSupport() {
        // デバイスサポート状況の確認
        let isSupported = deviceCompatibility.isDeviceSupported()
        let deviceInfo = deviceCompatibility.deviceInfo
        let arSupport = deviceCompatibility.arKitSupport
        
        let expectedSupport = deviceInfo.isSupported && arSupport.isSupported
        XCTAssertEqual(isSupported, expectedSupport, "デバイスサポート判定が正しいこと")
    }
    
    func testPerformanceSettingsConsistency() {
        // パフォーマンス設定の一貫性確認
        let settings = deviceCompatibility.getRecommendedSettings()
        
        // 高品質設定では全ての機能が有効
        if settings.renderQuality == .high {
            XCTAssertTrue(settings.antiAliasing, "高品質ではアンチエイリアシングが有効")
            XCTAssertEqual(settings.shadowQuality, .high, "高品質では高品質シャドウ")
            XCTAssertEqual(settings.particleCount, .high, "高品質では多数のパーティクル")
        }
        
        // 低品質設定では機能が制限される
        if settings.renderQuality == .low {
            XCTAssertFalse(settings.antiAliasing, "低品質ではアンチエイリアシングが無効")
            XCTAssertEqual(settings.shadowQuality, .low, "低品質では低品質シャドウ")
            XCTAssertEqual(settings.particleCount, .low, "低品質では少数のパーティクル")
        }
    }
}