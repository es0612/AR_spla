// Infrastructure Layer - External Concerns
// This layer contains implementations of interfaces defined in inner layers

import Application
import Domain
import Foundation

/// Infrastructure layer contains concrete implementations
/// It depends on Domain and Application layers
public struct Infrastructure {
    public static let version = "1.0.0"

    private init() {}
}
