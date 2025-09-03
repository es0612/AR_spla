import Foundation
import SwiftData

class DataContainer {
    static let shared = DataContainer()

    lazy var container: ModelContainer = {
        let schema = Schema([
            GameHistory.self,
            PlayerProfile.self
        ])

        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    private init() {}
}
