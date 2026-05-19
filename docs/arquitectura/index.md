# Arquitectura del Sistema

## Visión general

Bazaar está construido como un conjunto de **microservicios independientes**, cada uno con su propia base de datos y responsabilidad bien definida. Los clientes (app mobile y backoffice web) nunca se comunican directamente con los servicios: todas las peticiones pasan por un **API Gateway** que se encarga del enrutamiento y la autenticación.

```
┌─────────────────┐         ┌─────────────────┐
│   Mobile App    │         │   Backoffice    │
│ (React Native)  │         │  (React + Vite) │
└────────┬────────┘         └────────┬────────┘
         │                           │
         └─────────────┬─────────────┘
                       │
              ┌────────▼────────┐
              │  Kong Gateway   │  ← Punto único de entrada
              │  (JWT · roles)  │
              └──┬──────┬───┬───┘
                 │      │   │
       ┌─────────▼─┐ ┌──▼──────────┐ ┌──────────────────┐
       │user-service│ │product-svc  │ │ checkout-service │
       │ (FastAPI)  │ │ (FastAPI)   │ │   (FastAPI)      │
       └─────┬──────┘ └──┬──────────┘ └────────┬─────────┘
             │            │                     │
       ┌─────▼──────┐ ┌───▼──────┐     ┌───────▼────────┐
       │ PostgreSQL │ │ MongoDB  │     │  PostgreSQL    │
       └────────────┘ └──────────┘     └────────────────┘
                           │                     │
                           │   ┌─────────────────┘
                           │   │  publica eventos
                           ▼   ▼
                    ┌─────────────┐
                    │  RabbitMQ   │  ← Mensajería asíncrona
                    └──────┬──────┘
                           │ consume
                  ┌────────▼──────────┐
                  │notification-service│
                  │      (Go)         │
                  └────────┬──────────┘
                           │
                  ┌────────▼──────────┐
                  │  Expo Push API    │  ← Notificaciones mobile
                  └───────────────────┘
```

### ¿Por qué microservicios?

En lugar de tener toda la lógica en una sola aplicación, el sistema se divide en servicios más chicos que se pueden desarrollar, testear y desplegar de forma independiente. Cada servicio tiene su propia base de datos, lo que evita acoplamientos y permite que un equipo trabaje en un servicio sin afectar a los demás.

### ¿Qué hace el API Gateway?

Kong recibe todas las peticiones de los clientes y se encarga de:

- **Redirigirlas al servicio correcto** según la URL (ej: `/users/*` va al user-service, `/products/*` va al product-service, `/checkout/*` va al checkout-service).
- **Validar el token JWT** en las rutas que requieren autenticación.
- **Extraer la identidad del usuario** del token y pasarla como header al servicio backend, para que los servicios sepan quién está haciendo el request sin tener que parsear el token ellos mismos.
- **Verificar el rol de administrador** en las rutas del panel de admin.

---

## Servicios

| Servicio | Lenguaje / Framework | Base de datos | Responsabilidad |
|---|---|---|---|
| **user-service** | Python / FastAPI | PostgreSQL | Autenticación, perfiles, administración de usuarios |
| **product-service** | Python / FastAPI | MongoDB | Catálogo de productos, stock, imágenes, categorías |
| **checkout-service** | Python / FastAPI | PostgreSQL | Carrito, checkout con MercadoPago, ciclo de vida de órdenes, cupones y reseñas |
| **notification-service** | Go / net/http | MongoDB | Push notifications a vendedores por stock bajo o agotado |
| **backoffice** | TypeScript / React + Vite | — | Panel web de administración |
| **mobileApp** | TypeScript / React Native + Expo | — | App mobile para compradores y vendedores |

---

## Mensajería asíncrona (RabbitMQ)

Los servicios se comunican de forma asíncrona a través de RabbitMQ para desacoplarse entre sí. Los eventos fluyen así:

