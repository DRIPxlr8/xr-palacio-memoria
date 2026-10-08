# CLAUDE.md — Palacio de Memoria en RA

Guía para Claude Code en este repositorio. Léela completa antes de hacer cambios.

## Qué es el proyecto

App de **realidad aumentada para iPhone** que ayuda a estudiar terminología técnica con la técnica del **palacio de memoria** (método de loci). El estudiante "pega" cada término sobre un lugar real de su sala de estudio (mesa, pared, estante) y luego recorre físicamente el espacio para repasar y evaluarse.

La app tiene tres modos, uno por caso de uso:

| Modo | Qué hace el estudiante |
|---|---|
| **CU1 · Anclar** | Toca una superficie detectada por la cámara, coloca un marcador virtual y le asocia un término y su definición. |
| **CU2 · Estudio** | Recorre la sala; al tocar un marcador ve su definición. Botón "Siguiente término" para seguir el recorrido. |
| **CU3 · Quiz** | Los marcadores muestran "?". Toca para revelar la definición, marca Acerté / No acerté y al final ve un resumen con los términos a repasar. |

**Pantalla:** mitad superior con los controles y el contenido de cada modo; mitad inferior siempre con la vista de cámara. Los marcadores deben quedar fijos y estables al caminar, y su texto debe leerse desde cualquier ángulo.

**Alcance actual (Hito 2, prototipo lo-fi):** los tres modos funcionando de punta a punta en iPhone, con un glosario de prueba y elementos visuales simples (placeholders). Fuera de alcance por ahora: persistencia del palacio entre sesiones, oclusión, diseño visual final y soporte optimizado para iPad.

Proyecto del curso IDI3185 Realidad Extendida (PUC). Equipo de 3 personas.

## Stack

- **Swift 6**, **SwiftUI**, **ARKit**, **RealityKit**. Sin Unity ni motores de terceros.
- Plataforma objetivo: **iPhone, iOS 17 o superior**.
- Tests: **Swift Testing** (`import Testing`, `@Test`, `#expect`).
- Sin dependencias externas salvo que el equipo lo decida explícitamente.

## Arquitectura

Tres partes, que corresponden a los tres roles del equipo:

```
Capa AR (A)  <──>  Estado de la app (B)  <──>  Interfaz (C)
                          │
                    Lógica / PalacioCore (B)
```

- **Capa AR** (`PalacioMemoria/AR/`): sesión ARKit, detección de planos, raycast al tocar, creación y borrado de anclajes y marcadores, detección de toques sobre marcadores, estilos visuales de los marcadores.
- **Interfaz** (`PalacioMemoria/Features/`, `PalacioMemoria/Shared/`): vistas SwiftUI de cada modo, selector de modo, formularios, paneles y resumen.
- **Estado de la app** (`PalacioMemoria/App/`): modelo observable con el modo actual, el término seleccionado, etc. Es el único punto de contacto entre la capa AR y la interfaz: **la capa AR y la interfaz no se llaman directamente.**
- **Lógica** (`Packages/PalacioCore/`): modelos y reglas de negocio puras (términos, recorrido de estudio, quiz, puntaje), con tests.

### Regla crítica: PalacioCore debe compilar en Windows y Linux

El rol B desarrolla desde **Windows**, sin Xcode. Por eso `PalacioCore`:

- **Solo puede importar `Foundation`** (y `Testing` en los tests). **Nunca** `SwiftUI`, `UIKit`, `ARKit`, `RealityKit`, `Combine` ni otro framework exclusivo de Apple.
- Debe compilar y pasar los tests con `swift build` y `swift test` desde la carpeta `Packages/PalacioCore/`.
- Toda la lógica que no dependa de la cámara ni de la UI va aquí, no en el target de la app. Mientras más lógica viva en PalacioCore, más se puede desarrollar y probar sin Mac.
- No debe conocer tipos de ARKit. Para referirse a un anclaje usa identificadores propios (por ejemplo `UUID`).

## Estructura del repositorio

```
xr-palacio-memoria/
├── PalacioMemoria.xcodeproj         # Proyecto de Xcode (se crea en Mac)
├── PalacioMemoria/                  # Código de la app (iOS)
│   ├── App/        estado de la app, punto de entrada         (B)
│   ├── AR/         cámara, superficies, marcadores             (A)
│   ├── Features/                                               (C)
│   │   ├── Anclar/
│   │   ├── Estudio/
│   │   └── Quiz/
│   ├── Shared/     componentes de interfaz reutilizables       (C)
│   └── Resources/  glosario de prueba, íconos, colores
├── Packages/PalacioCore/            # Lógica pura + tests      (B)
│   ├── Package.swift
│   ├── Sources/PalacioCore/
│   └── Tests/PalacioCoreTests/
├── docs/
│   ├── arquitectura.md
│   ├── pruebas.md                   # registro de pruebas en dispositivo y con usuarios
│   └── decisiones/                  # decisiones de diseño (ADRs cortos)
├── Build/                           # ejecutable para instalar en iPhone + INSTALL.md
├── .github/
│   ├── ISSUE_TEMPLATE/
│   ├── pull_request_template.md
│   └── workflows/
├── .gitattributes
├── .gitignore
├── CLAUDE.md
└── README.md
```

## Equipo y roles

| Rol | Dueño de | Equipo |
|---|---|---|
| **A · Realidad aumentada** | `AR/`, configuración del proyecto Xcode (targets, firma, capabilities), build para iPhone | Mac + iPhone |
| **B · Lógica y datos** | `Packages/PalacioCore/`, `App/`, glosario, tests, README, tag de versión | **Windows** |
| **C · Interfaz** | `Features/`, `Shared/`, pruebas en dispositivo y con usuarios | Mac + iPhone |

