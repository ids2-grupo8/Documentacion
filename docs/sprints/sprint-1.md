# Sprint 1

**Período:** 27/03/2026 — 17/04/2026  
**Checkpoints cubiertos:** CP0 + CP1  
**Estado:** Completado

---

## Objetivo del sprint

Establecer la infraestructura del proyecto (Kubernetes, Kong, CI/CD), implementar los flujos de autenticación, el catálogo de productos y las interfaces iniciales del backoffice y la app mobile.

---

## Historias de usuario completadas

### Obligatorias

| # | Historia | Puntos |
|---|----------|:------:|
| 1 | Registro de usuarios | 2 |
| 2 | Login con email y contraseña | 2 |
| 3 | Recupero de contraseña | 3 |
| 4 | Edición de perfil | 3 |
| 5 | Visualización de perfil propio | 1 |
| 8 | Detalle de producto | 2 |
| 14 | Publicar producto | 3 |
| 15 | Gestión de stock y publicaciones | 3 |
| 17 | Listar usuarios del sistema | 1 |
| 18 | Bloquear y desbloquear usuario | 2 |

**Total obligatorias (enunciado):** 22 puntos

### Optativas

| # | Historia | Puntos |
|---|----------|:------:|
| 22 | Login con proveedor federado (Google) | 3 |
| 24 | Visualización de perfil público | 2 |

**Total optativas (enunciado):** 5 puntos

### Infraestructura

- Deploy automático en GKE  
- API Gateway (Kong)  
- Verificación de autenticación JWT en Kong  
- Verificación de rol de administrador en Kong  

---

## Resumen técnico

### User service (Python / FastAPI + PostgreSQL)

- Autenticación: registro, login email/contraseña, OAuth con Supabase, recupero de contraseña.
- Perfil: edición, foto en Cloudinary, perfil propio y perfil público de otros usuarios.
- Administración: listado con búsqueda, bloqueo y desbloqueo de usuarios.
- Modelo `User` y `UserIdentity` para identidades federadas.
- Observabilidad: `/livez`, `/readyz`, métricas Prometheus.

### Product service (Python / FastAPI + MongoDB)

- CRUD de productos con imágenes (Cloudinary), stock, precio y estados.
- Catálogo: listado, detalle y productos por vendedor; categorías predefinidas.
- Integración con user-service para datos del vendedor.
- Observabilidad: `/livez` y `/readyz`.

### Mobile app (React Native + Expo)

- Pantallas de login, registro, recupero de contraseña y OAuth con Google.
- Exploración de productos, detalle con galería de imágenes.
- Perfil propio (ver y editar) y publicación de productos.

### Backoffice (React + Vite)

- Login reservado a rol administrador.
- Panel de usuarios con búsqueda, bloqueo y desbloqueo.
- Dashboard con navegación a las secciones.

### Infraestructura

- Despliegue en Kubernetes (GKE) con Helm.
- Kong: enrutamiento, validación JWT, comprobación de rol admin, CORS.
- ArgoCD e Image Updater para despliegue continuo.
- CI por repositorio: tests y build de imágenes Docker.

---

## Arquitectura

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
                          └──────────┘    └──────────────┘
```

---

## Métricas del sprint

| Métrica | Valor |
|---------|------:|
| Historias de usuario (obligatorias) | 10 |
| Historias de usuario (optativas) | 2 |
| Puntos obligatorios (según enunciado) | 22 |
| Puntos optativos (según enunciado) | 5 |
| Servicios backend desplegados | 2 |
| Clientes (mobile + backoffice) | 2 |
