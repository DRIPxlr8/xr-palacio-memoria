import SwiftUI
import PalacioCore

/// Panel del modo Estudio (CU2).
///
/// Sin términos anclados invita a ir a Anclar. Con términos, pide acercarse a un marcador
/// y tocarlo; al hacerlo muestra el término y su definición.
struct StudyPanel: View {
    /// Término del marcador tocado, o `nil` si todavía no se toca ninguno.
    let term: Term?
    /// Cantidad de términos anclados.
    let total: Int

    var body: some View {
        if let term {
            StudyTermCard(term: term)
        } else if total == 0 {
            ContentUnavailableView {
                Label("Tu palacio está vacío", systemImage: AppMode.study.systemImage)
            } description: {
                Text("Ancla términos en el modo Anclar para poder recorrerlos.")
            }
        } else {
            ContentUnavailableView {
                Label("Recorre tu palacio", systemImage: AppMode.study.systemImage)
            } description: {
                Text("Acércate a un marcador y tócalo para ver su definición.")
            }
        }
    }
}

#Preview("Sin términos") {
    StudyPanel(term: nil, total: 0)
}

#Preview("Esperando un marcador") {
    StudyPanel(term: nil, total: 3)
}

#Preview("Con término") {
    StudyPanel(term: Glossary.sample[0], total: 3)
}
