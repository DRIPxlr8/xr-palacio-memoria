import SwiftUI
import PalacioCore

/// Pregunta del quiz para el marcador que el usuario tocó.
///
/// Primero oculta la respuesta tras «Tocar para revelar». Al revelarla muestra
/// el término y su definición, con los botones Acerté / No acerté.
struct QuizQuestionCard: View {
    let term: Term
    let isRevealed: Bool
    let onReveal: () -> Void
    /// Recibe `true` si el usuario acertó.
    let onAnswer: (Bool) -> Void

    var body: some View {
        Group {
            if isRevealed {
                answer
            } else {
                question
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }

    private var question: some View {
        VStack(spacing: 12) {
            Text("¿Qué término dejaste aquí?")
                .font(.title3.bold())
                .multilineTextAlignment(.center)

            Button(action: onReveal) {
                Label("Tocar para revelar", systemImage: "eye")
                    .font(.headline)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(Color.accentColor)
            .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.accentColor, style: StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
            )
        }
    }

    private var answer: some View {
        VStack(spacing: 12) {
            // Si la definición cabe, queda centrada; si es muy larga, se puede desplazar.
            ViewThatFits(in: .vertical) {
                termText
                ScrollView {
                    termText
                }
            }
            .frame(maxHeight: .infinity)

            HStack(spacing: 12) {
                Button {
                    onAnswer(false)
                } label: {
                    Label("No acerté", systemImage: "xmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.red)

                Button {
                    onAnswer(true)
                } label: {
                    Label("Acerté", systemImage: "checkmark")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
            .controlSize(.large)
        }
    }

    private var termText: some View {
        VStack(spacing: 8) {
            Text(term.name)
                .font(.title2.bold())
            Text(term.definition)
                .font(.body)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }
}

#Preview("Oculta") {
    QuizQuestionCard(term: Glossary.sample[4], isRevealed: false, onReveal: {}, onAnswer: { _ in })
        .frame(height: 260)
}

#Preview("Revelada") {
    QuizQuestionCard(term: Glossary.sample[4], isRevealed: true, onReveal: {}, onAnswer: { _ in })
        .frame(height: 260)
}
