# Palacio de Memoria en Realidad Aumentada

Proyecto del curso IDI3185, Realidad Extendida (UC, 2026-2).

## Equipo

- Benjamín Masson — benjamin.masson@uc.cl
- Joaquín Rubio — jrubic@uc.cl
- Vicente San Juan — sanjuan.vicente@uc.cl

## Descripción

Palacio de Memoria es una aplicación de realidad aumentada para iPhone que usa la técnica del *palacio de la memoria*. El estudiante deja términos técnicos en lugares reales de una sala, los recorre para estudiarlos y luego se autoevalúa recordando qué dejó en cada lugar.

La parte espacial es central: la cámara permite asociar cada término con una posición física y volver a encontrarlo al desplazarse por el espacio.

## Funciones

### Anclar

En modo Anclar, el usuario toca una superficie detectada por la cámara. La app crea un marcador provisorio, abre un formulario y permite escribir un término y su definición o elegirlos desde el glosario. Al confirmar, el nombre queda sobre el marcador durante la sesión.

### Estudio

El modo Estudio propone un término y muestra su posición dentro del recorrido. El usuario debe recordar dónde lo dejó y tocar el marcador correspondiente para ver la definición. Después puede avanzar al siguiente término o saltarlo.

### Quiz

En Quiz, los marcadores pendientes muestran «?». Al tocar uno, la app pregunta qué término se dejó ahí. La respuesta se revela solo después de pulsar el botón correspondiente y luego el usuario marca si acertó o no. Al finalizar, se muestra el puntaje y los términos que conviene repasar. El quiz se puede reiniciar.

## Tecnologías

- Swift 6 y SwiftUI
- ARKit y RealityKit
- Swift Testing para la lógica de `PalacioCore`
- Paquete local `Packages/PalacioCore`, sin dependencias de ARKit ni SwiftUI

## Requisitos

- Mac con una versión de Xcode compatible con el SDK de iOS 27.
- iPhone compatible con ARKit y con iOS 27 o posterior. El proyecto tiene iOS 27 como versión mínima.
- Una cuenta de Apple para firmar la app durante el desarrollo.

`PalacioCore` declara iOS 17 como mínimo porque contiene solo lógica reutilizable; esto no cambia el requisito de iOS 27 de la aplicación.

La versión actual se probó en un **iPhone 16 Pro con iOS 27 y Modo desarrollador activado**. El simulador no sirve para probar la cámara ni el seguimiento espacial.

## Instalación y ejecución

1. Abre `PalacioMemoria.xcodeproj` en Xcode.
2. Conecta el iPhone y selecciónalo como destino de ejecución.
3. En **Signing & Capabilities**, selecciona tu cuenta en el campo **Team**.
4. Activa el Modo desarrollador en el iPhone, si todavía no está activo.
5. Ejecuta la app con **Cmd + R** y acepta el permiso de cámara en el primer inicio.

La carpeta `Build/` contiene los artefactos preparados para la entrega. Para instalar en otro iPhone, se debe firmar la app para ese dispositivo desde Xcode o volver a firmar el paquete con una cuenta compatible.

## Tests de PalacioCore

```bash
cd Packages/PalacioCore
swift build
swift test
```

En Windows con Swift 6.4, si aparece el error `'stdlib.h' file not found`, agrega `--build-system native` a ambos comandos.

## Estado actual

El prototipo lo-fi implementa los tres flujos principales: anclar términos, repasarlos en un recorrido y responder un quiz. Se probaron seguidos en el iPhone, incluyendo la selección de marcadores, los cambios de color, las etiquetas y el resumen final.

Por ahora los términos y marcadores solo existen durante la sesión actual. La persistencia entre sesiones, los modelos 3D por término y el seguimiento del progreso son mejoras previstas para el siguiente hito.

## Estructura del repositorio

```text
PalacioMemoria/          → código de la app iOS
Packages/PalacioCore/    → lógica y pruebas automatizadas
docs/                    → arquitectura, decisiones y pruebas
Build/                   → artefactos de la entrega
informe/                 → informe del proyecto
```

La arquitectura se describe en [docs/arquitectura.md](docs/arquitectura.md).
