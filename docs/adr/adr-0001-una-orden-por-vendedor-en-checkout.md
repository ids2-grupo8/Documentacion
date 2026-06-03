# ADR-0001: Una orden por vendedor en el checkout

## Estado

Aceptada

**Fecha:** 2026-06-02

## Contexto

Bazaar es un marketplace multi-vendedor: un mismo carrito puede contener productos de distintos sellers. Al cerrar la compra, el sistema debe decidir cómo se modelan las entidades `Order` resultantes. Existen dos alternativas razonables:

1. **Orden única consolidada** — un solo registro `Order` que agrupa todos los items del carrito, sin importar el vendedor.
2. **Una orden por vendedor** — el carrito se agrupa por `seller_email` y se crea un registro `Order` por cada vendedor distinto, compartiendo `idempotency_key` y un único pago en MercadoPago.

Fuerzas en juego:

- Cada vendedor gestiona sus propias ventas: ve, procesa, despacha y cobra de forma independiente. Necesita un objeto de negocio que represente "su parte" de la transacción.
- El estado de la orden (`PAYMENT_PENDING → CONFIRMED → PROCESSING → SHIPPED → DELIVERED`) avanza a distinto ritmo según el vendedor; un único estado consolidado obligaría a esperar al más lento o a inventar sub-estados.
- Las autorizaciones del backend se hacen contra `orders.seller_email` (endpoints `/process`, `/ship`) y `orders.buyer_email` (detalle); un único registro mezclaría dueños y complicaría la verificación de permisos.
- MercadoPago acepta una sola preferencia de pago con múltiples ítems, así que el cobro se puede mantener unificado independientemente del modelo de datos.
- Para el comprador, "Mis compras" se muestra como una lista — agrupar visualmente varias órdenes del mismo checkout es trivial en la UI; separarlas en BD no rompe la UX.

## Decisión

Adoptamos **una orden por vendedor**. El servicio de checkout agrupa los items del carrito por `seller_email` y crea un registro `Order` por cada vendedor distinto. Todas las órdenes generadas en el mismo checkout comparten la misma `idempotency_key` y se referencian juntas en el `external_reference` de la preferencia de MercadoPago, de modo que el webhook de pago confirme o rechace el conjunto en una sola operación.

## Consecuencias

**Positivas**

- Cada vendedor opera su propia orden de forma independiente: avanza el estado, marca despachada y consulta detalle sin coordinarse con otros vendedores.
- La autorización es directa: cada endpoint compara `X-User-Email` contra el `seller_email` o `buyer_email` del registro `Order`, sin lógica adicional para órdenes mixtas.
- La máquina de estados [State Pattern del checkout-service](../servicios/checkout-service.md) se mantiene simple — un único estado por entidad, sin sub-estados por vendedor.
- "Mis ventas" del backoffice/mobile filtra por `seller_email == X-User-Email` y devuelve sólo lo que el vendedor debe atender.

**Negativas**

- El webhook de MercadoPago debe iterar sobre la lista de `order_ids` extraída del `external_reference` para confirmar/rechazar todas a la vez; un único registro hubiera requerido una sola actualización.
- La `idempotency_key` deja de ser PK natural de `Order` (se vuelve compartida) — el unique constraint se aplica a (`idempotency_key`, `seller_email`).

**Neutras**

- El cobro al comprador sigue siendo único: una sola preferencia de MercadoPago, una sola transacción visible para el usuario.
