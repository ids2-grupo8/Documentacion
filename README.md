# Bazaar — Documentación

Documentación del proyecto Bazaar (Grupo 8 — Ingeniería de Software II).

**Sitio web:** https://ids2-grupo8.github.io/Documentacion/site/

Sitio construido con [MkDocs](https://www.mkdocs.org/) + tema
[Material](https://squidfunk.github.io/mkdocs-material/). Los diagramas C4 se generan desde
`docs/arquitectura/workspace.dsl` (Structurizr DSL) y se renderizan con
[Kroki](https://kroki.io/) vía `mkdocs-kroki-plugin`.

## Contenido

- **Sprints** — seguimiento de los 4 sprints.
- **Arquitectura** — resumen y diagramas C4 (contexto, contenedores, componentes).
- **API** — contratos OpenAPI/Swagger de los servicios.
- **Guías de usuario** — app mobile y backoffice.
- **ADR** — registro de decisiones de arquitectura.
- **Pruebas de carga** — resultados y optimizaciones.
- **Retrospectiva** — retrospectiva final del proyecto.

## Setup local

Requisitos: **Python 3.10+** y `pip`.

```bash
# 1. Clonar el repo
git clone https://github.com/ids2-grupo8/Documentacion.git
cd Documentacion

# 2. (Opcional) crear un entorno virtual
python -m venv .venv && source .venv/bin/activate

# 3. Instalar dependencias
pip install -r requirements.txt
```

### Renderizar los diagramas C4 (Kroki)

Los diagramas usan un servidor Kroki. Levantá uno local con Docker:

```bash
docker run -d -p 8001:8000 yuzutech/kroki
export KROKI_SERVER_URL=http://localhost:8001
```

> Si no levantás Kroki, el sitio igual compila pero los diagramas C4 no se renderizan.

### Previsualizar el sitio

```bash
mkdocs serve
# Abrir http://127.0.0.1:8000
```

### Build estático

```bash
mkdocs build   # genera el sitio en site/
```

## Despliegue

El sitio se publica automáticamente en GitHub Pages mediante el workflow
`.github/workflows/deploy.yml` al pushear a `main`.
