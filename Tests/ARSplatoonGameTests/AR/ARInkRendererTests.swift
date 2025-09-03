//
//  ARInkRendererTests.swift
//  ARSplatoonGameTests
//
//  Created by Kiro on 2025-01-09.
//

import XCTest
import ARKit
import RealityKit
import Domain
@testable import ARSplatoonGame

final class ARInkRendererTests: XCTestCase {
    
    var arView: ARView!
    var renderer: ARInkRenderer!
    var mockDelegate: MockARInkRendererDelegate!
    
    override func setUp() {
        super.setUp()
        arView = ARView()
        renderer = ARInkRenderer(arView: arView)
        mockDelegate = MockARInkRendererDelegate()
        renderer.delegate = mockDelegate
    }
    
    override func tearDown() {
        renderer = nil
        arView = nil
        mockDelegate = nil
        super.tearDown()
    }
    
    func testInitialization() {
        XCTAssertEqual(renderer.inkSpotCount, 0)
    }
    
    func testAddInkSpot() {
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .blue,
            size: 1.0,
            ownerId: PlayerId()
        )
        
        let transform = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
        
        renderer.addInkSpot(inkSpot, at: transform)
        
        XCTAssertEqual(renderer.inkSpotCount, 1)
        XCTAssertTrue(renderer.hasInkSpot(id: inkSpot.id))
        XCTAssertTrue(mockDelegate.didAddInkSpotCalled)
    }
    
    func testRemoveInkSpot() {
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0, y: 0, z: 0),
            color: .red,
            size: 1.0,
            ownerId: PlayerId()
        )
        
        let transform = simd_float4x4(
            SIMD4<Float>(1, 0, 0, 0),
            SIMD4<Float>(0, 1, 0, 0),
            SIMD4<Float>(0, 0, 1, 0),
            SIMD4<Float>(0, 0, 0, 1)
        )
        
        renderer.addInkSpot(inkSpot, at: transform)
        XCTAssertEqual(renderer.inkSpotCount, 1)
        
        renderer.removeInkSpot(id: inkSpot.id)
        
        // Note: Removal is animated, so we need to wait
        let expectation = XCTestExpectation(description: "Ink spot removal")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(renderer.inkSpotCount, 0)
        XCTAssertFalse(renderer.hasInkSpot(id: inkSpot.id))
    }
    
    func testClearAllInkSpots() {
        // Add multiple ink spots
        for i in 0..<3 {
            let inkSpot = InkSpot(
                id: InkSpotId(),
                position: Position3D(x: Float(i), y: 0, z: 0),
                color: .green,
                size: 1.0,
                ownerId: PlayerId()
            )
            
            let transform = simd_float4x4(
                SIMD4<Float>(1, 0, 0, Float(i)),
                SIMD4<Float>(0, 1, 0, 0),
                SIMD4<Float>(0, 0, 1, 0),
                SIMD4<Float>(0, 0, 0, 1)
            )
            
            renderer.addInkSpot(inkSpot, at: transform)
        }
        
        XCTAssertEqual(renderer.inkSpotCount, 3)
        
        renderer.clearAllInkSpots()
        
        XCTAssertEqual(renderer.inkSpotCount, 0)
        XCTAssertTrue(mockDelegate.didClearAllInkSpotsCalled)
    }
    
    func testPlayerColorToUIColor() {
        let colors: [PlayerColor] = [.red, .blue, .green, .yellow, .purple, .orange]
        
        for color in colors {
            let uiColor = color.toUIColor()
            XCTAssertNotNil(uiColor)
            
            // Verify color components match expected values
            let rgb = color.rgbValues
            var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
            uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            XCTAssertEqual(Float(red), rgb.red, accuracy: 0.01)
            XCTAssertEqual(Float(green), rgb.green, accuracy: 0.01)
            XCTAssertEqual(Float(blue), rgb.blue, accuracy: 0.01)
            XCTAssertEqual(alpha, 1.0, accuracy: 0.01)
        }
    }
}

// MARK: - Mock Delegate

class MockARInkRendererDelegate: ARInkRendererDelegate {
    
    var didAddInkSpotCalled = false
    var didRemoveInkSpotCalled = false
    var didUpdateInkSpotCalled = false
    var didClearAllInkSpotsCalled = false
    
    func inkRenderer(_ renderer: ARInkRenderer, didAddInkSpot inkSpot: InkSpot) {
        didAddInkSpotCalled = true
    }
    
    func inkRenderer(_ renderer: ARInkRenderer, didRemoveInkSpot id: InkSpotId) {
        didRemoveInkSpotCalled = true
    }
    
    func inkRenderer(_ renderer: ARInkRenderer, didUpdateInkSpot inkSpot: InkSpot) {
        didUpdateInkSpotCalled = true
    }
    
    func inkRendererDidClearAllInkSpots(_ renderer: ARInkRenderer) {
        didClearAllInkSpotsCalled = true
    }
}