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
  - Secciones de descubrimiento: **`Recientes`** (productos marcados como recientes en la sesión de listado), **`Para vos`** (solo si aplica) y **`Todos los productos`** (rejilla a dos columnas), con loading, pull-to-refresh y manejo de error en la carga principal del catálogo.
  - Para usuarios no autenticados se restringen acciones sensibles (agregar al carrito, publicar, abrir carrito), solicitando login.
  - **`Para vos`**: solo usuarios **autenticados**; la app usa `GET .../recommendations/context` y muestra la sección cuando hay ítems . No se muestra en invitados; si no hay señal útil, el catálogo cae a recomendaciones **globales** y esa hilera no se trata como “Para vos” personalizado. Con filtros o búsqueda activos en Home no se pide la sección (evita mezclar contextos).
  - **Criterio operativo actual (recomendados personalizados):** por ahora **solo** se utiliza la **visualización del detalle de producto**. La app registra cada vista autenticada con `POST /products/{id}/recent-detail-view` (identidad vía `X-User-Email`); `product-service` persiste en la colección `product_detail_views`, infiere categorías “pico” a partir de esos productos vistos y devuelve candidatos con stock excluyendo publicaciones propias . El listado global sigue como respaldo cuando no hay vistas de detalle registradas.

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

