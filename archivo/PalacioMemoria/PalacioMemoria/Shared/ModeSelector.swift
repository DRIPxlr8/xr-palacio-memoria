import SwiftUI

/// Selector segmentado para cambiar entre Anclar, Estudio y Quiz.
struct ModeSelector: View {
    @Binding var mode: AppMode

    var body: some View {
        Picker("Modo", selection: $mode) {
            ForEach(AppMode.allCases) { option in
                Text(option.title).tag(option)
            }
        }
        .pickerStyle(.segmented)
    }
}

#Preview {
    @Previewable @State var mode: AppMode = .anchor
    ModeSelector(mode: $mode)
        .padding()
}
