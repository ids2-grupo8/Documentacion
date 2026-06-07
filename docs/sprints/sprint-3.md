# Sprint 3

**Período:** 13/05/2026 — 05/06/2026  
**Checkpoint cubierto:** CP3  
**Estado:** Completado

---

## Objetivo del sprint

Completar el ciclo post-compra del marketplace: seguimiento de órdenes, historiales de compras y ventas, administración operativa (órdenes y métricas), reseñas con reputación de vendedores y aplicación de cupones en checkout.

---

## Alcance del sprint

Este sprint se enfoca en:

- Seguimiento del estado de órdenes y flujo de fulfillment (comprador y vendedor).
- Historial de compras y de ventas en la app mobile.
- Reseñas de producto y vendedor, con reputación visible en perfil público.
- Cupones de descuento aplicables en checkout.
- Panel administrativo de órdenes y métricas del sistema.

Los flujos de catálogo, carrito y checkout inicial ya fueron documentados en `sprints/sprint-2.md`.

---

## Historias de usuario completadas

### Obligatorias

| # | Historia | Puntos |
|---|----------|:------:|
| 12 | Estado y seguimiento de orden | 5 |
| 13 | Historial de compras | 2 |
| 16 | Historial de ventas | 3 |
| 20 | Listar órdenes del sistema | 2 |
| 21 | Métricas del sistema | 5 |

**Total obligatorias (enunciado):** 17 puntos

### Optativas

| # | Historia | Puntos |
|---|----------|:------:|
| 31 | Calificar producto y vendedor | 5 |
| 32 | Reputación del vendedor en perfil público | 3 |
| 34 | Aplicar cupón en checkout | 3 |

**Total optativas (enunciado):** 11 puntos

---

## Seguimiento por historias completadas

### Obligatorias

**#12 Estado y seguimiento de orden**
  - Flujo de estados con historial de transiciones y timestamps; el comprador ve el estado actual y la evolución de su orden.
  - El vendedor avanza la orden (preparación → enviada) e ingresa opcionalmente un código de seguimiento; el comprador confirma la entrega.
  - Transiciones inválidas son rechazadas. Integración con Mercado Pago para confirmar o rechazar el pago; órdenes pendientes de pago expiran automáticamente.
  - App mobile: detalle de orden con timeline, código de seguimiento y acciones según rol. Tras el checkout, la app consulta el estado del pago hasta resolverlo.

**#13 Historial de compras**
  - Listado de órdenes del comprador ordenado por fecha descendente, con estado, total y fecha.
  - Detalle con ítems, precios, estado, historial de transiciones y código de seguimiento si aplica.
  - Filtro por estado en el listado. Un checkout con varios vendedores genera una orden por vendedor (ADR-0001).

**#16 Historial de ventas**
  - Listado de ventas del vendedor ordenado por fecha descendente, con filtro por estado.
  - Detalle con ítems vendidos, comprador, dirección de entrega, total parcial y estado actual.
  - El vendedor puede avanzar el estado de envío desde el detalle de la venta.

**#20 Listar órdenes del sistema**
  - Backoffice con listado paginado de órdenes (ID, comprador, fecha, estado, monto).
  - Búsqueda por ID de orden y filtro por estado. Detalle completo con comprador, vendedor, ítems e historial.
  - Solo lectura: el administrador no puede modificar el estado de las órdenes.

**#21 Métricas del sistema**
  - Panel de métricas en backoffice: usuarios registrados (totales y por período), órdenes por estado con evolución temporal, monto transaccionado y productos más vendidos.
  - Períodos predefinidos de 7, 30 y 90 días. Datos agregados desde user-service y checkout-service.

### Optativas

**#31 Calificar producto y vendedor**
  - El comprador puede calificar al vendedor y a cada producto recibido una vez que la orden está entregada; una calificación por orden.
  - Puntaje con comentario opcional. No se permite calificar órdenes que aún no fueron entregadas ni duplicar calificaciones.
  - **Alcance vs. enunciado:** la UI usa estrellas (1–5 con medias); el backend persiste una escala 1–10.

**#32 Reputación del vendedor en perfil público**
  - Perfil público del vendedor muestra puntaje promedio y cantidad de calificaciones, más el detalle de reseñas individuales.
  - Solo se consideran calificaciones de órdenes entregadas. Sin historial, el perfil lo indica explícitamente.

**#34 Aplicar cupón en checkout**
  - Campo de cupón en checkout con validación previa; descuento reflejado en el total antes de pagar.
  - Rechazo con mensaje claro si el cupón es inválido, vencido o ya fue usado. Un cupón por checkout; el descuento no supera el total.
  - Descuento repartido proporcionalmente cuando el carrito incluye productos de varios vendedores.
  - **Pendiente:** gestión de cupones en backoffice (la API admin existe, sin interfaz).

---

## Métricas del sprint

| Métrica | Valor |
|---------|------:|
| Historias de usuario (obligatorias) | 5 |
| Historias de usuario (optativas) | 3 |
| Puntos obligatorios (según enunciado) | 17 |
| Puntos optativos (según enunciado) | 11 |
| Servicios backend con cambios relevantes | 2 (checkout-service, user-service) |
| Clientes con cambios relevantes | 2 (mobile + backoffice) |

---

## Puntos acumulados (CP3)

| Sprint | Obl. | Opt. | Total |
|--------|-----:|-----:|------:|
| Sprint 1 | 22 | 7 | 29 |
| Sprint 2 | 24 | 7 | 31 |
| Sprint 3 | 17 | 11 | 28 |
| **Total** | **63** | **25** | **88** |
