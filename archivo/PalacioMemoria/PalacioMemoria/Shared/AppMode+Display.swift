/// Textos e íconos con que cada modo aparece en la interfaz.
extension AppMode {
    /// Nombre visible en el selector de modo.
    var title: String {
        switch self {
        case .anchor: "Anclar"
        case .study: "Estudio"
        case .quiz: "Quiz"
        }
    }

    /// Símbolo de SF Symbols que representa al modo.
    var systemImage: String {
        switch self {
        case .anchor: "mappin.and.ellipse"
        case .study: "book"
        case .quiz: "questionmark.circle"
        }
    }
}
