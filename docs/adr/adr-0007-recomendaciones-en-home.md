# ADR-0007: Recomendaciones personalizadas en Home

## Estado

Aceptada

**Fecha:** 2026-05-12

## Contexto

El enunciado exige en **Home** (CA-4) una sección de recomendaciones personalizadas cuando el sistema tenga historial disponible para ese usuario. El alcance es cumplir ese criterio de aceptación dentro de la pantalla de inicio.

En Bazaar el descubrimiento ocurre en la app mobile (sección **Para vos**), con datos repartidos entre servicios:

- **checkout-service** concentra el historial de compras del comprador.
- **product-service** concentra el catálogo y debe devolver candidatos con stock y visibles.
- **user-service** aporta el estado de los vendedores (bloqueos) al filtrar visibilidad.

Fuerzas en juego:

- **Simplicidad operativa:** evitar un microservicio de recomendaciones solo para el MVP; el algoritmo inicial debe ser explicable y testeable.
- **Cold start:** usuarios nuevos o sin señal deben ver contenido útil (productos recientes globales), no una sección vacía.
- **Consistencia de catálogo:** las mismas reglas de visibilidad del listado público (stock, estado, moderación, vendedor bloqueado) deben aplicar a las recomendaciones.
- **Señales disponibles:** compras recientes son la señal más fuerte; la navegación complementa cuando no hay compras o son antiguas.
- **Resiliencia:** una caída de checkout-service no debe romper Home; el browse local puede seguir aportando señal o degradar a global.
- **UX en mobile:** la sección **Para vos** no debe mezclarse con búsqueda/filtros activos en Home.

Alternativas consideradas:

1. **Microservicio de recomendaciones** dedicado.
2. **Log append-only** de cada vista a detalle de producto (un documento por evento).
3. **Solo historial de navegación**, sin consultar compras.
4. **Solo historial de compras**, sin capturar navegación.
5. **Filtrado colaborativo o ML** sobre interacciones.

## Decisión

Centralizamos la lógica de recomendaciones en **product-service**. El mobile registra navegación y consume un único endpoint con metadata de personalización. Las compras se obtienen por HTTP desde checkout-service.

### 1. Cadena de señales (prioridad)

Para usuarios autenticados, resolvemos señal en este orden:

1. **Compras recientes** — ítems de órdenes en estados de pago confirmado o posteriores (`payment confirmed`, `processing`, `shipped`, `delivered`) dentro de una ventana de **30 días** (`RECOMMENDATION_PURCHASE_RECENCY_DAYS`). Se infieren categorías pico ponderadas por cantidad comprada.
2. **Blend compras + navegación** — si no hay compras recientes, se combinan todas las compras históricas (mismo criterio de estado) con contadores de navegación por categoría. Peso configurable: compras **×2**, navegación **×1** (`RECOMMENDATION_PURCHASE_CATEGORY_WEIGHT` / `RECOMMENDATION_BROWSE_CATEGORY_WEIGHT`).
3. **Solo navegación** — si no hay compras pero sí contadores de categoría, se usa browse como única señal.
4. **Global (cold start)** — usuarios anónimos, sin señal o con señal que no produce resultados visibles: productos disponibles más recientes, excluyendo publicaciones propias del usuario.

Órdenes en `payment pending`, `payment rejected` o `canceled` **no** alimentan la señal de compras.

### 2. Captura de historial de navegación

- Al abrir el **detalle de producto**, la app mobile (usuario autenticado) envía `POST /api/v1/products/{id}/recent-detail-view`.
- product-service incrementa un contador **por categoría** en MongoDB (`user_category_interest`), no un log de eventos por visita.
- Se registra la categoría del producto visto, no el ID del producto en el historial de browse (los IDs ya comprados se excluyen vía señal de compras).

### 3. Selección de productos candidatos

- A partir de las categorías pico (empates incluidos), se buscan productos `available` con `actual_stock > 0` en esas categorías.
- Orden: **más recientes primero** (`created_at` descendente).
- Exclusiones: publicaciones del propio usuario y productos ya presentes en la señal de compras (`exclude_product_ids`).
- Tras la query, se aplican las mismas reglas de visibilidad del catálogo público (vendedor no bloqueado, producto no moderado).

### 4. Degradación y contrato de API

- Si la lista personalizada queda vacía (sin señal o filtrada por visibilidad), se repite la búsqueda con criterio **global** y `source: global`.
- `GET /api/v1/products/recommendations/context` devuelve:
  - `items`: productos recomendados.
  - `source`: `purchases` | `blended` | `browse` | `global`.
  - `is_personalized`: `true` cuando `source` ∈ {`purchases`, `blended`, `browse`}.
- Errores de red hacia checkout-service devuelven listas de compra vacías; el flujo continúa con browse o global.

### 5. Comportamiento en mobile (Home)

- **Para vos** se muestra solo si el usuario está autenticado, `is_personalized === true` y hay ítems.
- Con **búsqueda o filtros activos** en Home no se solicitan recomendaciones (evita mezclar contextos).
- Si el endpoint falla, la sección no se muestra; **Todos los productos** sigue operativo.
- **Recientes** es independiente: productos vistos en la sesión de exploración local, no confundir con la señal de browse persistida.

### 6. Alternativas descartadas

| Alternativa | Motivo de descarte |
|-------------|-------------------|
| Microservicio de recomendaciones | Costo operativo y de despliegue desproporcionado para el alcance del MVP. |
| Log append-only por vista | Mayor volumen de escrituras y agregaciones más costosas; los contadores por categoría cubren el CA de Home con menos almacenamiento. |
| Solo navegación / solo compras | Limitaría la calidad de **Para vos**; el blend mejora personalización dentro del CA-4 sin scope de la optativa #39. |
| ML / filtrado colaborativo | Complejidad y opacidad fuera del alcance del checkpoint; el enfoque por categorías es auditable en defensa. |

## Consecuencias

**Positivas**

- Una sola fuente de verdad para recomendaciones (`product-service`), alineada con el dueño del catálogo.
- Algoritmo determinista, cubierto por tests en `test_recommendations.py`.
- Degradación graceful: checkout caído → browse o global; sin señal → global; API caída en mobile → Home usable sin **Para vos**.
- La UI distingue claramente personalizado vs. global mediante `is_personalized`, sin mostrar **Para vos** con picks globales.

**Negativas**

- product-service depende de checkout-service en runtime para la señal de compras (acoplamiento HTTP sincrónico).
- Los contadores por categoría pierden granularidad a nivel producto en browse (solo la categoría del detalle visitado).
- La ventana de 30 días y los pesos 2:1 son heurísticas fijas; ajustarlos requiere configuración/despliegue.

**Neutras**

- El valor `profile` en el DTO de `source` queda reservado; la implementación actual no lo emite.
- El mismo endpoint puede reutilizarse si en el futuro se implementa la optativa #39 como pantalla dedicada; queda fuera del alcance actual.
