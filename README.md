# Palacio de Memoria en Realidad Aumentada para el Aprendizaje de Terminología Técnica

Proyecto del curso IDI3185, Realidad Extendida (UC, 2026-1)

## Equipo

- Benjamín Masson — benja.masson@gmail.com
- Joaquín Rubio — jrubic@uc.cl
- Vicente San Juan — sanjuan.vicente@uc.cl

## Descripción del proyecto

Los estudiantes de asignaturas con alta densidad de terminología técnica, como anatomía, farmacología o glosarios especializados de ingeniería, suelen estudiar con métodos lineales, como listas o tarjetas de memoria, que no aprovechan la memoria espacial. Este proyecto propone una aplicación de realidad aumentada que implementa la técnica del *palacio de la memoria* (*method of loci*). El estudiante ancla términos técnicos como objetos virtuales sobre su propio espacio físico y luego repasa y se autoevalúa recorriendo ese mismo espacio.

## Por qué XR

La asociación espacial es el núcleo de la técnica. El usuario necesita registrar objetos virtuales sobre posiciones reales específicas y mantener esa asociación estable mientras se mueve. Esto depende directamente de las capacidades de *tracking* y registro propias de la realidad aumentada y no se puede replicar con una app 2D convencional.

## Casos de uso

1. **Anclar términos nuevos** — el usuario coloca objetos virtuales sobre superficies reales y asocia cada uno a un término y su definición.
2. **Repasar en modo estudio** — el usuario recorre el espacio y consulta las definiciones ya ancladas.
3. **Autoevaluarse en modo quiz** — el usuario recorre el espacio sin ver las etiquetas, intenta recordar la información y confirma tocando el objeto.

## Tecnologías

- Unity + AR Foundation, con plugin ARKit
- Dispositivo objetivo: iPad Pro 11" del laboratorio DILAB

## Estado actual

- [x] Hito 1 — Formulación del proyecto (entregado 8 de septiembre de 2026)
- [ ] Hito 2 — Prototipo lo-fi (13 de octubre de 2026)
- [ ] Hito 3 — Prototipo final (24 de noviembre de 2026)

## Control de versiones

El informe se versiona en `/informe` a través del repositorio Git del equipo. A medida que el proyecto avanza entre hitos, el informe se actualiza sobre la misma base en lugar de reescribirse desde cero. Cada entrega queda marcada como un punto identificable en el historial, de modo que se pueda revisar cómo evolucionó el documento de un hito al siguiente.

## Estructura del repositorio

```text
/informe       → informe LaTeX (IEEE) de cada hito
/prototipo     → proyecto Unity (a partir del Hito 2)
README.md      → este archivo
```

## Informe

El informe se encuentra en `/informe` (fuente LaTeX y PDF compilado).