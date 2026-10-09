# 004 · Cómo se guardan los términos anclados (CU1)

- **Fecha:** 09-10-2026
- **Paso:** 3 · CU1 Anclar
- **Rol:** B · Lógica y datos (afecta a A y C)
- **Estado:** propuesta, se confirma en la revisión del PR

## Contexto

El flujo para anclar ya está definido en `005-flujo-anclar.md`: tocar superficie → completar el término → fijar. Falta decidir qué guarda la lógica y cómo se enteran la capa AR y la interfaz.

Ese documento pedía que el estado de la app guardara el término con su posición. La posición es un tipo de ARKit, y PalacioCore no puede conocerlo.

## Decisión

- **La lógica guarda el `UUID` del marcador, no la posición.** La posición se queda en la capa AR, que ya tiene sus marcadores indexados por `UUID`.
- **`Palace` (PalacioCore) es la fuente de verdad.** Guarda los términos anclados, en orden, y el marcador provisorio que espera su término (`pendingMarkerID`).
- **`AppState` expone las acciones:** `beginPlacement(markerID:)`, `confirmPlacement(name:definition:)`, `cancelPlacement()` y `removeTerm(_:)`.
- **La capa AR se ajusta al estado, sin recibir órdenes.** Un marcador debe existir solo si su `UUID` es el pendiente o pertenece a un término de `palace.terms`; su texto es el nombre de ese término.

Reglas de la lógica:

- Confirmar sin nombre o sin definición no guarda nada y deja el marcador pendiente.
- Tocar otra superficie con el formulario abierto reemplaza el marcador pendiente.
- `beginPlacement` solo tiene efecto en modo Anclar.

## Qué necesita cada rol

- **B (hecho en este paso):** `Palace` con tests y las acciones en `AppState`.
- **A (hecho en #17):** `onSurfaceTapped` entrega el `UUID` del marcador que crea. `ARContainerView` recibe el marcador pendiente y los nombres por marcador (`palace.namesByMarker`); en `updateUIView` quita los marcadores que no estén ahí y pone el nombre del término. Solo crea marcadores en modo Anclar.
- **C (hecho en #14):** `MainView` usa `AppState` en vez de los `@State` provisorios: `mode`, `isPlacingTerm`, el glosario (`appState.glossary` convertido a `TermDraft`), `confirmPlacement` en `onConfirm` y `cancelPlacement` en `onCancel` y al cambiar de modo.

## Consecuencias

- Toda la regla de anclar, cancelar y borrar se prueba con `swift test`, sin iPhone.
- La capa AR no recibe órdenes: si un marcador no aparece en el estado, lo quita en la siguiente actualización. Así cancelar, cambiar de modo y tocar otra superficie se resuelven igual.
- Todavía no hay interfaz para borrar un término ya anclado; la acción queda disponible para cuando se defina.
