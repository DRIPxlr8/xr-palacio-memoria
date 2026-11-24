import SwiftUI

@main
struct AnatomiaCaninaApp: App {
    var body: some Scene {
        WindowGroup {
            PalaceView()
                .preferredColorScheme(.dark)
                .tint(Theme.mint)
        }
    }
}

enum Theme {
    static let background = Color(red: 0.055, green: 0.09, blue: 0.115)
    static let panel = Color(red: 0.10, green: 0.16, blue: 0.19)
    static let mint = Color(red: 0.46, green: 0.89, blue: 0.76)
    static let ink = Color(red: 0.91, green: 0.94, blue: 0.92)
    static let secondary = Color(red: 0.68, green: 0.76, blue: 0.76)
}

struct AnatomyCredits: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("Modelos anatómicos") {
                    Text("Adaptados de los datos de James Charles y colaboradores, University of Liverpool (2026). CC BY 4.0. Se orientaron las mallas y se marcaron zonas seleccionables sobre sus superficies.")
                    Link("Datos originales", destination: URL(string: "https://datacat.liverpool.ac.uk/3093/")!)
                    Link("Licencia CC BY 4.0", destination: URL(string: "https://creativecommons.org/licenses/by/4.0/deed.es")!)
                }
                Section("Referencias de estudio") {
                    Link("Anatomía de carnívoros · Universidad de Minnesota",
                         destination: URL(string: "https://vanat.ahc.umn.edu/carnLabs/Lab04/Lab04.html")!)
                    Link("Huesos del carpo · Estudio de microtomografía",
                         destination: URL(string: "https://pmc.ncbi.nlm.nih.gov/articles/PMC13281358/")!)
                }
                Section("Privacidad") {
                    Text("El progreso se guarda en este dispositivo. La cámara permite colocar y observar las estaciones. La app no graba imágenes.")
                }
            }
            .navigationTitle("Fuentes y créditos")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Listo") { dismiss() } } }
        }
    }
}

struct DogMap: View {
    var body: some View {
        Canvas { context, size in
            let width = size.width / 400
            let height = size.height / 200
            func point(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x * width, y: y * height) }

            let outline: [(CGFloat, CGFloat)] = [
                (26, 73), (50, 63), (62, 42), (82, 40), (96, 25), (109, 53),
                (129, 66), (159, 62), (219, 65), (263, 63), (291, 72),
                (310, 64), (341, 38), (363, 32), (362, 42), (337, 56), (315, 87),
                (296, 101), (285, 132), (301, 171), (301, 184), (278, 185),
                (277, 176), (282, 171), (267, 146), (257, 116), (230, 113),
                (189, 125), (148, 120), (136, 145), (135, 174), (142, 180),
                (141, 187), (115, 187), (112, 176), (115, 147), (113, 121),
                (100, 106), (88, 83), (66, 85), (52, 92), (28, 89), (23, 81)
            ]
            let dog = Path { path in
                path.move(to: point(outline[0].0, outline[0].1))
                for (x, y) in outline.dropFirst() { path.addLine(to: point(x, y)) }
                path.closeSubpath()
            }
            context.fill(dog, with: .color(Theme.mint.opacity(0.16)))
            context.stroke(dog, with: .color(Theme.mint.opacity(0.47)), style: StrokeStyle(lineWidth: 1.4, lineJoin: .round))

            let joints = [point(137, 93), point(124, 124), point(124, 166)]
            context.stroke(Path { path in
                path.move(to: point(146, 72))
                for joint in joints { path.addLine(to: joint) }
            }, with: .color(Theme.mint), style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
            for joint in joints {
                let marker = Path(ellipseIn: CGRect(x: joint.x - 5, y: joint.y - 5, width: 10, height: 10))
                context.fill(marker, with: .color(Theme.background))
                context.stroke(marker, with: .color(Theme.mint), lineWidth: 2)
            }
        }
        .padding(8)
        .background(Theme.panel, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityLabel("Silueta lateral de un perro con hombro, codo y carpo resaltados")
    }
}
