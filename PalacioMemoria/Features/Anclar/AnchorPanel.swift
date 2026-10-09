import SwiftUI

/// Panel del modo Anclar (CU1).
///
/// Mientras no hay un punto elegido muestra la instrucción. Cuando el usuario toca
/// una superficie, muestra el formulario para completar el término antes de fijarlo.
struct AnchorPanel: View {
    /// `true` cuando el usuario tocó una superficie y falta completar el término.
    let isPlacingTerm: Bool
    let glossary: [TermDraft]
    let onConfirm: (TermDraft) -> Void
    let onCancel: () -> Void

    var body: some View {
        if isPlacingTerm {
            AnchorForm(glossary: glossary, onConfirm: onConfirm, onCancel: onCancel)
        } else {
            ContentUnavailableView {
                Label("Anclar términos", systemImage: AppMode.anchor.systemImage)
            } description: {
                Text("Toca una superficie en la cámara para dejar un término en ese lugar.")
            }
        }
    }
}

#Preview("Instrucción") {
    AnchorPanel(isPlacingTerm: false, glossary: TermDraft.samples, onConfirm: { _ in }, onCancel: {})
}

#Preview("Formulario") {
    AnchorPanel(isPlacingTerm: true, glossary: TermDraft.samples, onConfirm: { _ in }, onCancel: {})
}
