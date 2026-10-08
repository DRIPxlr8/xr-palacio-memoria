import SwiftUI
// Lógica de la app. Todavía no se usa aquí; el import hace que el build falle
// si se rompe el enlace con el paquete local.
import PalacioCore

@main
struct PalacioMemoriaApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
        }
    }
}
