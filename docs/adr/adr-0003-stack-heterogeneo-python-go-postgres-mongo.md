# ADR-0003: Stack heterogéneo — Python + Go, PostgreSQL + MongoDB

## Estado

Aceptada

**Fecha:** 2026-06-02

## Contexto

La cátedra exige que el sistema combine **al menos dos lenguajes** distintos entre microservicios y **al menos dos motores de base de datos** distintos (uno relacional y uno no relacional). La consigna deja la elección abierta pero recomienda Python, Node.js o Go por ser los lenguajes donde el equipo docente puede acompañar mejor, y PostgreSQL y/o MongoDB como motores sugeridos.

El equipo cuenta con cuatro microservicios backend (`user-service`, `product-service`, `checkout-service`, `notification-service`) y debe distribuir lenguajes y motores entre ellos respetando dos criterios prácticos:

- **Familiaridad del equipo:** la mayor productividad y la menor cantidad de bugs se obtiene con lenguajes y motores que el grupo ya domina; el tiempo del cuatrimestre no alcanza para aprender un stack nuevo en cada servicio.
- **Encaje técnico con la naturaleza del dominio:**
    - Usuarios, carritos y órdenes son datos altamente relacionales, con esquema estable, integridad referencial fuerte (`buyer_email`, `seller_email`, FK a items) y transacciones que abarcan varias tablas.
    - El catálogo de productos, en cambio, requiere un esquema **flexible y dinámico**: cada categoría define sus propios atributos (`Electronics` no comparte campos con `Clothing`), las búsquedas son full-text y por filtros heterogéneos, y los productos se agregan/quitan a alta frecuencia.
    - Las notificaciones consumen eventos de RabbitMQ y persisten registros simples e idempotentes; conviene un runtime liviano, concurrente y con baja huella de memoria.

## Decisión

Adoptamos la siguiente distribución de lenguajes y motores entre los servicios backend:

| Servicio | Lenguaje / Framework | Base de datos | Motivo principal |
|---|---|---|---|
| `user-service` | **Python / FastAPI** | **PostgreSQL** | Familiaridad + datos relacionales (usuarios, roles, PIN, OAuth) |
| `product-service` | **Python / FastAPI** | **MongoDB** | Familiaridad + catálogo con atributos dinámicos por categoría y búsqueda full-text |
| `checkout-service` | **Python / FastAPI** | **PostgreSQL** | Familiaridad + transaccionalidad (carrito, órdenes, estados, idempotencia de pagos) |
| `notification-service` | **Go** | **MongoDB** | Familiaridad del subgrupo asignado + runtime liviano para un consumer de RabbitMQ |

Con esta combinación se cumplen **explícitamente** los dos requisitos de la cátedra:

- **Dos lenguajes distintos:** Python (tres servicios) y Go (`notification-service`).
- **Dos motores distintos:** PostgreSQL (relacional, en `user-service` y `checkout-service`) y MongoDB (no relacional, en `product-service` y `notification-service`).

## Consecuencias

**Positivas**

- **Productividad:** el grueso del backend está en Python/FastAPI, el stack más conocido por el equipo; eso nos permite avanzar rápido con los CRUDs y la lógica de negocio en el tiempo disponible del cuatrimestre.
- **Encaje del modelo de datos:**
    - PostgreSQL cubre los servicios con esquema fijo y transacciones (orden + items + estado avanzan juntos).
    - MongoDB se aprovecha realmente: el catálogo guarda documentos heterogéneos por categoría sin migraciones y el full-text index resuelve la búsqueda nativamente.
- **Go en `notification-service`** aporta un runtime concurrente y de baja memoria ideal para un consumer de RabbitMQ que vive idle la mayor parte del tiempo, y cumple el requisito de heterogeneidad de lenguajes sin obligar a aprender un stack desconocido (el subgrupo asignado ya lo conoce).
- Heterogeneidad cumplida **sin fragmentación excesiva:** dos lenguajes y dos motores, no cuatro de cada uno; el costo operativo de Docker images, dependencias y CI se mantiene acotado.

**Negativas**

- **Dos runtimes distintos en CI/CD y producción:** pipelines, Dockerfiles base, observabilidad y manejo de dependencias se duplican (pip + go modules, pytest + go test). Mitigación: cada servicio tiene su propio `Dockerfile` y workflow de GHCR; ArgoCD las despliega con la misma estrategia.
- **Dos motores de base de datos distintos:** los tests de integración requieren tanto un Postgres como un MongoDB; el equipo debe conocer ambos lenguajes de consulta (SQL + queries/aggregations de Mongo) y dos modelos de migración (Alembic vs. evolución de schema "soft" en Mongo).
- **Conocimiento desigual:** Go vive sólo en un servicio; si el subgrupo que lo mantiene no está disponible, el resto del equipo tarda más en intervenir ahí. Mitigación: mantener `notification-service` pequeño y bien documentado, y limitar su responsabilidad a consumir eventos.

**Neutras**

- La comunicación entre servicios es agnóstica del lenguaje: HTTP (Kong) y RabbitMQ (eventos). El stack heterogéneo no introduce acoplamiento, sólo políglota a nivel deployment.
- La elección no condiciona futuras incorporaciones: si más adelante un servicio justifica Node.js u otro lenguaje, puede integrarse sin romper el resto del sistema.
