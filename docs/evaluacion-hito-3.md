# Evaluación preliminar del Hito 3

## Piloto interno de usabilidad

Vicente San Juan, integrante del equipo, probó las versiones 0.2.2 a 0.2.5 en un iPhone 16 Pro el 21 y 22 de noviembre de 2026. La tabla registra las observaciones de esas pruebas internas y la versión en que se aplicó cada cambio.

| Versión probada | Tarea y observación | Recomendación | Cambio implementado |
|---|---|---|---|
| 0.2.2 | Al responder en Quiz, dos colores dificultaban distinguir piezas vecinas. | Asignar un color distinto a cada superficie. | 0.2.3. Colores por pieza y selección en blanco antes de confirmar. |
| 0.2.3 | Al colocar en el suelo, observar el modelo obligaba a agacharse. | Ajustar altura y tamaño por estación. | 0.2.4. Controles de altura y tamaño durante la colocación y la edición. |
| 0.2.4 | Al elegir una estructura en Estudiar, el modelo podía girar automáticamente. | Conservar la orientación del modelo y permitir que la persona se mueva. | 0.2.5. Se resalta la pieza en su sitio. |
| 0.2.5 | Al salir de Quiz, el aviso aparecía sobre la cámara. | Llevar la confirmación al panel de modos. | 0.2.6. Confirmación integrada en el panel de Quiz. |

## Verificación técnica de la versión 0.2.6

Las compilaciones corregidas se instalaron en el iPhone de prueba. En la 0.2.6 se verificaron las reglas de catálogo, colocación, dimensiones, selección y puntaje. RealityKit cargó 15 superficies seleccionables entre hombro (4), codo (5) y carpo (6).

## Método del piloto con estudiantes

El protocolo contempla **tres sesiones de 12 minutos** con estudiantes de Veterinaria, con el mismo iPhone 16 Pro, entorno y moderador. Usa la versión **0.2.6, compilación 8**. Se reinicia la sesión de realidad aumentada para cada persona y se mantiene el mismo punto de colocación de Hombro, la misma mesa y una iluminación comparable.

Las tareas son anclar Hombro, explorar dos estructuras y responder cuatro consignas. Se registran aciertos, ayudas, dificultades táctiles y una sugerencia por estudiante. El orden de las consignas puede variar.

| Tiempo | Actividad | Registro |
|---|---|---|
| 00:00–01:00 | Introducción con el mismo guion. | Año o curso y familiaridad con RA. |
| 01:00–03:00 | Colocar y confirmar Hombro en el punto marcado. | Completó, completó con ayuda o quedó incompleta. Tiempo hasta confirmar. |
| 03:00–06:00 | Resaltar cavidad glenoidea y cabeza del húmero. Rodear el modelo. | Completitud y observación desde más de un ángulo. |
| 06:00–10:00 | Resolver las cuatro consignas del quiz. | Orden real, aciertos al primer intento confirmado y preguntas pendientes. Registrar dificultades táctiles por separado. |
| 10:00–12:00 | Entrevista con tres preguntas fijas. | Comentarios y una sugerencia prioritaria de cada persona. |

**Guion inicial.** «Te pediré tres tareas. Usa la aplicación como lo harías por tu cuenta. Si algo te confunde, dilo en voz alta». Ante una consulta, repetir la consigna antes de dar una pista de interfaz y contar las intervenciones.

**Preguntas de la entrevista.** ¿Cuándo te costó más saber qué hacer? ¿Qué te ayudó a reconocer o seleccionar una parte? ¿Qué cambiarías y por qué?

## Registro del piloto con estudiantes

**Versión evaluada.** 0.2.6, compilación 8, en iPhone 16 Pro.

**Resultados por participante.** Por incorporar en este registro.

**Datos de cada sesión.** Código (P1, P2 o P3), fecha, familiaridad con RA, tiempo de colocación, resultado de cada tarea, primera respuesta confirmada por consigna, preguntas pendientes, ayudas, dificultades táctiles, incidentes y sugerencia.

**Registro de cambios posteriores.** Código de participante, versión probada, observación, recomendación, decisión, versión corregida y resultado de la reprueba. El piloto evalúa usabilidad. Medir aprendizaje requiere contrastar el reconocimiento antes y después de estudiar.

El [registro del Hito 2](pruebas.md) corresponde a Palacio de Memoria.
