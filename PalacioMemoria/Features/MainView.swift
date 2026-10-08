import SwiftUI

/// Pantalla principal: arriba el selector y el panel del modo actual; abajo, siempre, la cámara AR.
///
/// Al cambiar de modo solo cambia el panel superior. La cámara no se vuelve a crear,
/// así que los marcadores anclados se mantienen.
///
/// Sin preview: la cámara AR solo funciona en un iPhone.
struct MainView: View {
    // Provisorio: cuando exista el estado de la app (rol B), el modo se lee y escribe ahí.
    @State private var mode: AppMode = .anchor

    var body: some View {
        VStack(spacing: 0) {
            topPanel
                .frame(maxHeight: .infinity)

            ARContainerView()
                .frame(maxHeight: .infinity)
                .ignoresSafeArea(edges: .bottom)
        }
    }

    /// Mitad superior: selector de modo y contenido del modo.
    private var topPanel: some View {
        VStack(spacing: 0) {
            ModeSelector(mode: $mode)
                .padding(.horizontal)
                .padding(.top, 8)

            modePanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private var modePanel: some View {
        switch mode {
        case .anchor: AnchorPanel()
        case .study: StudyPanel()
        case .quiz: QuizPanel()
        }
    }
}
