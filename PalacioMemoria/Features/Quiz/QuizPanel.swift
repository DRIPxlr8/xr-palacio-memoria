import SwiftUI

/// Panel del modo Quiz (CU3).
/// Por ahora solo muestra la instrucción; «Tocar para revelar», Acerté / No acerté y el resumen se agregan en el Paso 5.
struct QuizPanel: View {
    var body: some View {
        ContentUnavailableView {
            Label("Ponte a prueba", systemImage: AppMode.quiz.systemImage)
        } description: {
            Text("Toca un marcador «?» e intenta recordar su definición antes de revelarla.")
        }
    }
}

#Preview {
    QuizPanel()
}
