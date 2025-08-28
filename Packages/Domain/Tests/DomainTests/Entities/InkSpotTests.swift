import Testing
import Foundation
import simd
@testable import Domain

struct InkSpotTests {
    
    @Test("InkSpot should be created with valid properties")
    func testInkSpotCreation() {
        let id = InkSpotId()
        let position = Position3D(x: 1.0, y: 2.0, z: 3.0)
        let color = PlayerColor.red
        let size = Float(0.5)
        let playerId = PlayerId()
        
        let inkSpot = InkSpot(
            id: id,
            position: position,
            color: color,
            size: size,
            ownerId: playerId
        )
        
        #expect(inkSpot.id == id)
        #expect(inkSpot.position == position)
        #expect(inkSpot.color == color)
        #expect(inkSpot.size == size)
        #expect(inkSpot.ownerId == playerId)
        #expect(inkSpot.createdAt <= Date()) // Should be recent
    }
    
    @Test("InkSpot should validate size range")
    func testInkSpotSizeValidation() {
        let position = Position3D(x: 0.0, y: 0.0, z: 0.0)
        let color = PlayerColor.blue
        let playerId = PlayerId()
        
        // Valid sizes
        #expect(InkSpot.isValidSize(0.1))
        #expect(InkSpot.isValidSize(0.5))
        #expect(InkSpot.isValidSize(2.0))
        
        // Invalid sizes
        #expect(!InkSpot.isValidSize(0.0))
        #expect(!InkSpot.isValidSize(-0.1))
        #expect(!InkSpot.isValidSize(2.1))
        #expect(!InkSpot.isValidSize(Float.nan))
        #expect(!InkSpot.isValidSize(Float.infinity))
    }
    
    @Test("InkSpot should calculate area correctly")
    func testInkSpotAreaCalculation() {
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.0, y: 0.0, z: 0.0),
            color: .red,
            size: 1.0,
            ownerId: PlayerId()
        )
        
        let expectedArea = Float.pi * 1.0 * 1.0 // π * r²
        #expect(abs(inkSpot.area - expectedArea) < 0.001)
    }
    
    @Test("InkSpot should check overlap with other ink spots")
    func testInkSpotOverlap() {
        let position1 = Position3D(x: 0.0, y: 0.0, z: 0.0)
        let position2 = Position3D(x: 1.0, y: 0.0, z: 0.0) // 1 unit away
        let position3 = Position3D(x: 3.0, y: 0.0, z: 0.0) // 3 units away
        
        let inkSpot1 = InkSpot(
            id: InkSpotId(),
            position: position1,
            color: .red,
            size: 0.8, // radius 0.8
            ownerId: PlayerId()
        )
        
        let inkSpot2 = InkSpot(
            id: InkSpotId(),
            position: position2,
            color: .blue,
            size: 0.8, // radius 0.8, total diameter would be 1.6, distance is 1.0
            ownerId: PlayerId()
        )
        
        let inkSpot3 = InkSpot(
            id: InkSpotId(),
            position: position3,
            color: .green,
            size: 0.8, // radius 0.8, no overlap with inkSpot1
            ownerId: PlayerId()
        )
        
        #expect(inkSpot1.overlaps(with: inkSpot2)) // Should overlap
        #expect(!inkSpot1.overlaps(with: inkSpot3)) // Should not overlap
    }
    
    @Test("InkSpot should be equatable by ID")
    func testInkSpotEquality() {
        let id = InkSpotId()
        let inkSpot1 = InkSpot(
            id: id,
            position: Position3D(x: 0.0, y: 0.0, z: 0.0),
            color: .red,
            size: 0.5,
            ownerId: PlayerId()
        )
        let inkSpot2 = InkSpot(
            id: id,
            position: Position3D(x: 10.0, y: 10.0, z: 10.0), // Different position
            color: .blue, // Different color
            size: 1.0,    // Different size
            ownerId: PlayerId() // Different owner
        )
        let inkSpot3 = InkSpot(
            id: InkSpotId(), // Different ID
            position: Position3D(x: 0.0, y: 0.0, z: 0.0),
            color: .red,
            size: 0.5,
            ownerId: PlayerId()
        )
        
        #expect(inkSpot1 == inkSpot2) // Same ID
        #expect(inkSpot1 != inkSpot3) // Different ID
    }
    
    @Test("InkSpot should be codable")
    func testInkSpotCodable() throws {
        let originalInkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 1.5, y: 2.5, z: 3.5),
            color: .green,
            size: 0.75,
            ownerId: PlayerId()
        )
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalInkSpot)
        
        let decoder = JSONDecoder()
        let decodedInkSpot = try decoder.decode(InkSpot.self, from: data)
        
        #expect(originalInkSpot.id == decodedInkSpot.id)
        #expect(originalInkSpot.position == decodedInkSpot.position)
        #expect(originalInkSpot.color == decodedInkSpot.color)
        #expect(originalInkSpot.size == decodedInkSpot.size)
        #expect(originalInkSpot.ownerId == decodedInkSpot.ownerId)
        // Note: createdAt might have slight differences due to encoding/decoding
    }
    
    @Test("InkSpot should age correctly")
    func testInkSpotAge() {
        let pastDate = Date().addingTimeInterval(-60) // 1 minute ago
        let inkSpot = InkSpot(
            id: InkSpotId(),
            position: Position3D(x: 0.0, y: 0.0, z: 0.0),
            color: .red,
            size: 0.5,
            ownerId: PlayerId(),
            createdAt: pastDate
        )
        
        let age = inkSpot.age
        #expect(age >= 60.0) // Should be at least 60 seconds old
        #expect(age < 65.0)  // But not too much more (allowing for test execution time)
    }
}