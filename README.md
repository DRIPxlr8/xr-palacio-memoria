# Anatomía Canina en RA

Prototipo final de IDI3185 Realidad Extendida, UC, segundo semestre de 2026. Versión 0.2.6, compilación 8.

**Equipo** Benjamín Masson, Joaquín Rubio y Vicente San Juan.

## Qué hace

Permite estudiar el miembro anterior izquierdo de un perro mediante estaciones de realidad aumentada. El estudiante coloca modelos de hombro, codo y carpo, los inspecciona desde diferentes posiciones y responde un quiz tocando la estructura que pide la consigna.

- **Colocar.** Abre la cámara y toca una superficie horizontal. Ajusta altura y tamaño antes de confirmar. Para mover o quitar una estación, vuelve a Colocar.
- **Estudiar.** Elige una estructura para resaltarla y leer su pista. Puedes rodear el modelo para cambiar de punto de vista.
- **Quiz.** Lee la consigna, toca una pieza y confirma. Las preguntas salen de las estaciones confirmadas. Cada región aporta cuatro preguntas.

Las estaciones duran la sesión activa de cámara. El progreso de estudio y el último resultado por región se guardan en el iPhone.

## Instalación y ejecución

- [Instalación del paquete iOS 0.2.6](Build/INSTALL.md)
- [Instalación y pruebas desde el código](AnatomiaCanina/README.md)

Abre **Anatomía Canina** en un iPhone con iOS 27, concede permiso de cámara y pulsa **Abrir cámara**. Para la demo, usa un lugar iluminado con una superficie que tenga detalles visibles. El paquete de desarrollo se instala en un dispositivo registrado en su perfil de firma.

## Tecnologías y estructura

- **SwiftUI** administra los modos y el estado de la sesión. **ARKit** estima la pose del dispositivo y las superficies. **RealityKit** ubica los modelos USDZ y detecta qué pieza recibe el toque.
- [AnatomiaCanina/](AnatomiaCanina/) contiene la aplicación, tres modelos 3D, instrucciones de desarrollo y pruebas.
- [Build/](Build/) contiene el paquete de iOS y las instrucciones de instalación.
- [Evaluación del Hito 3](docs/evaluacion-hito-3.md) reúne los hallazgos internos, las iteraciones y el protocolo del piloto con estudiantes.
- [Ensayo de la demo](docs/demo-hito-3.md) detalla el recorrido, la comprobación en sala y la grabación de respaldo.
- [archivo/PalacioMemoria/](archivo/PalacioMemoria/) conserva el código y la documentación del prototipo anterior. Su [paquete del Hito 2](Build/PalacioMemoria-iOS-v0.2.zip) sigue disponible en `Build/`.

## Modelos y créditos

Las mallas del miembro anterior derivan de Charles y colaboradores, University of Liverpool, bajo [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es). Las regiones seleccionables son anotaciones en las superficies de esas mallas, con revisión anatómica pendiente en zonas articulares y carpales. [Conjunto original](https://doi.org/10.17638/datacat.liverpool.ac.uk/3093) · [Adaptaciones y referencias anatómicas](AnatomiaCanina/README.md)
