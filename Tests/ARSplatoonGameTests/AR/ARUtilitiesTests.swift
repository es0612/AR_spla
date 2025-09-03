//
//  ARUtilitiesTests.swift
//  ARSplatoonGameTests
//
//  Created by Kiro on 2025-01-09.
//

import XCTest
import ARKit
import Domain
@testable import ARSplatoonGame

final class ARUtilitiesTests: XCTestCase {
    
    func testARErrorLocalizedDescription() {
        let errors: [ARError] = [
            .sessionFailed,
            .trackingLimited,
            .planeDetectionFailed,
            .unsupportedDevice,
            .gameFieldNotFound,
            .coordinateConversionFailed
        ]
        
        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
            XCTAssertNotNil(error.recoverySuggestion)
            XCTAssertFalse(error.recoverySuggestion!.isEmpty)
        }
    }
    
    func testARSessionStateIsActive() {
        XCTAssertTrue(ARSessionState.running.isActive)
        XCTAssertFalse(ARSessionState.notStarted.isActive)
        XCTAssertFalse(ARSessionState.starting.isActive)
        XCTAssertFalse(ARSessionState.paused.isActive)
        XCTAssertFalse(ARSessionState.interrupted.isActive)
        XCTAssertFalse(ARSessionState.failed(ARError.sessionFailed).isActive)
    }
    
    func testGameFieldStateIsReady() {
        let anchor = ARPlaneAnchor()
        
        XCTAssertTrue(GameFieldState.setup(anchor).isReady)
        XCTAssertFalse(GameFieldState.notDetected.isReady)
        XCTAssertFalse(GameFieldState.detecting.isReady)
        XCTAssertFalse(GameFieldState.detected(anchor).isReady)
        XCTAssertFalse(GameFieldState.lost.isReady)
    }
    
    func testGameFieldStateAnchor() {
        let anchor = ARPlaneAnchor()
        
        XCTAssertEqual(GameFieldState.setup(anchor).anchor?.identifier, anchor.identifier)
        XCTAssertEqual(GameFieldState.detected(anchor).anchor?.identifier, anchor.identifier)
        XCTAssertNil(GameFieldState.notDetected.anchor)
        XCTAssertNil(GameFieldState.detecting.anchor)
        XCTAssertNil(GameFieldState.lost.anchor)
    }
    
    func testARCoordinateSystemIsWithinGameField() {
        // Test positions within field
        XCTAssertTrue(ARCoordinateSystem.isWithinGameField(Position3D(x: 0, y: 0, z: 0)))
        XCTAssertTrue(ARCoordinateSystem.isWithinGameField(Position3D(x: 0.5, y: 0, z: 0.5)))
        XCTAssertTrue(ARCoordinateSystem.isWithinGameField(Position3D(x: -0.5, y: 0, z: -0.5)))
        XCTAssertTrue(ARCoordinateSystem.isWithinGameField(Position3D(x: 1.0, y: 0, z: 1.0)))
        XCTAssertTrue(ARCoordinateSystem.isWithinGameField(Position3D(x: -1.0, y: 0, z: -1.0)))
        
        // Test positions outside field
        XCTAssertFalse(ARCoordinateSystem.isWithinGameField(Position3D(x: 1.1, y: 0, z: 0)))
        XCTAssertFalse(ARCoordinateSystem.isWithinGameField(Position3D(x: 0, y: 0, z: 1.1)))
        XCTAssertFalse(ARCoordinateSystem.isWithinGameField(Position3D(x: -1.1, y: 0, z: 0)))
        XCTAssertFalse(ARCoordinateSystem.isWithinGameField(Position3D(x: 0, y: 0, z: -1.1)))
    }
    
    func testARCoordinateSystemDistance() {
        let pos1 = SIMD4<Float>(0, 0, 0, 1)
        let pos2 = SIMD4<Float>(3, 4, 0, 1)
        
        let distance = ARCoordinateSystem.distance(from: pos1, to: pos2)
        XCTAssertEqual(distance, 5.0, accuracy: 0.01) // 3-4-5 triangle
    }
    
    func testARCoordinateSystemInterpolate() {
        let from = SIMD4<Float>(0, 0, 0, 1)
        let to = SIMD4<Float>(10, 10, 10, 1)
        
        let midpoint = ARCoordinateSystem.interpolate(from: from, to: to, factor: 0.5)
        XCTAssertEqual(midpoint.x, 5.0, accuracy: 0.01)
        XCTAssertEqual(midpoint.y, 5.0, accuracy: 0.01)
        XCTAssertEqual(midpoint.z, 5.0, accuracy: 0.01)
        
        let start = ARCoordinateSystem.interpolate(from: from, to: to, factor: 0.0)
        XCTAssertEqual(start.x, 0.0, accuracy: 0.01)
        
        let end = ARCoordinateSystem.interpolate(from: from, to: to, factor: 1.0)
        XCTAssertEqual(end.x, 10.0, accuracy: 0.01)
        
        // Test clamping
        let clamped = ARCoordinateSystem.interpolate(from: from, to: to, factor: 1.5)
        XCTAssertEqual(clamped.x, 10.0, accuracy: 0.01)
    }
    
    func testARTrackingQualityAssessment() {
        // Note: This test would require mocking ARFrame and ARCamera
        // For now, we just test the enum properties
        
        XCTAssertTrue(ARTrackingQuality.TrackingQuality.good.isGoodEnoughForGameplay)
        XCTAssertFalse(ARTrackingQuality.TrackingQuality.poor.isGoodEnoughForGameplay)
        
        // Test limited tracking states
        let excessiveMotion = ARTrackingQuality.TrackingQuality.limited(.excessiveMotion)
        XCTAssertTrue(excessiveMotion.isGoodEnoughForGameplay)
        
        let initializing = ARTrackingQuality.TrackingQuality.limited(.initializing)
        XCTAssertFalse(initializing.isGoodEnoughForGameplay)
    }
    
    func testARPerformanceMonitor() {
        let monitor = ARPerformanceMonitor()
        
        // Initially no performance data
        XCTAssertEqual(monitor.averageFrameRate, 0.0)
        XCTAssertFalse(monitor.isPerformanceGood)
        
        // Simulate some frames
        for _ in 0..<10 {
            monitor.recordFrame()
            // Small delay to simulate frame time
            Thread.sleep(forTimeInterval: 0.001)
        }
        
        // Should have some frame rate data now
        XCTAssertGreaterThan(monitor.averageFrameRate, 0.0)
        
        // Reset should clear data
        monitor.reset()
        XCTAssertEqual(monitor.averageFrameRate, 0.0)
    }
}