# ADR-0005: Resiliencia en llamadas HTTP entre servicios — Retry exponencial y Circuit Breaker

## Estado

Aceptada

**Fecha:** 2026-06-02

## Contexto

`checkout-service` realiza llamadas HTTP sincrónicas a otros microservicios durante el flujo de compra y los listados administrativos:

- `product-service`: `get_product`, `get_products`, `reserve_products` (crítico para el checkout — sin él no se reserva stock).
- `user-service`: `get_user_by_email`, `get_user_role_by_email` (usado en listados admin y validación de roles).

Estas llamadas son susceptibles a **fallos transitorios** típicos de un sistema distribuido en Kubernetes: pods recién levantados con startup tardío, timeouts puntuales por GC o I/O, errores 502/503 durante un rolling update de ArgoCD, throttling temporal, problemas de red intermitentes.

Hasta este ADR la estrategia consistía únicamente en:

- **Timeout configurable** (`*_TIMEOUT_SECONDS`).
- **Fail-soft**: ante cualquier error los clientes devolvían `None`/`[]`, y los endpoints respondían con datos parciales.

Esa estrategia tiene dos debilidades:

1. **Pierde requests recuperables**: un timeout aislado o un 503 momentáneo se traducen directamente en degradación funcional, cuando un único reintento hubiera resuelto el problema.
2. **No protege contra cascadas de fallo**: si `product-service` queda caído por minutos, cada checkout sigue pagando el timeout completo (3s) antes de degradarse, consumiendo workers de FastAPI y propagando latencia al cliente.

La cátedra sugiere explícitamente aplicar **Retry con backoff exponencial** y **Circuit Breaker** para evitar cascadas. La asíncrona vía RabbitMQ ya está cubierta por `connect_robust` + DLX (ver [ADR-0004](adr-0004-consistencia-distribuida-saga-compensacion.md)); este ADR cubre el plano HTTP.

Alternativas consideradas:

- **Sólo timeouts (estado previo):** simple pero no recupera transitorios ni evita cascadas.
- **Retry sin Circuit Breaker:** mejora la tolerancia a errores puntuales pero amplifica el daño cuando el upstream está caído de verdad (multiplica la carga sobre el servicio en problemas).
- **Circuit Breaker sin Retry:** evita cascadas pero pierde la recuperación automática de transitorios genuinos.
- **Retry + Circuit Breaker combinados:** Retry absorbe el ruido transitorio, Breaker corta el flujo cuando el problema es persistente. Es la combinación recomendada y la que adoptamos.
- **Sidecar de service mesh** (Istio/Linkerd): da retry y outlier detection a nivel infra sin tocar código, pero introduce un componente operativo de peso elevado, fuera del scope del proyecto académico y con curva de aprendizaje no justificada.

## Decisión

Adoptamos un módulo de resiliencia in-house (`app/clients/resilience.py`) que combina:

### Retry con backoff exponencial

- Implementado con **`tenacity`** (`AsyncRetrying`).
- **`max_attempts = 3`** (1 intento + 2 reintentos).
- **Backoff exponencial** entre `0.2s` y `2.0s` (configurable vía `HTTP_CLIENT_BACKOFF_INITIAL_SECONDS` y `HTTP_CLIENT_BACKOFF_MAX_SECONDS`).
- **Predicado de retry selectivo**: sólo errores transitorios se reintentan.
    - **Sí se reintenta:** `httpx.TimeoutException`, `httpx.ConnectError`, `httpx.NetworkError`, `httpx.RemoteProtocolError`, HTTP `5xx` y `429`.
    - **No se reintenta:** HTTP `4xx` (404, 400, 403...), errores de validación, excepciones de dominio. Reintentar un 404 sólo desperdicia latencia.

### Circuit Breaker

