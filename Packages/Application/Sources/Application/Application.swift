// Application Layer - Use Cases and Coordinators
// This layer orchestrates the flow of data to and from the entities

import Foundation
import Domain

/// Application layer contains use cases and application services
/// It depends on the Domain layer but not on Infrastructure
public struct Application {
    public static let version = "1.0.0"
    
    private init() {}
}