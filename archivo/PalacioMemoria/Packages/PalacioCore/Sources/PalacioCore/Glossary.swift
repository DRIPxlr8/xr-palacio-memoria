import Foundation

/// Glosarios de términos listos para anclar.
public enum Glossary {
    /// Glosario de prueba del prototipo: terminología de realidad extendida.
    /// Los términos vienen sin marcador; el estudiante los ancla en el modo Anclar.
    public static let sample: [Term] = [
        Term(
            name: "Realidad aumentada",
            definition: "Tecnología que superpone objetos virtuales sobre la vista del mundo real."
        ),
        Term(
            name: "Realidad virtual",
            definition: "Tecnología que reemplaza por completo la vista del mundo real por un entorno generado por computador."
        ),
        Term(
            name: "Realidad mixta",
            definition: "Experiencia donde los objetos virtuales conviven con el entorno real y responden a él."
        ),
        Term(
            name: "Tracking",
            definition: "Seguimiento continuo de la posición y la orientación del dispositivo en el espacio."
        ),
        Term(
            name: "Registro",
            definition: "Alineación de un objeto virtual con una posición del mundo real, de modo que parezca estar ahí."
        ),
        Term(
            name: "Anclaje",
            definition: "Punto fijo del mundo real al que se asocia un objeto virtual para que no se mueva."
        ),
        Term(
            name: "Detección de planos",
            definition: "Reconocimiento de superficies planas del entorno, como mesas, pisos y paredes."
        ),
        Term(
            name: "Raycast",
            definition: "Rayo que se lanza desde un punto de la pantalla para saber qué superficie del mundo real toca."
        ),
        Term(
            name: "SLAM",
            definition: "Técnica que construye un mapa del entorno y, a la vez, ubica al dispositivo dentro de él."
        ),
        Term(
            name: "Seis grados de libertad",
            definition: "Movimiento en tres ejes de posición y tres de rotación; se abrevia 6DoF."
        ),
        Term(
            name: "Oclusión",
            definition: "Efecto en que un objeto real tapa a uno virtual que está detrás de él."
        ),
        Term(
            name: "Deriva",
            definition: "Error que se acumula en el tracking y desplaza los objetos virtuales de su lugar."
        ),
    ]
}
