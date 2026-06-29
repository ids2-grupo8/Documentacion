# Guía de usuario — Backoffice

Guía para **administradores** del marketplace. El backoffice es la aplicación web desde la
que se gestionan usuarios, se supervisan órdenes y se consultan las métricas del sistema.

!!! warning "Acceso restringido"
    El backoffice es **solo para administradores**. Si tu cuenta no tiene rol de
    administrador, no vas a poder ingresar aunque tus credenciales sean válidas.

---

## 1. Iniciar sesión

1. Abrí el backoffice en el navegador.
2. Ingresá tu **email** y **contraseña** de administrador.
3. Tocá **Ingresar**.

Si la cuenta no tiene rol admin, el sistema rechaza el acceso al panel.

---

## 2. El panel

Una vez dentro vas a ver un **dashboard** con una barra lateral para moverte entre secciones:

| Sección | Para qué sirve |
|---|---|
| **Usuarios** | Buscar usuarios y bloquear / desbloquear cuentas. |
| **Órdenes** | Consultar las órdenes del sistema (solo lectura). |
| **Productos** | Vista de moderación de publicaciones. |
| **Métricas** | KPIs y gráficos del estado del marketplace. |

---

## 3. Gestionar usuarios

1. Entrá a la sección **Usuarios**.
2. Usá el **buscador** para filtrar por email o nombre.
3. En cada usuario tenés la acción de **bloquear** o **desbloquear**:
   - **Bloquear** suspende la cuenta: ese usuario no podrá operar en la app.
   - **Desbloquear** la reactiva.

!!! note "Protección del propio admin"
    No podés bloquearte a vos mismo: la acción está deshabilitada sobre tu propia cuenta.

---

## 4. Consultar órdenes

1. Entrá a la sección **Órdenes**.
2. Vas a ver el listado de órdenes del sistema con su ID, comprador, fecha, estado y monto.
3. Podés **buscar por ID** de orden y **filtrar por estado**.
4. Tocá una orden para ver el **detalle completo**: comprador, vendedor, ítems e historial
   de transiciones.

!!! info "Solo lectura"
    Como administrador podés **consultar** las órdenes, pero **no modificar su estado**. El
    avance del envío lo maneja el vendedor desde la app mobile.

---

## 5. Métricas del sistema

En la sección **Métricas** encontrás los indicadores clave del marketplace:

- **Usuarios registrados** (totales y por período).
- **Órdenes por estado** y su evolución en el tiempo.
- **Monto transaccionado.**
- **Productos más vendidos.**

Podés elegir el **período** de análisis (por ejemplo, 7, 30 o 90 días) para ver la evolución
de cada indicador.

---

## 6. Moderación de productos

La sección **Productos** muestra las publicaciones para revisión y moderación.

!!! warning "Alcance actual"
    Algunas vistas del backoffice (parte de la moderación de productos y ciertas pantallas
    operativas) trabajan con **datos de ejemplo** en el cliente, ya que no todos los flujos
    tienen un microservicio conectado en esta versión. La gestión real conectada a la API
    es la de **usuarios**.

---

## Preguntas frecuentes

**Inicié sesión pero no me deja entrar.**
El acceso al backoffice requiere rol de administrador. Si tus credenciales son correctas
pero no entrás, tu cuenta probablemente no tiene ese rol asignado.

**¿Puedo cambiar el estado de una orden desde acá?**
No. El panel de órdenes es de solo lectura; el ciclo de envío lo gestiona el vendedor desde
la app mobile.

**¿Por qué no puedo bloquearme a mí mismo?**
Es una protección intencional para que un administrador no se deje a sí mismo sin acceso.
