# Pruebas preliminares

Las pruebas de esta versión se hicieron con la build actual en un **iPhone 16 Pro con iOS 27**, usando Modo desarrollador y la instalación desde Xcode.

## Pruebas realizadas

| Prueba | Qué se hizo | Resultado |
|---|---|---|
| Inicio de la aplicación | Se instaló la app, se aceptó el permiso de cámara y se esperó la detección de una superficie. | La cámara y la sesión de realidad aumentada iniciaron correctamente. |
| Anclar | Se tocaron distintas superficies, se ingresaron términos y definiciones, y se fijaron varios marcadores. | Los marcadores quedaron en el lugar elegido durante la sesión y mostraron el nombre del término. También se comprobó que cancelar elimina el marcador provisorio. |
| Estudio | Con varios términos anclados, se siguió el recorrido, se tocaron marcadores y se avanzó al siguiente término. | El panel indicó qué término buscar, mostró la definición del marcador tocado y permitió continuar el recorrido. |
| Quiz | Se inició un quiz con los mismos marcadores, se revelaron respuestas, se marcaron aciertos y errores, y se reinició el quiz. | Los marcadores pendientes mostraron «?», cambiaron de color al responder y el resumen mostró el puntaje y los términos para repasar. |

## Pruebas con usuarios

También se hicieron pruebas informales con dos estudiantes externos, usando el mismo iPhone y la misma build.

### Participante 1 — estudiante de Ingeniería

Se le pidió anclar tres conceptos de redes y repasarlos en Estudio. Completó el flujo sin ayuda, pero al volver a un concepto intentó tocar el texto flotante en lugar de la esfera.

Para evitar que ese gesto se interpretara como un toque vacío, se amplió el área táctil de la esfera y se añadió colisión a la etiqueta de texto. Después del ajuste, ambos puntos permiten seleccionar el marcador.

### Participante 2 — estudiante de Veterinaria

Se le pidió resolver un quiz con marcadores ya ubicados. Entendió de inmediato el uso de «?» y los botones de autoevaluación. Al moverse alrededor de la mesa, comentó que necesitaba poder leer los nombres desde distintos ángulos y distinguir rápido los términos fallados.

Como respuesta, las etiquetas se orientan hacia la cámara y los colores del quiz quedaron definidos así: azul para pendiente, amarillo para la pregunta abierta, verde para un acierto y rojo para un error.

## Dificultades encontradas

- Las etiquetas 3D podían quedar de lado o invertidas al rodear un marcador. Se corrigió su orientación para que miren a la cámara y el texto se lea de izquierda a derecha.
- El área de toque de una esfera pequeña era fácil de perder. Se aumentó su zona de colisión y se hizo seleccionable la etiqueta.
- Los marcadores no se guardan entre sesiones. Es una limitación conocida del prototipo; al cerrar la app se debe crear el palacio nuevamente.

## Pruebas automáticas

La lógica que no depende de ARKit está en `Packages/PalacioCore`. La suite de Swift Testing cubre el modelo de término, el glosario, el anclaje, el recorrido de Estudio y las reglas del Quiz, incluyendo la revelación obligatoria, el puntaje y los términos a repasar.
