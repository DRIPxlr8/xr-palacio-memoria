import Foundation

enum Region: String, CaseIterable, Identifiable, Codable {
    case shoulder, elbow, carpus

    var id: String { rawValue }

    var title: String {
        switch self {
        case .shoulder: "Hombro"
        case .elbow: "Codo"
        case .carpus: "Carpo"
        }
    }

    var modelParts: [AnatomicalPart] {
        switch self {
        case .shoulder: [
            .init("scapula", "la porción principal de la escápula"),
            .init("glenoid", "la cavidad glenoidea de la escápula"),
            .init("humerus", "la porción principal del húmero"),
            .init("humeral_head", "la cabeza del húmero"),
        ]
        case .elbow: [
            .init("humerus", "el extremo distal del húmero"),
            .init("radius", "el cuerpo del radio"),
            .init("radial_head", "la cabeza del radio"),
            .init("ulna", "el cuerpo de la ulna"),
            .init("olecranon", "el olécranon de la ulna"),
        ]
        case .carpus: [
            .init("accessory", "el hueso accesorio del carpo"),
            .init("intermedioradial", "el hueso intermediorradial del carpo"),
            .init("ulnar", "el hueso ulnar del carpo"),
            .init("distal_row", "la fila distal de los huesos del carpo"),
            .init("metacarpal_context", "la porción visible de los metacarpianos"),
            .init("forearm_context", "el extremo distal del antebrazo"),
        ]
        }
    }

    var quizColors: [String: QuizZoneColor] {
        let parts = modelParts
        let palette = QuizZoneColor.palette(count: parts.count)
        return Dictionary(uniqueKeysWithValues: zip(parts.map(\.id), palette))
    }

    var targets: [Target] {
        switch self {
        case .shoulder: [
            .init("scapula", "Escápula", .basic, ["scapula", "glenoid"],
                  "Es la lámina triangular. Busca la cresta que sobresale sobre su cara lateral.", quizName: "la escápula"),
            .init("humerus", "Húmero", .basic, ["humerus", "humeral_head"],
                  "Es el hueso largo que desciende del hombro hacia el codo.", quizName: "el húmero"),
            .init("glenoid", "Cavidad glenoidea", .detail, ["glenoid"],
                  "Busca la superficie cóncava en el extremo estrecho de la escápula. Recibe la cabeza del húmero.", quizName: "la cavidad glenoidea de la escápula"),
            .init("humeral_head", "Cabeza del húmero", .detail, ["humeral_head"],
                  "Busca la superficie redondeada del extremo del húmero que encaja en la escápula.", quizName: "la cabeza del húmero")
        ]
        case .elbow: [
            .init("radius", "Radio", .basic, ["radius", "radial_head"],
                  "Es el hueso situado hacia la parte craneal del antebrazo. Su cabeza queda junto al húmero.", quizName: "el radio"),
            .init("ulna", "Ulna (cúbito)", .basic, ["ulna", "olecranon"],
                  "Es el hueso que asciende por detrás del radio y se prolonga formando la punta del codo.", quizName: "la ulna (cúbito)"),
            .init("radial_head", "Cabeza del radio", .detail, ["radial_head"],
                  "Busca el extremo ancho del radio justo debajo del húmero, por delante de la ulna.", quizName: "la cabeza del radio"),
            .init("olecranon", "Olécranon", .detail, ["olecranon"],
                  "Es la proyección más alta de la ulna hacia la parte posterior de la articulación.", quizName: "el olécranon de la ulna")
        ]
        case .carpus: [
            .init("proximal_row", "Fila proximal", .basic, ["intermedioradial", "ulnar", "accessory"],
                  "Es la fila más próxima al radio y la ulna. Incluye el intermediorradial, el ulnar y el accesorio.", quizName: "la fila proximal de los huesos del carpo"),
            .init("distal_row", "Fila distal", .basic, ["distal_row"],
                  "Es el grupo de cuatro huesos más cercano a los metacarpianos.", quizName: "la fila distal de los huesos del carpo"),
            .init("accessory", "Hueso accesorio del carpo", .detail, ["accessory"],
                  "Busca la proyección hacia la cara palmar, al lado ulnar de la fila proximal.", quizName: "el hueso accesorio del carpo"),
            .init("intermedioradial", "Hueso intermediorradial", .detail, ["intermedioradial"],
                  "Es el hueso grande de la fila proximal ubicado hacia el lado del radio.", quizName: "el hueso intermediorradial del carpo")
        ]
        }
    }
}

