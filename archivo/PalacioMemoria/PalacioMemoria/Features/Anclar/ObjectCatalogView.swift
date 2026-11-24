import SwiftUI

struct ObjectCatalogView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var objectToRemove: ObjectCatalog.Entry?
    @State private var showRemovalError = false

    let catalog: ObjectCatalog
    let anchoredIDs: Set<UUID>
    let onScan: (ObjectCatalog.Kind) -> Void
    let onAnchor: (UUID) -> Void

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Button { onScan(.object) } label: {
                        Label("Escanear objeto 3D", systemImage: "viewfinder")
                    }
                    .disabled(!ObjectScan.isSupported)
                    Button { onScan(.image) } label: {
                        Label("Capturar imagen plana", systemImage: "photo")
                    }
                } footer: {
                    if ObjectScan.isSupported {
                        Text("Usa el escaneo 3D para objetos con volumen y la captura de imagen para cuadros, afiches y otras superficies planas con detalles.")
                    } else {
                        Text("El escaneo de objetos no está disponible en este dispositivo.")
                    }
                }

                Section {
                    if catalog.entries.isEmpty {
                        Text("Aún no hay objetos guardados.")
                            .foregroundStyle(.secondary)
                    }
                    ForEach(catalog.entries) { entry in
                        VStack(alignment: .leading, spacing: 6) {
                            Toggle(isOn: Binding(
                                get: { catalog.isEnabled(entry.id) },
                                set: { catalog.setEnabled($0, for: entry.id) }
                            )) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(entry.name)
                                    Text(entry.kind.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            if anchoredIDs.contains(entry.id) {
                                Label("Término anclado", systemImage: "checkmark.circle")
                                    .font(.footnote)
                                    .foregroundStyle(.secondary)
                            } else {
                                Button { onAnchor(entry.id) } label: {
                                    Label("Anclar término", systemImage: "pin")
                                        .font(.footnote.weight(.medium))
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                        .swipeActions(allowsFullSwipe: false) {
                            Button(role: .destructive) {
                                objectToRemove = entry
                            } label: {
                                Label("Eliminar", systemImage: "trash")
                            }
                        }
                        .accessibilityAction(named: "Eliminar") { objectToRemove = entry }
                    }
                } header: {
                    Text("Objetos guardados")
                } footer: {
                    Text("Activa los objetos que quieres que la cámara busque en la sala.")
                }

                if catalog.hasUnreadableEntries {
                    Text("No se pudieron cargar todos los objetos guardados.")
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Catálogo de objetos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Listo") { dismiss() }
                }
            }
            .alert("¿Eliminar del catálogo?", isPresented: Binding(
                get: { objectToRemove != nil },
                set: { if !$0 { objectToRemove = nil } }
            ), presenting: objectToRemove) { entry in
                Button("Eliminar", role: .destructive) { remove(entry) }
                Button("Cancelar", role: .cancel) {}
            } message: { entry in
                Text(entry.name)
            }
            .alert("No se pudo eliminar el objeto", isPresented: $showRemovalError) {
                Button("Aceptar", role: .cancel) {}
            }
        }
    }

    private func remove(_ entry: ObjectCatalog.Entry) {
        do {
            try catalog.remove(entry)
        } catch {
            showRemovalError = true
        }
    }
}
