import SwiftUI

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

    // Provisorio: cuando exista el estado de la app (rol B), estos valores se leen y escriben ahí.
    @State private var mode: AppMode = .anchor
    /// El usuario tocó una superficie en modo Anclar y falta completar el término.
    @State private var isPlacingTerm = false

    var body: some View {
        GeometryReader { proxy in
            VStack(spacing: 0) {
                topPanel
                    .frame(height: proxy.size.height * Self.topPanelFraction)

                ARContainerView(onSurfaceTapped: { _ in
                    // Provisorio: el estado de la app (rol B) guardará la posición tocada.
                    if mode == .anchor { isPlacingTerm = true }
                })
                .ignoresSafeArea(edges: .bottom)
            }
        }
        // Si el usuario cambia de modo con el formulario abierto, el término se descarta.
        .onChange(of: mode) { isPlacingTerm = false }
        // Al escribir en el formulario de Anclar, el teclado se superpone a la cámara
        // en vez de achicar el panel.
        .ignoresSafeArea(.keyboard)
    }

    /// Panel superior: selector de modo y contenido del modo.
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
        case .anchor:
            AnchorPanel(
                isPlacingTerm: isPlacingTerm,
                glossary: TermDraft.samples, // Provisorio hasta el glosario de prueba (rol B).
                onConfirm: { _ in isPlacingTerm = false },
                onCancel: { isPlacingTerm = false }
            )
        case .study: StudyPanel()
        case .quiz: QuizPanel()
        }
    }
}
