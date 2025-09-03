import Foundation

// MARK: - PlayerColor

/// Value Object representing player colors in the game
public enum PlayerColor: String, CaseIterable, Codable {
    case red
    case blue
    case green
    case yellow
    case purple
    case orange

    /// Display name for the color
    public var displayName: String {
        switch self {
        case .red: return "Red"
        case .blue: return "Blue"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .purple: return "Purple"
        case .orange: return "Orange"
        }
    }

    /// RGB values for the color (0.0 to 1.0)
    public var rgbValues: (red: Float, green: Float, blue: Float) {
        switch self {
        case .red: return (1.0, 0.0, 0.0)
        case .blue: return (0.0, 0.0, 1.0)
        case .green: return (0.0, 1.0, 0.0)
        case .yellow: return (1.0, 1.0, 0.0)
        case .purple: return (0.5, 0.0, 0.5)
        case .orange: return (1.0, 0.5, 0.0)
        }
    }
}

// MARK: CustomStringConvertible

extension PlayerColor: CustomStringConvertible {
    public var description: String {
        displayName
    }
}
