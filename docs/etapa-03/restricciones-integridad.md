# Restricciones de integridad

**Asignatura:** Bases de Datos I, año 2026

**Equipo:** 51

**Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware

**Autor:** Martín Miño

**Etapa:** III

Este documento describe las restricciones declaradas en `sql/ddl/crear_bd.sql`.

## 1. Claves primarias y datos obligatorios

Las claves primarias son `PK_CATEGORIA`, `PK_METODO_PAGO`, `PK_CLIENTE`, `PK_PRODUCTO`, `PK_VENTA`, `PK_DETALLE_VENTA` y `PK_PAGA_CON`. Impiden repetir la clave de cada tabla.

`PK_DETALLE_VENTA` utiliza `(codigo_venta, id)`: el número de renglón solo debe ser único dentro de su venta. `PK_PAGA_CON` utiliza `(codigo_venta, codigo_metodo)`: admite un registro por medio de pago y venta.

Todas las columnas son `NOT NULL`, excepto `PRODUCTO.descripcion_tecnica`. En particular, el cliente debe tener correo y teléfono, y cada venta debe tener cliente y estado. `NOT NULL` rechaza valores nulos; por sí solo no rechaza cadenas vacías.

## 2. Claves foráneas

| Restricción | Referencia | ON UPDATE | ON DELETE |
| --- | --- | --- | --- |
| `FK_PRODUCTO_CATEGORIA` | `PRODUCTO.codigo_categoria` → `CATEGORIA.codigo_categoria` | `CASCADE` | `NO ACTION` |
| `FK_VENTA_CLIENTE` | `VENTA.dni_cuit` → `CLIENTE.dni_cuit` | `CASCADE` | `NO ACTION` |
| `FK_DETALLE_VENTA_VENTA` | `DETALLE_VENTA.codigo_venta` → `VENTA.codigo_venta` | `CASCADE` | `CASCADE` |
| `FK_DETALLE_VENTA_PRODUCTO` | `DETALLE_VENTA.sku` → `PRODUCTO.sku` | `CASCADE` | `NO ACTION` |
| `FK_PAGA_CON_VENTA` | `PAGA_CON.codigo_venta` → `VENTA.codigo_venta` | `CASCADE` | `CASCADE` |
| `FK_PAGA_CON_METODO_PAGO` | `PAGA_CON.codigo_metodo` → `METODO_PAGO.codigo_metodo` | `CASCADE` | `NO ACTION` |

Las FK rechazan referencias a registros inexistentes. `ON UPDATE CASCADE` propaga el cambio de la clave referenciada. `ON DELETE NO ACTION` rechaza la eliminación si existen filas dependientes, sin importar el stock o estado de esas filas. `ON DELETE CASCADE` elimina las filas dependientes de la venta cuando se elimina su cabecera; esta acción referencial no distingue estados.

## 3. Condiciones CHECK

| Restricción | Condición |
| --- | --- |
| `CHK_CLIENTE_email` | `email LIKE '%_@__%.__%'` |
| `CHK_PRODUCTO_precio_lista` | `precio_lista > 0` |
| `CHK_PRODUCTO_stock_actual` | `stock_actual >= 0` |
| `CHK_PRODUCTO_stock_reservado` | `stock_reservado >= 0` |
| `CHK_PRODUCTO_consistencia_stock` | `stock_reservado <= stock_actual` |
| `CHK_VENTA_monto_total` | `monto_total > 0` |
| `CHK_VENTA_estado` | `estado IN ('Pendiente', 'Abonado', 'Cancelado')` |
| `CHK_DETALLE_VENTA_id` | `id > 0` |
| `CHK_DETALLE_VENTA_cantidad` | `cantidad > 0` |
| `CHK_DETALLE_VENTA_precio_uni_historico` | `precio_uni_historico >= 0` |
| `CHK_PAGA_CON_monto_abonado` | `monto_abonado > 0` |

El patrón del correo comprueba una estructura básica; no demuestra que la dirección exista. La consistencia de stock compara las dos columnas de un producto. El estado se limita a tres valores, sin validar mediante ese `CHECK` la suma de pagos ni las transiciones entre estados.

El precio de lista debe ser positivo. El precio histórico admite cero, mientras que la cantidad y cada importe abonado deben ser mayores que cero.

## 4. Unicidad

| Restricción | Columna |
| --- | --- |
| `UQ_CATEGORIA_nombre` | `CATEGORIA.nombre_categoria` |
| `UQ_METODO_PAGO_nombre` | `METODO_PAGO.nombre_metodo` |
| `UQ_CLIENTE_email` | `CLIENTE.email` |

Estas restricciones evitan repetir nombres de categorías, nombres de medios y correos de clientes.

## 5. Valores predeterminados

| Restricción | Columna | Valor |
| --- | --- | --- |
| `DF_PRODUCTO_stock_reservado` | `PRODUCTO.stock_reservado` | `0` |
| `DF_VENTA_estado` | `VENTA.estado` | `'Pendiente'` |
| `DF_VENTA_fecha_hora` | `VENTA.fecha_hora` | `CURRENT_TIMESTAMP` |

El valor predeterminado se aplica al omitir la columna en una inserción. No impide indicar otro valor admitido y no reemplaza un `NULL` explícito.
