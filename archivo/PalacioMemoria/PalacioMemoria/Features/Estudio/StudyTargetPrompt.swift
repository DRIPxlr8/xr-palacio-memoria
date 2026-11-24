import SwiftUI
import PalacioCore

/// Indica qué término buscar en el modo Estudio, sin mostrar su definición.
///
/// El usuario tiene que recordar dónde lo dejó, caminar hasta ahí y tocar su marcador,
/// que es lo que aprovecha la memoria espacial.
struct StudyTargetPrompt: View {
    let term: Term
    /// Posición del término en el recorrido, partiendo en 1.
    let position: Int?
    let total: Int
    /// El usuario no encuentra el término y pide pasar al siguiente.
    let onSkip: () -> Void

    var body: some View {
        VStack(spacing: 10) {
            Text(caption)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Text(term.name)
                .font(.title2.bold())

            Label("Recuerda dónde lo dejaste, acércate y toca su marcador.", systemImage: "figure.walk")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Button("Saltar", action: onSkip)
                .buttonStyle(.bordered)
                .padding(.top, 4)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// «Siguiente término», con la posición en el recorrido si se conoce.
    private var caption: String {
        if let position {
            "Siguiente término · \(position) de \(total)"
        } else {
            "Siguiente término"
        }
    }
}

#Preview {
    StudyTargetPrompt(term: Glossary.sample[3], position: 2, total: 5, onSkip: {})
        .frame(height: 260)
}
