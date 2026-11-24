import SwiftUI
import PalacioCore

/// Término del marcador que el usuario tocó en el modo Estudio, con su definición.
///
/// Si es el término que estaba buscando, ofrece pasar al siguiente. Si es otro,
/// recuerda cuál sigue buscando.
struct StudyTermCard: View {
    let term: Term
    /// `true` si este es el término que el usuario tenía que buscar.
    let isTarget: Bool
    /// Nombre del término que el usuario tiene que buscar.
    let targetName: String?
    /// El usuario pide pasar al siguiente término.
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            // Si la definición cabe, el término queda centrado en el panel;
            // si es muy larga, se puede desplazar.
            ViewThatFits(in: .vertical) {
                termText
                ScrollView {
                    termText
                        .padding(.vertical, 8)
                }
            }
            .frame(maxHeight: .infinity)

            footer
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var termText: some View {
        VStack(spacing: 10) {
            Text(term.name)
                .font(.title2.bold())
            Text(term.definition)
                .font(.body)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var footer: some View {
        if isTarget {
            Button(action: onNext) {
                Text("Siguiente término")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        } else if let targetName {
            Label("Sigues buscando: \(targetName)", systemImage: "figure.walk")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }
}

#Preview("Término encontrado") {
    StudyTermCard(term: Glossary.sample[3], isTarget: true, targetName: Glossary.sample[3].name, onNext: {})
        .frame(height: 260)
}

#Preview("Otro término") {
    StudyTermCard(term: Glossary.sample[3], isTarget: false, targetName: Glossary.sample[0].name, onNext: {})
        .frame(height: 260)
}
