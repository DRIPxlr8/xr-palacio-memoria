import Foundation

/// Término que el usuario está escribiendo o eligió del glosario, antes de fijarlo en la sala.
///
/// Es un tipo de la interfaz: al confirmar, el estado de la app lo convierte
/// al modelo `Term` de PalacioCore.
struct TermDraft: Identifiable, Hashable {
    var name: String
    var definition: String

    /// En el glosario cada nombre es único, así que sirve como identificador.
    var id: String { name }

    /// Nombre y definición sin espacios ni saltos de línea al inicio o al final.
    var trimmed: TermDraft {
        TermDraft(
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            definition: definition.trimmingCharacters(in: .whitespacesAndNewlines)
        )
    }

    /// Se puede fijar solo si tiene nombre y definición.
    var isComplete: Bool {
        let draft = trimmed
        return !draft.name.isEmpty && !draft.definition.isEmpty
    }
}

extension TermDraft {
    /// Ejemplos para las previews. La app usa el glosario de prueba de PalacioCore.
    static let samples: [TermDraft] = [
        TermDraft(name: "Latencia", definition: "Tiempo que tarda un dato en ir desde su origen hasta su destino."),
        TermDraft(name: "Ancho de banda", definition: "Cantidad máxima de datos que un canal puede transmitir por unidad de tiempo."),
        TermDraft(name: "Redundancia", definition: "Duplicación de componentes para que el sistema siga funcionando si uno falla."),
    ]
}
