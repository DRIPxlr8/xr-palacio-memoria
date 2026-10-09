# 006 · Recorrido del modo Estudio (CU2)

- **Fecha:** 09-10-2026
- **Paso:** 4 · CU2 Estudio
- **Rol:** B · Lógica y datos (afecta a A y C)
- **Estado:** propuesta, se confirma en la revisión del PR

## Contexto

En el modo Estudio el estudiante toca un marcador para ver su definición y usa «Siguiente término» para seguir. Falta decidir en qué orden se recorren los términos y qué pasa al llegar al final.

## Decisión

- **Orden: el mismo en que se anclaron.** Es el orden en que el estudiante armó su palacio, y recorrerlo igual refuerza la ruta, que es la base del método de loci.
- **El recorrido es circular:** después del último término vuelve al primero, para repetir el recorrido sin salir del modo.
- **Parte sin término actual.** El estudiante elige por dónde empezar tocando un marcador; si usa «Siguiente término» primero, parte por el primer término anclado.
- **Tocar un marcador cambia el término actual**, y «Siguiente término» continúa desde ahí.
- **El término actual se mantiene** al cambiar de modo y al anclar términos nuevos. Si se borra, el recorrido queda sin término actual.

La lógica está en `StudyTour` (PalacioCore). `AppState` la expone con `currentStudyTerm`, `studyTour.position`, `studyTour.count`, `highlightedMarkerID`, `selectMarker(_:)` y `advanceStudy()`.

## Qué necesita cada rol

- **B (hecho en este paso):** `StudyTour` con tests y las acciones en `AppState`.
- **A:** llamar a `selectMarker` desde `onMarkerSelected` y resaltar solo el marcador de `highlightedMarkerID`. Hoy el marcador tocado queda verde para siempre.
- **C:** en `StudyPanel`, mostrar `currentStudyTerm` (nombre y definición), la posición («2 de 5») y el botón «Siguiente término», que llama a `advanceStudy()`. Sin término actual, mantener la instrucción; con el palacio vacío, avisar que primero hay que anclar términos.

## Consecuencias

- El orden no depende de dónde está parado el estudiante: «Siguiente término» puede mandarlo al otro lado de la sala. Para el prototipo basta; ordenar por cercanía necesitaría la posición, que la lógica no conoce.
- `selectMarker` solo tiene efecto en modo Estudio. El Paso 5 define qué hace un toque en modo Quiz.
