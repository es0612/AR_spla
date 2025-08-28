import Foundation

/// Value Object representing the status of a game session
public enum GameSessionStatus: String, CaseIterable, Codable {
    case waiting = "waiting"
    case active = "active"
    case paused = "paused"
    case finished = "finished"
    case cancelled = "cancelled"
    
    /// Display name for the status
    public var displayName: String {
        switch self {
        case .waiting: return "Waiting"
        case .active: return "Active"
        case .paused: return "Paused"
        case .finished: return "Finished"
        case .cancelled: return "Cancelled"
        }
    }
    
    /// Whether the game session is in a playable state
    public var isPlayable: Bool {
        switch self {
        case .active, .paused:
            return true
        case .waiting, .finished, .cancelled:
            return false
        }
    }
    
    /// Whether the game session has ended
    public var hasEnded: Bool {
        switch self {
        case .finished, .cancelled:
            return true
        case .waiting, .active, .paused:
            return false
        }
    }
}

// MARK: - CustomStringConvertible
extension GameSessionStatus: CustomStringConvertible {
    public var description: String {
        return displayName
    }
}