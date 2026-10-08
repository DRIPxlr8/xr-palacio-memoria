/// Modo de uso de la app. Cada modo corresponde a un caso de uso del informe.
enum AppMode: String, CaseIterable, Identifiable {
    /// CU1 · Anclar términos sobre superficies.
    case anchor
    /// CU2 · Recorrer el palacio y repasar.
    case study
    /// CU3 · Autoevaluarse.
    case quiz

    var id: Self { self }
}
