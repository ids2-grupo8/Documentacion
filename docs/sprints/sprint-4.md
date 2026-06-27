# Sprint 4

**Período:** 06/06/2026 — 29/06/2026  
**Checkpoint cubierto:** Entrega final  
**Estado:** Completado

---

## Objetivo del sprint

Cerrar el sistema de cara a la entrega final: incorporar notificaciones push para mantener informados a compradores y vendedores ante cambios relevantes, y endurecer el flujo crítico de compra mediante pruebas de carga y estrés con su correspondiente conjunto de optimizaciones de resiliencia y rendimiento.

---

## Alcance del sprint

Este sprint se enfoca en:

- Notificaciones push hacia la app mobile (Expo) y la web (Web Push) ante cambios de estado de orden, nuevas ventas y alertas de stock.
- Deep link desde la notificación al detalle de la orden correspondiente.
- Pruebas de carga y estrés del `checkout-service` con k6, y las optimizaciones aplicadas a partir de los resultados.
---

## Historias de usuario completadas

### Optativas

| # | Historia | Puntos |
|---|----------|:------:|
| 37 | Notificación de cambio de estado de orden | 5 |
| 38 | Notificación de stock bajo al vendedor | 2 |

**Total optativas (enunciado):** 7 puntos

---

## Seguimiento por historias completadas

### Optativas

Ambas historias se apoyan en un nuevo microservicio **`notification-service`** (Go) que consume eventos de RabbitMQ y emite notificaciones push por dos canales: **Expo Push** para la app mobile y **Web Push** para la web. Los tokens de dispositivo y las suscripciones se persisten en MongoDB.

**#37 Notificación de cambio de estado de orden**
  - El servicio consume el evento `order.status_changed` del `checkout-service` y envía al comprador una notificación push con el nuevo estado y el identificador de la orden (CA-1).
  - La notificación aparece en el sistema operativo cuando la app no está en primer plano (CA-2).
  - El payload incluye `order_id`; al tocar la notificación, la app abre directamente el detalle de la orden vía deep link, y cuenta con una pestaña de notificaciones que navega a `/orders/:id` (CA-3).
  - Cada estado se traduce a un copy orientado al comprador (pago confirmado, en preparación, enviado, entregado, etc.).

**#38 Notificación de stock bajo al vendedor**
  - El servicio consume eventos de cambio de stock y notifica al vendedor cuando un producto cae por debajo del umbral mínimo (5 unidades o el configurado), indicando producto y stock actual (CA-1).
  - Control de no duplicación: no se reenvía la alerta de stock bajo mientras el producto siga bajo; se vuelve a habilitar tras reponer stock y volver a bajar (CA-2).
  - Alerta específica de **stock agotado** (`out_of_stock`) cuando el stock llega a cero (CA-3).
  - El servicio también contempla una notificación de **nueva venta** (`new_sale`) al vendedor.

**Nota técnica:** la entrega usa **Expo Push** para mobile (que se apoya en **FCM** para la entrega a Android, según pide el enunciado) y **Web Push** para la web.

---

## Hardening: pruebas de carga y optimizaciones

Además de las historias, el sprint incluyó trabajo de ingeniería sobre el flujo crítico de compra (no asociado a una historia del enunciado):

- **Pruebas de carga y estrés con k6** sobre `checkout-service`, el cuello del sistema: cada compra atraviesa cuatro de sus endpoints y coordina llamadas a `product-service`, `user-service`, PostgreSQL, RabbitMQ y Mercado Pago.
  - *Load test*: 20 VUs, 3m30s de carga sostenida — `http_req_failed` 0.00%.
  - *Stress test*: 150 VUs, 4m, para encontrar el punto de quiebre.
- **Optimizaciones aplicadas** a partir de los resultados: capa de resiliencia HTTP (retry + circuit breaker, ver [ADR-0005](../adr/adr-0005-resiliencia-http-retry-y-circuit-breaker.md)), cliente Mercado Pago async, pool de conexiones PostgreSQL ampliado, cache LRU+TTL de datos de `product-service` y modo mock de Mercado Pago para load testing.

Detalle completo y números antes/después en [Pruebas de carga](../pruebas-de-carga/index.md) y [Optimizaciones aplicadas](../pruebas-de-carga/optimizaciones.md).

---

## Métricas del sprint

| Métrica | Valor |
|---------|------:|
| Historias de usuario (obligatorias) | 0 |
| Historias de usuario (optativas) | 2 |
| Puntos obligatorios (según enunciado) | 0 |
| Puntos optativos (según enunciado) | 7 |
| Servicios backend con cambios relevantes | 2 (notification-service nuevo, checkout-service) |
| Clientes con cambios relevantes | 2 (mobile + web) |

---

## Puntos acumulados (Entrega final)

| Sprint | Obl. | Opt. | Total |
|--------|-----:|-----:|------:|
| Sprint 1 | 22 | 7 | 29 |
| Sprint 2 | 24 | 7 | 31 |
| Sprint 3 | 17 | 11 | 28 |
| Sprint 4 | 0 | 7 | 7 |
| **Total** | **63** | **32** | **95** |
