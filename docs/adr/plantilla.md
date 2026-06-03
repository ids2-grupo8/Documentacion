# ADR-NNNN: [Título corto de la decisión]

!!! info "Plantilla"
    Basada en [Michael Nygard — Documenting Architecture Decisions](https://github.com/architecture-decision-record/architecture-decision-record/blob/main/locales/en/templates/decision-record-template-by-michael-nygard/index.md), traducida al español.

## Estado

[Propuesta | Aceptada | Rechazada | Obsoleta | Reemplazada por ADR-XXXX]

**Fecha:** YYYY-MM-DD

## Contexto

Describir las fuerzas en juego, incluyendo factores técnicos, políticos, sociales y del proyecto. Estas fuerzas probablemente están en tensión y deben ser explicitadas. La redacción de esta sección es **descriptiva**, en tiempo presente y en lenguaje neutral: se limita a enunciar hechos.

## Decisión

Describir la respuesta que se da a esas fuerzas. Se redacta en voz activa y con frases completas: *"Vamos a..."*, *"Adoptamos..."*, *"Reemplazamos X por Y..."*.

## Consecuencias

Describir el contexto resultante luego de aplicar la decisión. Listar **todas** las consecuencias —positivas, negativas y neutras— porque todas afectan al equipo y al proyecto en el futuro.

---

## Cómo usar esta plantilla

1. Copiar este archivo a `docs/adr/adr-NNNN-titulo-corto.md`, usando el siguiente número correlativo libre.
2. Completar los cuatro apartados. Mantener el ADR **corto** (1–2 páginas): una decisión por archivo.
3. Agregar la entrada al [registro del índice](index.md#registro).
4. Registrar el archivo en `mkdocs.yml` bajo la sección `ADR`.
5. Una vez aceptado, **no editar el contenido**: si la decisión cambia, crear un nuevo ADR que reemplace al anterior.
