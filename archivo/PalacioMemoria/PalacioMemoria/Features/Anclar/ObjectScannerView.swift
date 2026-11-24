import SwiftUI

struct ObjectScannerView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var scan = ObjectScan()
    @State private var name = ""
    @State private var imageWidth = 30.0
    @State private var error: String?
    @State private var saveTask: Task<Void, Never>?

    let catalog: ObjectCatalog
    let kind: ObjectCatalog.Kind
    let onAnchor: (UUID) -> Void

    var body: some View {
        GeometryReader { proxy in
            let landscape = proxy.size.width > proxy.size.height && proxy.size.width >= 540
            let layout = landscape ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
            layout {
                ObjectScanCamera(scan: scan, kind: kind, isSaving: saveTask != nil)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .overlay { cameraGuide }
                    .accessibilityLabel("Cámara de escaneo")

                controls
                    .frame(width: landscape ? min(360, proxy.size.width * 0.46) : nil)
                    .frame(height: landscape ? nil : min(300, proxy.size.height * 0.54))
            }
        }
        .task(id: saveTask == nil ? scan.selectionID : nil) {
            guard saveTask == nil, scan.selectionID != nil else { return }
            while !Task.isCancelled {
                do { try await Task.sleep(for: .milliseconds(450)) } catch { return }
                await scan.refreshOutline()
            }
        }
        .onDisappear { saveTask?.cancel() }
        .alert("No se pudo guardar el objeto", isPresented: Binding(
            get: { error != nil },
            set: { if !$0 { error = nil } }
        )) {
            Button("Aceptar", role: .cancel) {}
        } message: {
            Text(error ?? "")
        }
    }

    @ViewBuilder
    private var cameraGuide: some View {
        if kind == .image {
            GeometryReader { proxy in
                RoundedRectangle(cornerRadius: 3)
                    .strokeBorder(.mint, lineWidth: 2)
                    .frame(width: proxy.size.width * ObjectScan.imageGuide.width,
                           height: proxy.size.height * ObjectScan.imageGuide.height)
                    .position(x: proxy.size.width * ObjectScan.imageGuide.midX,
                              y: proxy.size.height * ObjectScan.imageGuide.midY)
            }
            .allowsHitTesting(false)
        } else if let outline = scan.outline {
            GeometryReader { proxy in
                let path = Path(outline).applying(CGAffineTransform(scaleX: proxy.size.width, y: proxy.size.height))
                path.fill(.mint.opacity(0.13))
                path.stroke(.mint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                    .shadow(color: .black.opacity(0.4), radius: 2)
            }
            .clipped()
            .allowsHitTesting(false)
        } else if scan.isSelecting {
            ProgressView()
                .tint(.white)
                .padding(12)
                .background(.black.opacity(0.5), in: Circle())
                .accessibilityLabel("Buscando el contorno")
                .allowsHitTesting(false)
        } else if scan.selectionID == nil {
            Image(systemName: "viewfinder")
                .font(.system(size: 50, weight: .light))
                .foregroundStyle(.white)
                .shadow(radius: 3)
                .allowsHitTesting(false)
        }
    }

    private var controls: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text(kind == .object ? "Escanear objeto 3D" : "Capturar imagen plana")
                    .font(.headline)
                Spacer()
                Button("Cancelar") {
                    saveTask?.cancel()
                    dismiss()
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            ScrollView {
                @Bindable var scan = scan
                VStack(alignment: .leading, spacing: 12) {
                    if kind == .image {
                        Text("Apunta de frente y encuadra una zona con detalles dentro del marco. Evita incluir la pared o reflejos.")
                        nameField
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Ancho real del área encuadrada (cm)").font(.subheadline)
                            TextField("Ancho en centímetros", value: $imageWidth, format: .number)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    } else if scan.selectionID == nil {
                        Text(scan.selectionMessage ?? "Apunta al objeto y tócalo en la cámara para seleccionarlo.")
                    } else {
                        Label("Objeto seleccionado", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.mint)
                        Text("Obsérvalo desde varios ángulos sin moverlo y guárdalo cuando termines.")
                        nameField
                        DisclosureGroup("Ajustar profundidad") {
                            Slider(value: $scan.distance, in: 15...250, step: 1) {
                                Text("Profundidad")
                            } minimumValueLabel: {
                                Text("Cerca")
                            } maximumValueLabel: {
                                Text("Lejos")
                            }
                            .accessibilityValue("\(Int(scan.distance)) centímetros")
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
                .disabled(saveTask != nil)
            }
            .scrollDismissesKeyboard(.interactively)

            HStack {
                Button("Solo guardar") { save(anchor: false) }
                    .buttonStyle(.bordered)
                Button {
                    save(anchor: true)
                } label: {
                    Group {
                        if saveTask != nil {
                            ProgressView()
                                .accessibilityLabel("Guardando objeto")
                        } else {
                            Text("Guardar y anclar")
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
            .disabled(!canSave || saveTask != nil)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
        .background(.background)
    }

    private var cleanName: String { name.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var canSave: Bool {
        !cleanName.isEmpty && (kind == .object ? scan.selectionID != nil : (2...500).contains(imageWidth))
    }

    private var nameField: some View {
        TextField("Nombre", text: $name)
            .textFieldStyle(.roundedBorder)
            .textInputAutocapitalization(.sentences)
    }

    private func save(anchor: Bool) {
        let name = cleanName
        saveTask = Task {
            defer { saveTask = nil }
            do {
                let id: UUID
                switch kind {
                case .object:
                    let reference = try await scan.capture()
                    try Task.checkCancellation()
                    id = try catalog.add(name: name, reference: reference)
                case .image:
                    let capture = try await scan.captureImage(widthInMeters: imageWidth / 100)
                    try Task.checkCancellation()
                    id = try catalog.add(name: name, image: capture.reference, data: capture.data)
                }
                if anchor { onAnchor(id) }
                dismiss()
            } catch {
                guard !Task.isCancelled else { return }
                self.error = (error as? ObjectScan.CaptureError)?.errorDescription
                    ?? "No se pudo escribir la referencia en el catálogo. Comprueba que haya espacio disponible e inténtalo de nuevo."
            }
        }
    }
}
