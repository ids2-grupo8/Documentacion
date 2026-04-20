# Backoffice

Aplicación web para **administradores**: gestión de usuarios y vistas operativas del marketplace.

## Stack

| | |
|---|---|
| Lenguaje | TypeScript |
| Framework | React (Vite) |
| API | Cliente HTTP al API Gateway (rutas bajo `/users/...` según prefijos configurables en `VITE_*`) |

## Responsabilidades (implementado)

- **Login**: email/contraseña contra el **user-service**; el cliente exige respuesta con rol administrador para ingresar al panel.
- **Usuarios**: listado con filtro de búsqueda y bloqueo/desbloqueo vía API real (incluye protección para no bloquearse a sí mismo el admin).
- **Métricas, productos y órdenes**: pantallas de métricas (KPIs y gráficos a partir de datos locales), moderación simulada de productos y bandeja de órdenes con **datos semilla en el front** (no hay microservicio de pedidos ni de moderación conectado en este cliente).
- **UI**: layout tipo dashboard (sidebar, tabs de sección, estética “liquid glass” alineada al diseño del proyecto).

## Repositorio

[github.com/ids2-grupo8/backoffice](https://github.com/ids2-grupo8/backoffice)

Setup local: ver el `README` del repositorio.
