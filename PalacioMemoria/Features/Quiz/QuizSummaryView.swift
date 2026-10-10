import SwiftUI
import PalacioCore

/// Resumen final del quiz: puntaje y términos a repasar.
struct QuizSummaryView: View {
    let correct: Int
    let total: Int
    /// Términos que el usuario marcó como «No acerté».
    let toReview: [Term]
    let onRestart: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            Text("Quiz terminado")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            Text("\(correct) de \(total) correctas")
                .font(.title.bold())

            if toReview.isEmpty {
                Label("Recordaste todos los términos.", systemImage: "star.fill")
                    .foregroundStyle(.secondary)
                    .frame(maxHeight: .infinity)
            } else {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Para repasar")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)

                    ScrollView {
                        VStack(alignment: .leading, spacing: 6) {
                            ForEach(toReview) { term in
                                Label(term.name, systemImage: "arrow.uturn.backward.circle")
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxHeight: .infinity, alignment: .top)
            }

            Button(action: onRestart) {
                Label("Repetir quiz", systemImage: "arrow.counterclockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .controlSize(.large)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 12)
    }
}

#Preview("Con términos a repasar") {
    QuizSummaryView(correct: 3, total: 5, toReview: Array(Glossary.sample.prefix(2)), onRestart: {})
        .frame(height: 260)
}

#Preview("Todo correcto") {
    QuizSummaryView(correct: 5, total: 5, toReview: [], onRestart: {})
        .frame(height: 260)
}
