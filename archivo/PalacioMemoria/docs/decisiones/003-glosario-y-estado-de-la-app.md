# 003 · Glosario de prueba en PalacioCore y estado de la app en el target

- **Fecha:** 08-10-2026
- **Paso:** 2 · Base de la app
- **Rol:** B · Lógica y datos
- **Estado:** propuesta, se confirma en la revisión del PR

## Contexto

El Paso 2 pide definir el término, el estado de la app y un glosario de prueba. La estructura del repositorio ubicaba el glosario en `PalacioMemoria/Resources/`, y el estado de la app tiene que ser observable para que las vistas de SwiftUI se actualicen.

## Decisión

- **El glosario de prueba va en código, en PalacioCore** (`Glossary.sample`), y no como archivo en `Resources/`. Son 12 términos de realidad extendida.
- **El estado de la app (`AppState`) va en `PalacioMemoria/App/`**, como clase `@Observable`. Guarda el modo actual, el glosario y el término elegido. Se entrega a las vistas por el entorno de SwiftUI.
- **`AppMode` se queda en el target de la app**, donde lo creó el rol C.
- **Un término guarda el `UUID` de su marcador** (`Term.markerID`), sin tipos de ARKit.

## Consecuencias

- El glosario se prueba con `swift test` en Windows y en la CI, y no hace falta leer ni decodificar un archivo al abrir la app.
- Cambiar el glosario implica recompilar. Para el prototipo basta; si en el Hito 3 se cargan glosarios del usuario, habrá que revisarlo.
- `AppState` no se puede compilar ni probar en Windows, así que se mantiene sin lógica: las reglas van en PalacioCore.
- Para asociar un término a su marcador, la capa AR tiene que entregar el `UUID` del marcador que crea. Hoy solo avisa la posición; se ajusta en el Paso 3.
