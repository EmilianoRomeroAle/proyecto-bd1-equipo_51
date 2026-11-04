# Manejo de Permisos y Roles de Seguridad — Etapa V

**Equipo:** 51  
**Responsable del bloque:** Integrante 4  
**Motor:** Microsoft SQL Server Express · SSMS  
**Base de datos:** `tienda_hardware`

---

## 1. Definición y Objetivo

La seguridad en un motor de base de datos relacional como SQL Server permite regular el acceso a los datos y restringir las operaciones que cada entidad (usuario o proceso) puede realizar. 

El objetivo principal de este bloque es aplicar el **Principio de Mínimo Privilegio** sobre el sistema `tienda_hardware`. Esto garantiza que cada perfil de usuario tenga unicamente los accesos necesarios para cumplir con su rol operativo, evitando accesos directos indeseados, modificaciones no autorizadas o alteraciones accidentales sobre las tablas comerciales (`VENTA`, `DETALLE_VENTA`, `PRODUCTO`, `PAGA_CON`, `CLIENTE`, `CATEGORIA` y `METODO_PAGO`).

---

## 2. Ventajas y Aplicaciones

* **Protección de la Información Sensible:** Impide el acceso o alteración malintencionada de los registros del padrón de clientes y del historial transaccional de ventas.
* **Integridad de la Lógica de Negocio:** Al denegar permisos de modificación directa (`INSERT`, `UPDATE`, `DELETE`) sobre las tablas comerciales a los usuarios operativos y obligar el uso de los procedimientos almacenados desarrollados por los integrantes 1 y 2 (`usp_RegistrarVentaPendiente`, `usp_AgregarDetalleVenta`, `usp_RegistrarPago`, `usp_ConfirmarVenta`, `usp_CancelarVentasVencidas`), se garantiza que ninguna transacción saltee las restricciones de stock, precios históricos o estados de la venta.
* **Mantenibilidad y Escalabilidad:** El uso de **Roles de Base de Datos (`CREATE ROLE`)** permite agrupar privilegios y asignarlos masivamente a perfiles de usuarios. Al incorporarse nuevos empleados, solo basta con agregarlos al rol correspondiente sin reconfigurar permisos objeto por objeto.

---

## 3. Implementación en SQL Server Express

Se definieron e implementaron cuatro perfiles dentro del esquema `dbo` de la base de datos `tienda_hardware`:

### 3.1. Cuentas de Inicios de Sesión (Logins) y Usuarios

1. **`usuario_admin` / `usuario_admin_login`**: Cuenta con privilegios completos de administración. Se asocia al rol fijo de base de datos `db_owner`.
2. **`usuario_lector` / `usuario_lector_login`**: Cuenta de consulta destinada a personal de auditoría o catálogo.
3. **`usuario_operador` / `usuario_operador_login`**: Cuenta operativa asignada al personal de ventas y cobros.
4. **`usuario_sin_rol` / `usuario_sin_permisos_login`**: Cuenta de prueba sin permisos explícitos ni roles asignados para certificar el bloqueo preventivo del motor.

### 3.2. Roles Personalizados y Asignación de Permisos

* **Rol `rol_consulta_catalogo`:**
  * Permisos: `GRANT SELECT` sobre `dbo.PRODUCTO`, `dbo.CATEGORIA` y `dbo.CLIENTE`.
  * Miembros: `usuario_lector`.
* **Rol `rol_operador_ventas`:**
  * Permisos de lectura (`GRANT SELECT`) sobre las tablas necesarias para comprobaciones del sistema (`PRODUCTO`, `CLIENTE`, `METODO_PAGO`, `VENTA`, `DETALLE_VENTA`, `PAGA_CON`).
  * Permisos de ejecución (`GRANT EXECUTE`) sobre los procedimientos almacenados de negocio:
    * `dbo.usp_RegistrarVentaPendiente`
    * `dbo.usp_AgregarDetalleVenta`
    * `dbo.usp_RegistrarPago`
    * `dbo.usp_ConfirmarVenta`
    * `dbo.usp_CancelarVentasVencidas`
  * **Restricción clave:** No posee ningún permiso directo de `INSERT`, `UPDATE` o `DELETE` sobre las tablas del sistema.
  * Miembros: `usuario_operador`.

---

## 4. Pruebas y Resultados Obtenidos

Las pruebas fueron ejecutadas mediante la instrucción `EXECUTE AS USER = '...'` y revertidas con `REVERT`, permitiendo simular la suplantación de contexto dentro del script `sql/tecnico/pruebas/04_pruebas_seguridad.sql`.

| Caso | Usuario Simulado | Operación Evaluada | Resultado Esperado | Resultado Obtenido |
| --- | --- | --- | --- | --- |
| **P1** | `usuario_lector` | `SELECT` sobre `dbo.PRODUCTO` | Correcto (Lectura autorizada vía rol) | **ÉXITO**: Consulta ejecutada sin errores. |
| **P2** | `usuario_lector` | `INSERT` directo sobre `dbo.VENTA` | Error (Acceso denegado) | **CORRECTO**: SQL Server bloqueó la operación con error de permisos directos. |
| **P3** | `usuario_operador` | `EXEC dbo.usp_RegistrarVentaPendiente` | Correcto (Ejecución de SP autorizado) | **ÉXITO**: Se registró la venta mediante la lógica centralizada del SP. |
| **P4** | `usuario_operador` | `UPDATE` directo sobre `dbo.PRODUCTO` | Error (Acceso denegado) | **CORRECTO**: Se bloqueó la modificación directa sin pasar por los procedimientos. |
| **P5** | `usuario_sin_rol` | `SELECT` sobre `dbo.PRODUCTO` | Error (Acceso denegado por defecto) | **CORRECTO**: Bloqueo absoluto al carecer de asignación a roles. |

---

## 5. Alcance y Limitaciones

* **Alcance:** La solución cubre la separación de accesos administrativos, lectura de catálogo y ejecución de operaciones transaccionales a través de rutinas almacenadas para SQL Server Express.
* **Limitaciones:** 
  * Los permisos concedidos a un rol no bloquean a usuarios con el rol `db_owner` (administradores), quienes conservan acceso total al esquema.
  * No se implementó cifrado de datos en reposo (Transparent Data Encryption) ni cifrado a nivel de columna, por estar fuera del alcance de la asignatura.
  * Los inicios de sesión (`LOGINS`) utilizan contraseñas de demostración para el entorno de evaluación académica y no deben utilizarse en entornos de producción.