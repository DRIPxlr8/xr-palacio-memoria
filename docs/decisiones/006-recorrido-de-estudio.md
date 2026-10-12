# 006 · Recorrido guiado del modo Estudio (CU2)

- **Fecha:** 11-10-2026 (reemplaza la versión del 09-10-2026)
- **Paso:** 4 · CU2 Estudio
- **Rol:** B · Lógica y datos (afecta a A y C)
- **Estado:** propuesta, se confirma en la revisión del PR

## Contexto

La guía pide un panel con el término, su definición y el botón «Siguiente término». La primera versión de la interfaz no tenía ese botón: el estudiante tocaba cualquier marcador y veía su definición. Así la app no pedía recordar nada, solo leer lo que estaba a la vista.

El método de loci funciona al revés: se parte del concepto y hay que recordar el lugar.

## Decisión

El modo Estudio es un **recorrido guiado**:

1. La app muestra **«Siguiente término»** con el nombre del término a buscar, sin su definición.
2. El estudiante recuerda dónde lo dejó, camina hasta ahí y **toca su marcador**.
3. Se abre la definición y aparece el botón **«Siguiente término»**, que pasa al que sigue.

Reglas:

- **Orden:** el mismo en que se anclaron los términos. Es la ruta con que el estudiante armó su palacio.
- **Circular:** después del último vuelve al primero, para repetir el recorrido.
- **Tocar otro marcador** también abre su definición, y el panel recuerda cuál se sigue buscando. El término buscado no cambia.
- **«Saltar»** pasa al siguiente sin haber encontrado el término, por si el estudiante no lo recuerda o el marcador se perdió.
- **Tocar fuera de un marcador** o cambiar de modo cierra la definición; el término buscado se mantiene.
- **Resaltado:** solo el marcador con la definición abierta. Nunca el del término buscado, porque delataría dónde está.

## Cómo quedó en cada rol

- **B:** `StudyTour` (PalacioCore) lleva el término buscado (`target`), el que tiene la definición abierta (`revealed`) y si ya se encontró (`isTargetFound`). `AppState` expone `studyTour`, `selectMarker(_:)`, `closeOpenTerm()`, `advanceStudy()` y `markerStyles`.
- **C:** `StudyPanel` muestra `StudyTargetPrompt` (qué buscar) o `StudyTermCard` (definición, con «Siguiente término» si era el buscado).
- **A:** `ARContainerView` recibe `markerStyles` y destaca solo el marcador con la definición abierta (amarillo desde el Paso 5; ver `007-quiz.md`). Ya no deja marcado cada marcador tocado.

## Consecuencias

- El orden no depende de dónde está parado el estudiante: el siguiente término puede estar al otro lado de la sala. Es parte del ejercicio.
- Los marcadores siguen mostrando el nombre del término sobre la esfera, así que de cerca se puede leer cuál es cuál. El ejercicio de memoria es llegar al lugar correcto; ocultar los nombres en este modo queda como posible mejora.
- En modo Quiz los colores siguen otra regla; ver `007-quiz.md`.
