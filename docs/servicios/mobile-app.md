# Mobile App

Cliente **React Native (Expo)** para compradores y vendedores: misma cuenta para ambos roles.

## Stack

| | |
|---|---|
| Lenguaje | TypeScript |
| Framework | React Native + Expo |
| Estado | Zustand (sesión, carrito, tema, datos de usuario) |
| API | Cliente al API Gateway (`users`, `products`, …) vía helpers en `constants/api` y `services/` |

## Responsabilidades (implementado)

- **Autenticación**: registro, login email/contraseña, recupero y nueva contraseña (deep link del enlace de Supabase hacia `reset-password`); login con **Google** (OAuth en navegador in-app + intercambio de tokens con el backend).
- **Catálogo y compra**: home con productos desde el **product-service**, filtros (categoría, texto, rango de precio), detalle por id, carrito persistente (hidrata desde almacenamiento).
- **Vendedor**: flujo de publicación de producto con imágenes; edición de perfil en pantalla dedicada.
- **Navegación**: Expo Router (tabs Home / Explore / Perfil más rutas de producto y vendedor); pestaña “Explore” aún con contenido plantilla de Expo.
- **Tema**: claro/oscuro/sistema coherente con la identidad visual del proyecto.

## Repositorio

[github.com/ids2-grupo8/mobileApp](https://github.com/ids2-grupo8/mobileApp)

Setup local: ver el `README` del repositorio.
