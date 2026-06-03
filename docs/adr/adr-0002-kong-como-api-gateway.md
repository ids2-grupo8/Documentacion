# ADR-0002: Kong como API Gateway

## Estado

Aceptada

**Fecha:** 2026-06-02

## Contexto

Bazaar está compuesto por varios microservicios backend desplegados en Kubernetes (`user-service`, `product-service`, `checkout-service`, `notification-service`), cada uno en su propio namespace y con su propia base de datos. Los clientes —backoffice web y app mobile— necesitan **un único punto de entrada** estable para consumir el sistema, en lugar de conocer la URL interna de cada servicio.

Ese punto único debe cumplir tres responsabilidades transversales que no tiene sentido reimplementar en cada microservicio:

1. **Enrutamiento** de cada path público (`/users/*`, `/products/*`, `/checkout/*`) al backend interno correspondiente, con reescritura de prefijo (`/users/auth/* → /api/v1/auth/*`).
2. **Validación del token de sesión** (JWT emitido por Supabase Auth) antes de que la request llegue a los servicios, rechazando tráfico no autenticado en el borde y propagando la identidad del usuario hacia adentro como header `X-User-Email`.
3. **Rate limiting** y otras políticas de tráfico (CORS, TLS termination) aplicables por ruta sin tocar el código de los servicios.

Alternativas consideradas:

- **NGINX Ingress** plano: liviano y conocido, pero la validación de JWT y el rate limiting requieren módulos extra (`lua-resty-jwt`, `limit_req`) y scripting manual; sin modelo declarativo nativo de plugins por ruta.
- **Traefik**: buena integración con Gateway API, pero los plugins de auth JWT y rate limit son de pago en la versión Enterprise o requieren middleware custom.
- **Kong OSS**: open source, despliegue self-hosted en el mismo cluster, soporta Gateway API (HTTPRoute), tiene plugins first-class para JWT, rate-limit, transformaciones y permite escribir plugins Lua propios (los necesitamos para `forward-email` y `require-admin`).

## Decisión

Adoptamos **Kong OSS v3.9** como API Gateway, desplegado en el cluster Kubernetes (namespace `kong`) en **modo sin base de datos**, configurado declarativamente vía Kong Ingress Controller y recursos Gateway API (`Gateway`, `HTTPRoute`, `ReferenceGrant`).

Configuración acordada:

- **Punto único de entrada:** `35.247.221.39.nip.io` con TLS (Let's Encrypt vía cert-manager) y listener HTTP:80 / HTTPS:443.
- **Enrutamiento:** un `HTTPRoute` por path público con filtro `URLRewrite` que mapea el prefijo externo al interno (`/api/v1/...`). Los servicios viven en otros namespaces y se referencian con `ReferenceGrant`.
- **Validación de tokens:** plugin `jwt` validando firma con el secret de Supabase (`supabase-jwt-secret`) y `exp`. Se aplica selectivamente a las rutas que requieren autenticación.
- **Propagación de identidad:** plugin Lua propio `forward-email` que extrae `claims.email` del JWT validado y lo inyecta como header `X-User-Email` hacia el backend. Los servicios confían en ese header (la validación ya ocurrió en el gateway) y devuelven 403 si falta.
- **Autorización admin:** plugin Lua propio `require-admin` que valida `claims.app_role == "admin"` para rutas administrativas.
- **Rate limiting:** se utilizará el plugin `rate-limiting` nativo de Kong por ruta cuando se identifiquen endpoints sensibles (login, webhooks). Se deja como capacidad disponible del gateway, configurable sin tocar código de los servicios.
- **GitOps:** todos los manifiestos viven en `infra/kong/`, ArgoCD sincroniza los cambios automáticamente.

## Consecuencias

**Positivas**

- Un único host público y un único certificado TLS para todo el sistema; los clientes no conocen URLs internas.
- Los servicios backend reciben tráfico **ya autenticado**: no implementan validación de JWT ni manejo de secret de Supabase; sólo leen `X-User-Email`. Esto simplifica los tests (no se montan llaves) y reduce el riesgo de divergencia en la validación entre servicios.
- Las políticas transversales (auth, CORS, rate-limit, transformaciones) se cambian declarando YAML en `infra/kong/`, sin redeploy de los servicios.
- Modelo declarativo + GitOps: el routing es auditable en git, revisable por PR y reproducible en cualquier cluster.
- Los plugins Lua propios cubren necesidades específicas (forward-email, require-admin) sin abandonar el ecosistema Kong.

**Negativas**

- Punto único de falla en el plano de tráfico: si Kong cae, todo el sistema queda inaccesible. Se mitiga con réplicas del Deployment y health checks de Kubernetes.
- Los servicios confían en `X-User-Email` sin re-verificar firma: si alguien expone un servicio por fuera de Kong, podría enviar el header directamente. Se mitiga manteniendo los `Service` como `ClusterIP` y exigiendo Kong como única ingress.
- Curva de aprendizaje extra: el equipo debe entender Gateway API, plugins de Kong y Lua básico para mantener `forward-email`/`require-admin`.
- Debug más indirecto: una request fallida puede deberse a un plugin de Kong (JWT inválido, rate-limit, rewrite mal) además del bug aplicativo; obliga a leer logs del gateway antes de los del servicio.

**Neutras**

- Kong OSS no incluye panel de administración: la configuración se gestiona 100% por archivos YAML versionados, lo que es consistente con la estrategia GitOps del proyecto.
- La elección de Gateway API (en lugar de Ingress clásico) condiciona la sintaxis de los HTTPRoutes pero da portabilidad a otras implementaciones de gateway si se necesitara migrar.
