import SwiftUI

/// Panel del modo Estudio (CU2).
/// Por ahora solo muestra la instrucción; la definición y el botón «Siguiente término» se agregan en el Paso 4.
struct StudyPanel: View {
    var body: some View {
        ContentUnavailableView {
            Label("Recorre tu palacio", systemImage: AppMode.study.systemImage)
        } description: {
            Text("Toca un marcador en la cámara para ver su definición.")
        }
    }
}

#Preview {
    StudyPanel()
}
