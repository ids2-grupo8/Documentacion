# Sprint 1

**Período:** 27/03/2026 — 17/04/2026  
**Checkpoints cubiertos:** CP0 + CP1  
**Estado:** Completado

---

## Objetivo del sprint

Establecer la infraestructura del proyecto, configurar CI/CD en todos los componentes, implementar los flujos de autenticación completos en el user-service, el CRUD de productos en el product-service, y las interfaces iniciales del backoffice y la app mobile con al menos un flujo funcional de punta a punta.

---

## Historias de usuario trabajadas

### Obligatorias

| # | Historia | Puntos | Estado | Componentes involucrados |
|---|----------|:------:|--------|--------------------------|
| 1 | Registro de usuarios | 2 | Completada | user-service, mobileApp |
| 2 | Login con email y contraseña | 2 | Completada | user-service, mobileApp, backoffice |
| 3 | Recupero de contraseña | 3 | Completada | user-service, mobileApp |
| 4 | Edición de perfil | 3 | Completada | user-service, mobileApp |
| 5 | Visualización de perfil propio | 1 | Completada | user-service, mobileApp |
| 6 | Home | 3 | Completada | product-service, mobileApp |
| 7 | Listado y búsqueda de productos | 3 | Completada | product-service, mobileApp |
| 8 | Detalle de producto | 2 | Completada | product-service, mobileApp |
| 14 | Publicar producto | 3 | Completada | product-service, mobileApp |
| 15 | Gestión de stock y publicaciones | 3 | Completada | product-service |
| 17 | Listar usuarios del sistema | 1 | Completada | user-service, backoffice |
| 18 | Bloquear y desbloquear usuario | 2 | Completada | user-service, backoffice |

**Subtotal obligatorias:** 28 / 63 pts

### Optativas

| # | Historia | Puntos | Estado | Componentes involucrados |
|---|----------|:------:|--------|--------------------------|
| 22 | Login con proveedor federado (Google) | 3 | Completada | user-service, mobileApp |
| 24 | Visualización de perfil público | 2 | Completada | user-service |

**Subtotal optativas:** 5 pts

---

## Detalle de lo implementado

### User Service (Python / FastAPI + PostgreSQL)

- **Autenticación completa:** registro, login email/password, login federado con Google vía Supabase Auth, y recupero de contraseña con enlace de uso único.
- **Perfil:** edición de datos personales, subida de foto de perfil a Cloudinary, visualización del perfil propio y de perfiles públicos de otros usuarios.
- **Administración:** listado paginado de usuarios con búsqueda, bloqueo/desbloqueo sincronizado con Supabase (el usuario bloqueado no puede iniciar sesión y ve un mensaje claro).
- **Modelo de datos:** tablas `User` y `UserIdentity` para soportar múltiples proveedores de identidad.
- **Observabilidad:** endpoints `/livez` y `/readyz`, métricas Prometheus con `prometheus-fastapi-instrumentator`.

### Product Service (Python / FastAPI + MongoDB)

- **CRUD de productos:** creación con imágenes (Cloudinary), edición de precio/descripción/stock, cambio de estado (disponible / no disponible / deshabilitado).
- **Catálogo:** listado paginado de productos activos con stock > 0, detalle completo de producto, listado de productos por vendedor.
- **Categorías:** soporte para categorías predefinidas (Electronics, Clothing).
- **Comunicación inter-servicio:** consulta al user-service para obtener datos del vendedor.
- **Observabilidad:** endpoints `/livez` y `/readyz`.

### Mobile App (React Native / Expo)

- **Autenticación:** login, registro, recupero de contraseña y login con Google OAuth.
- **Home:** pantalla principal con productos recientes, íconos de categoría y barra de búsqueda.
- **Catálogo:** navegación de productos, detalle de producto con galería de imágenes.
- **Perfil:** visualización y edición del perfil propio.
- **Vendedor:** pantalla de publicación de producto.

### Backoffice Web (React / Vite)

- **Login de administrador:** validación de rol admin, flujo exclusivo para administradores.
- **Panel de usuarios:** listado con búsqueda, bloqueo/desbloqueo de usuarios.
- **Dashboard:** vista inicial con secciones de navegación.
- **UI:** estética dark/glass consistente con el sistema de diseño del proyecto.

### Infraestructura

- **Kubernetes** como orquestador de despliegue.
- **Kong** como API Gateway (enrutamiento, CORS).
- **ArgoCD** + Argo Image Updater para CD automático.
- **CI:** pipelines por servicio que corren tests y buildean imágenes Docker en cada push.
- **Helm charts** por servicio para gestión de despliegue.

---

## Arquitectura del sprint

```
┌─────────────┐     ┌──────────────┐     ┌───────────────────┐
│  Mobile App │────▶│  API Gateway │────▶│   user-service    │
│  (Expo)     │     │  (Kong)      │     │  (FastAPI + PG)   │
└─────────────┘     │              │     └───────────────────┘
                    │              │              │
┌─────────────┐     │              │     ┌───────────────────┐
│  Backoffice │────▶│              │────▶│ product-service   │
│  (React)    │     └──────────────┘     │ (FastAPI + Mongo) │
└─────────────┘                          └───────────────────┘
                                                 │
                          ┌──────────┐    ┌──────┴──────┐
                          │ Supabase │    │ Cloudinary  │
                          │  Auth    │    │  (imágenes) │
                          └──────────┘    └─────────────┘
```

---

## Métricas del sprint

| Métrica | Valor |
|---------|-------|
| Historias completadas | 14 |
| Puntos obligatorios entregados | 28 / 63 |
| Puntos optativos entregados | 5 |
| Servicios backend | 2 (user-service, product-service) |
| Frontends | 2 (backoffice, mobile) |
| PRs mergeados (user-service) | ~10 |
| PRs mergeados (product-service) | ~11 |

---