| Exchange | Routing key | Publicador | Consumidor | Cuándo |
|---|---|---|---|---|
| `bazaar.payments` | `payment.confirmed` | checkout-service | product-service | Pago aprobado por MercadoPago → descuenta stock definitivamente |
| `bazaar.payments` | `payment.rejected` | checkout-service | product-service | Pago rechazado o orden expirada → restaura el stock reservado |
| `bazaar.stock` | `stock.updated` | product-service | notification-service | Stock de un producto cae por debajo del umbral → dispara push al vendedor |

---

## Flujo de una compra

```
Comprador           checkout-service      product-service     MercadoPago
    │                      │                    │                  │
    │─── POST /checkout ──▶│                    │                  │
    │                      │── reserva stock ──▶│                  │
    │                      │◀── OK ─────────────│                  │
    │                      │── crea preferencia ────────────────▶ │
    │◀── init_point ───────│                    │                  │
    │                      │                    │                  │
    │── paga en MP ──────────────────────────────────────────────▶│
    │                      │◀── webhook (approved/rejected) ───────│
    │                      │                    │                  │
    │                      │── payment.confirmed/rejected ──▶ [RabbitMQ]
    │                      │                    │◀── consume ──────│
    │                      │                    │ ajusta stock     │
```

---

## Servicios externos

| Servicio | Para qué lo usamos |
|---|---|
| **Supabase Auth** | Maneja el registro, login, OAuth con Google y recupero de contraseña. Emite los JWT que usa todo el sistema. |
| **Cloudinary** | Almacena las imágenes de perfil y de productos. En la base de datos solo guardamos la URL. |
| **MercadoPago** | Procesamiento de pagos. El checkout-service genera una preferencia de pago y recibe el resultado vía webhook. |
| **Expo Push API** | Envío de notificaciones push a la app mobile. El notification-service llama a esta API cuando detecta stock bajo. |

---

## Decisiones de tecnología

| Decisión | Qué elegimos | Por qué |
|---|---|---|
| BD del user-service | **PostgreSQL** | Los datos de usuarios tienen estructura fija y relaciones claras (usuario → identidades federadas). Una base relacional es lo más natural. |
| BD del product-service | **MongoDB** | Los productos pueden tener atributos distintos según la categoría (ej: talle en ropa, memoria en electrónica). Un modelo de documentos permite esa flexibilidad sin tener que alterar el esquema. |
| BD del checkout-service | **PostgreSQL** | Las órdenes y sus ítems tienen estructura fija y relaciones claras (orden → ítems, historial). Alembic maneja las migraciones. |
| BD del notification-service | **MongoDB** | Los tokens de dispositivo y notificaciones son documentos simples sin relaciones fuertes. |
| Autenticación | **Supabase Auth** | Nos da JWT, OAuth con Google, recupero de contraseña y gestión de sesiones sin tener que implementarlo desde cero. |
| Imágenes | **Cloudinary** | CDN con plan gratuito suficiente para el proyecto. Subimos la imagen y obtenemos una URL pública. |
| Pagos | **MercadoPago** | Gateway de pagos ampliamente usado en Latinoamérica. La integración se hace vía preferencias y webhooks. |
| Push notifications | **Expo Push API** | Compatible nativamente con React Native/Expo. Abstrae iOS (APNs) y Android (FCM) en un único endpoint. |
| Mensajería | **RabbitMQ** | Broker de mensajería liviano que desacopla los servicios. Permite que el product-service restaure stock sin que el checkout-service lo llame directamente. |
| API Gateway | **Kong (OSS)** | Se integra nativamente con Kubernetes y permite agregar lógica custom con plugins Lua (validación de JWT, extracción de email, chequeo de rol admin). |
| Despliegue | **Kubernetes + ArgoCD** | Despliegue declarativo con GitOps: cuando se pushea una imagen nueva, ArgoCD detecta el cambio y actualiza el servicio automáticamente. |
| Lenguaje del notification-service | **Go** | Binario liviano ideal para un servicio que solo consume eventos y dispara llamadas HTTP. Concurrencia nativa con goroutines. |
