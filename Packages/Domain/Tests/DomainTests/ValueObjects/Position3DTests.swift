import Testing
import Foundation
import simd
@testable import Domain

struct Position3DTests {
    
    @Test("Position3D should be created with valid coordinates")
    func testPosition3DCreation() {
        let position = Position3D(x: 1.0, y: 2.0, z: 3.0)
        
        #expect(position.x == 1.0)
        #expect(position.y == 2.0)
        #expect(position.z == 3.0)
    }
    
    @Test("Position3D should be created from simd_float3")
    func testPosition3DFromSimd() {
        let simdVector = simd_float3(1.0, 2.0, 3.0)
        let position = Position3D(simdVector)
        
        #expect(position.x == 1.0)
        #expect(position.y == 2.0)
        #expect(position.z == 3.0)
    }
    
    @Test("Position3D should convert to simd_float3")
    func testPosition3DToSimd() {
        let position = Position3D(x: 1.0, y: 2.0, z: 3.0)
        let simdVector = position.toSimd()
        
        #expect(simdVector.x == 1.0)
        #expect(simdVector.y == 2.0)
        #expect(simdVector.z == 3.0)
    }
    
    @Test("Position3D should calculate distance correctly")
    func testPosition3DDistance() {
        let position1 = Position3D(x: 0.0, y: 0.0, z: 0.0)
        let position2 = Position3D(x: 3.0, y: 4.0, z: 0.0)
        
        let distance = position1.distance(to: position2)
        #expect(abs(distance - 5.0) < 0.001) // 3-4-5 triangle
    }
    
    @Test("Position3D should be equatable with tolerance")
    func testPosition3DEquality() {
        let position1 = Position3D(x: 1.0, y: 2.0, z: 3.0)
        let position2 = Position3D(x: 1.0, y: 2.0, z: 3.0)
        let position3 = Position3D(x: 1.001, y: 2.0, z: 3.0)
        let position4 = Position3D(x: 1.1, y: 2.0, z: 3.0)
        
        #expect(position1 == position2)
        #expect(position1 == position3) // Within tolerance
        #expect(position1 != position4) // Outside tolerance
    }
    
    @Test("Position3D should validate coordinates")
    func testPosition3DValidation() {
        // Valid positions
        #expect(Position3D.isValid(x: 0.0, y: 0.0, z: 0.0))
        #expect(Position3D.isValid(x: -10.0, y: 10.0, z: 5.0))
        
        // Invalid positions (NaN or infinite)
        #expect(!Position3D.isValid(x: Float.nan, y: 0.0, z: 0.0))
        #expect(!Position3D.isValid(x: 0.0, y: Float.infinity, z: 0.0))
        #expect(!Position3D.isValid(x: 0.0, y: 0.0, z: -Float.infinity))
    }
    
    @Test("Position3D should be codable")
    func testPosition3DCodable() throws {
        let originalPosition = Position3D(x: 1.5, y: 2.5, z: 3.5)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalPosition)
        
        let decoder = JSONDecoder()
        let decodedPosition = try decoder.decode(Position3D.self, from: data)
        
        #expect(originalPosition == decodedPosition)
    }
}