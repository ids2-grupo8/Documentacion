# Architecture Decision Records (ADR)

Registro de decisiones arquitectónicas del sistema Bazaar. Cada ADR sigue la plantilla de [Michael Nygard](https://github.com/architecture-decision-record/architecture-decision-record/blob/main/locales/en/templates/decision-record-template-by-michael-nygard/index.md).

## Convenciones

- **Ubicación:** `docs/adr/`
- **Nombre de archivo:** `adr-NNNN-titulo-corto.md` (numeración correlativa, 4 dígitos).
- **Plantilla:** [Plantilla ADR](plantilla.md)
- **Inmutabilidad:** una vez aceptado, el contenido no se edita. Si la decisión cambia, se crea un nuevo ADR que reemplaza al anterior y se marca el viejo como `Reemplazada por ADR-XXXX`.
- **Estados válidos:** Propuesta, Aceptada, Rechazada, Obsoleta, Reemplazada.

## Registro

| #                                                                       | Título                              | Estado   | Fecha      |
| ----------------------------------------------------------------------- | ----------------------------------- | -------- | ---------- |
| [0001](adr-0001-una-orden-por-vendedor-en-checkout.md)                  | Una orden por vendedor en checkout  | Aceptada | 2026-06-02 |
| [0002](adr-0002-kong-como-api-gateway.md)                               | Kong como API Gateway               | Aceptada | 2026-06-02 |
| [0003](adr-0003-stack-heterogeneo-python-go-postgres-mongo.md)          | Stack heterogéneo: Python+Go / PostgreSQL+MongoDB | Aceptada | 2026-06-02 |
| [0004](adr-0004-consistencia-distribuida-saga-compensacion.md)          | Consistencia distribuida — Saga con compensación basada en eventos | Aceptada | 2026-06-02 |
| [0005](adr-0005-resiliencia-http-retry-y-circuit-breaker.md)            | Resiliencia HTTP — Retry exponencial + Circuit Breaker | Aceptada | 2026-06-02 |
| [0006](adr-0006-despliegue-gke-en-gcp.md)                               | Despliegue en GKE sobre GCP         | Aceptada | 2026-06-02 |
| [0007](adr-0007-recomendaciones-en-home.md)                            | Recomendaciones personalizadas en Home | Aceptada | 2026-05-12 |
