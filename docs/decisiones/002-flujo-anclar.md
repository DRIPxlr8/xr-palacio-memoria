# 002 · Flujo para anclar un término (CU1)

- **Fecha:** 08-10-2026
- **Paso:** 3 · CU1 Anclar
- **Rol:** C · Interfaz (afecta a A y B)
- **Estado:** propuesta, se confirma en la revisión del PR

## Contexto

La guía pide un formulario para escribir (o elegir del glosario) el término y su definición **antes de fijarlo**. Hoy la capa AR crea el marcador apenas se toca una superficie, siempre con el texto «Concepto», y no le avisa a la app qué marcador creó.

## Decisión

El orden es: **tocar superficie → completar el término → fijar**.

1. En modo Anclar, el usuario toca una superficie. La capa AR muestra un **marcador provisorio** en ese punto y avisa la posición (`onSurfaceTapped`).
2. El panel superior muestra el formulario: término, definición y botón «Glosario» para elegir uno de la lista.
3. **Fijar término** (activo solo con término y definición): el estado de la app guarda el término con su posición y la capa AR deja el marcador fijo con el nombre del término.
4. **Cancelar**, o cambiar de modo: se descarta el término y la capa AR quita el marcador provisorio.

El teclado se superpone a la cámara (no achica el panel), y el formulario no lo abre solo, para que el usuario siga viendo el punto elegido.

## Qué necesita cada rol

- **C (hecho en este paso):** `AnchorForm` y `AnchorPanel`, que reciben `isPlacingTerm`, el glosario y las acciones `onConfirm` / `onCancel`. Mientras no exista el estado de la app, `MainView` los conecta con valores provisorios.
- **B:** en el estado de la app, la posición pendiente, el glosario de prueba y las acciones para confirmar (guardar término + posición) y cancelar.
- **A:** marcador provisorio al tocar en modo Anclar; al confirmar, fijarlo con el nombre del término; al cancelar, quitarlo. Además, que `updateUIView` actualice `context.coordinator.parent = self` para que los avisos usen siempre el estado vigente.
