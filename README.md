# Palacio de Memoria en Realidad Aumentada para el Aprendizaje de Terminología Técnica

Proyecto del curso IDI3185, Realidad Extendida (UC, 2026-2)

## Equipo

- Benjamín Masson — benjamin.masson@uc.cl
- Joaquín Rubio — jrubic@uc.cl
- Vicente San Juan — sanjuan.vicente@uc.cl

## Descripción del proyecto

Los estudiantes de asignaturas con alta densidad de terminología técnica, como anatomía, farmacología o glosarios especializados de ingeniería, suelen estudiar con métodos lineales, como listas o tarjetas de memoria, que no aprovechan la memoria espacial. Este proyecto propone una aplicación de realidad aumentada para iPhone que implementa la técnica del *palacio de la memoria* (*method of loci*). El estudiante ancla términos técnicos como marcadores virtuales sobre su propio espacio físico y luego repasa y se autoevalúa recorriendo ese mismo espacio.

## Por qué XR

La asociación espacial es el núcleo de la técnica. El usuario necesita registrar objetos virtuales sobre posiciones reales específicas y mantener esa asociación estable mientras se mueve. Esto depende directamente de las capacidades de *tracking* y registro propias de la realidad aumentada y no se puede replicar con una app 2D convencional.

## Casos de uso

1. **CU1 · Anclar** — el usuario toca una superficie detectada por la cámara, coloca un marcador virtual y le asocia un término y su definición.
2. **CU2 · Estudio** — el usuario recorre el espacio y, al tocar un marcador, ve su definición.
3. **CU3 · Quiz** — los marcadores muestran "?"; el usuario intenta recordar la definición, toca para revelarla y marca si acertó o no. Al final ve los términos a repasar.

## Stack

- Swift 6, SwiftUI, ARKit y RealityKit (sin Unity ni motores de terceros)
- Plataforma objetivo: iPhone con iOS 17 o superior
- Tests con Swift Testing
- Lógica pura en el paquete SwiftPM `Packages/PalacioCore`, que solo depende de `Foundation` y compila en Windows, Linux y Mac

## Requisitos

- **App completa:** Mac con Xcode y un iPhone físico (el simulador no tiene cámara AR).
- **PalacioCore (lógica y tests):** cualquier sistema con Swift 6 (Windows, Linux o Mac).

## Tests de PalacioCore

```bash
cd Packages/PalacioCore
swift build
swift test
```

## Instalación

*Pendiente.*

## Uso

*Pendiente.*

## Estado actual

- [x] Hito 1 — Formulación del proyecto (entregado 8 de septiembre de 2026)
- [ ] Hito 2 — Prototipo lo-fi (13 de octubre de 2026)
- [ ] Hito 3 — Prototipo final (24 de noviembre de 2026)

## Estructura del repositorio

```text
PalacioMemoria/          → código de la app iOS (App, AR, Features, Shared, Resources)
Packages/PalacioCore/    → lógica pura + tests
docs/                    → arquitectura, registro de pruebas y decisiones
Build/                   → ejecutable para instalar en iPhone
informe/                 → informe (IEEE) de cada hito
.github/                 → plantillas de issues/PR y CI
CLAUDE.md                → guía de trabajo del repositorio
```

La arquitectura se describe en [docs/arquitectura.md](docs/arquitectura.md).

## Informe

El informe se versiona en `/informe` (fuente LaTeX y PDF compilado). A medida que el proyecto avanza entre hitos, se actualiza sobre la misma base en lugar de reescribirse desde cero, y cada entrega queda marcada como un punto identificable en el historial.
