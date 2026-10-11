import SwiftUI
import PalacioCore

/// Panel del modo Estudio (CU2): recorrido guiado.
///
/// Sin términos anclados invita a ir a Anclar. Con términos, dice cuál buscar; el usuario
/// recuerda dónde lo dejó, se acerca y toca su marcador, y entonces se muestra la definición.
struct StudyPanel: View {
    /// Término que el usuario tiene que buscar, o `nil` si no hay términos anclados.
    let target: Term?
    /// Término del marcador tocado, con la definición abierta, o `nil` si no hay ninguno abierto.
    let revealed: Term?
    /// Posición del término buscado en el recorrido, partiendo en 1.
    let position: Int?
    /// Cantidad de términos anclados.
    let total: Int
    /// El usuario pide pasar al siguiente término.
    let onNext: () -> Void

    var body: some View {
        if let revealed {
            StudyTermCard(
                term: revealed,
                isTarget: revealed.id == target?.id,
                targetName: target?.name,
                onNext: onNext
            )
        } else if let target {
            StudyTargetPrompt(term: target, position: position, total: total, onSkip: onNext)
        } else {
            ContentUnavailableView {
                Label("Tu palacio está vacío", systemImage: AppMode.study.systemImage)
            } description: {
                Text("Ancla términos en el modo Anclar para poder recorrerlos.")
            }
        }
    }
}

#Preview("Sin términos") {
    StudyPanel(target: nil, revealed: nil, position: nil, total: 0, onNext: {})
}

#Preview("Buscando un término") {
    StudyPanel(target: Glossary.sample[0], revealed: nil, position: 1, total: 3, onNext: {})
}

#Preview("Término encontrado") {
    StudyPanel(target: Glossary.sample[0], revealed: Glossary.sample[0], position: 1, total: 3, onNext: {})
}

#Preview("Otro término") {
    StudyPanel(target: Glossary.sample[0], revealed: Glossary.sample[3], position: 1, total: 3, onNext: {})
}
