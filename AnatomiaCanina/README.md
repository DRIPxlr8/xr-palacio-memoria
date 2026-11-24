# Anatomía Canina en RA

Aplicación local para estudiar osteología veterinaria del miembro anterior izquierdo canino. Incluye hombro, codo y carpo, con dos niveles y cuatro objetivos por región.

## Abrir y probar el palacio

1. Abre `AnatomiaCanina.xcodeproj` en Xcode 27 y selecciona el esquema **AnatomiaCanina**. Conecta un iPhone o iPad con realidad aumentada e iOS 27 y ejecútalo con firma automática.
2. Pulsa **Abrir cámara** y permite el acceso. En **Colocar**, toca una superficie horizontal para previsualizar Hombro. Usa **Altura sobre la superficie** (0–180 cm) y **Tamaño del modelo** (50–200 %) y pulsa **Confirmar colocación**. Repite con Codo y Carpo en puntos distintos de la habitación.
3. Comprueba que al cambiar a **Estudiar** las tres estaciones siguen en su sitio. Toca una superficie del hueso o elige una estructura del nivel básico o de detalle. La zona se resalta en su sitio. Puedes rodear cada estación, girar su modelo con un dedo o acercarlo con dos.
4. En **Quiz**, localiza cada respuesta en el espacio. Cada pregunta nombra una estructura de una estación confirmada. Por ejemplo, «Toca la cavidad glenoidea de la escápula». Los modelos mantienen sus rótulos ocultos y cada pieza visible tiene un color distinto dentro de su estación. La zona tocada se marca en blanco. Al confirmar, el quiz indica si acertaste y resalta la zona correcta.
5. Vuelve a **Colocar**, selecciona una estación existente para ajustar su altura y tamaño en el mismo lugar. Toca otro punto si quieres moverla. Pulsa **Cancelar colocación** para comprobar que vuelve al sitio anterior. Prueba también cancelar un modelo nuevo, que debe desaparecer. El basurero al lado de cada estación confirmada la retira del espacio y de las próximas rondas. Prueba también orientación vertical y horizontal y retorno desde segundo plano.

El palacio pertenece a la sesión activa de cámara. Los resultados de estudio y quiz se guardan aunque cierres la app.

La copia local de [Palacio de Memoria](../archivo/PalacioMemoria/) mantiene su propio proyecto y paquete Swift.

## Modelos y créditos

Los modelos y sus imágenes de portada son adaptaciones de las mallas de Labrador del conjunto de James Charles, Gabriella Rose, Tatjana Hoehfurtner, Rebecca Arnold, Eithne Comerford y Karl Bates. [Datos de la Universidad de Liverpool, DOI 10.17638/datacat.liverpool.ac.uk/3093](https://doi.org/10.17638/datacat.liverpool.ac.uk/3093). Mallas y vistas derivadas bajo [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/deed.es).

Los STL de origen son `L SCAP.stl`, `L HUM.stl`, `L RAD.stl` y `L MAN_carpals.stl`. Los huesos del antebrazo y del carpo vienen unidos en la fuente. Las divisiones seleccionables son anotaciones de superficie sobre esa geometría. Antes de usar el quiz en una evaluación docente, revisar la delimitación de cada zona con un docente de anatomía veterinaria, especialmente las zonas articulares y carpales. El archivo [prepare_models.py](Tools/prepare_models.py) contiene las reglas reproducibles para orientar, marcar y exportar los modelos, además de generar sus imágenes. Usa Python con NumPy y Pillow, `tar`, `usdcat` y `usdzip`. Los USDZ y las imágenes se incluyen en el proyecto para que la app funcione sin red.

Las fichas se basan en la [guía de anatomía de carnívoros de la Universidad de Minnesota](https://vanat.ahc.umn.edu/carnLabs/Lab04/Lab04.html) y en la [comparación microtomográfica del carpo canino y felino](https://pmc.ncbi.nlm.nih.gov/articles/PMC13281358/).

## Verificación

- Ejecuta **Product → Test** con un simulador de iPhone para comprobar la portada y el requisito de realidad aumentada. Colocar y tocar estaciones se comprueba en un dispositivo físico.
- Para las reglas de colocación, quiz y persistencia, desde esta carpeta compila utilizando `swiftc AnatomiaCanina/Catalog.swift Tests/VerifyCatalog.swift -o /tmp/verify-anatomia-canina` y ejecuta `/tmp/verify-anatomia-canina`.
- Para comprobar la carga de las mallas en RealityKit desde macOS, compila con `swiftc -parse-as-library AnatomiaCanina/Catalog.swift AnatomiaCanina/AnatomyModel.swift Tests/VerifyModels.swift -o /tmp/verify-anatomia-models` y ejecuta `/tmp/verify-anatomia-models AnatomiaCanina/Models`.
- Para el piloto, compara identificación al primer intento antes y después del estudio. Usa vistas distintas y registra por separado la ayuda requerida, los toques que fallan por la interfaz y las confusiones anatómicas. La RA y la revisión docente requieren verificación presencial.
