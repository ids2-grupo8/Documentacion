# Contratos de API (OpenAPI / Swagger)

Los tres microservicios de dominio de Bazaar están construidos con **FastAPI**, que
**autogenera** la especificación **OpenAPI 3** a partir del código (rutas, modelos Pydantic y
tipos). No mantenemos el contrato a mano: se deriva siempre de la implementación, por lo que
queda sincronizado con el comportamiento real del servicio.

Cada servicio expone su documentación interactiva en dos formatos estándar de FastAPI:

| Ruta | Herramienta | Para qué sirve |
|---|---|---|
| `/docs` | **Swagger UI** | Explorar y **probar** los endpoints desde el navegador. |
| `/redoc` | **ReDoc** | Lectura del contrato en formato documento. |
| `/openapi.json` | **OpenAPI 3 (JSON)** | El contrato crudo, para importar en Postman/Insomnia o generar clientes. |

> El **notification-service** (Go) no expone API pública de negocio: consume eventos de
> RabbitMQ y registra tokens de dispositivo. Su superficie HTTP se limita a *health checks* y
> registro de suscripciones.

---

## Acceso a través del API Gateway

En producción, los clientes nunca llaman directo a los servicios: todo pasa por **Kong**
(ver [ADR-0002](../adr/adr-0002-kong-como-api-gateway.md)). Los prefijos públicos se mapean
al prefijo interno `/api/v1/...` de cada servicio:

| Prefijo público (Gateway) | Servicio backend | Dominio |
|---|---|---|
| `/users/*` | user-service | Autenticación, perfiles, administración de usuarios |
| `/products/*` | product-service | Catálogo, stock, categorías, imágenes |
| `/checkout/*` | checkout-service | Carrito, checkout, órdenes, cupones, reseñas |

---

## Cómo ver el contrato de cada servicio

### En local

Levantá el servicio con su `compose.yml` (ver el README del repo correspondiente) y abrí en
el navegador:

| Servicio | Swagger UI | OpenAPI JSON |
|---|---|---|
| **user-service** | `http://localhost:8000/docs` | `http://localhost:8000/openapi.json` |
| **product-service** | `http://localhost:8000/docs` | `http://localhost:8000/openapi.json` |
| **checkout-service** | `http://localhost:8000/docs` | `http://localhost:8000/openapi.json` |

> El puerto puede variar según el `compose.yml` / variable de entorno de cada repo;
> confirmá el mapeo de puertos en su README.

### Exportar la especificación

Para guardar el contrato como artefacto (por ejemplo, para versionarlo o importarlo en
Postman):

```bash
# Con el servicio corriendo en local
curl http://localhost:8000/openapi.json -o user-service.openapi.json
```

---

## Resumen de superficies de API

### user-service — `/users/*`

- `/api/v1/auth` — registro, login email/contraseña, login federado (Google/Supabase),
  recupero y reseteo de contraseña, login por PIN.
- `/api/v1` — consulta de usuario por email, perfil propio (edición de nombre/descripción),
  subida de foto de perfil, perfil público con publicaciones del vendedor.
- `/api/v1/admin` — listado de usuarios con búsqueda, bloqueo/desbloqueo (requiere rol admin).
- `/api/v1/health` — `livez` / `readyz`.

### product-service — `/products/*`

- CRUD de productos con imágenes (Cloudinary), stock, precio y estados.
- Catálogo: listado, búsqueda, filtros, detalle, productos por vendedor, categorías.
- Endpoints administrativos de moderación de publicaciones.
- Recomendaciones para Home (ver [ADR-0007](../adr/adr-0007-recomendaciones-en-home.md)).
- Ajuste de stock por eventos de pago (consumidor RabbitMQ).

### checkout-service — `/checkout/*`

- Carrito: alta/modificación/eliminación de ítems, verificación de stock.
- Checkout: creación de preferencia de Mercado Pago, webhook de pago, una orden por vendedor
  (ver [ADR-0001](../adr/adr-0001-una-orden-por-vendedor-en-checkout.md)).
- Órdenes: estados y transiciones, historial de compras y ventas, código de seguimiento.
- Cupones: validación y aplicación de descuento en checkout.
- Reseñas: calificación de producto y vendedor sobre órdenes entregadas; reputación agregada.
- Métricas del sistema para el backoffice.

---

> El detalle exacto de cada endpoint (parámetros, request/response, códigos de estado) vive
> en el **Swagger UI autogenerado** de cada servicio, que es la fuente de verdad del contrato.
