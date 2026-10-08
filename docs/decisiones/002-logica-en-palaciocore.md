# 002 · Lógica en un paquete SwiftPM aparte (PalacioCore)

- **Fecha:** 08-10-2026
- **Paso:** 1 · Setup del proyecto
- **Rol:** B · Lógica y datos
- **Estado:** propuesta, se confirma en la revisión del PR

## Contexto

El rol B desarrolla desde Windows, sin Xcode ni iPhone. La app usa ARKit y RealityKit, que solo compilan en Mac, así que el código que vive en el target de la app no se puede compilar ni probar en Windows.

Gran parte de lo que hace la app no depende de la cámara: qué es un término, en qué orden se recorre el palacio, cómo se lleva el puntaje del quiz.

## Decisión

Esa lógica vive en `Packages/PalacioCore`, un paquete SwiftPM que solo importa `Foundation`. La app lo usa como paquete local de Xcode y lo importa desde `PalacioMemoria/App/`.

Para referirse a un marcador, PalacioCore usa identificadores propios (`UUID`), sin tipos de ARKit.

Los tests usan Swift Testing y corren en tres lugares: en Windows (rol B), en Mac y en la CI sobre Linux.

## Consecuencias

- La lógica se desarrolla y se prueba sin Mac, y la CI la verifica en cada PR.
- La capa AR y la interfaz no pueden filtrar tipos de Apple hacia la lógica: si PalacioCore importa algo más que `Foundation`, deja de compilar en Windows y en la CI.
- El build de la app solo se puede verificar en Mac. Un cambio en `App/` hecho desde Windows necesita que alguien con Xcode lo compile antes del merge.

## Dificultades del entorno en Windows

Quedan anotadas porque costaron tiempo y son material para la presentación.

- Una instalación incompleta de Visual Studio Build Tools 2026 impedía que Swift encontrara el compilador de C (`'stdlib.h' file not found`). Se resolvió desinstalándola y dejando solo Visual Studio 2022 Community.
- Con Swift 6.4, el build system por defecto sigue sin detectar Visual Studio en Windows. Los comandos funcionan con `--build-system native`, que esa versión marca como obsoleto.
- La CI usa Swift 6.0 y la máquina del rol B usa 6.4, así que algo que compila localmente puede fallar en la CI si usa una función posterior a 6.0.
