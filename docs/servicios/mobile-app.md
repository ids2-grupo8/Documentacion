# Mobile App

Cliente **React Native (Expo)** para compradores y vendedores: la misma cuenta habilita ambos roles sin fricción. Se distribuye como app nativa (Android/iOS) y como **PWA** (deploy web en Vercel).

## Stack

| | |
|---|---|
| Lenguaje | TypeScript |
| Framework | React Native + Expo (Expo Router) |
| Estado | Zustand (sesión, carrito, tema, notificaciones, datos de usuario) |
| API | Cliente al API Gateway (`users`, `products`, `checkout`, `notification`) vía helpers en `constants/api` y `services/` |
| Pagos | MercadoPago (checkout hosteado) |
| Push | Expo Push Notifications (nativo) + Web Push (PWA) |

Toda la comunicación pasa **exclusivamente** por el API Gateway; la app no llama directo a los servicios backend.

## Navegación

Barra inferior flotante con cinco pestañas:

- **Inicio** — descubrimiento: banner promocional activo, accesos rápidos por categoría, sección "Lo nuevo" y recomendaciones.
- **Explorar** — búsqueda en vivo (debounced), filtros (categoría, rango de precio), orden y chips de filtros activos.
- **Carrito** — gestión del carrito y paso al checkout.
- **Notificaciones** — cambios de estado de las órdenes.
- **Perfil** — cuenta, compras, ventas, publicaciones y preferencias.

Más rutas stack: detalle de producto, reviews, perfil público de vendedor, checkout, órdenes y publicación.

## Responsabilidades

- **Autenticación**: registro, login email/contraseña, recupero y nueva contraseña (deep link de Supabase hacia `reset-password`), login con **Google** (OAuth in-app + intercambio de tokens), **PIN** ligado al dispositivo (opcional, con vinculación sugerida), refresh token sin re-login y manejo de cuenta suspendida / rate limit.
- **Catálogo**: home de descubrimiento + recomendaciones basadas en historial (product-service con JWT); búsqueda en vivo y filtros (categoría, texto, rango de precio) con orden; detalle de producto con descripción y especificaciones colapsables; compartir link directo (deep link); registro de vistas recientes.
- **Carrito**: persistente entre sesiones (SecureStore), sincronización con backend y verificación de stock antes del checkout; manejo de items no disponibles.
- **Checkout y órdenes**: pago con **MercadoPago**, cupones de descuento (validación + cupón activo), dirección de envío y pantallas de éxito / pendiente / fallo; historial de compras y ventas, detalle de orden y transiciones de estado (en preparación, enviada con código de seguimiento).
- **Reviews / reputación**: calificar **producto** y **vendedor** (UI de medias estrellas), sólo sobre órdenes **entregadas** (validado en checkout-service); reputación agregada del producto en su detalle y perfil público de reputación del vendedor.
- **Vendedor**: publicación de producto con imágenes (multipart), gestión de publicaciones (con estado de moderación) y órdenes de venta.
- **Notificaciones**: notificaciones in-app de cambio de estado de orden (abren el detalle) y **push** (Expo nativo + Web Push en PWA) con banner de opt-in y registro de dispositivo.
- **Perfil**: visualización y edición, avatar, estadísticas, configuración de PIN y tema.
- **Tema**: claro / oscuro / sistema, coherente con la identidad visual del proyecto.

## Resiliencia

Cliente HTTP con reintentos, manejo explícito de loading/error, timeouts y expiración de sesión (redirección a login conservando contexto cuando es posible).

## Repositorio

[github.com/ids2-grupo8/mobileApp](https://github.com/ids2-grupo8/mobileApp)

Setup local: ver el `README` del repositorio.
