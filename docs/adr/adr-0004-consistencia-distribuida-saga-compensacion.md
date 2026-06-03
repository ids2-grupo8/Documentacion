# ADR-0004: Consistencia distribuida — Saga con compensación basada en eventos

## Estado

Aceptada

**Fecha:** 2026-06-02

## Contexto

El flujo de checkout en Bazaar atraviesa **tres servicios y dos motores de datos distintos**:

1. `checkout-service` (PostgreSQL) crea las órdenes y orquesta el pago contra MercadoPago.
2. `product-service` (MongoDB) reserva stock y lo descuenta o lo libera al confirmarse/rechazarse el pago.
3. **MercadoPago** es un sistema externo que finaliza el cobro asincrónicamente vía webhook.

Cada uno de estos pasos puede fallar de manera independiente (timeouts HTTP, restart de pods, errores transitorios de Mongo, mensajes perdidos, webhook llegando duplicado), y la consigna exige que el sistema **no quede en estado inconsistente**: si el pago se confirma pero la creación/confirmación de la orden falla, el cobro debe revertirse o el stock debe liberarse; si las órdenes se crean pero el pago no se concreta, el stock reservado debe volver al catálogo.

Una transacción ACID distribuida (2PC/XA) no es viable: MercadoPago no participa de un commit coordinado, Postgres y MongoDB no comparten coordinator, y bloquear recursos durante todo el flujo degradaría el sistema. Por otro lado, hacer compensación **síncrona vía HTTP** acopla los servicios y propaga las fallas: si `product-service` está caído cuando `checkout-service` quiere ajustar stock, el checkout falla aunque el cobro ya haya sido válido.

Alternativas consideradas:

- **Transacciones distribuidas (2PC):** descartado por requerir coordinator común y bloqueos largos; además MercadoPago no lo soporta.
- **Llamadas HTTP sincrónicas con rollback manual:** simple de razonar pero frágil — un servicio caído interrumpe el flujo y deja estado parcial difícil de recuperar.
- **Saga orquestada por un servicio coordinador dedicado:** mayor claridad de control pero introduce un componente extra a mantener; con sólo dos pasos compensables no se justifica.
- **Saga coreografiada por eventos asíncronos:** cada servicio reacciona a eventos del broker; el desacople absorbe fallas temporales y permite reintentos sin acoplar deploys.

## Decisión

Adoptamos una **saga coreografiada con compensación basada en eventos**, implementada con RabbitMQ como broker y reforzada por cuatro mecanismos concretos:

1. **Reserve + confirm en `product-service`.** Antes de crear las órdenes, `checkout-service` llama síncronamente a `ProductServiceClient.reserve_products()`. La reserva descuenta stock "tentativo"; el descuento definitivo o la liberación ocurre después según el resultado del pago.

2. **Órdenes en estado `PAYMENT_PENDING`.** Las `Order` se crean en Postgres en estado pendiente. Sólo el webhook de MercadoPago las mueve a `CONFIRMED` o `REJECTED` — nunca quedan en un estado que asuma cobro sin confirmación.

3. **Eventos asíncronos vía RabbitMQ.** Al recibir el webhook, `checkout-service` publica en el exchange `bazaar.payments`:
    - `payment.confirmed` → `product-service` finaliza el descuento de stock.
    - `payment.rejected` → `product-service` libera la reserva (compensación).

   El payload incluye `event_id`, `order_ids`, `items` y `timestamp`.

4. **Garantías operativas del broker:**
    - **At-least-once delivery** con queues durables (`product.stock.confirm`, `product.stock.reject`) y mensajes `PERSISTENT`.
    - **Idempotencia en el consumer:** colección `processed_payment_events` en MongoDB con unique index sobre `event_id` y TTL de 30 días. Si llega un evento duplicado, el handler lo descarta.
    - **Dead Letter Exchange (`bazaar.payments.dlx`):** mensajes que fallan se mueven a las DLQs (`product.stock.confirm.dlq`, `product.stock.reject.dlq`) en lugar de re-encolarse infinitamente, permitiendo inspección y reproceso manual.
    - **`connect_robust`** en publisher y consumer: reconexión automática ante caídas de RabbitMQ.

5. **Idempotencia end-to-end del checkout** vía `idempotency_key`: un mismo intento de pago no genera órdenes duplicadas aunque el cliente reintente.

## Consecuencias

**Positivas**

- **Sin estado inconsistente persistente:** cada paso de la saga tiene su compensación explícita. Pago fallido → stock liberado; pago exitoso pero consumer caído → el mensaje queda durable y se procesa al recuperarse.
- **Desacople temporal:** si `product-service` está caído cuando llega el webhook, el evento queda encolado y se procesa al reanudarse, sin bloquear ni perder información.
- **Tolerancia a duplicados:** webhook de MercadoPago, retries del broker o reintentos del cliente no producen doble descuento de stock ni doble orden gracias a la doble idempotencia (`event_id` en consumer, `idempotency_key` en checkout).
- **Diagnóstico operativo:** las DLQs son el punto de inspección para fallas no transitorias; lo que llega ahí es una alerta accionable, no estado perdido.

**Negativas**

- **Consistencia eventual, no inmediata.** Entre que MercadoPago confirma y el consumer procesa el evento puede haber una ventana (segundos en condiciones normales) en la que la orden ya está `CONFIRMED` pero el stock todavía figura como reservado, no descontado. Es aceptable para el dominio, pero hay que diseñar las queries de catálogo sabiéndolo.
- **Complejidad operativa mayor:** hay que monitorear el broker, las DLQs y la conexión RabbitMQ además de los servicios HTTP. Mitigación: el modo degradado (`RABBITMQ_URL` no seteada) permite operar sin broker en tests y dev.
- **Mensajes en DLQ requieren intervención humana** (o un job de reproceso). El sistema no auto-resuelve fallas persistentes; las visibiliza.
- **El borde con MercadoPago sigue siendo "best-effort":** confiamos en que MP reenvíe el webhook si falla. No tenemos forma de "pull" del estado del pago.

**Neutras**

- La coreografía sin orquestador deja la lógica de la saga **distribuida en cada servicio**. Está documentada en [Sistema/RabbitMQ — Mensajería Async](../arquitectura/index.md) y reforzada por el ADR.
- El esquema actual asume dos eventos (`confirmed` / `rejected`); el exchange es `topic` para que agregar nuevos tipos no requiera cambiar la topología existente.