enum Level: String, CaseIterable, Identifiable, Codable {
    case basic, detail

    var id: String { rawValue }
    var title: String { self == .basic ? "Básico" : "Detalle" }
}

struct Target: Identifiable, Equatable {
    let id: String
    let title: String
    let quizName: String
    let level: Level
    let parts: Set<String>
    let hint: String

    init(_ id: String, _ title: String, _ level: Level, _ parts: Set<String>, _ hint: String, quizName: String) {
        self.id = id
        self.title = title
        self.quizName = quizName
        self.level = level
        self.parts = parts
        self.hint = hint
    }
}

struct Answer: Codable, Equatable {
    let targetID: String
    let correct: Bool
}

struct StationDimensions: Equatable {
    static let elevationRange: ClosedRange<Float> = 0...1.8
    static let scaleRange: ClosedRange<Float> = 0.5...2
    static let standard = StationDimensions(elevation: 0.05, scale: 1)

    let elevation: Float
    let scale: Float

    init(elevation: Float, scale: Float) {
        self.elevation = min(Self.elevationRange.upperBound, max(Self.elevationRange.lowerBound, elevation))
        self.scale = min(Self.scaleRange.upperBound, max(Self.scaleRange.lowerBound, scale))
    }
}

struct StationPlacement: Equatable {
    let position: SIMD3<Float>
    let facing: Float
    var dimensions = StationDimensions.standard
}

struct PlacementDraft: Equatable {
    let region: Region
    var placement: StationPlacement
}

struct PalaceLayout {
    private(set) var stations: [Region: StationPlacement] = [:]
    private(set) var draft: PlacementDraft?

    func visiblePlacement(for region: Region) -> StationPlacement? {
        if let draft, draft.region == region { return draft.placement }
        return stations[region]
    }

    mutating func preview(_ region: Region, at placement: StationPlacement) -> Bool {
        let nearby = stations.contains { other, station in
            guard other != region else { return false }
            let delta = station.position - placement.position
            return abs(delta.y) < 0.16 && delta.x * delta.x + delta.z * delta.z < 0.22 * 0.22
        }
        guard !nearby else { return false }
        var next = placement
        next.dimensions = visiblePlacement(for: region)?.dimensions ?? .standard
        draft = PlacementDraft(region: region, placement: next)
        return true
    }

    mutating func beginEditing(_ region: Region) {
        draft = stations[region].map { PlacementDraft(region: region, placement: $0) }
    }

    mutating func adjustDraft(elevation: Float? = nil, scale: Float? = nil) {
        guard var draft else { return }
        let current = draft.placement.dimensions
        draft.placement.dimensions = StationDimensions(elevation: elevation ?? current.elevation,
                                                       scale: scale ?? current.scale)
        self.draft = draft
    }

    mutating func resizeStation(_ region: Region, to scale: Float) {
        if draft?.region == region {
            adjustDraft(scale: scale)
        } else if var placement = stations[region] {
            placement.dimensions = StationDimensions(elevation: placement.dimensions.elevation, scale: scale)
            stations[region] = placement
        }
    }

    mutating func confirmPlacement() {
        guard let draft else { return }
        stations[draft.region] = draft.placement
        self.draft = nil
    }

    mutating func cancelPlacement() { draft = nil }

