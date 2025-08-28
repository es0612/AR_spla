import Foundation
import simd

/// Value Object representing a 3D position in space
public struct Position3D: Equatable, Codable {
    public let x: Float
    public let y: Float
    public let z: Float
    
    /// Tolerance for floating point comparison
    private static let tolerance: Float = 0.01
    
    /// Create a Position3D with specific coordinates
    public init(x: Float, y: Float, z: Float) {
        self.x = x
        self.y = y
        self.z = z
    }
    
    /// Create a Position3D from simd_float3
    public init(_ vector: simd_float3) {
        self.x = vector.x
        self.y = vector.y
        self.z = vector.z
    }
    
    /// Convert to simd_float3
    public func toSimd() -> simd_float3 {
        return simd_float3(x, y, z)
    }
    
    /// Calculate distance to another position
    public func distance(to other: Position3D) -> Float {
        let dx = x - other.x
        let dy = y - other.y
        let dz = z - other.z
        return sqrt(dx * dx + dy * dy + dz * dz)
    }
    
    /// Validate if coordinates are valid (not NaN or infinite)
    public static func isValid(x: Float, y: Float, z: Float) -> Bool {
        return !x.isNaN && !x.isInfinite &&
               !y.isNaN && !y.isInfinite &&
               !z.isNaN && !z.isInfinite
    }
    
    /// Check if this position is valid
    public var isValid: Bool {
        return Position3D.isValid(x: x, y: y, z: z)
    }
}

// MARK: - Equatable with tolerance
extension Position3D {
    public static func == (lhs: Position3D, rhs: Position3D) -> Bool {
        return abs(lhs.x - rhs.x) < tolerance &&
               abs(lhs.y - rhs.y) < tolerance &&
               abs(lhs.z - rhs.z) < tolerance
    }
}

// MARK: - CustomStringConvertible
extension Position3D: CustomStringConvertible {
    public var description: String {
        return "Position3D(x: \(x), y: \(y), z: \(z))"
    }
}