import SwiftUI

/// Formulario del modo Anclar (CU1): el usuario escribe o elige del glosario
/// el término y su definición antes de fijarlo en el punto que tocó.
///
/// Está pensado para el panel superior (unos 250 pt de alto libres): todo cabe
/// sin desplazarse y queda visible con el teclado abierto. No abre el teclado solo,
/// para que el usuario siga viendo en la cámara el punto que eligió.
struct AnchorForm: View {
    /// Términos disponibles para elegir. Si está vacío, no se muestra el botón «Glosario».
    let glossary: [TermDraft]
    let onConfirm: (TermDraft) -> Void
    let onCancel: () -> Void

    @State private var draft = TermDraft(name: "", definition: "")
    @FocusState private var focusedField: Field?

    private enum Field {
        case name, definition
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            header

            TextField("Término", text: $draft.name)
                .textFieldStyle(.roundedBorder)
                .textInputAutocapitalization(.sentences)
                .submitLabel(.next)
                .focused($focusedField, equals: .name)
                .onSubmit { focusedField = .definition }

            TextField("Definición", text: $draft.definition, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(2...3)
                .focused($focusedField, equals: .definition)

            buttons
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .frame(maxHeight: .infinity, alignment: .top)
    }

    private var header: some View {
        HStack {
            Text("Nuevo término")
                .font(.headline)

            Spacer()

            if !glossary.isEmpty {
                Menu {
                    ForEach(glossary) { entry in
                        Button(entry.name) {
                            draft = entry
                            focusedField = nil
                        }
                    }
                } label: {
                    Label("Glosario", systemImage: "text.book.closed")
                        .font(.subheadline)
                }
            }
        }
    }

    private var buttons: some View {
        HStack(spacing: 12) {
            Button(role: .cancel) {
                focusedField = nil
                onCancel()
            } label: {
                Text("Cancelar")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)

            Button {
                focusedField = nil
                onConfirm(draft.trimmed)
            } label: {
                Text("Fijar término")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .disabled(!draft.isComplete)
        }
        .controlSize(.large)
    }
}

#Preview {
    AnchorForm(glossary: TermDraft.samples, onConfirm: { _ in }, onCancel: {})
        .frame(height: 300)
}
