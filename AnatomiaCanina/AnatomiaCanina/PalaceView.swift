import ARKit
import AVFoundation
import SwiftUI

private enum PalaceMode: String, CaseIterable, Identifiable {
    case place, study, quiz

    var id: Self { self }

    var title: String {
        switch self {
        case .place: "Colocar"
        case .study: "Estudiar"
        case .quiz: "Quiz"
        }
    }
}

struct PalaceView: View {
    @State private var cameraOpen = false
    @State private var permissionDenied = false
    @State private var creditsOpen = false
    @State private var panelOpen = true
    @State private var sessionID = UUID()
    @State private var tracking = TrackingStatus.starting
    @State private var loaded: Set<Region>?
    @State private var layout = PalaceLayout()
    @State private var mode = PalaceMode.place
    @State private var pending: Region?
    @State private var notice: String?
    @State private var restartConfirmation = false
    @State private var nextMode: PalaceMode?

    @State private var region: Region?
    @State private var level = Level.basic
    @State private var studied: Target?
    @State private var progress = ProgressStore.load()
    @State private var round: QuizRound?

    @Environment(\.openURL) private var openURL

    private var placed: [Region] { Region.allCases.filter { layout.stations[$0] != nil } }
    private var isResults: Bool { mode == .quiz && round?.current == nil }
    private var placementRegion: Region? { mode == .place ? pending : nil }

