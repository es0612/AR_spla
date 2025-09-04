//
//  CollisionDetectionService.swift
//  Domain
//
//  Created by Kiro on 2025-01-09.
//

import Foundation

// MARK: - CollisionResult

/// Result of a collision detection check
public struct CollisionResult: Equatable {
    public let hasCollision: Bool
    public let distance: Float
    public let collisionPoint: Position3D?

    public init(hasCollision: Bool, distance: Float, collisionPoint: Position3D? = nil) {
        self.hasCollision = hasCollision
        self.distance = distance
        self.collisionPoint = collisionPoint
    }

    public static let noCollision = CollisionResult(hasCollision: false, distance: Float.infinity)
}

// MARK: - InkSpotOverlapResult

/// Result of ink spot overlap detection
public struct InkSpotOverlapResult: Equatable {
    public let hasOverlap: Bool
    public let overlapArea: Float
    public let mergedSize: Float?

    public init(hasOverlap: Bool, overlapArea: Float, mergedSize: Float? = nil) {
        self.hasOverlap = hasOverlap
        self.overlapArea = overlapArea
        self.mergedSize = mergedSize
    }

    public static let noOverlap = InkSpotOverlapResult(hasOverlap: false, overlapArea: 0.0)
}

// MARK: - CollisionDetectionService

/// Domain service for collision detection between game entities
public struct CollisionDetectionService {
    private let gameRules: GameRules

    /// Create a collision detection service with specified game rules
    public init(gameRules: GameRules = .default) {
        self.gameRules = gameRules
    }

    // MARK: - Player-Ink Collision Detection

    /// Check if a player collides with an ink spot
    public func checkPlayerInkCollision(_ player: Player, with inkSpot: InkSpot) -> CollisionResult {
        // Players don't collide with their own ink
        guard inkSpot.ownerId != player.id else {
            return .noCollision
        }

        // Player must be active to be affected by collisions
        guard player.isActive else {
            return .noCollision
        }

        // Calculate distance between player and ink spot center
        let distance = player.position.distance(to: inkSpot.position)

        // Collision occurs if distance is less than ink spot radius + player collision radius
        let collisionDistance = inkSpot.size + gameRules.playerCollisionRadius

        let hasCollision = distance < collisionDistance

        // Calculate collision point (on the edge of the ink spot closest to player)
        let collisionPoint: Position3D?
        if hasCollision {
            let direction = player.position.subtract(inkSpot.position).normalized()
            let collisionOffset = direction.multiply(by: inkSpot.size)
            collisionPoint = inkSpot.position.add(collisionOffset)
        } else {
            collisionPoint = nil
        }

        return CollisionResult(
            hasCollision: hasCollision,
            distance: distance,
            collisionPoint: collisionPoint
        )
    }

    /// Check if a player collides with any ink spots in a collection
    public func checkPlayerInkCollisions(_ player: Player, with inkSpots: [InkSpot]) -> [InkSpot] {
        inkSpots.filter { inkSpot in
            checkPlayerInkCollision(player, with: inkSpot).hasCollision
        }
    }

    // MARK: - Ink Spot Overlap Detection

    /// Check if two ink spots overlap
    public func checkInkSpotOverlap(_ inkSpot1: InkSpot, _ inkSpot2: InkSpot) -> InkSpotOverlapResult {
        // Can't overlap with itself
        guard inkSpot1.id != inkSpot2.id else {
            return .noOverlap
        }

        let distance = inkSpot1.position.distance(to: inkSpot2.position)
        let combinedRadius = inkSpot1.size + inkSpot2.size

        guard distance < combinedRadius else {
            return .noOverlap
        }

        // Calculate overlap area using circle intersection formula
        let overlapArea = calculateCircleIntersectionArea(
            center1: inkSpot1.position,
            radius1: inkSpot1.size,
            center2: inkSpot2.position,
            radius2: inkSpot2.size
        )

        // Calculate merged size if same color
        let mergedSize: Float?
        if inkSpot1.color == inkSpot2.color {
            // For same color, calculate combined area and derive new radius
            let totalArea = inkSpot1.area + inkSpot2.area - overlapArea
            mergedSize = sqrt(totalArea / Float.pi)
        } else {
            mergedSize = nil
        }

        return InkSpotOverlapResult(
            hasOverlap: true,
            overlapArea: overlapArea,
            mergedSize: mergedSize
        )
    }

    /// Find all ink spots that overlap with a given ink spot
    public func findOverlappingInkSpots(_ targetInkSpot: InkSpot, in inkSpots: [InkSpot]) -> [(InkSpot, InkSpotOverlapResult)] {
        var overlaps: [(InkSpot, InkSpotOverlapResult)] = []

        for inkSpot in inkSpots {
            let overlapResult = checkInkSpotOverlap(targetInkSpot, inkSpot)
            if overlapResult.hasOverlap {
                overlaps.append((inkSpot, overlapResult))
            }
        }

        return overlaps
    }

