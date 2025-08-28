import Foundation

/// Error types for GameScore validation
public enum GameScoreError: Error, LocalizedError {
    case invalidPaintedArea
    
    public var errorDescription: String? {
        switch self {
        case .invalidPaintedArea:
            return "Painted area must be between 0.0 and 100.0"
        }
    }
}

/// Result of comparing two game scores
public enum GameScoreComparison {
    case first
    case second
    case tie
}

/// Value Object representing a game score based on painted area percentage
public struct GameScore: Equatable, Comparable, Codable {
    public let paintedArea: Float
    
    /// Painted area as percentage (same as paintedArea for this implementation)
    public var percentage: Float {
        return paintedArea
    }
    
    /// Create a GameScore with validated painted area
    public init(paintedArea: Float) {
        guard paintedArea >= 0.0 && paintedArea <= 100.0 else {
            fatalError("Invalid painted area: \(paintedArea). Must be between 0.0 and 100.0")
        }
        self.paintedArea = paintedArea
    }
    
    /// Create a GameScore with validated painted area (throwing version)
    public static func create(paintedArea: Float) throws -> GameScore {
        guard paintedArea >= 0.0 && paintedArea <= 100.0 else {
            throw GameScoreError.invalidPaintedArea
        }
        return GameScore(paintedArea: paintedArea)
    }
    
    /// Add painted area to current score, capped at maximum
    public func adding(paintedArea additionalArea: Float) -> GameScore {
        let newArea = min(100.0, self.paintedArea + additionalArea)
        return GameScore(paintedArea: newArea)
    }
    
    /// Determine winner between two scores
    public static func determineWinner(_ first: GameScore, _ second: GameScore) -> GameScoreComparison {
        if first.paintedArea > second.paintedArea {
            return .first
        } else if second.paintedArea > first.paintedArea {
            return .second
        } else {
            return .tie
        }
    }
    
    /// Zero score
    public static let zero = GameScore(paintedArea: 0.0)
    
    /// Maximum score
    public static let maximum = GameScore(paintedArea: 100.0)
}

// MARK: - Comparable
extension GameScore {
    public static func < (lhs: GameScore, rhs: GameScore) -> Bool {
        return lhs.paintedArea < rhs.paintedArea
    }
}

// MARK: - CustomStringConvertible
extension GameScore: CustomStringConvertible {
    public var description: String {
        return "GameScore(paintedArea: \(paintedArea)%)"
    }
}