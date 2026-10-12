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

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topPanel
                    .frame(height: proxy.size.height * Self.topPanelFraction)

                ARContainerView(
                    isPlacementEnabled: appState.mode == .anchor,
                    pendingMarkerID: appState.palace.pendingMarkerID,
                    markerNames: appState.markerLabels,
                    markerStyles: appState.markerStyles,
                    onMarkerSelected: { markerID in
                        appState.selectMarker(markerID)
                    },
                    onSurfaceTapped: { markerID, _ in
                        appState.beginPlacement(markerID: markerID)
                    },
                    onEmptyTapped: {
                        // Tocar fuera de un marcador cierra la definición de Estudio o la pregunta del Quiz.
                        appState.closeOpenTerm()
                    }
                )
                .ignoresSafeArea(edges: .bottom)
            }
        }
        // Al cambiar de modo se descarta el término a medio anclar y se cierra lo que estaba abierto.
        .onChange(of: appState.mode) {
            appState.cancelPlacement()
            appState.closeOpenTerm()
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
                target: appState.studyTour.target,
                revealed: appState.studyTour.revealed,
                position: appState.studyTour.position,
                total: appState.studyTour.count,
                onNext: { appState.advanceStudy() }
            )
        case .quiz:
            QuizPanel(
                phase: appState.quiz.phase,
                onReveal: { appState.revealQuizAnswer() },
                onAnswer: { isCorrect in appState.answerQuiz(isCorrect: isCorrect) },
                onRestart: { appState.restartQuiz() }
            )
        }
    }
}
