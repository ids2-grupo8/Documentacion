# Retrospectiva final del proyecto

**Proyecto:** Bazaar — Marketplace
**Grupo 8** — Ingeniería de Software II
**Período:** 27/03/2026 — 29/06/2026 (4 sprints)
**Puntos totales entregados:** 95

---

## Resumen del recorrido

Arrancamos en el Sprint 1 montando las bases: infraestructura en GKE, API Gateway con Kong,
CI/CD por repositorio y los primeros flujos de autenticación y catálogo. En el Sprint 2
completamos el core de compra (home, búsqueda, carrito y checkout con Mercado Pago). El
Sprint 3 cerró el ciclo post-compra (seguimiento de órdenes, historiales, reseñas con
reputación, cupones y métricas en el backoffice). Finalmente, el Sprint 4 sumó las
notificaciones push (mobile y web) con un nuevo microservicio en Go, y endureció el flujo
crítico de compra con pruebas de carga y un set de optimizaciones de resiliencia.

Terminamos con un marketplace funcional de punta a punta: el mismo usuario puede comprar y
vender, pagar con Mercado Pago, seguir sus órdenes y recibir notificaciones, mientras los
administradores gestionan usuarios, órdenes y métricas desde el backoffice.

---

## Qué salió bien 👍

- **La arquitectura de microservicios se sostuvo.** Dividir por dominio (user, product,
  checkout, notification) nos permitió trabajar en paralelo sin pisarnos y desplegar cada
  servicio de forma independiente. *Database per service* evitó acoplamientos.
- **El API Gateway centralizó lo transversal.** Validar JWT y propagar identidad en Kong
  (ver [ADR-0002](adr/adr-0002-kong-como-api-gateway.md)) simplificó muchísimo los
  servicios: no tuvieron que reimplementar autenticación cada uno.
- **GitOps con ArgoCD.** Una vez configurado, desplegar fue pushear y olvidarse. El estado
  del cluster quedó versionado y auditable.
- **La saga de stock por eventos funcionó.** Desacoplar el descuento de stock del cobro
  (ver [ADR-0004](adr/adr-0004-consistencia-distribuida-saga-compensacion.md)) nos evitó
  problemas de consistencia y nos dio idempotencia ante reintentos.
- **Cerramos con hardening real, no improvisado.** Las pruebas de carga con k6 en el Sprint 4
  nos dieron números concretos para decidir las optimizaciones (retry + circuit breaker,
  cache, pool de conexiones).

---

## Qué nos costó 👎

- **La complejidad operativa de los microservicios.** Debuggear un request que pasa por
  Kong, un servicio y RabbitMQ es más indirecto que en un monolito: hay que mirar varios
  logs antes de encontrar la causa.
- **La integración con Mercado Pago.** Las credenciales, URLs de notificación y el webhook
  dependían del entorno y nos costó tener pruebas E2E estables. Lo mitigamos con un modo
  mock para poder desarrollar y hacer load testing sin pegarle al sandbox real.
- **Coordinación de contratos entre front y back.** Cuando cambiaba un endpoint, el cliente
  a veces se enteraba tarde. Apoyarnos más temprano en el OpenAPI autogenerado hubiera
  ayudado.

---

## Qué aprendimos 💡

- Invertir el tiempo necesario en infraestructura y en el gateway al principio nos ahorro muchos posibles dolores de cabeza.
- La consistencia eventual por eventos es poderosa pero es necesario que sea idempotente,
  *dead letter queues* y pensar bien los reintentos desde el día uno.
- Medir antes de optimizar. Las pruebas de carga nos mostraron que el cuello estaba en el
  checkout y en las llamadas HTTP entre servicios, no donde lo intuíamos.
- Documentar decisiones en el momento (ADRs) aclara las ideas y evita rediscutir después.

---

## Métricas finales

| Sprint | Obligatorios | Optativos | Total |
|--------|-----:|-----:|------:|
| Sprint 1 | 22 | 7 | 29 |
| Sprint 2 | 24 | 7 | 31 |
| Sprint 3 | 17 | 11 | 28 |
| Sprint 4 | 0  | 7  | 7  |
| **Total** | **63** | **32** | **95** |

| | |
|---|---:|
| Microservicios backend | 4 (user, product, checkout, notification) |
| Clientes | 2 (mobile + backoffice) |
| ADRs registrados | 7 |
| Servicios externos integrados | Supabase, Cloudinary, Mercado Pago, Expo Push |

---

## Cierre

Bazaar nos sirvió para llevar a la práctica un sistema distribuido completo: desde la
infraestructura y el despliegue continuo hasta los patrones de resiliencia y la mensajería
orientada a eventos. Más allá de las funcionalidades, nos llevamos la experiencia de
diseñar, discutir y documentar decisiones de arquitectura en equipo.
