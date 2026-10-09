import SwiftUI
import PalacioCore

/// Término del marcador que el usuario tocó en el modo Estudio, con su definición.
///
/// No hay botón para avanzar: el recorrido se hace caminando hasta otro marcador
/// y tocándolo, que es lo que aprovecha la memoria espacial.
struct StudyTermCard: View {
    let term: Term

    var body: some View {
        VStack(spacing: 0) {
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

            Label("Acércate a otro marcador y tócalo para seguir repasando.", systemImage: "figure.walk")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
}

#Preview {
    StudyTermCard(term: Glossary.sample[3])
        .frame(height: 260)
}
