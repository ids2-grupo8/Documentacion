# Checkout Service

Microservicio de **carrito, órdenes y pagos**: gestión del carrito de compras, procesamiento del checkout con MercadoPago, ciclo de vida de órdenes, cupones de descuento y reseñas post-entrega.

## Stack

| | |
|---|---|
| Lenguaje | Python |
| Framework | FastAPI |
| Base de datos | PostgreSQL (Alembic para migraciones) |
| Pagos | MercadoPago SDK |
| Mensajería | RabbitMQ (aio-pika) |

## Responsabilidades

- **Carrito (`/api/v1/cart/items`)**: agregar, listar, actualizar cantidad y eliminar ítems del carrito del comprador autenticado. Cada ítem se identifica por `product_id`; si el producto ya existe, se incrementa la cantidad. El total del carrito se calcula al listar.

- **Checkout (`POST /api/v1/`)**: inicia el proceso de compra. Valida que el carrito no esté vacío, reserva stock consultando al **product-service**, agrupa los productos por vendedor, aplica el cupón de descuento si se provee (proporcionalmente entre vendedores), crea una orden por vendedor en estado `PAYMENT_PENDING` y genera una preferencia en MercadoPago devolviendo el `init_point`. Incluye clave de idempotencia para evitar doble-cobro: si la orden ya existe y sigue pendiente, extiende su expiración y re-genera la preferencia.

- **Webhook MercadoPago (`POST /api/v1/webhook/mercadopago`)**: recibe notificaciones de pago de MercadoPago. Si el pago es `approved`, confirma las órdenes, registra el uso del cupón, vacía el carrito y publica el evento `payment.confirmed` en RabbitMQ. Si es `rejected`, rechaza las órdenes y publica `payment.rejected`.

- **Órdenes (`/api/v1/order`)**: ciclo de vida completo mediante el patrón **State**:
    - `GET /order/purchases` — listado de compras del comprador autenticado (filtrable por estado).
    - `GET /order/sales` — listado de ventas del vendedor autenticado (filtrable por estado).
    - `GET /order/{id}` — detalle de una orden (solo comprador o vendedor).
    - `POST /order/{id}/process` — vendedor marca la orden en preparación (`PAYMENT_CONFIRMED → PROCESSING`).
    - `POST /order/{id}/ship` — vendedor marca la orden como enviada (`PROCESSING → SHIPPED`), opcionalmente con código de seguimiento.
    - `POST /order/{id}/deliver` — comprador confirma recepción (`SHIPPED → DELIVERED`).

- **Expiración automática de órdenes**: tarea de fondo que corre cada 30 segundos y cancela las órdenes `PAYMENT_PENDING` cuya fecha de expiración (5 minutos desde la creación) ya pasó, publicando el evento `payment.rejected` para que el product-service restaure el stock.

- **Cupones (`/api/v1/coupons`, `/api/v1/admin/coupons`)**: validación de cupones antes del checkout; creación, listado, actualización y eliminación de cupones por admin. Los cupones tienen vigencia por fechas, límite global de usos y seguimiento por usuario.

- **Reseñas (`/api/v1/review`)**: habilitadas únicamente sobre órdenes en estado `DELIVERED`.
    - `GET /review/order/{id}` — reseñas ya enviadas por el comprador para esa orden.
    - `POST /review/order/{id}/seller` — califica al vendedor (puntaje + comentario opcional).
    - `POST /review/order/{id}/product/{product_id}` — califica un producto de la orden.

- **Administración (`/api/v1/admin/orders`)**: listado paginado de todas las órdenes del sistema con filtro por estado y búsqueda; detalle completo de una orden con historial de estados.

- **Salud (`/health`)**: endpoint de liveness para orquestación y monitoreo.

## Ciclo de vida de una orden

```
                  ┌─────────────┐
                  │PAYMENT_PENDING│ ← orden creada (expira en 5 min)
                  └──────┬──────┘
           ┌─────────────┴─────────────┐
     approved                      rejected / expired
           ↓                            ↓
  ┌────────────────┐          ┌──────────────────┐
  │PAYMENT_CONFIRMED│          │ PAYMENT_REJECTED  │
  └────────┬───────┘          └──────────────────┘
    (vendedor)
           ↓ /process
     ┌───────────┐
     │ PROCESSING │
     └─────┬─────┘
    (vendedor)
           ↓ /ship
       ┌────────┐
       │ SHIPPED │
       └────┬───┘
    (comprador)
           ↓ /deliver
      ┌──────────┐
      │ DELIVERED │  ← habilita reseñas
      └──────────┘
```

Cualquier estado puede transicionar a `CANCELED` ante condiciones inválidas o acción de cancelación.

## Mensajería (RabbitMQ)

| Evento | Routing key | Cuándo se publica |
|---|---|---|
| Pago confirmado | `payment.confirmed` | Webhook MP `approved` o confirmación manual |
| Pago rechazado | `payment.rejected` | Webhook MP `rejected` o expiración de orden |

Exchange: `bazaar.payments` (topic, durable). El **product-service** consume estos eventos para actualizar el stock.

## Variables de entorno clave

| Variable | Descripción |
|---|---|
| `DATABASE_URL` | URL de PostgreSQL (o se arma desde `DATABASE_HOST/PORT/NAME/USER/PASSWORD`) |
| `MERCADOPAGO_ACCESS_TOKEN` | Token de acceso a la API de MercadoPago |
| `RABBITMQ_URL` | URL de conexión a RabbitMQ |
| `PRODUCT_SERVICE_URL` | URL base del product-service |
| `USER_SERVICE_BASE_URL` | URL base del user-service |

## Repositorio

[github.com/ids2-grupo8/checkout-service](https://github.com/ids2-grupo8/checkout-service)

Setup local y variables de entorno: ver el `README` del repositorio.
