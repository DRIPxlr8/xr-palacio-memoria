# Palacio de Memoria en Realidad Aumentada para el Aprendizaje de Terminología Técnica

Proyecto del curso IDI3185, Realidad Extendida (UC, 2026-2)

## Equipo

- Benjamín Masson — benjamin.masson@uc.cl
- Joaquín Rubio — jrubic@uc.cl
- Vicente San Juan — sanjuan.vicente@uc.cl

## Descripción del proyecto

Los estudiantes de asignaturas con alta densidad de terminología técnica, como anatomía, farmacología o glosarios especializados de ingeniería, suelen estudiar con métodos lineales, como listas o tarjetas de memoria, que no aprovechan la memoria espacial. Este proyecto propone una aplicación de realidad aumentada para iPhone que implementa la técnica del *palacio de la memoria* (*method of loci*). El estudiante ancla términos técnicos como marcadores virtuales sobre su propio espacio físico y luego repasa y se autoevalúa recorriendo ese mismo espacio.

## Por qué XR

La asociación espacial es el núcleo de la técnica. El usuario necesita registrar objetos virtuales sobre posiciones reales específicas y mantener esa asociación estable mientras se mueve. Esto depende directamente de las capacidades de *tracking* y registro propias de la realidad aumentada y no se puede replicar con una app 2D convencional.

## Casos de uso

1. **CU1 · Anclar** — el usuario toca una superficie detectada por la cámara, coloca un marcador virtual y le asocia un término y su definición.
2. **CU2 · Estudio** — la app le dice qué término buscar; el usuario recuerda dónde lo dejó, camina hasta ahí y toca su marcador para ver la definición.
3. **CU3 · Quiz** — los marcadores muestran «?»; el usuario toca uno, intenta recordar qué término dejó ahí, revela la respuesta y marca si acertó o no. Al final ve su puntaje y los términos a repasar.

## Stack

- Swift, SwiftUI, ARKit y RealityKit (sin Unity ni motores de terceros).
- Proyecto de Xcode creado con Xcode 27, con **iOS 27.0 como versión mínima**.
- Lógica pura en el paquete SwiftPM `Packages/PalacioCore` (Swift 6), que solo depende de `Foundation` y compila en Windows, Linux y Mac. La app lo usa como paquete local.
- Tests con Swift Testing: 69 tests sobre PalacioCore.
- CI en GitHub Actions: corre los tests de PalacioCore en Linux en cada pull request y en cada cambio de `main`. No compila la app.

La arquitectura se describe en [docs/arquitectura.md](docs/arquitectura.md) y las decisiones de diseño en [docs/decisiones/](docs/decisiones/).

## Requisitos

- **App completa:** Mac con Xcode 27 y un iPhone físico con iOS 27 o superior. El simulador no sirve, porque no tiene cámara AR.
- **PalacioCore (lógica y tests):** cualquier sistema con Swift 6 (Windows, Linux o Mac).

## Instalación

### Desde el código, con Xcode

1. Clonar el repositorio y abrir el proyecto:

   ```bash
   git clone https://github.com/DRIPxlr8/xr-palacio-memoria.git
   cd xr-palacio-memoria
   open PalacioMemoria.xcodeproj
   ```

   Xcode resuelve solo el paquete local `Packages/PalacioCore`; no hay dependencias externas que descargar.

2. En el target **PalacioMemoria**, pestaña *Signing & Capabilities*, elegir tu propio *Team*. El proyecto viene con el equipo de desarrollo de un integrante. Si Xcode reclama por el identificador de la app, cambiar el *Bundle Identifier* por uno propio.

3. Conectar el iPhone, elegirlo como destino y ejecutar con ⌘R.

4. La primera vez, en el iPhone:
   - activar el *Modo de desarrollador* en Ajustes → Privacidad y seguridad, si no está activo;
   - confiar en el desarrollador en Ajustes → General → VPN y gestión de dispositivos;
   - aceptar el permiso de cámara cuando la app lo pida.

Con una cuenta gratuita de Apple, la app instalada deja de abrir a los 7 días y hay que volver a instalarla desde Xcode.

### Desde el ejecutable

El ejecutable para instalar sin compilar va en [`Build/`](Build/), junto con sus instrucciones. Todavía no está generado.

## Uso

La pantalla tiene dos partes: arriba, el panel con el contenido del modo actual; abajo, siempre, la cámara. El selector de la parte superior cambia entre **Anclar**, **Estudio** y **Quiz**. Los marcadores se mantienen al cambiar de modo.

