# Evaluación preliminar del Hito 3

## Piloto interno e iteraciones

Primeras iteraciones del prototipo y comprobación interna en iPhone 16 Pro.

| ASPECTO | VERSIÓN ANTERIOR | VERSIÓN ACTUAL |
|---|---|---|
| Carga de modelos | La primera versión permitía colocar un solo modelo en RA. | Hombro, codo y carpo cargan sin conexión. Se pueden anclar varios modelos a la vez. |
| Inspección 3D en Estudiar | En la cámara se veía un marcador fijo con el nombre del término. | Puedes girar el hueso con un dedo y ampliarlo con dos para examinar sus detalles. |
| Modo Estudiar | Se seguían marcadores y se leía la definición asociada a cada uno. | Al elegir una estructura, la app la resalta en el hueso y muestra una pista. |

## Resultados de la evaluación

### OBSERVACIÓN EN EL IPHONE

En Estudiar, la estructura elegida se resalta sobre el hueso.

Puedes rodear el modelo, girarlo con un dedo o ampliarlo con dos para observar sus detalles.

### VERIFICACIÓN TÉCNICA

RealityKit cargó los tres modelos incluidos en la app.

Se verificaron 15 superficies seleccionables entre hombro (4), codo (5) y carpo (6).

El piloto interno orientó mejoras de usabilidad.

## Método del piloto con estudiantes

### TRES SESIONES DE 12 MINUTOS

Mismo iPhone, entorno y moderador

Introducción 1 min, colocación 2 min, estudio 3 min, quiz 4 min y entrevista 2 min.

### TAREAS Y REGISTRO

Anclar Hombro, explorar dos estructuras y responder cuatro consignas.

Registrar aciertos, ayudas, dificultades táctiles y una sugerencia por estudiante.

## Registro del piloto con estudiantes

| QUÉ SE PROBÓ | QUÉ SE OBSERVÓ | QUÉ CAMBIÓ |
|---|---|---|
| Altura y tamaño<br>Versión 0.2.3 | El modelo quedaba demasiado bajo al usar el suelo. Había que agacharse. | 0.2.4. Ajuste de altura y tamaño por estación. |
| Piezas en Quiz<br>Versión 0.2.2 | Dos colores dejaban piezas adyacentes sin distinguir. | 0.2.3. Color por pieza y selección visible antes de confirmar. |
| Orientación en Estudiar<br>Versión 0.2.4 | Al elegir una estructura en Estudiar, el modelo a veces giraba solo. | 0.2.5. Resaltado en su sitio y orientación fija. |
