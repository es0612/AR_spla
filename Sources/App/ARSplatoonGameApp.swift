import SwiftData
import SwiftUI

@main
struct ARSplatoonGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataContainer.shared.container)
    }
}
