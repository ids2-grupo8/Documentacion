# Sprint 2

**Período:** 20/04/2026 — 12/05/2026  
**Checkpoint cubierto:** CP2  
**Estado:** Completado 

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

  - Pantalla de inicio con secciones **Recientes**, **Para vos** (cuando aplica) y **Todos los productos** en rejilla de dos columnas.
  - Loading, pull-to-refresh y mensaje de error ante fallos de carga.
  - Usuarios no autenticados pueden explorar el catálogo; acciones como agregar al carrito o publicar solicitan login.

  **Sección “Para vos”**

  - Visible solo para usuarios autenticados, cuando el backend indica personalización (`is_personalized`) y hay ítems.
  - No aparece con filtros o búsqueda activos en Home.
  - Sin señal de personalización, la sección no se muestra; el catálogo general sigue disponible en **Todos los productos**.

  **Recomendaciones (CA-4 de Home):** criterios, señales y decisiones de diseño en [ADR-0007](../adr/adr-0007-recomendaciones-en-home.md).

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

**#5 Checkout e inicio de pago** — **Implementada (Mercado Pago)**
  - UI de checkout con validación de dirección, resumen de orden y medio de pago **Mercado Pago** (flujo mobile: preferencia / `init_point` vía `checkout-service`, apertura en navegador in-app, deep links a éxito / pendiente / fallo).
  - **`checkout-service`**: SDK de Mercado Pago, creación de preferencia y **webhook** `POST /api/v1/webhook/mercadopago` para actualizar órdenes; la app hace **polling** del estado de orden hasta salir de `payment pending`.
  - **Pendiente / variable por entorno:** credenciales y URLs de notificación válidas en cada despliegue, y pruebas E2E formales contra el sandbox productivo del corrector.

**#6 Gestión del carrito** 
  - Vista completa de carrito con modificar cantidades, eliminar ítems y vaciar carrito.
  - Cálculo de subtotal/total y control de ítems no disponibles antes de checkout.
  - Mensajería de stock bajo/no disponible para prevenir compras inválidas.

### Optativas

**#22 Ordenamiento de resultados** 
  - Ordenamiento por precio ascendente/descendente y más recientes.
  - Opción de orden predeterminado para mantener experiencia consistente.

**#24 Filtros avanzados de búsqueda** 
  - Filtros por categoría y rango de precio en Home (sincronizados con el fetch del catálogo donde corresponde).
  - Aplicación y limpieza de filtros con feedback visual; rango de precio mínimo mayor que máximo tratado como **sin resultados** (validación en cliente al armar la petición).

**#25 Registro con PIN** 
  - **Mobile:** pantalla de alta/cambio de PIN (`app/profile/pin.tsx`) y flujo de login por PIN (`app/(auth)/pin-login.tsx`), con PIN de 6 dígitos y `device_id` para amarrar el acceso al dispositivo.
  - **API (user-service):** rutas versionadas bajo **`/api/v1/auth/pin/...`** (p. ej. enroll, login, cuentas por dispositivo, estado / actualización); persistencia en base relacional y límites de intentos.
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

