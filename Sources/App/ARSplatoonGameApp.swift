import SwiftUI
import SwiftData

@main
struct ARSplatoonGameApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(DataContainer.shared.container)
    }
}