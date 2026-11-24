import SwiftUI
import PalacioCore

/// Mantiene la misma cámara al girar el dispositivo, cambiar de modo o plegar el panel.
struct MainView: View {
    @Environment(AppState.self) private var appState
    @State private var catalog = ObjectCatalog()
    @State private var isPanelExpanded = true
    @State private var isCatalogPresented = false
    @State private var requestedScan: ObjectCatalog.Kind?
    @State private var scanKind: ObjectCatalog.Kind = .object
    @State private var isScannerPresented = false
    @State private var isCameraPaused = false
    @State private var scannedObjectToAnchor: UUID?

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height && proxy.size.width >= 620
            let layout = landscape ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            layout {
                panel(landscape: landscape)
                    .frame(width: landscape ? (isPanelExpanded ? min(340, proxy.size.width * 0.47) : 0) : nil)
                    .frame(height: landscape ? nil : (isPanelExpanded ? min(preferredPanelHeight, proxy.size.height * 0.56) : 0))
                    .clipped()
                    .accessibilityHidden(!isPanelExpanded)
                    .allowsHitTesting(isPanelExpanded)

                camera
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay(alignment: .topLeading) {
                        if !isPanelExpanded {
                            Button {
                                isPanelExpanded = true
                            } label: {
                                Label("Mostrar panel", systemImage: landscape ? "chevron.right" : "chevron.down")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 12)
                                    .frame(minHeight: 44)
                                    .background(.regularMaterial, in: Capsule())
                            }
                            .buttonStyle(.plain)
                            .padding(12)
                        }
                    }
            }
        }
        .onChange(of: appState.mode) {
            appState.cancelPlacement()
            appState.closeOpenTerm()
        }
        .ignoresSafeArea(.keyboard)
        .sheet(isPresented: $isCatalogPresented, onDismiss: openScannerIfRequested) {
            ObjectCatalogView(catalog: catalog, anchoredIDs: Set(appState.palace.namesByMarker.keys), onScan: { kind in
                requestedScan = kind
                isCatalogPresented = false
            }, onAnchor: { id in
                anchorObject(id)
                isCatalogPresented = false
            })
        }
        .fullScreenCover(isPresented: $isScannerPresented, onDismiss: finishScanning) {
            ObjectScannerView(catalog: catalog, kind: scanKind) { scannedObjectToAnchor = $0 }
        }
    }

    private var preferredPanelHeight: CGFloat {
        switch appState.mode {
        case .anchor: appState.isPlacingTerm ? 300 : 225
        case .study: appState.studyTour.revealed != nil ? 300 : 245
        case .quiz:
            switch appState.quiz.phase {
            case .question(_, true), .finished: 320
            case .question(_, false): 265
            case .noTerms, .waiting: 225
            }
        }
    }

    private var camera: some View {
        ARContainerView(
            isPlacementEnabled: appState.mode == .anchor,
            isSessionPaused: isCameraPaused,
            pendingMarkerID: appState.palace.pendingMarkerID,
            markerNames: appState.markerLabels,
            markerStyles: appState.markerStyles,
            objectsToDetect: catalog.enabledEntries,
            onMarkerSelected: { markerID in
                appState.selectMarker(markerID)
                if appState.studyTour.revealed != nil || appState.quiz.current != nil {
                    isPanelExpanded = true
                }
            },
            onPlacementStarted: { markerID in
                appState.beginPlacement(markerID: markerID)
                isPanelExpanded = true
            },
            onEmptyTapped: { appState.closeOpenTerm() }
        )
        .ignoresSafeArea(edges: .bottom)
    }

    private func panel(landscape: Bool) -> some View {
        @Bindable var appState = appState

        return VStack(spacing: 0) {
            HStack(spacing: 4) {
                ModeSelector(mode: $appState.mode)

                if appState.mode == .anchor {
                    Button {
                        isCatalogPresented = true
                    } label: {
                        Text("Objetos")
                            .font(.subheadline.weight(.semibold))
                            .padding(.horizontal, 6)
                            .frame(minWidth: 44, minHeight: 44)
                    }
                    .accessibilityLabel("Catálogo de objetos")
                    .accessibilityIdentifier("objectCatalog")
                }

                Button {
                    isPanelExpanded = false
                } label: {
                    Label("Ocultar panel", systemImage: landscape ? "chevron.left" : "chevron.up")
                        .labelStyle(.iconOnly)
                        .frame(width: 44, height: 44)
                }
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            Divider()

            modePanel
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(.background)
    }

    private func openScannerIfRequested() {
        guard let requestedScan else { return }
        scanKind = requestedScan
        self.requestedScan = nil
        isCameraPaused = true
        isScannerPresented = true
    }

    private func finishScanning() {
        isCameraPaused = false
        guard let scannedObjectToAnchor else { return }
        self.scannedObjectToAnchor = nil
        anchorObject(scannedObjectToAnchor)
    }

    private func anchorObject(_ id: UUID) {
        catalog.setEnabled(true, for: id)
        appState.beginPlacement(markerID: id)
        isPanelExpanded = true
    }

    @ViewBuilder
    private var modePanel: some View {
        switch appState.mode {
        case .anchor:
            AnchorPanel(
                isPlacingTerm: appState.isPlacingTerm,
                glossary: appState.glossary.map { TermDraft(name: $0.name, definition: $0.definition) },
                objectName: catalog.entries.first { $0.id == appState.palace.pendingMarkerID }?.name,
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
