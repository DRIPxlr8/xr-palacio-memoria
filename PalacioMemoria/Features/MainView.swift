import SwiftUI
import PalacioCore

/// Pantalla principal: arriba el selector y el panel del modo actual (40 %); abajo, siempre, la cámara AR (60 %).
///
/// Al cambiar de modo solo cambia el panel superior. La cámara no se vuelve a crear,
/// así que los marcadores anclados se mantienen.
///
/// Sin preview: la cámara AR solo funciona en un iPhone.
struct MainView: View {
    /// Parte del alto de la pantalla (dentro del área segura) que ocupa el panel superior.
    /// La cámara usa el resto. Ver docs/decisiones/001-proporcion-panel-camara.md.
    private static let topPanelFraction: CGFloat = 0.4

    @Environment(AppState.self) private var appState

    // Provisorio: el estado del quiz y el puntaje los llevará la lógica de PalacioCore.
    /// Respuestas del quiz por término (`true` si acertó).
    @State private var quizResults: [Term.ID: Bool] = [:]
    /// Si ya se reveló la respuesta del término preguntado.
    @State private var isAnswerRevealed = false

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topPanel
                    .frame(height: proxy.size.height * Self.topPanelFraction)

                ARContainerView(
                    isPlacementEnabled: appState.mode == .anchor,
                    pendingMarkerID: appState.palace.pendingMarkerID,
                    markerNames: appState.palace.namesByMarker,
                    onMarkerSelected: { markerID in
                        selectMarker(markerID)
                    },
                    onSurfaceTapped: { markerID, _ in
                        appState.beginPlacement(markerID: markerID)
                    },
                    onEmptyTapped: {
                        // Tocar fuera de un marcador cierra el término de Estudio o la pregunta del Quiz.
                        closeSelection()
                    }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        // Al cambiar de modo se descarta el término a medio anclar y se cierra lo que estaba abierto.
        .onChange(of: appState.mode) {
            appState.cancelPlacement()
            closeSelection()
        }
        // Al escribir en el formulario de Anclar, el teclado se superpone a la cámara
        // en vez de achicar el panel.
        .ignoresSafeArea(.keyboard)
    }

    /// Panel superior: selector de modo y contenido del modo.
    private var topPanel: some View {
        @Bindable var appState = appState

        return VStack(spacing: 0) {
            ModeSelector(mode: $appState.mode)
                .padding(.horizontal)
                .padding(.top, 8)

            modePanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var modePanel: some View {
        switch appState.mode {
        case .anchor:
            AnchorPanel(
                isPlacingTerm: appState.isPlacingTerm,
                glossary: appState.glossary.map { TermDraft(name: $0.name, definition: $0.definition) },
                onConfirm: { draft in
                    appState.confirmPlacement(name: draft.name, definition: draft.definition)
                },
                onCancel: { appState.cancelPlacement() }
            )
        case .study:
            StudyPanel(
                term: appState.selectedTerm,
                total: appState.palace.terms.count
            )
        case .quiz:
            QuizPanel(
                phase: quizPhase,
                onReveal: { isAnswerRevealed = true },
                onAnswer: { isCorrect in
                    if let term = appState.selectedTerm {
                        quizResults[term.id] = isCorrect
                    }
                    closeSelection()
                },
                onRestart: { quizResults = [:] }
            )
        }
    }

    /// El usuario tocó un marcador: en Estudio muestra su término; en Quiz lo pregunta
    /// si todavía no lo respondió.
    private func selectMarker(_ markerID: UUID) {
        guard let term = appState.palace.term(forMarker: markerID) else { return }

        switch appState.mode {
        case .anchor:
            break
        case .study:
            appState.selectedTerm = term
        case .quiz:
            guard quizResults[term.id] == nil else { return }
            appState.selectedTerm = term
            isAnswerRevealed = false
        }
    }

    /// Cierra el término de Estudio o la pregunta abierta del Quiz.
    private func closeSelection() {
        appState.selectedTerm = nil
        isAnswerRevealed = false
    }

    /// Provisorio: el estado del quiz y el puntaje los calculará la lógica de PalacioCore.
    private var quizPhase: QuizPhase {
        let terms = appState.palace.terms
        if terms.isEmpty {
            return .noTerms
        }
        if let term = appState.selectedTerm {
            return .question(term, isRevealed: isAnswerRevealed)
        }
        let answered = terms.filter { quizResults[$0.id] != nil }.count
        if answered == terms.count {
            let toReview = terms.filter { quizResults[$0.id] == false }
            return .finished(correct: terms.count - toReview.count, total: terms.count, toReview: toReview)
        }
        return .waiting(answered: answered, total: terms.count)
    }
}
