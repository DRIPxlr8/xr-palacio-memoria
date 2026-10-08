import SwiftUI

/// Panel del modo Anclar (CU1).
/// Por ahora solo muestra la instrucción; el formulario del término se agrega en el Paso 3.
struct AnchorPanel: View {
    var body: some View {
        ContentUnavailableView {
            Label("Anclar términos", systemImage: AppMode.anchor.systemImage)
        } description: {
            Text("Toca una superficie en la cámara para dejar un término en ese lugar.")
        }
    }
}

#Preview {
    AnchorPanel()
}