    mutating func remove(_ region: Region) {
        if draft?.region == region { cancelPlacement() }
        stations.removeValue(forKey: region)
    }
}

struct AnatomicalPart: Equatable {
    let id: String
    let name: String

    init(_ id: String, _ name: String) {
        self.id = id
        self.name = name
    }
}

struct QuizZoneColor: Hashable {
    let hue: Double
    let saturation: Double
    let brightness: Double

    static func palette(count: Int) -> [QuizZoneColor] {
        let distinct = [
            QuizZoneColor(hue: 0.58, saturation: 0.82, brightness: 0.98),
            QuizZoneColor(hue: 0.064, saturation: 0.86, brightness: 1.0),
            QuizZoneColor(hue: 0.75, saturation: 0.62, brightness: 0.99),
            QuizZoneColor(hue: 0.29, saturation: 0.77, brightness: 0.88),
            QuizZoneColor(hue: 0.92, saturation: 0.74, brightness: 0.98),
            QuizZoneColor(hue: 0.155, saturation: 0.76, brightness: 1.0),
        ]
        if count <= distinct.count { return Array(distinct.prefix(count)) }
        return (0..<count).map { index in
            QuizZoneColor(hue: Double(index) / Double(count),
                          saturation: index.isMultiple(of: 2) ? 0.83 : 0.65,
                          brightness: index.isMultiple(of: 2) ? 0.96 : 0.81)
        }
    }
}

struct QuizSelection: Equatable {
    let region: Region
    let part: AnatomicalPart
}

struct QuizQuestion: Equatable {
    let region: Region
    let target: Target

    var instruction: String { "Toca \(target.quizName)." }
}

struct QuizRound {
    let questions: [QuizQuestion]
    private(set) var index = 0
    private(set) var answers: [Answer] = []
    private(set) var selection: QuizSelection?

    init(questions: [QuizQuestion]) { self.questions = questions }

    init(regions: [Region]) {
        questions = Level.allCases.flatMap { level in
            regions.flatMap { region in
                region.targets.filter { $0.level == level }.map { QuizQuestion(region: region, target: $0) }
            }.shuffled()
        }
    }

    var current: QuizQuestion? { questions.indices.contains(index) ? questions[index] : nil }
    var feedback: Answer? { answers.indices.contains(index) ? answers[index] : nil }

    var answersByRegion: [Region: [Answer]] {
        Dictionary(grouping: zip(questions, answers), by: { $0.0.region })
            .mapValues { $0.map { $0.1 } }
    }

    mutating func select(part: String, region: Region) -> Bool {
        guard current != nil, feedback == nil,
              questions.contains(where: { $0.region == region }),
              let piece = region.modelParts.first(where: { $0.id == part }) else { return false }
        selection = QuizSelection(region: region, part: piece)
        return true
    }

    mutating func confirmAnswer() {
        guard let current, let selection, feedback == nil else { return }
        let correct = current.region == selection.region && current.target.parts.contains(selection.part.id)
        answers.append(Answer(targetID: current.target.id, correct: correct))
    }

    mutating func next() {
        guard feedback != nil else { return }
        index += 1
        selection = nil
    }
}

struct RegionProgress: Codable {
    var explored: Set<String> = []
    var latestQuiz: [Answer] = []
}

enum ProgressStore {
    static let key = "canine-anatomy-progress-v1"

    static func load(defaults: UserDefaults = .standard) -> [Region: RegionProgress] {
        guard let data = defaults.data(forKey: key),
              let progress = try? JSONDecoder().decode([Region: RegionProgress].self, from: data)
        else { return [:] }
        return progress
    }

    static func save(_ progress: RegionProgress, for region: Region) {
        save([region: progress])
    }

    static func save(_ updates: [Region: RegionProgress]) {
        var all = load()
        all.merge(updates) { _, updated in updated }
        if let data = try? JSONEncoder().encode(all) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