    var body: some View {
        NavigationStack {
            Group {
                if cameraOpen { workspace }
                else { welcome }
            }
            .background(Theme.background.ignoresSafeArea())
            .navigationTitle("Palacio anatómico")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if cameraOpen {
                        Button(panelOpen ? "Plegar panel" : "Mostrar panel",
                               systemImage: panelOpen ? "rectangle.compress.vertical" : "rectangle.expand.vertical") {
                            panelOpen.toggle()
                        }
                        .labelStyle(.iconOnly)
                        .disabled(isResults || nextMode != nil)
                    }
                    Menu("Opciones", systemImage: "ellipsis.circle") {
                        Button("Fuentes y créditos", systemImage: "info.circle") { creditsOpen = true }
                        if cameraOpen {
                            Button("Nueva sesión", systemImage: "arrow.clockwise") { requestRestart() }
                        }
                    }
                }
            }
            .sheet(isPresented: $creditsOpen) { AnatomyCredits() }
            .alert("¿Empezar una nueva sesión?", isPresented: $restartConfirmation) {
                Button("Empezar de nuevo", role: .destructive, action: restart)
                Button("Cancelar", role: .cancel) {}
            } message: {
                Text("Tendrás que volver a colocar las regiones. Los resultados guardados seguirán disponibles.")
            }
        }
    }

    private var welcome: some View {
        ScrollView {
            ViewThatFits(in: .horizontal) {
                HStack(alignment: .center, spacing: 30) {
                    welcomeText.frame(width: 320)
                    DogMap().frame(width: 340, height: 170)
                }
                VStack(alignment: .leading, spacing: 24) {
                    welcomeText
                    DogMap().aspectRatio(2, contentMode: .fit)
                }
            }
            .padding(24)
            .frame(maxWidth: 800)
            .frame(maxWidth: .infinity)
        }
    }

    private var welcomeText: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Anatomía canina en RA").font(.subheadline.weight(.semibold)).foregroundStyle(Theme.mint)
            Text("Estudia en tu espacio")
                .font(.system(.largeTitle, design: .serif, weight: .semibold))
                .foregroundStyle(Theme.ink)
                .accessibilityAddTraits(.isHeader)
            Text("Ubica el hombro, el codo y el carpo en distintos lugares. Recorre tus estaciones para estudiar los huesos y encontrarlos en el quiz.")
                .foregroundStyle(Theme.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if ARWorldTrackingConfiguration.isSupported {
                Button("Abrir cámara", systemImage: "arkit", action: requestCamera)
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(Theme.background)
                    .accessibilityIdentifier("open-palace-camera")
                if permissionDenied {
                    Text("Permite el acceso a la cámara para colocar los modelos.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondary)
                    Button("Abrir Ajustes", systemImage: "gear") {
                        if let url = URL(string: UIApplication.openSettingsURLString) { openURL(url) }
                    }
                }
            } else {
                Label("Necesitas un dispositivo con realidad aumentada para abrir el palacio.", systemImage: "arkit")
                    .font(.subheadline)
                    .foregroundStyle(Theme.secondary)
                    .accessibilityIdentifier("spatial-device-required")
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var workspace: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 630 && geometry.size.width > geometry.size.height
            let direction = wide ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            direction {
                viewport
                if panelOpen || isResults {
                    panel
                        .frame(width: wide ? min(375, geometry.size.width * 0.44) : nil,
                               height: wide ? nil : min(350, geometry.size.height * 0.43))
                }
            }
        }
    }

    private var viewport: some View {
        ZStack(alignment: .topLeading) {
            AnatomyViewer(
                layout: layout,
                placementRegion: placementRegion,
                showLabels: mode != .quiz,
                highlighted: currentHighlight,
                showQuizColors: mode == .quiz && round?.current != nil,
                awaitingAnswer: mode == .quiz && round?.feedback == nil,
                jointSpacing: mode == .quiz ? [.shoulder: 0.030, .elbow: 0.015] : [:],
                onLoaded: modelsLoaded,
                onTracking: { tracking = $0 },
                onSurfaceUnavailable: { notice = "Aún no detecto una superficie horizontal ahí. Mueve el teléfono despacio y vuelve a tocar." },
                onPlacement: previewPlacement,
                onResize: resizeStation,
                onSelection: select
            )
            .id(sessionID)
            .accessibilityLabel("Cámara del palacio anatómico")

            VStack(alignment: .leading, spacing: 8) {
                Group {
                    if let question = round?.current, mode == .quiz, !panelOpen {
                        overlay(question.instruction, bold: true)
                            .accessibilityAddTraits(.isHeader)
                    }
                    if let studied, mode == .study, !panelOpen {
                        overlay(studied.title, bold: true)
                    }
                    if let guidance { overlay(guidance) }
                }
                .allowsHitTesting(false)
                Spacer()
                viewportActions
            }
            .padding(12)

            if tracking == .failed {
                Button("Reiniciar cámara", systemImage: "arrow.clockwise", action: requestRestart)
                    .buttonStyle(.borderedProminent)
                    .foregroundStyle(Theme.background)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    @ViewBuilder
    private var viewportActions: some View {
        if mode == .place, pending != nil {
            HStack(spacing: 8) {
                Button("Cancelar colocación", action: cancelPlacement)
                    .buttonStyle(.bordered)
                    .tint(.white)
                if layout.draft != nil {
                    Button("Confirmar colocación", action: confirmPlacement)
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Theme.background)
                        .disabled(tracking == .failed)
                }
            }
            .font(.subheadline.weight(.semibold))
            .padding(5)
            .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 13))
        } else if mode == .quiz, nextMode == nil, round?.feedback == nil, round?.selection != nil {
            Button("Confirmar respuesta", systemImage: "checkmark", action: confirmAnswer)
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Theme.background)
                .disabled(tracking == .failed)
        } else {
            overlay("\(placed.count) de \(Region.allCases.count) regiones colocadas")
                .allowsHitTesting(false)
        }
    }

    private func overlay(_ text: String, bold: Bool = false) -> some View {
        Text(text)
            .font(bold ? .headline : .subheadline)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .foregroundStyle(.white)
            .background(.black.opacity(0.78), in: RoundedRectangle(cornerRadius: 11))
    }

    private var guidance: String? {
        switch tracking {
        case .starting: return "Preparando la cámara…"
        case .limited: return "Mueve el teléfono despacio y apunta a una zona iluminada con detalles visibles."
        case .failed: return "Se interrumpió el seguimiento espacial."
        case .ready: break
        }

        if loaded == nil { return "Cargando los modelos…" }
        if loaded?.isEmpty == true { return "No se pudieron cargar los modelos anatómicos." }
        if let notice, nextMode == nil { return notice }
        if mode == .place, layout.draft != nil {
            return "Vista previa. Ajusta la altura y el tamaño o toca otro punto para mover el modelo."
        }
        if let pending, mode == .place {
            let action = layout.stations[pending] == nil ? "colocar" : "mover"
            return "Toca una superficie horizontal para \(action) la estación de \(pending.title.lowercased())."
        }
        if mode == .place {
            return "Elige una región para cambiarla de lugar o abre Estudiar."
        }
        return nil
    }

    private var currentHighlight: StationHighlight? {
        if mode == .quiz, let round {
            if round.feedback == nil {
                return round.selection.map { StationHighlight(region: $0.region, parts: [$0.part.id]) }
            }
            return round.current.map { StationHighlight(region: $0.region, parts: $0.target.parts) }
        }
        if mode == .study, let region, let studied {
            return StationHighlight(region: region, parts: studied.parts)
        }
        return nil
    }

    private var panel: some View {
        VStack(spacing: 0) {
            modeBar
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .disabled(nextMode != nil)
            Divider()
            if nextMode == nil, mode == .quiz, let round, let question = round.current {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Pregunta \(round.index + 1) de \(round.questions.count) · \(question.region.title)")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(Theme.secondary)
                    Text(question.instruction)
                        .font(.headline)
                        .foregroundStyle(Theme.ink)
                        .accessibilityAddTraits(.isHeader)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 15)
                .padding(.vertical, 10)
                Divider()
            }
            ScrollView {
                Group {
                    if let nextMode {
                        quizExitPanel(to: nextMode)
                    } else {
                        switch mode {
                        case .place: placementPanel
                        case .study: studyPanel
                        case .quiz: quizPanel
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(15)
            }
            .id(nextMode.map { "quiz-exit-\($0.rawValue)" } ?? mode.rawValue)
        }
        .background(Theme.panel)
    }

    private func quizExitPanel(to destination: PalaceMode) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("¿Salir del quiz?")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            Text("Se cerrará la ronda en curso.")
                .font(.subheadline)
                .foregroundStyle(Theme.secondary)
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 8) { quizExitActions(to: destination) }
                    .fixedSize(horizontal: true, vertical: false)
                VStack(alignment: .leading, spacing: 8) { quizExitActions(to: destination) }
            }
        }
    }

    @ViewBuilder
    private func quizExitActions(to destination: PalaceMode) -> some View {
        Button("Seguir en el quiz") { nextMode = nil }
            .buttonStyle(.borderedProminent)
            .foregroundStyle(Theme.background)
        Button("Ir a \(destination.title)", role: .destructive) { switchMode(to: destination) }
            .buttonStyle(.bordered)
            .tint(.red)
    }

    private var modeBar: some View {
        HStack(spacing: 5) {
            ForEach(PalaceMode.allCases) { option in
                Button {
                    chooseMode(option)
                } label: {
                    Text(option.title)
                        .font(.subheadline.weight(.semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                        .frame(maxWidth: .infinity, minHeight: 42)
                        .foregroundStyle(option == mode ? Theme.background : Theme.ink)
                        .background(option == mode ? Theme.mint : Theme.background, in: RoundedRectangle(cornerRadius: 10))
                }
                .buttonStyle(.plain)
                .disabled(option != .place && placed.isEmpty)
                .opacity(option != .place && placed.isEmpty ? 0.45 : 1)
                .accessibilityAddTraits(option == mode ? .isSelected : [])
                .accessibilityIdentifier("mode-\(option.rawValue)")
            }
        }
    }

    @ViewBuilder
    private var placementPanel: some View {
        if let draft = layout.draft {
            placementAdjustments(for: draft)
        } else {
            stationList
        }
    }

    private func placementAdjustments(for draft: PlacementDraft) -> some View {
        let dimensions = draft.placement.dimensions
        return VStack(alignment: .leading, spacing: 12) {
            Text("Ajustar \(draft.region.title.lowercased())")
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            VStack(alignment: .leading, spacing: 4) {
                adjustmentValue("Altura sobre la superficie", value: heightText(dimensions.elevation))
                Slider(
                    value: Binding(get: { layout.draft?.placement.dimensions.elevation ?? dimensions.elevation },
                                   set: { layout.adjustDraft(elevation: $0) }),
                    in: StationDimensions.elevationRange,
                    step: 0.05
                ) {
                    Text("Altura sobre la superficie")
                }
                .labelsHidden()
                .accessibilityLabel("Altura sobre la superficie")
                .accessibilityValue(heightText(dimensions.elevation))
                .accessibilityIdentifier("station-elevation")
            }
            VStack(alignment: .leading, spacing: 4) {
                adjustmentValue("Tamaño del modelo", value: sizeText(dimensions.scale))
                Slider(
                    value: Binding(get: { layout.draft?.placement.dimensions.scale ?? dimensions.scale },
                                   set: { layout.adjustDraft(scale: $0) }),
                    in: StationDimensions.scaleRange,
                    step: 0.05
                ) {
                    Text("Tamaño del modelo")
                }
                .labelsHidden()
                .accessibilityLabel("Tamaño del modelo")
                .accessibilityValue(sizeText(dimensions.scale))
                .accessibilityIdentifier("station-scale")
            }
        }
    }

    private func adjustmentValue(_ title: String, value: String) -> some View {
        LabeledContent(title) {
            Text(value)
                .monospacedDigit()
                .foregroundStyle(Theme.mint)
        }
        .font(.subheadline)
    }

    private func heightText(_ elevation: Float) -> String {
        "\(Int((elevation * 100).rounded())) cm"
    }

    private func sizeText(_ scale: Float) -> String {
        scale.formatted(.percent.precision(.fractionLength(0)))
    }

    private var stationList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Tus estaciones").font(.headline).accessibilityAddTraits(.isHeader)
            ForEach(Region.allCases) { item in
                let inRoom = layout.stations[item] != nil
                HStack(spacing: 8) {
                    Button {
                        layout.beginEditing(item)
                        pending = item
                        notice = nil
                        panelOpen = true
                    } label: {
                        Label(item.title, systemImage: inRoom ? "checkmark.circle.fill" : "plus.circle")
                            .font(.subheadline.weight(.medium))
                            .foregroundStyle(pending == item ? Theme.mint : Theme.ink)
                            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                            .padding(.horizontal, 10)
                            .background(Theme.background, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .disabled(loaded?.contains(item) != true)
                    .accessibilityHint(inRoom
                        ? "Colocada. Toca para ajustar la altura, el tamaño o la ubicación."
                        : "Toca para colocarla en el espacio.")
                    .accessibilityAddTraits(pending == item ? .isSelected : [])
                    .accessibilityIdentifier("station-\(item.rawValue)")

                    if inRoom {
                        Button(role: .destructive) {
                            removeStation(item)
                        } label: {
                            Image(systemName: "trash")
                                .font(.subheadline.weight(.medium))
                                .frame(width: 44, height: 44)
                                .background(Theme.background, in: RoundedRectangle(cornerRadius: 9))
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.red)
                        .accessibilityLabel("Quitar \(item.title.lowercased())")
                        .accessibilityIdentifier("remove-station-\(item.rawValue)")
                    }
                }
            }
        }
    }

    private var studyPanel: some View {
        VStack(alignment: .leading, spacing: 11) {
            HStack {
                Text(region?.title ?? "Estudiar").font(.headline).accessibilityAddTraits(.isHeader)
                Spacer()
                if let region {
                    Text("\(progress[region]?.explored.count ?? 0)/\(region.targets.count) exploradas")
                        .font(.caption)
                        .foregroundStyle(Theme.secondary)
                }
            }

            if let region {
                Picker("Estación", selection: Binding(get: { region }, set: chooseStudyRegion)) {
                    ForEach(placed) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Picker("Nivel", selection: Binding(get: { level }, set: changeLevel)) {
                    ForEach(Level.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                Text(studied?.hint ?? "Elige una estructura para resaltarla. Rodea el modelo para verla desde otro ángulo.")
                    .font(.subheadline)
                    .foregroundStyle(studied == nil ? Theme.secondary : Theme.ink)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(region.targets.filter { $0.level == level }) { target in
                    Button {
                        study(target, at: region)
                    } label: {
                        Label(target.title, systemImage: studied == target ? "checkmark.circle.fill" : "viewfinder")
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(10)
                            .background(Theme.background, in: RoundedRectangle(cornerRadius: 9))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(studied == target ? Theme.mint : Theme.ink)
                    .accessibilityAddTraits(studied == target ? .isSelected : [])
                }
                if let answers = progress[region]?.latestQuiz, !answers.isEmpty {
                    Label("Último quiz · \(answers.filter(\.correct).count) de \(answers.count)", systemImage: "checkmark.circle")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private var quizPanel: some View {
        if let round, let question = round.current {
            VStack(alignment: .leading, spacing: 9) {
                if let feedback = round.feedback {
                    Label(feedback.correct ? "Correcto" : "Incorrecto",
                          systemImage: feedback.correct ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(feedback.correct ? Theme.mint : .orange)
                    if !feedback.correct, let selection = round.selection {
                        Text("Tocaste \(selection.part.name) · \(selection.region.title).")
                            .font(.subheadline)
                        Text("La zona correcta está resaltada en turquesa.")
                            .font(.subheadline)
                            .foregroundStyle(Theme.secondary)
                    }
                    Button(round.index + 1 == round.questions.count ? "Ver resultado" : "Siguiente pregunta",
                           action: advance)
                        .buttonStyle(.borderedProminent)
                        .foregroundStyle(Theme.background)
                    Text(question.target.hint)
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondary)
                } else {
                    Text(round.selection == nil
                         ? "Cada pieza tiene su color. Toca la parte que pide la pregunta y confirma."
                         : "La zona que tocaste está en blanco. Confírmala o elige otra.")
                        .font(.subheadline)
                        .foregroundStyle(Theme.secondary)
                }
            }
        } else if let round {
            resultsPanel(round)
        }
    }

    private func resultsPanel(_ round: QuizRound) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Resultado").font(.headline).accessibilityAddTraits(.isHeader)
            Text("\(round.answers.filter(\.correct).count) de \(round.answers.count) al primer intento")
                .foregroundStyle(Theme.mint)
            let grouped = round.answersByRegion
            ForEach(placed) { item in
                if let answers = grouped[item] {
                    Text("\(item.title) · \(answers.filter(\.correct).count) de \(answers.count)")
                        .font(.subheadline.weight(.semibold))
                    ForEach(answers.filter { !$0.correct }, id: \.targetID) { answer in
                        if let target = item.targets.first(where: { $0.id == answer.targetID }) {
                            Button("Repasar \(target.title)", systemImage: "arrow.uturn.backward") {
                                switchMode(to: .study)
                                study(target, at: item)
                            }
                            .font(.subheadline)
                        }
                    }
                }
            }
            Button("Repetir quiz", systemImage: "arrow.clockwise") { switchMode(to: .quiz) }
                .buttonStyle(.borderedProminent)
                .foregroundStyle(Theme.background)
        }
    }

    private func modelsLoaded(_ regions: Set<Region>) {
        loaded = regions
        pending = Region.allCases.first { regions.contains($0) && layout.stations[$0] == nil }
    }

    private func previewPlacement(_ item: Region, _ placement: StationPlacement) {
        guard mode == .place, pending == item else { return }
        if layout.preview(item, at: placement) {
            notice = nil
            panelOpen = true
        } else {
            notice = "Elige un punto un poco más alejado de la otra estación."
        }
    }

    private func resizeStation(_ item: Region, _ scale: Float) {
        guard scale.isFinite, placementRegion == nil || layout.draft?.region == item else { return }
        layout.resizeStation(item, to: scale)
    }

    private func confirmPlacement() {
        guard mode == .place, let draft = layout.draft, draft.region == pending else { return }
        let item = draft.region
        let moving = layout.stations[item] != nil
        layout.confirmPlacement()
        if region == nil { region = item }
        notice = nil
        pending = moving ? nil : Region.allCases.first {
            loaded?.contains($0) == true && layout.stations[$0] == nil
        }
        if !moving && pending == nil { switchMode(to: .study) }
    }

    private func cancelPlacement() {
        layout.cancelPlacement()
        pending = nil
        notice = nil
    }

    private func removeStation(_ item: Region) {
        layout.remove(item)
        if region == item {
            region = placed.first
            studied = nil
        }
        if pending == item { cancelPlacement() }
        else { notice = nil }
    }

    private func chooseMode(_ option: PalaceMode) {
        guard option != mode, nextMode == nil else { return }
        if mode == .quiz && round?.current != nil {
            nextMode = option
        } else {
            switchMode(to: option)
        }
    }

    private func switchMode(to option: PalaceMode) {
        guard option == .place || !placed.isEmpty else { return }
        nextMode = nil
        cancelPlacement()
        mode = option
        panelOpen = true
        round = option == .quiz ? QuizRound(regions: placed) : nil
    }

    private func select(_ item: Region, _ part: String) {
        guard layout.stations[item] != nil else { return }
        switch mode {
        case .place:
            break
        case .study:
            let matching = item.targets.filter { $0.parts.contains(part) }
            if let target = matching.first(where: { $0.level == level }) ?? matching.first {
                study(target, at: item)
            } else {
                chooseStudyRegion(item)
            }
        case .quiz:
            guard nextMode == nil, round?.current != nil, round?.feedback == nil else { return }
            if round?.select(part: part, region: item) == true { notice = nil }
            else { notice = "Toca una zona coloreada para seleccionar una respuesta." }
        }
    }

    private func confirmAnswer() {
        guard nextMode == nil else { return }
        round?.confirmAnswer()
        notice = nil
        if round?.feedback != nil { panelOpen = true }
    }

    private func chooseStudyRegion(_ item: Region) {
        guard item != region else { return }
        studied = nil
        region = item
    }

    private func changeLevel(_ next: Level) {
        guard next != level else { return }
        studied = nil
        level = next
    }

    private func study(_ target: Target, at item: Region) {
        region = item
        level = target.level
        studied = target
        progress[item, default: RegionProgress()].explored.insert(target.id)
        if let entry = progress[item] { ProgressStore.save(entry, for: item) }
    }

    private func advance() {
        guard nextMode == nil else { return }
        notice = nil
        round?.next()
        guard let round, round.current == nil else { return }
        var updates: [Region: RegionProgress] = [:]
        for (item, answers) in round.answersByRegion {
            progress[item, default: RegionProgress()].latestQuiz = answers
            updates[item] = progress[item]
        }
        ProgressStore.save(updates)
    }

    private func requestCamera() {
        Task { @MainActor in
            let allowed: Bool
            switch AVCaptureDevice.authorizationStatus(for: .video) {
            case .authorized: allowed = true
            case .notDetermined: allowed = await AVCaptureDevice.requestAccess(for: .video)
            default: allowed = false
            }
            permissionDenied = !allowed
            if allowed { cameraOpen = true }
        }
    }

    private func requestRestart() {
        if placed.isEmpty { restart() }
        else { restartConfirmation = true }
    }

    private func restart() {
        layout = PalaceLayout()
        mode = .place
        panelOpen = true
        region = nil
        level = .basic
        studied = nil
        pending = nil
        notice = nil
        nextMode = nil
        round = nil
        loaded = nil
        tracking = .starting
        sessionID = UUID()
    }
}
