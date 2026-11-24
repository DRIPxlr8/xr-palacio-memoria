# Evaluación preliminar del Hito 3

## Piloto interno de usabilidad

La evaluación preliminar se apoya en tres pruebas exploratorias de Vicente San Juan, integrante del equipo, en un iPhone 16 Pro, el 21 y 22 de noviembre de 2026. La tabla registra esas tres pruebas y el ajuste adicional del aviso de salida del quiz.

| Versión probada | Tarea y observación | Recomendación | Cambio implementado |
|---|---|---|---|
| 0.2.2 | Al responder en Quiz, dos colores dificultaban distinguir piezas vecinas. | Asignar un color distinto a cada superficie. | 0.2.3. Colores por pieza y selección en blanco antes de confirmar. |
| 0.2.3 | Al colocar en el suelo, observar el modelo obligaba a agacharse. | Ajustar altura y tamaño por estación. | 0.2.4. Controles de altura y tamaño durante la colocación y la edición. |
| 0.2.4 | Al elegir una estructura en Estudiar, el modelo podía girar automáticamente. | Conservar la orientación del modelo y permitir que la persona se mueva. | 0.2.5. Se resalta la pieza en su sitio. |
| 0.2.5 | Al salir de Quiz, el aviso aparecía sobre la cámara. | Llevar la confirmación al panel de modos. | 0.2.6. Confirmación integrada en el panel de Quiz. |

Las compilaciones corregidas se instalaron en el iPhone de prueba. La 0.2.6 se verificó con las pruebas de lógica del catálogo, colocación, dimensiones, selección y puntaje. RealityKit cargó las 15 superficies de los tres modelos. La verificación técnica evalúa funcionamiento y los comentarios internos orientan ajustes de interacción.

## Protocolo del piloto con estudiantes

**Estado** Tres sesiones pendientes. La prueba usará la **0.2.6, compilación 8**, con tres estudiantes de Veterinaria identificados como P1, P2 y P3. Se usará el mismo iPhone 16 Pro, el mismo moderador, una mesa, el mismo punto marcado y luz comparable. Se reiniciará la sesión de realidad aumentada antes de cada persona. La única estación del piloto será Hombro.

Cada sesión dura **12 minutos** y el moderador cambia de etapa al mismo tiempo. La app utiliza el mismo conjunto de cuatro consignas de Hombro y puede variar el orden.

| Tiempo | Actividad | Registro |
|---|---|---|
| 00:00–01:00 | Introducción con el mismo guion. | Año o curso y familiaridad con RA. |
| 01:00–03:00 | Colocar y confirmar Hombro en el punto marcado. | Completó, completó con ayuda o quedó incompleta. Tiempo hasta confirmar. |
| 03:00–06:00 | Resaltar cavidad glenoidea y cabeza del húmero. Rodear el modelo. | Completitud y observación desde más de un ángulo. |
| 06:00–10:00 | Resolver las cuatro consignas del quiz. | Orden real, aciertos al primer intento confirmado y preguntas pendientes. Registrar dificultades táctiles por separado. |
| 10:00–12:00 | Entrevista con tres preguntas fijas. | Comentarios y una sugerencia prioritaria de cada persona. |

**Guion inicial.** «Te pediré tres tareas. Usa la aplicación como lo harías por tu cuenta. Si algo te confunde, dilo en voz alta». Ante una consulta, repetir la consigna antes de dar una pista de interfaz y contar las intervenciones.

**Preguntas de la entrevista.** ¿Cuándo te costó más saber qué hacer? ¿Qué te ayudó a reconocer o seleccionar una parte? ¿Qué cambiarías y por qué?

**Registro de una sesión.** Código, fecha, versión, familiaridad con RA, tiempo de colocación, resultado de cada tarea, primera respuesta confirmada por consigna, preguntas pendientes, ayudas, dificultades táctiles, incidentes y sugerencia.

**Registro de cambios posteriores.** Código de participante, versión probada, observación, recomendación, decisión, versión corregida y resultado de la reprueba. El piloto evalúa usabilidad. Medir aprendizaje requiere contrastar el reconocimiento antes y después de estudiar.

El [registro del Hito 2](pruebas.md) corresponde a Palacio de Memoria.
