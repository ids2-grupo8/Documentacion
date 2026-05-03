# Sprint 2

**Período:** 20/04/2026 — 12/05/2026  
**Checkpoint cubierto:** CP2  
**Estado:** En proceso (actualizado)

---

## Objetivo del sprint

Completar los flujos core de compra del marketplace para alcanzar el objetivo de CP2: CRUDs principales al 100% y al menos 70% de historias obligatorias implementadas.

---

## Alcance del sprint

Este sprint se enfoca en:

- Home y catálogo de productos para compradores.
- Carrito de compras y su gestión.
- Inicio del flujo de checkout/pago.
- Moderación de publicaciones en backoffice.
- Mejoras de descubrimiento en catálogo (optativas).

Las bases de infraestructura, autenticación y arquitectura general ya fueron documentadas en `sprints/sprint-1.md`.

---

## Historias de usuario planificadas

### Obligatorias

| # | Historia | Puntos |
|---|----------|:------:|
| 1 | Home | 3 |
| 2 | Listado y búsqueda de productos | 6 |
| 3 | Agregar producto al carrito | 5 |
| 4 | Listar y moderar productos | 5 |
| 5 | Checkout e inicio de pago | 13 |
| 6 | Gestión del carrito | 6 |

**Total obligatorias (enunciado):** 38 puntos

### Optativas

| # | Historia | Puntos |
|---|----------|:------:|
| 22 | Ordenamiento de resultados | 2 |
| 24 | Filtros avanzados de búsqueda | 3 |
| 25 | Registro con PIN | 2 |

**Total optativas (enunciado):** 7 puntos

---

## Seguimiento por historias planificadas

### Obligatorias

**#1 Home**
  - Se incorporaron secciones de descubrimiento (`Para vos` y `Todos los productos`) con manejo de loading/error.
  - Para usuarios no autenticados se restringen acciones sensibles (agregar al carrito/publicar/abrir carrito), solicitando login.
  - La sección `Para vos` depende del endpoint de recomendaciones y se oculta cuando no hay datos.

**#2 Listado y búsqueda de productos** 
  - Búsqueda por texto con debounce.
  - Integración de filtros y ordenamiento sobre el fetch del catálogo.
  - Soporte de estados vacíos y retry ante fallos de red.

**#3 Agregar producto al carrito** 
  - Alta rápida desde Home y flujo de agregado desde el catálogo.
  - Validaciones de stock para evitar superar cantidad disponible.
  - Persistencia de carrito en cliente y protección para usuarios no autenticados.

**#4 Listar y moderar productos** 
  - Backoffice con listado de productos para administración.
  - Acción de moderación para bloquear/desbloquear publicaciones.
  - Sincronización con product-service mediante endpoints administrativos.

**#5 Checkout e inicio de pago** — **Parcialmente implementada**
  - UI de checkout con validación de dirección, resumen de orden y selección de medio de pago.
  - Flujo de confirmación y pantalla de éxito implementados en mobile.
  - Integración final con gateway real/sandbox y validaciones E2E de pago aún pendientes.

**#6 Gestión del carrito** 
  - Vista completa de carrito con modificar cantidades, eliminar ítems y vaciar carrito.
  - Cálculo de subtotal/total y control de ítems no disponibles antes de checkout.
  - Mensajería de stock bajo/no disponible para prevenir compras inválidas.

### Optativas

**#22 Ordenamiento de resultados** 
  - Ordenamiento por precio ascendente/descendente y más recientes.
  - Opción de orden predeterminado para mantener experiencia consistente.

**#24 Filtros avanzados de búsqueda** — **Implementada**
  - Filtros por categoría y rango de precio en Home.
  - Aplicación y limpieza de filtros con feedback visual.

**#25 Registro con PIN** 
  - **Mobile:** pantalla de alta/cambio de PIN (`app/profile/pin.tsx`) y flujo de login por PIN (`app/(auth)/pin-login.tsx`), con PIN de 6 dígitos y `device_id` para amarrar el acceso al dispositivo.
  - **API (user-service):** endpoints bajo `/auth/pin/*` (enroll, login, cuentas por dispositivo, estado); persistencia en base relacional y límites de intentos 
  - **Alcance vs. enunciado:** el registro inicial sigue siendo email/contraseña; el PIN se configura **después** para acceso rápido desde el dispositivo (historia optativa de PIN).


---

## Métricas del sprint (objetivo)

| Métrica | Valor |
|---------|------:|
| Historias de usuario (obligatorias) | 6 |
| Historias de usuario (optativas) | 3 |
| Puntos obligatorios (según enunciado) | 38 |
| Puntos optativos (según enunciado) | 7 |

---

