# Cómo ejecutar las pruebas

Guía para correr el suite de carga + estrés localmente.

## Requisitos

- **Docker Desktop** corriendo.
- **k6** instalado. En Windows con Chocolatey: `choco install k6`. Con winget: `winget install k6.k6`. Verificar con `k6 version`.
- **Python 3.12+** con `pymongo`, `bson` y `psycopg2` (el venv del proyecto los tiene).

## Pasos

### 1. Levantar el stack completo

Desde `notification-service/` (donde vive el `compose.yml` que orquesta todos los servicios + RabbitMQ + Mongo + Postgres):

```powershell
docker compose up -d --build
```

El servicio `checkout-service` corre `alembic upgrade head` automáticamente al iniciar (configurado vía `command:` en el compose), así que **no hace falta correr migraciones aparte**.

Verificar que los servicios críticos estén `healthy`:

```powershell
docker ps --format "table {{.Names}}\t{{.Status}}" | Select-String -Pattern "checkout|product|user|mongo|rabbit"
```

### 2. Sembrar datos de prueba

Desde `checkout-service/`:

```powershell
python load-tests\seed.py
```

Inserta 10 productos en MongoDB y un usuario vendedor. Genera `load-tests/product_ids.json` con los ObjectIds reales, que los scripts k6 leen al arrancar.

### 3. Correr load test (~3m30s)

```powershell
k6 run --no-color `
  --summary-export load-tests\results\load_summary.json `
  load-tests\load_test.js
```

k6 puede salir con código 99 si se cruzan umbrales — es esperado, no es error.

### 4. Correr stress test (~4m)

```powershell
k6 run --no-color `
  --summary-export load-tests\results\stress_summary.json `
  load-tests\stress_test.js
```

### 5. Generar reporte

```powershell
python load-tests\generate_report.py
```

Lee los dos `*_summary.json` y produce `load-tests/results/RESULTS.md` con tablas, percentiles, umbrales y un diagnóstico automático.

### 6. (Opcional) Limpiar

```powershell
python load-tests\seed.py teardown
```

Elimina los 10 productos seed y el usuario vendedor.

## Pipeline automatizado (bash)

Si usás Git Bash o WSL, hay un script que orquesta todo:

```bash
bash load-tests/run_tests.sh
```

Flags útiles:

- `--skip-seed` — saltea el seed (datos ya cargados).
- `--skip-teardown` — mantiene los datos al terminar.

## Modo mock de MercadoPago

El `compose.yml` activa por default `MERCADOPAGO_MOCK_MODE=true`. Eso hace que `checkout-service` devuelva respuestas sintéticas en lugar de pegarle a MP sandbox. Beneficios:

- Las corridas no consumen rate-limit ni tokens de MP.
- Los números reflejan **el sistema propio**, sin la latencia del integrador externo.

Para correr contra MP real:

```powershell
$env:MERCADOPAGO_MOCK_MODE = "false"
docker compose up -d --force-recreate checkout-service
```

Recordá tener configurado `MERCADOPAGO_ACCESS_TOKEN` en el `.env` antes de desactivar el mock.

## Troubleshooting

### `open ./product_ids.json: no such file`

Falta el seed. Correr `python load-tests/seed.py`.

### `cart add → 2xx: 0%`

El flujo no se está validando. Probable: `product-service` no expone el endpoint que `checkout-service` está pegando, o el seed apunta a IDs que no existen. Validá manualmente con `curl`:

```powershell
$pid = (Get-Content load-tests\product_ids.json | ConvertFrom-Json)[0]
curl -i "http://localhost:8000/api/v1/products/$pid"
curl -i -X POST "http://localhost:8002/api/v1/cart/items" `
  -H "Content-Type: application/json" `
  -H "X-User-Email: test@test.com" `
  -d "{`"product_id`":`"$pid`",`"quantity`":1}"
```

El reporte (`RESULTS.md`) también incluye un **diagnóstico data-driven** que cuando detecta `cart_add < 50%` lista las causas más probables ordenadas.

### `UnicodeEncodeError: 'charmap' codec` al generar el reporte

PowerShell ejecuta Python en cp1252 por default. Solución:

```powershell
$env:PYTHONUTF8 = "1"
python load-tests\generate_report.py
```

(El generador ya pasa `encoding="utf-8"` al `open`, pero algunos entornos lo ignoran.)

### Los contenedores no toman cambios de código

`docker compose up -d` sin `--build` reutiliza la imagen vieja. Forzar:

```powershell
docker compose up -d --build --force-recreate checkout-service
```

### Tablas no existen en `checkout-db`

Verificar que el `command:` del compose esté presente para `checkout-service` (corre `alembic upgrade head` al arrancar). Si por alguna razón falla, correr manualmente:

```powershell
docker compose exec checkout-service alembic upgrade head
```
