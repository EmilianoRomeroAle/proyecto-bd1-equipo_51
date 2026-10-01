# Restricciones de Integridad y Reglas del SGBD

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  
**Autor:** Martín Miño  
**Etapa:** Etapa III — Implementación Física  

El presente documento analiza en profundidad el conjunto de restricciones técnicas implementadas en el script `sql/ddl/crear_bd.sql`. Estas reglas aseguran la integridad referencial, la integridad de dominio y la consistencia transaccional del negocio directamente en el motor de base de datos.

---

## 1. Integridad Referencial: Claves Foráneas (FK) y Acciones Referenciales

Las claves foráneas garantizan que ninguna relación contenga referencias a registros inexistentes. Para cada vínculo se definieron acciones específicas de actualización (`ON UPDATE`) y eliminación (`ON DELETE`):

| Clave Foránea | Tabla Origen $\rightarrow$ Tabla Destino | Acción ON UPDATE | Acción ON DELETE | Fundamento Operativo y Comercial |
| :--- | :--- | :--- | :--- | :--- |
| **`FK_PRODUCTO_CATEGORIA`** | `PRODUCTO` $\rightarrow$ `CATEGORIA` | `CASCADE` | `NO ACTION` (RESTRICT) | Si se reclasifica el código de una categoría, se propaga a los artículos asociados. Si se intenta borrar una categoría con productos en stock, la operación se bloquea para evitar artículos huérfanos. |
| **`FK_VENTA_CLIENTE`** | `VENTA` $\rightarrow$ `CLIENTE` | `CASCADE` | `NO ACTION` (RESTRICT) | Si se normaliza el documento de un cliente, se actualiza el histórico. Se prohíbe eliminar del padrón a clientes que posean compras registradas (RN.01 y auditoría fiscal). |
| **`FK_DETALLE_VENTA_VENTA`** | `DETALLE_VENTA` $\rightarrow$ `VENTA` | `CASCADE` | `CASCADE` | Los renglones de detalle son una entidad débil subordinada a la venta. Si por motivos administrativos una venta se descarta, sus ítems se eliminan en cascada. |
| **`FK_DETALLE_VENTA_PRODUCTO`** | `DETALLE_VENTA` $\rightarrow$ `PRODUCTO` | `CASCADE` | `NO ACTION` (RESTRICT) | Si el SKU de un producto se actualiza, se replica en los comprobantes. Se prohíbe eliminar físicamente del catálogo cualquier producto que ya figure en una venta emitida (RN.08). |
| **`FK_PAGA_CON_VENTA`** | `PAGA_CON` $\rightarrow$ `VENTA` | `CASCADE` | `CASCADE` | Los registros de cobros pertenecen a una venta específica. Si la cabecera de venta se elimina, se depuran en cascada sus asignaciones de cobro. |
| **`FK_PAGA_CON_METODO_PAGO`** | `PAGA_CON` $\rightarrow$ `METODO_PAGO` | `CASCADE` | `NO ACTION` (RESTRICT) | Si cambia el código de un método de pago se propaga. Se prohíbe borrar un medio de pago si existen transacciones históricas saldadas con ese instrumento. |

> **Nota técnica sobre Microsoft SQL Server:**  
> En el estándar T-SQL, `NO ACTION` representa el comportamiento equivalente a `RESTRICT` del estándar ANSI SQL: si existe algún registro dependiente en la tabla hija al momento de ejecutar la sentencia, el motor levanta un error y revierte la instrucción (*Rollback*).

---

## 2. Restricciones de Dominio (CHECK)

Las restricciones `CHECK` imponen reglas de validación sobre los valores permitidos en columnas individuales o entre columnas de la misma fila, impidiendo que ingresen datos corruptos o fuera de lógica de negocio:

### 2.1. Validaciones en `CLIENTE`
* **`CHK_CLIENTE_email` (`email LIKE '%_@__%.__%'`):**  
  Exige que todo correo electrónico registrado posea una estructura básica válida con `@` intermedio y dominio con punto posterior, evitando direcciones vacías o cadenas de texto inválidas.

### 2.2. Validaciones en `PRODUCTO`
* **`CHK_PRODUCTO_precio_lista` (`precio_lista > 0`):**  
  Ningún artículo puede poseer un precio de catálogo nulo o negativo.
* **`CHK_PRODUCTO_stock_actual` (`stock_actual >= 0`):**  
  El stock físico en depósito no puede ser inferior a cero (prohíbe existencias negativas).
* **`CHK_PRODUCTO_stock_reservado` (`stock_reservado >= 0`):**  
  El stock reservado no puede ser negativo.
* **`CHK_PRODUCTO_consistencia_stock` (`stock_reservado <= stock_actual`):**  
  **Regla de Negocio Crítica (RN.04).** Garantiza que las existencias comprometidas en ventas pendientes jamás superen las existencias físicas reales en depósito, impidiendo el fenómeno de sobreventa (*overselling*).

### 2.3. Validaciones en `VENTA`
* **`CHK_VENTA_monto_total` (`monto_total > 0`):**  
  Todo comprobante comercial debe reflejar un importe total estrictamente positivo.

### 2.4. Validaciones en `DETALLE_VENTA`
* **`CHK_DETALLE_VENTA_cantidad` (`cantidad > 0`):**  
  Exige que toda línea de compra contenga al menos 1 unidad del producto.
* **`CHK_DETALLE_VENTA_precio_unitario` (`precio_unitario >= 0`):**  
  Garantiza que el precio unitario pactado sea un valor no negativo (permite registrar bonificaciones excepcionales o artículos en promoción a costo cero sin admitir importes negativos).

### 2.5. Validaciones en `PAGA_CON`
* **`CHK_PAGA_CON_monto` (`monto > 0`):**  
  Todo pago imputado a un medio de cobro (sea parcial o total) debe ser mayor a cero, evitando registros ficticios de cobro sin valor económico.

---

## 3. Valores Predeterminados (DEFAULT)

Los valores predeterminados facilitan la consistencia de los datos en operaciones de alta en mostrador:

1. **`DF_PRODUCTO_stock_reservado` (`DEFAULT 0`):**  
   Al dar de alta un producto nuevo en el catálogo, sus existencias reservadas se inicializan en 0 automáticamente si no se especifican.
2. **`DF_VENTA_fecha_hora` (`DEFAULT CURRENT_TIMESTAMP`):**  
   Al crear una nueva orden de venta, el SGBD captura automáticamente la fecha y hora exacta del servidor en que se generó la transacción, asegurando la cronología e inmutabilidad temporal del comprobante.

---

## 4. Restricciones de Unicidad (UNIQUE)

Complementando a las claves primarias, se definieron restricciones `UNIQUE` para asegurar que ciertos datos no se repitan:
* **`UQ_CATEGORIA_nombre`:** No se admiten dos categorías con la misma denominación (ej. dos registros llamados "Procesadores").
* **`UQ_METODO_PAGO_nombre`:** Impide duplicar medios de cobro en el catálogo maestro.
* **`UQ_CLIENTE_email`:** Garantiza que cada cliente posea una cuenta de correo electrónico exclusiva en el padrón del negocio.
