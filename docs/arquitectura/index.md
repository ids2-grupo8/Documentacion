# Arquitectura del Sistema

## Visión general

Bazaar está construido como un conjunto de **microservicios independientes**, cada uno con su propia base de datos y responsabilidad bien definida. Los clientes (app mobile y backoffice web) nunca se comunican directamente con los servicios: todas las peticiones pasan por un **API Gateway** que se encarga del enrutamiento y la autenticación.

```
┌─────────────┐       ┌─────────────┐
│  Mobile App │       │  Backoffice │
│  (Expo)     │       │  (React)    │
└──────┬──────┘       └──────┬──────┘
       │                     │
       └──────────┬──────────┘
                  │
         ┌────────▼────────┐
         │   Kong Gateway  │  ← Punto único de entrada
         └───┬─────────┬───┘
             │         │
   ┌─────────▼───┐ ┌───▼──────────┐
   │user-service │ │product-service│
   │  (FastAPI)  │ │  (FastAPI)    │
   └──────┬──────┘ └───┬──────────┘
          │             │
   ┌──────▼──────┐ ┌───▼──────────┐
   │ PostgreSQL  │ │   MongoDB    │
   └─────────────┘ └──────────────┘
```

### ¿Por qué microservicios?

En lugar de tener toda la lógica en una sola aplicación, el sistema se divide en servicios más chicos que se pueden desarrollar, testear y desplegar de forma independiente. Cada servicio tiene su propia base de datos, lo que evita acoplamientos y permite que un equipo trabaje en un servicio sin afectar a los demás.

### ¿Qué hace el API Gateway?

Kong recibe todas las peticiones de los clientes y se encarga de:

- **Redirigirlas al servicio correcto** según la URL (ej: `/users/*` va al user-service, `/products/*` va al product-service).
- **Validar el token JWT** en las rutas que requieren autenticación.
- **Extraer la identidad del usuario** del token y pasarla como header al servicio backend, para que los servicios sepan quién está haciendo el request sin tener que parsear el token ellos mismos.
- **Verificar el rol de administrador** en las rutas del panel de admin.

---

## Servicios

| Servicio | Lenguaje / Framework | Base de datos | Responsabilidad |
|---|---|---|---|
| **user-service** | Python / FastAPI | PostgreSQL | Autenticación, perfiles, administración de usuarios |
| **product-service** | Python / FastAPI | MongoDB | Catálogo de productos, stock, imágenes, categorías |
| **backoffice** | TypeScript / React + Vite | — | Panel web de administración |
| **mobileApp** | TypeScript / React Native + Expo | — | App mobile para compradores y vendedores |

---

## Servicios externos

| Servicio | Para qué lo usamos |
|---|---|
| **Supabase Auth** | Maneja el registro, login, OAuth con Google y recupero de contraseña. Emite los JWT que usa todo el sistema. |
| **Cloudinary** | Almacena las imágenes de perfil y de productos. En la base de datos solo guardamos la URL. |

---

## Decisiones de tecnología

| Decisión | Qué elegimos | Por qué |
|---|---|---|
| BD del user-service | **PostgreSQL** | Los datos de usuarios tienen estructura fija y relaciones claras (usuario → identidades federadas). Una base relacional es lo más natural. |
| BD del product-service | **MongoDB** | Los productos pueden tener atributos distintos según la categoría (ej: talle en ropa, memoria en electrónica). Un modelo de documentos permite esa flexibilidad sin tener que alterar el esquema. |
| Autenticación | **Supabase Auth** | Nos da JWT, OAuth con Google, recupero de contraseña y gestión de sesiones sin tener que implementarlo desde cero. |
| Imágenes | **Cloudinary** | CDN con plan gratuito suficiente para el proyecto. Subimos la imagen y obtenemos una URL pública. |
| API Gateway | **Kong (OSS)** | Se integra nativamente con Kubernetes y permite agregar lógica custom con plugins Lua (validación de JWT, extracción de email, chequeo de rol admin). |
| Despliegue | **Kubernetes + ArgoCD** | Despliegue declarativo con GitOps: cuando se pushea una imagen nueva, ArgoCD detecta el cambio y actualiza el servicio automáticamente. |
