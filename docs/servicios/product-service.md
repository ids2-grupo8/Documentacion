# Product Service

Microservicio del **catálogo**: publicaciones, stock, imágenes y exposición al comprador.

## Stack

| | |
|---|---|
| Lenguaje | Python |
| Framework | FastAPI |
| Base de datos | MongoDB |
| Imágenes | Cloudinary (solo URLs en BD) |

## Responsabilidades


- CRUD de productos del vendedor (precio, stock, estado, imágenes).
- Listado y detalle para el catálogo; productos por vendedor.
- Consultas al user-service para datos públicos del vendedor.
- **Salud (`/api/v1/health`)**: comprobaciones para despliegue y monitoreo.

## Repositorio

[github.com/ids2-grupo8/product-service](https://github.com/ids2-grupo8/product-service)

Setup local y variables de entorno: ver el `README` del repositorio.
