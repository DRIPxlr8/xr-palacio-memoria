import SwiftUI

@main
struct PalacioMemoriaApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            MainView()
                .environment(appState)
        }
    }
}