- Implementación **in-house** (`AsyncCircuitBreaker`, ~50 LoC) por simplicidad y para evitar dependencia de versión de `pybreaker`/equivalentes.
- **Tres estados estándar:** `closed → open → half_open → closed`.
- Una **instancia por upstream**: `product_service_breaker` y `user_service_breaker`. No se mezclan: un product-service caído no debe afectar el circuito de user-service.
- **Parámetros configurables por servicio:**
    - `*_CB_FAIL_MAX = 5`: cantidad de fallos consecutivos antes de abrir.
    - `*_CB_RESET_TIMEOUT_SECONDS = 30.0`: tiempo en estado `open` antes de pasar a `half_open`.
- **Conteo de fallos:** un éxito resetea el contador a cero; sólo cuentan los fallos *consecutivos*.

### Integración en los clientes

- `ProductServiceClient` y `UserServiceClient` envuelven cada llamada httpx con `call_with_resilience(breaker, fn, ...)`.
- **El contrato externo se preserva fail-soft:** después de que retry+breaker hicieron su trabajo, los clientes siguen capturando la excepción final (`HTTPError`, `CircuitOpenError`) y devolviendo `None`/`[]` para que los endpoints sigan respondiendo con datos parciales en vez de devolver 500.
- **Logging diferenciado:** apertura del circuito (`WARNING`) y recuperación (`INFO`) quedan en logs para diagnóstico operativo.

### Tests

`tests/test_clients_resilience.py` cubre 13 casos: clasificación de errores retryables, retry con éxito eventual, no-retry de errores definitivos, agotamiento de reintentos, apertura del circuito tras N fallos, transición half-open, y reseteo del contador ante éxito.

## Consecuencias

**Positivas**

- **Recuperación automática de transitorios:** un timeout aislado o un 503 durante un rolling update ya no se traducen en degradación de la respuesta — el segundo intento normalmente lo absorbe.
- **Protección contra cascadas:** cuando un upstream queda caído de verdad, después de 5 fallos consecutivos el circuito abre y las siguientes llamadas fallan en microsegundos (`CircuitOpenError`) en lugar de bloquear el worker FastAPI 3 segundos cada vez.
- **Aislamiento entre upstreams:** un product-service caído no propaga su tasa de fallos al breaker de user-service ni viceversa.
- **Recuperación automática:** tras `reset_timeout` el breaker hace half-open y vuelve a closed apenas el upstream responde bien.
- **Sin cambios en el contrato de los clientes:** los callers (services y endpoints) no necesitan saber de retry ni breaker — siguen viendo el mismo fail-soft.

**Negativas**

- **Latencia incrementada en el peor caso:** un fallo definitivo después de 3 intentos paga la suma de los backoffs (~0.2 + 0.4 + 0.8 ≈ 1.4s adicional). Aceptable dado que para llegar ahí ya hubo errores reales.
- **Más complejidad operativa:** hay un módulo más para mantener y dos parámetros nuevos por upstream (`CB_FAIL_MAX`, `CB_RESET_TIMEOUT_SECONDS`). Mitigación: defaults razonables y configurables vía env.
- **Riesgo de "thundering herd" al cerrar el circuito:** cuando el circuito pasa de `open` a `half_open` no hay control de concurrencia para limitar a una sola request de prueba. En el escenario actual (FastAPI con pocos workers) el riesgo es bajo, pero si en el futuro escalamos horizontalmente conviene considerar `jitter` en el backoff o limitar la cantidad de half-open trials.
- **Métricas no expuestas a Prometheus todavía:** las transiciones del breaker quedan sólo en logs. Una mejora futura sería emitir counters/gauges.

**Neutras**

- La asíncrona (RabbitMQ) **no se ve afectada por este ADR**: ya tenía `connect_robust` y DLX/idempotencia.
- El módulo es reutilizable: si en el futuro `product-service` o `user-service` agregan llamadas a otros upstreams, basta con declarar un nuevo `AsyncCircuitBreaker` y envolver las llamadas.
- Mantenemos la dependencia liviana: una sola lib nueva (`tenacity`), sin frameworks de service mesh.
