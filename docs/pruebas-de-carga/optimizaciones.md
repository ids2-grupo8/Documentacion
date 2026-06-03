# Optimizaciones aplicadas

Las pruebas de k6 sirvieron como **herramienta diagnóstica**: cada iteración expuso un cuello de botella, lo arreglamos, medimos de nuevo. Esta página resume las cinco rondas, con números antes/después de cada una.

## Línea base

Primera corrida del suite contra el sistema sin tocar. Resultado:

```
Load test (20 VUs)
  http_req_duration p95 = 5604 ms
  cart_add success      = 99%
  Throughput            = 4.45 req/s

Stress test (150 VUs)
  http_req_duration p95 = 30470 ms
  cart_add success      = 84%
  http_req_failed       = 10.75%
  Throughput            = 7.16 req/s
```

El sistema **funciona** pero **no escala**. Latencias inaceptables con apenas 20 VUs, errores cascada bajo 150 VUs.

---

## 1. Capa de resiliencia HTTP (retry + circuit breaker)

**Diagnóstico:** los clientes HTTP en `checkout-service` no tenían retry ni circuit breaker. Un transitorio puntual de `product-service` se traducía en degradación, y un servicio caído saturaba los workers con timeouts repetidos.

**Cambio:**

- Nuevo módulo [`app/clients/resilience.py`](https://github.com/ids2-grupo8/checkout-service/blob/development/app/clients/resilience.py) con:
    - Retry exponencial con `tenacity`: 3 intentos, backoff 0.2 s → 2 s. Sólo errores transitorios (timeouts, 5xx, 429).
    - Circuit breaker async in-house: abre tras 5 fallos consecutivos, reset_timeout 30 s, half-open con trial.
    - Una instancia de breaker por upstream (`product_service_breaker`, `user_service_breaker`).
- Los clientes `ProductServiceClient` y `UserServiceClient` envuelven cada call con `call_with_resilience(breaker, fn)`.
- Contrato externo se mantiene **fail-soft**: ante error definitivo o circuito abierto, los clientes devuelven `None`/`[]` y los endpoints siguen respondiendo con datos parciales.

Decisión completa en [ADR-0005](../adr/adr-0005-resiliencia-http-retry-y-circuit-breaker.md).

**Impacto:** la capa de resiliencia no se mide directamente en performance — su valor es en **resiliencia operativa**. Habilitó el resto de las optimizaciones sin riesgo de cascadas durante la experimentación.

---

## 2. Cliente MercadoPago async

**Diagnóstico:** el SDK oficial de MercadoPago es síncrono (basado en `requests`). Cada `mp.preference().create(...)` bloqueaba el event loop de FastAPI durante 0.6 – 2 s, impidiendo que el worker atendiera otras requests en paralelo.

**Cambio:**

- Eliminado `import mercadopago` y el global `mp = mercadopago.SDK(...)`.
- Nuevo cliente async en [`app/clients/mercadopago.py`](https://github.com/ids2-grupo8/checkout-service/blob/development/app/clients/mercadopago.py): `AsyncMercadoPagoClient` con `httpx.AsyncClient` compartido (`max_connections=500`, `max_keepalive=200`).
- Métodos `create_preference()` y `get_payment()` ahora son `async` y no bloquean el event loop.
- Cliente cerrado en shutdown de FastAPI.

**Impacto solo:** mejora moderada en cifras (era un cambio pre-requisito de las siguientes optimizaciones, su valor se ve combinado con #3 y #4).

---

## 3. Pool de conexiones PostgreSQL ampliado

**Diagnóstico:** `asyncpg` con `pool_size=20, max_overflow=10` (30 conexiones máximo). Bajo 20 VUs concurrentes con cada checkout abriendo 2-3 conexiones (cart + order + estado), el pool se saturaba.

**Cambio:**

- Configuración por env: `DB_POOL_SIZE=40`, `DB_MAX_OVERFLOW=60` → **100 conexiones totales**.
- [`app/db/async_session.py`](https://github.com/ids2-grupo8/checkout-service/blob/development/app/db/async_session.py) lee los valores de settings.

**Impacto combinado (#2 + #3):**

```
Load test
  p95           : 5604 → 841 ms    (6.7× más rápido)
  Throughput    : 4.45 → 12.5 req/s  (2.8×)

Stress test
  p95           : 30470 → 7398 ms  (4.1×)
  Throughput    : 7.16 → 32 req/s  (4.5×)
  http_req_failed: 10.75% → 0.47%  (22× mejor)
```

El sistema pasó de "se traba con 20 usuarios" a "procesa 150 con menos de 1% de fallas".

---

## 4. Cache LRU+TTL de datos de product-service

**Diagnóstico:** `cart_get` quedaba como el endpoint más lento por mucho (p95 = 939 ms en load, 10.5 s en stress). El `min` de 669 ms reveló que **incluso la mejor request** pagaba un round-trip HTTP a `product-service` para enriquecer cada carrito con `name`, `price`, `image_urls`, `status`.

**Cambio:**

- Cache `cachetools.TTLCache` en [`app/clients/product_service.py`](https://github.com/ids2-grupo8/checkout-service/blob/development/app/clients/product_service.py), indexado por `product_id`.
- `get_product`: lookup → si miss, fetch + store. Siempre devuelve dict plano.
- `get_products`: split en cached/missing → batch sólo de los missing → fallback per-id si batch devuelve incompletos.
- TTL configurable (`PRODUCT_CACHE_TTL_SECONDS=60`), tamaño máximo (`PRODUCT_CACHE_MAX_SIZE=2000`).
- Función `invalidate_product_cache(product_id)` como hook para futuras invalidaciones explícitas.

**Trade-offs aceptados:**

- Datos stale hasta TTL en `name`/`price`/`image_urls`. Para display del carrito es deseable (el precio que vio el usuario al agregar es el que paga).
- **No se cachea `reserve_products`** — ese va siempre directo a `product-service` porque ajusta stock real.
- Sin stampede protection: si N VUs piden el mismo `product_id` con cache vacío, hacen N fetches en paralelo. Aceptable para el régimen actual.

**Impacto:**

```
Load test
  cart_get p50    : 769 → 5.5 ms    (140×!)
  cart_get min    : 669 → 3 ms      (223×)
  http_req p95    : 841 → 312 ms    (2.7×)
  Throughput      : 12.5 → 16.2 req/s

Stress test
  cart_get p95    : 10469 → 443 ms  (24×!)
  Throughput      : 32 → 96.25 req/s  (3×)
  http_req_failed : 0.47% → 0.00%
  Checks          : 99% → 100%
```

La distribución de `cart_get` se volvió **bimodal**: p50 = 5.5 ms (hits del cache), p95 = 671 ms (las ~5% misses que pagan el round-trip). Aceptable para el SLA actual; si se quisiera cerrar ese tail, las opciones son TTL más largo o stale-while-revalidate.

---

## 5. Modo mock de MercadoPago para load testing

**Diagnóstico:** con todo lo anterior aplicado, el único bottleneck restante en stress era **checkout**, con p95 = 5.3 s. La razón: el round-trip a MP sandbox. `checkout_min = 257 ms` confirmaba que incluso la mejor request pagaba un viaje a MercadoPago.

**Cambio:** no es una optimización del sistema, es una **herramienta de diagnóstico** que permite aislar la performance del código propio de la latencia upstream.

- Nueva variable `MERCADOPAGO_MOCK_MODE` en settings (default `False`).
- `AsyncMercadoPagoClient.create_preference` y `get_payment` cortocircuitan a respuestas sintéticas cuando el flag está en `True`.
- `is_configured()` también respeta el flag (no requiere token en modo mock).
- Log de WARNING en startup para que sea obvio que está activo.
- En el `compose.yml` local, el flag está en `true` por default. En GKE/producción no se setea — el cliente pega a MP real.

**Impacto medido (stress test, 150 VUs):**

```
                       Con MP sandbox    Con MP mock
checkout p95           5338 ms           2593 ms
checkout min            257 ms             19 ms
http_req_duration p95  2660 ms           1733 ms
Throughput               96 req/s         116 req/s
```

**MercadoPago aporta ~2.7 segundos al p95 de checkout bajo stress y limita el throughput a 96 req/s.** Sin él, el sistema cumple los 8/8 umbrales de stress test.

---

## Resumen — mejoras acumuladas

Comparación de la **línea base** contra el sistema con las 5 optimizaciones aplicadas:

| Métrica | Baseline | Final (MP mock) | Mejora |
|---|---|---|---|
| **Load — p95** | 5604 ms | **47 ms** | **119×** |
| **Load — throughput** | 4.45 req/s | **17.7 req/s** | 4× |
| **Stress — p95** | 30470 ms | **1733 ms** | **17.5×** |
| **Stress — throughput** | 7.16 req/s | **115.95 req/s** | **16×** |
| **Stress — http_req_failed** | 10.75% | **0.00%** | ✓ eliminado |
| **Stress — checks funcionales** | 84% (peor) | **100%** | ✓ |

## Lecciones

- **Las herramientas de carga no miden performance, miden el sistema.** Con MP real y sin las optimizaciones, los números parecían "la app es lenta"; con el diagnóstico encima se vio que el bottleneck era arquitectural (sync MP, pool chico, HTTP repetido), no de FastAPI.
- **Cada optimización abrió la siguiente.** Sin la capa de resiliencia, experimentar con pool grande o cache hubiera sido peligroso (riesgo de cascada). Sin MP async, agrandar el pool no movía el throughput. Sin cache, MP era el cuello visible pero no el único.
- **Aislar dependencias externas con un flag es subestimado.** El modo mock de MP convirtió un debate "es nuestro código vs el integrador" en evidencia con números.