Solo el rol A modifica la configuración del proyecto Xcode, para evitar conflictos en `project.pbxproj`.

## Flujo de trabajo con Git

- `main` siempre compila. Nadie hace push directo a `main`.
- **Una tarea = un issue** en GitHub. **Una rama por issue**:
  `feat/<n>-descripcion-corta`, `fix/<n>-...`, `test/<n>-...`, `docs/<n>-...`, `chore/<n>-...`
- Los cambios entran por **pull request**, revisado por otro integrante. El PR incluye `Closes #<n>`.
- Merge **sin squash** (merge commit o rebase), para conservar los commits individuales y su autor.
- **Commits chicos y frecuentes**, uno por paso que compile, con formato Conventional Commits en español:

  ```
  feat(ar): colocar marcador al tocar superficie (#9)
  feat(core): agregar estado y puntaje del quiz (#21)
  test(core): casos borde de término vacío (#11)
  fix(ui): panel de estudio corta definiciones largas (#19)
  docs(readme): instrucciones de instalación (#29)
  chore(repo): configuración inicial del repositorio
  ```

  Tipos: `feat`, `fix`, `test`, `refactor`, `docs`, `chore`. Scopes: `ar`, `core`, `ui`, `app`, `ci`, `docs`, `repo`.
- No agregar líneas de coautoría ni firmas de herramientas en los commits.

## Convenciones de código

- Nombres de tipos, funciones y variables en **inglés**. Textos visibles en la app, comentarios y documentación en **español**.
- Una vista o tipo principal por archivo, con el nombre del archivo igual al del tipo.
- Cada cambio en PalacioCore viene con sus tests.
- Las features AR solo se validan en un iPhone físico: el simulador no tiene cámara AR.

## Comandos

```bash
# Lógica (funciona en Windows, Linux y Mac)
cd Packages/PalacioCore
swift build
swift test

# En Windows con Swift 6.4, el build system por defecto no encuentra Visual Studio
# ('stdlib.h' file not found). Usar el build system nativo:
swift build --build-system native
swift test --build-system native

# App completa (solo Mac)
xcodebuild -scheme PalacioMemoria -destination 'generic/platform=iOS' build
```

## Configuración inicial del repositorio (primer commit)

Si el repositorio está vacío, el primer commit debe dejar lo siguiente. **El proyecto Xcode no se crea en este commit si se trabaja desde Windows**; lo crea el rol A en Mac después (ver la nota al final).

1. **`.gitattributes`** en la raíz, para que todos los archivos de texto usen fin de línea LF aunque el equipo trabaje en Windows y Mac:

   ```
   * text=auto eol=lf
   *.png binary
   *.jpg binary
   *.usdz binary
   *.reality binary
   ```

2. **`.gitignore`** con la plantilla estándar de Xcode/Swift, que incluya al menos:
   `.DS_Store`, `xcuserdata/`, `*.xcuserstate`, `DerivedData/`, `.build/`, `.swiftpm/`, `*.xcscmblueprint`, `Package.resolved` (solo dentro de `Packages/`), `.vscode/` y los archivos de entorno locales.
   **No** ignorar `Build/`, porque ahí va el ejecutable entregable.

3. **Paquete `Packages/PalacioCore/`** creado con SwiftPM:
   - `Package.swift` con `swift-tools-version: 6.0`, plataformas `.iOS(.v17)` y `.macOS(.v14)`, un producto librería `PalacioCore` y un target de tests `PalacioCoreTests`.
   - Un archivo fuente mínimo y un test mínimo con Swift Testing que pase con `swift test`.

4. **Estructura de carpetas** de la app (`PalacioMemoria/App`, `AR`, `Features/Anclar`, `Features/Estudio`, `Features/Quiz`, `Shared`, `Resources`), más `docs/` y `Build/`, cada una con un `.gitkeep` mientras esté vacía.

5. **`README.md`** inicial con: descripción breve del proyecto, stack, requisitos (Mac con Xcode para la app; cualquier sistema con Swift 6 para PalacioCore), cómo correr los tests de PalacioCore y secciones vacías para Instalación, Uso y Estado actual.

6. **`docs/arquitectura.md`** con el diagrama y la descripción de las tres partes (copiar de la sección Arquitectura de este archivo), y **`docs/pruebas.md`** con una tabla vacía para el registro de pruebas (fecha, dispositivo, versión de iOS, qué se probó, resultado, bugs).

7. **Plantillas de GitHub** en `.github/`:
   - `ISSUE_TEMPLATE/tarea.md`: descripción, rol (A/B/C), paso de la guía, criterio de aceptación.
   - `ISSUE_TEMPLATE/bug.md`: qué pasó, qué se esperaba, pasos para reproducir, dispositivo.
   - `pull_request_template.md`: qué cambia, `Closes #`, cómo se probó, checklist (compila, tests pasan, probado en iPhone si aplica).

8. **CI en `.github/workflows/ci.yml`**: en cada PR y push a `main`, correr `swift test` en `Packages/PalacioCore` (runner `ubuntu-latest` con Swift 6). El build de la app con `xcodebuild` en `macos-latest` se agrega cuando exista el proyecto Xcode.

9. Este **`CLAUDE.md`** en la raíz.

Mensaje del commit: `chore(repo): configuración inicial del repositorio`.

**Nota para el rol A (en Mac), después del commit inicial:** crear `PalacioMemoria.xcodeproj` (App iOS, SwiftUI, iOS 17), usando las carpetas existentes como *carpetas sincronizadas* para que agregar archivos no modifique `project.pbxproj`. Agregar `Packages/PalacioCore` como paquete local (File → Add Package Dependencies → Add Local), configurar la firma y el permiso de cámara (`NSCameraUsageDescription`), y luego activar el job de `xcodebuild` en la CI.
