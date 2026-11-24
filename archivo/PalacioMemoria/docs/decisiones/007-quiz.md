# 007 · Quiz de autoevaluación (CU3)

- **Fecha:** 11-10-2026
- **Paso:** 5 · CU3 Quiz
- **Rol:** B · Lógica y datos (afecta a A y C)
- **Estado:** propuesta, se confirma en la revisión del PR

## Contexto

La interfaz del quiz ya existía (`QuizPanel`, `QuizQuestionCard`, `QuizSummaryView`), pero el estado de cada término y el puntaje se calculaban de forma provisoria dentro de `MainView`, sin tests. Los marcadores seguían mostrando el nombre del término, así que la respuesta estaba a la vista.

## Decisión

El quiz parte del lugar: el estudiante ve un marcador «?» y tiene que recordar qué término dejó ahí. Es el ejercicio inverso al del modo Estudio, que parte del término y pide recordar el lugar.

Flujo:

1. En modo Quiz, los marcadores sin responder muestran **«?»**.
2. El estudiante toca uno: se abre la pregunta, con la respuesta oculta.
3. **«Tocar para revelar»** muestra el término y su definición.
4. **«Acerté»** o **«No acerté»** registra la respuesta y cierra la pregunta.
5. Con todos respondidos, el panel muestra el **puntaje** y los **términos a repasar**.

Reglas de la lógica (`Quiz`, en PalacioCore):

- Cada término se responde **una sola vez**; tocar un marcador ya respondido no hace nada.
- No se puede evaluar sin haber revelado la respuesta.
- Tocar fuera de un marcador o cambiar de modo cierra la pregunta; el término queda pendiente.
- Las respuestas **se conservan** al salir del modo Quiz. Se borran con «Repetir quiz».
- Si se ancla un término nuevo, queda pendiente y el quiz deja de estar terminado. Si se borra uno, se borra su respuesta.
- Puntaje: cantidad de «Acerté». A repasar: los «No acerté», en el orden en que se anclaron.

Colores de los marcadores (`MarkerStyle`):

| Aspecto | Color | Cuándo |
|---|---|---|
| normal | azul | sin responder, o fuera del quiz |
| `selected` | amarillo | término abierto en el panel (Estudio y Quiz) |
| `correct` | verde | respondido «Acerté» |
| `incorrect` | rojo | respondido «No acerté» |

Un marcador respondido muestra el nombre de su término en vez de «?».

## Cómo quedó en cada rol

- **B:** `Quiz`, `QuizAnswer` y `QuizPhase` en PalacioCore, con tests. `AppState` expone `quiz`, `markerLabels`, `markerStyles`, `selectMarker(_:)`, `closeOpenTerm()`, `revealQuizAnswer()`, `answerQuiz(isCorrect:)` y `restartQuiz()`.
- **C:** `MainView` ya no calcula nada del quiz; le pasa `appState.quiz.phase` a `QuizPanel`. `QuizPhase` se movió de `Features/Quiz/` a PalacioCore, con los mismos casos.
- **A:** `ARContainerView` recibe `markerStyles` (en vez de `highlightedMarkerID`) y pinta cada marcador según su aspecto. El texto «?» llega por `markerNames`.

## Consecuencias

- El término abierto en modo Estudio pasa de verde a **amarillo**, para que el verde quede reservado a «Acerté».
- Se quita `selectedTerm` de `AppState`: la pregunta abierta la lleva `Quiz`.
- El puntaje no se guarda entre sesiones; la persistencia es del Hito 3.
