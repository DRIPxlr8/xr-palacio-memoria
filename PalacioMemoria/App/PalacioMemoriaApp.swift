import SwiftUI

@main
struct PalacioMemoriaApp: App {
    var body: some Scene {
        WindowGroup {
            ARContainerView()
                .edgesIgnoringSafeArea(.all)
        }
    }
}
