# 001 · Proporción entre panel superior y cámara en iPhone

- **Fecha:** 08-10-2026
- **Paso:** 2 · Base de la app
- **Rol:** C · Interfaz
- **Estado:** propuesta, se confirma en la revisión del PR

## Contexto

El informe del Hito 1 (Fig. 2) definió la pantalla dividida en dos mitades: arriba las acciones y el contenido de cada modo, abajo siempre la cámara, para no perder de vista muebles u obstáculos al caminar. Ese wireframe se pensó para el iPad Pro, pero el prototipo se desarrolla para iPhone.

En un iPhone de 6,1" (852 pt de alto), el 50/50 deja la cámara en unos 414 pt. Como la imagen de la cámara (3:4) se ajusta al ancho y se recorta arriba y abajo, solo se ve cerca del 79 % del encuadre: cuesta apuntar a una superficie y quedan fuera marcadores cercanos al borde.

## Decisión

Panel superior **40 %** y cámara **60 %** del alto dentro del área segura. La cámara además se extiende bajo el borde inferior de la pantalla.

Se configura en una sola constante: `MainView.topPanelFraction`.

## Consecuencias

- La cámara sube a unos 489 pt y se ve cerca del 93 % del encuadre.
- El panel baja de unos 380 a 304 pt. Alcanza para el contenido de los tres modos, pero el formulario del Paso 3 tiene que ser compacto.
- Al escribir, el teclado se superpone a la cámara y el panel mantiene su tamaño.
- Se mantiene la idea del informe (cámara siempre visible abajo, acciones arriba). Se revisará con la prueba con usuarios del Paso 6.