### 1. Anclar: armar el palacio

1. Mover el iPhone apuntando a la sala hasta que la app detecte superficies.
2. Tocar una superficie (mesa, pared, estante). Aparece una esfera con el texto «Nuevo término» y se abre el formulario.
3. Escribir el término y su definición, o elegir uno con el botón **Glosario** (12 términos de realidad extendida).
4. **Fijar término** deja el marcador con el nombre del término. **Cancelar** lo quita.
5. Repetir en otros lugares de la sala.

Con el formulario abierto, tocar otra superficie mueve el marcador a ese punto.

### 2. Estudio: recorrido guiado

1. El panel muestra **Siguiente término** con el nombre del término a buscar y su posición en el recorrido (por ejemplo, «2 de 5»). No muestra la definición.
2. Recordar dónde se dejó, caminar hasta ahí y tocar su marcador.
3. Se abre la definición, el marcador queda amarillo y aparece el botón **Siguiente término**.

El recorrido sigue el orden en que se anclaron los términos y, después del último, vuelve al primero. Si se toca otro marcador, se ve su definición y el panel recuerda cuál se sigue buscando. **Saltar** pasa al siguiente sin haberlo encontrado.

### 3. Quiz: autoevaluación

1. Los marcadores muestran «?».
2. Tocar uno. El panel pregunta «¿Qué término dejaste aquí?».
3. **Tocar para revelar** muestra el término y su definición.
4. Marcar **Acerté** (el marcador queda verde) o **No acerté** (queda rojo).
5. Al responder todos, el panel muestra el puntaje y la lista de términos a repasar. **Repetir quiz** empieza de nuevo.

Cada término se responde una sola vez. Las respuestas se conservan al cambiar de modo, hasta que se repite el quiz.

## Tests de PalacioCore

```bash
cd Packages/PalacioCore
swift build
swift test
```

En Windows con Swift 6.4, si el build falla con `'stdlib.h' file not found`, agregar `--build-system native` a ambos comandos.

## Estado actual

- [x] Hito 1 — Formulación del proyecto (entregado 8 de septiembre de 2026)
- [ ] Hito 2 — Prototipo lo-fi (13 de octubre de 2026)
- [ ] Hito 3 — Prototipo final (24 de noviembre de 2026)

### Qué incluye el prototipo del Hito 2

- Los tres modos (Anclar, Estudio y Quiz), que se usan uno tras otro sin reiniciar la app.
- Detección de superficies horizontales y verticales, y marcadores anclados al punto tocado.
- Glosario de prueba de 12 términos, además de términos escritos por el usuario.
- Recorrido de estudio, puntaje del quiz y lista de términos a repasar, con tests automáticos.

El registro de pruebas en dispositivo y con usuarios está en [docs/pruebas.md](docs/pruebas.md).

### Limitaciones conocidas

- **Sin persistencia:** el palacio se pierde al cerrar la app. Queda para el Hito 3.
- **No se puede borrar un término ya anclado** desde la interfaz. La lógica lo permite, pero falta el botón.
- **El texto de los marcadores no gira hacia la cámara**, así que desde algunos ángulos cuesta leerlo.
- **En modo Estudio los marcadores muestran su nombre**, de modo que de cerca se puede leer cuál es cuál.
- **Elementos visuales provisorios:** esferas de colores y texto simple. El diseño visual final queda para el Hito 3.
- **Requiere iOS 27**, que es la versión mínima con que quedó configurado el proyecto.
- **La CI no compila la app:** solo prueba la lógica. El build de la app se verifica a mano en Xcode.
- **El ejecutable instalable todavía no está en `Build/`.**

## Estructura del repositorio

```text
PalacioMemoria.xcodeproj → proyecto de Xcode
PalacioMemoria/          → código de la app iOS (App, AR, Features, Shared, Resources)
Packages/PalacioCore/    → lógica pura + tests
docs/                    → arquitectura, registro de pruebas y decisiones
Build/                   → ejecutable para instalar en iPhone
informe/                 → informe (IEEE) de cada hito
.github/                 → plantillas de issues/PR y CI
CLAUDE.md                → guía de trabajo del repositorio
```

## Informe

El informe se versiona en `/informe` (fuente LaTeX y PDF compilado). A medida que el proyecto avanza entre hitos, se actualiza sobre la misma base en lugar de reescribirse desde cero, y cada entrega queda marcada como un punto identificable en el historial.
