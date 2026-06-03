# Pruebas de carga — Checkout Service

Esta sección documenta la estrategia de pruebas de carga y estrés del `checkout-service`, las herramientas usadas, el conjunto de optimizaciones que se aplicaron al sistema a partir de los resultados, y cómo correr el suite localmente.

## Por qué medimos checkout-service

`checkout-service` es el cuello del sistema: cada compra atraviesa cuatro endpoints suyos (`POST /cart/items`, `GET /cart/items`, `POST /` para checkout, `GET /order/purchases`) y coordina llamadas a `product-service`, `user-service`, PostgreSQL, RabbitMQ y MercadoPago. Si algún componente del flujo se satura, el comprador lo siente acá.

El objetivo de las pruebas es:

- **Validar que el flujo end-to-end funciona** bajo carga realista.
- **Encontrar el punto de quiebre** del sistema bajo carga extrema.
- **Medir el impacto** de cada optimización aplicada, con números antes/después.

## Herramienta: k6

Usamos [k6](https://k6.io/) — herramienta open-source de load testing escrita en Go con scripts en JavaScript. Permite simular usuarios virtuales (VUs) que ejecutan un flujo de iteraciones con asserts, métricas y umbrales declarativos.

Dos scripts ([`load-tests/load_test.js`](https://github.com/ids2-grupo8/checkout-service/blob/development/load-tests/load_test.js) y [`stress_test.js`](https://github.com/ids2-grupo8/checkout-service/blob/development/load-tests/stress_test.js)) cubren los dos casos:

| Test | VUs máximos | Duración | Objetivo |
|------|-------------|----------|----------|
| **Load** | 20 | 3m30s | Carga sostenida realista — el sistema debe **responder bien** |
| **Stress** | 150 | 4m | Carga extrema — buscamos el punto de quiebre |

Cada iteración simula un comprador: agregar producto al carrito → consultar carrito → iniciar checkout → listar órdenes. Los emails son únicos por iteración para que cada VU empiece con carrito vacío.

## Flujo medido por iteración

```
1. POST /api/v1/cart/items      → cart_add_duration   + check "cart add → 2xx"
2. sleep 0.5s
3. GET  /api/v1/cart/items      → cart_get_duration   + check "cart get → 200"
4. sleep 0.5s
5. POST /api/v1/                → checkout_duration   + check "checkout → sin 5xx"
6. sleep 0.5s
7. GET  /api/v1/order/purchases → orders_list_duration + check "orders list → 200"
8. sleep 1s (load) / 0.2s (stress)
```

Los `sleep` simulan "tiempo de pensamiento" del usuario; sin ellos cada VU pegaría 1000+ req/s y mediríamos una carga irrealista.

## Resultado final — después de las optimizaciones

Después de aplicar las optimizaciones (ver [Optimizaciones aplicadas](optimizaciones.md)), el sistema cumple:

### Load test (20 VUs)

| Métrica | Valor | Umbral | Estado |
|---|---|---|---|
| Throughput | 17.7 req/s | — | ✓ |
| http_req_duration p95 | 47 ms | < 500 ms | ✓ |
| checkout p95 | 44 ms | < 800 ms | ✓ |
| http_req_failed | 0.00% | < 5% | ✓ |
| Checks funcionales | 100% (4/4) | 100% | ✓ |

### Stress test (150 VUs, con MercadoPago mockeado)

| Métrica | Valor | Umbral | Estado |
|---|---|---|---|
| Throughput | 115.95 req/s | — | ✓ |
| http_req_duration p95 | 1733 ms | < 2000 ms | ✓ |
| checkout p95 | 2593 ms | < 3000 ms | ✓ |
| http_req_failed | 0.00% | < 10% | ✓ |
| Checks funcionales | 100% (4/4) | 100% | ✓ |

Con **MercadoPago real** (sandbox) bajo el mismo stress, el throughput cae a 96 req/s y el checkout p95 sube a 5.3 s — el bottleneck queda demostradamente del lado del integrador externo.

## Cómo interpretar los reportes

El generador automático ([`generate_report.py`](https://github.com/ids2-grupo8/checkout-service/blob/development/load-tests/generate_report.py)) produce un `RESULTS.md` con tablas por métrica, percentiles, umbrales y un **diagnóstico data-driven** que identifica si el flujo se ejecutó funcionalmente o si los números reflejan errores enmascarados como respuestas rápidas.

Reglas para leerlos:

- **Umbrales de latencia** miden tiempos sobre **cualquier** respuesta del servidor, incluso 4xx/5xx. Que el p95 pase no implica que el flujo haya funcionado.
- **Checks individuales** son la métrica real de funcionalidad. Si están por debajo del 80%, el reporte de latencias describe un comportamiento que **no representa el caso de uso**.
- **`http_req_failed`** marca cualquier HTTP fallido (timeouts + 4xx/5xx). Cerca de 100% conviene `curl` manual antes de interpretar percentiles.

## Páginas relacionadas

- [Optimizaciones aplicadas](optimizaciones.md) — historia del antes/después de cada cambio.
- [Cómo ejecutar las pruebas](como-ejecutar.md) — pasos para correr el suite en local.