    // MARK: - Area-based Collision Detection

    /// Check if a position is within an ink spot's area
    public func isPositionInInkSpot(_ position: Position3D, inkSpot: InkSpot) -> Bool {
        let distance = position.distance(to: inkSpot.position)
        return distance <= inkSpot.size
    }

    /// Find all ink spots that contain a given position
    public func findInkSpotsContaining(_ position: Position3D, in inkSpots: [InkSpot]) -> [InkSpot] {
        inkSpots.filter { inkSpot in
            isPositionInInkSpot(position, inkSpot: inkSpot)
        }
    }

    // MARK: - Collision Effects

    /// Calculate the effect of a collision on a player
    public func calculatePlayerCollisionEffect(_ player: Player, with inkSpot: InkSpot) -> PlayerCollisionEffect {
        let collisionResult = checkPlayerInkCollision(player, with: inkSpot)

        guard collisionResult.hasCollision else {
            return .none
        }

        // Different effects based on ink spot properties
        let stunDuration = calculateStunDuration(for: inkSpot)
        let speedReduction = calculateSpeedReduction(for: inkSpot)

        return .stunned(duration: stunDuration, speedReduction: speedReduction)
    }

    /// Calculate stun duration based on ink spot properties
    private func calculateStunDuration(for inkSpot: InkSpot) -> TimeInterval {
        // Base stun duration from game rules
        let baseDuration: TimeInterval = 3.0

        // Larger ink spots cause longer stun
        let sizeFactor = Double(inkSpot.size / InkSpot.maxSize)

        return baseDuration * (0.5 + sizeFactor * 0.5) // 1.5 to 3.0 seconds
    }

    /// Calculate speed reduction based on ink spot properties
    private func calculateSpeedReduction(for inkSpot: InkSpot) -> Float {
        // Base speed reduction
        let baseReduction: Float = 0.5 // 50% speed reduction

        // Larger ink spots cause more speed reduction
        let sizeFactor = inkSpot.size / InkSpot.maxSize

        return baseReduction + (sizeFactor * 0.3) // 50% to 80% reduction
    }

    // MARK: - Private Helper Methods

    /// Calculate the intersection area of two circles
    private func calculateCircleIntersectionArea(
        center1: Position3D,
        radius1: Float,
        center2: Position3D,
        radius2: Float
    ) -> Float {
        let distance = center1.distance(to: center2)

        // No intersection if circles are too far apart
        guard distance < radius1 + radius2 else { return 0.0 }

        // One circle is completely inside the other
        if distance <= abs(radius1 - radius2) {
            let smallerRadius = min(radius1, radius2)
            return Float.pi * smallerRadius * smallerRadius
        }

        // Partial intersection - use circle intersection formula
        let r1Sq = radius1 * radius1
        let r2Sq = radius2 * radius2
        let dSq = distance * distance

        let part1 = r1Sq * acos((dSq + r1Sq - r2Sq) / (2 * distance * radius1))
        let part2 = r2Sq * acos((dSq + r2Sq - r1Sq) / (2 * distance * radius2))
        let part3 = 0.5 * sqrt((-distance + radius1 + radius2) * (distance + radius1 - radius2) * (distance - radius1 + radius2) * (distance + radius1 + radius2))

        return part1 + part2 - part3
    }
}

// MARK: - PlayerCollisionEffect

/// Effect of a collision on a player
public enum PlayerCollisionEffect: Equatable {
    case none
    case stunned(duration: TimeInterval, speedReduction: Float)

    public var isStunned: Bool {
        switch self {
        case .none:
            return false
        case .stunned:
            return true
        }
    }

    public var stunDuration: TimeInterval {
        switch self {
        case .none:
            return 0
        case let .stunned(duration, _):
            return duration
        }
    }

    public var speedReduction: Float {
        switch self {
        case .none:
            return 0
        case let .stunned(_, reduction):
            return reduction
        }
    }
}

// MARK: - Position3D Extensions

private extension Position3D {
    func subtract(_ other: Position3D) -> Position3D {
        Position3D(x: x - other.x, y: y - other.y, z: z - other.z)
    }

    func add(_ other: Position3D) -> Position3D {
        Position3D(x: x + other.x, y: y + other.y, z: z + other.z)
    }

    func multiply(by scalar: Float) -> Position3D {
        Position3D(x: x * scalar, y: y * scalar, z: z * scalar)
    }

    func normalized() -> Position3D {
        let length = sqrt(x * x + y * y + z * z)
        guard length > 0 else { return Position3D(x: 0, y: 0, z: 0) }
        return Position3D(x: x / length, y: y / length, z: z / length)
    }
}
