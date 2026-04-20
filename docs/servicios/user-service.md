# User Service

Microservicio de **identidad y usuarios**: autenticación, perfiles y operaciones de administración.

## Stack

| | |
|---|---|
| Lenguaje | Python |
| Framework | FastAPI |
| Base de datos | PostgreSQL |
| Auth externo | Supabase Auth (JWT) |

## Responsabilidades (implementado)

- **Autenticación (`/api/v1/auth`)**: registro y login email/contraseña (tokens vía Supabase); login federado completando la sesión OAuth (`/auth/federated-login`); flujo de recupero (`/auth/forgot-password`, `/auth/reset-password`) con rate limit en “olvidé contraseña”.
- **Salud (`/api/v1/health`)**: endpoints de liveness/readiness para orquestación.
- **Usuarios (`/api/v1`)**: consulta por email; perfil propio (actualización de nombre y descripción); subida de foto de perfil (multipart, imágenes vía Cloudinary); perfil autenticado y perfil público. Para los perfiles con publicaciones, el servicio **consulta al product-service** y devuelve usuario + listado de productos del vendedor.
- **Administración (`/api/v1/admin`)**: listado de usuarios con búsqueda opcional por email o nombre; bloqueo/desbloqueo por id (requiere rol admin en Supabase).

## Repositorio

[github.com/ids2-grupo8/user-service](https://github.com/ids2-grupo8/user-service)

Setup local y variables de entorno: ver el `README` del repositorio.
