# Arquitectura

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

## Regla crítica: PalacioCore debe compilar en Windows y Linux

El rol B desarrolla desde **Windows**, sin Xcode. Por eso `PalacioCore`:

- **Solo puede importar `Foundation`** (y `Testing` en los tests). **Nunca** `SwiftUI`, `UIKit`, `ARKit`, `RealityKit`, `Combine` ni otro framework exclusivo de Apple.
- Debe compilar y pasar los tests con `swift build` y `swift test` desde la carpeta `Packages/PalacioCore/`.
- Toda la lógica que no dependa de la cámara ni de la UI va aquí, no en el target de la app.
- No debe conocer tipos de ARKit. Para referirse a un anclaje usa identificadores propios (por ejemplo `UUID`).

Las decisiones de diseño se registran como ADRs cortos en [`decisiones/`](decisiones/).
