# Arquitectura

La aplicación separa la cámara, la interfaz y la lógica de aprendizaje. Así, las vistas no manipulan directamente los objetos de realidad aumentada y las reglas del palacio se pueden probar sin un iPhone.

```text
Cámara y marcadores AR  <──>  Estado de la app  <──>  Interfaz SwiftUI
                                   │
                                   ▼
                            PalacioCore
```

- **AR** (`PalacioMemoria/AR/`): inicia la sesión de ARKit, detecta superficies, crea marcadores, recibe toques y actualiza etiquetas y colores.
- **Interfaz** (`PalacioMemoria/Features/`, `PalacioMemoria/Shared/`): contiene los paneles de Anclar, Estudio y Quiz, además del selector de modo y los formularios.
- **Estado de la app** (`PalacioMemoria/App/`): `AppState` conecta la cámara con la interfaz. Mantiene el modo actual, el palacio, el recorrido de estudio y el estado del quiz.
- **Lógica** (`Packages/PalacioCore/`): define los términos, el palacio, el recorrido de estudio y las reglas del quiz. No conoce ni depende de la cámara o de las vistas.

## Flujo de datos

1. La capa AR avisa cuando el usuario toca una superficie, un marcador o un espacio vacío.
2. `AppState` actualiza el palacio, el recorrido o el quiz según el modo actual.
3. SwiftUI vuelve a mostrar el panel correspondiente y la capa AR recibe los nombres y estilos actualizados de los marcadores.

En modo Anclar se crea un marcador provisorio y se confirma o descarta desde el formulario. En Estudio se muestra el término que corresponde buscar y se abre la definición del marcador tocado. En Quiz, los marcadores pendientes muestran «?», se revela la respuesta y se registra el resultado.

## PalacioCore

`PalacioCore` solo importa `Foundation` y sus tests usan `Testing`. Por eso puede compilarse y probarse sin ARKit, RealityKit o SwiftUI:

```bash
cd Packages/PalacioCore
swift build
swift test
```

El paquete declara iOS 17 como mínimo porque su lógica no usa APIs posteriores. La aplicación completa tiene iOS 27 como destino mínimo, que es el requisito que aplica al instalarla en un iPhone.

Las decisiones de diseño se registran en [`decisiones/`](decisiones/).
