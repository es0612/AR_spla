import SwiftData
import SwiftUI

@main
struct ARSplatoonGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.regionalSettings, RegionalSettingsManager.shared)
                .environment(\.culturalColors, CulturalColorManager.shared)
                .environment(\.ratingCompliance, RatingComplianceManager.shared)
                .environment(\.playTimeManager, PlayTimeManager.shared)
        }
        .modelContainer(DataContainer.shared.container)
    }
}
