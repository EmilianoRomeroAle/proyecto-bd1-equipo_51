# Implementación física

**Asignatura:** Bases de Datos I, año 2026

**Equipo:** 51

**Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware

**Autor:** Nuñez Axel Gabriel

**Etapa:** III

## 1. Scripts y motor

La implementación utiliza Microsoft SQL Server y sintaxis T-SQL. Los scripts se pueden abrir en SQL Server Management Studio (SSMS). `GO` separa los lotes que ejecuta la herramienta.

| Archivo | Contenido |
| --- | --- |
| `sql/ddl/crear_bd.sql` | Creación de `tienda_hardware`, siete tablas y sus restricciones. |
| `sql/dml/datos_prueba.sql` | Carga de categorías, medios de pago, clientes, productos, ventas, detalles y pagos. |

## 2. Orden de ejecución

1. Trabajar sobre una base sin las tablas del proyecto y ejecutar `crear_bd.sql`.
2. Revisar que se hayan creado las siete tablas y sus restricciones.
3. Ejecutar una sola vez `datos_prueba.sql`.
4. Realizar los controles indicados en `pruebas-validacion.md`.

El DDL crea la base si no existe, pero no elimina ni reemplaza tablas existentes. El DML tampoco borra datos anteriores: repetirlo sobre el mismo lote produce claves duplicadas.

Las tablas referenciadas se crean antes que sus dependientes. La carga sigue el mismo criterio: primero los catálogos y clientes, después los productos y ventas, y al final los detalles y pagos.

## 3. Tablas y claves

| Tabla | Clave primaria | Referencias |
| --- | --- | --- |
| `CATEGORIA` | `codigo_categoria` | No tiene. |
| `METODO_PAGO` | `codigo_metodo` | No tiene. |
| `CLIENTE` | `dni_cuit` | No tiene. |
| `PRODUCTO` | `sku` | `codigo_categoria` referencia a `CATEGORIA`. |
| `VENTA` | `codigo_venta` | `dni_cuit` referencia a `CLIENTE`. |
| `DETALLE_VENTA` | `(codigo_venta, id)` | `codigo_venta` referencia a `VENTA`; `sku`, a `PRODUCTO`. |
| `PAGA_CON` | `(codigo_venta, codigo_metodo)` | `codigo_venta` referencia a `VENTA`; `codigo_metodo`, a `METODO_PAGO`. |

El `id` del detalle es un entero positivo que identifica el renglón dentro de una venta. Puede repetirse en ventas diferentes. En `PAGA_CON` se guarda un monto acumulado por cada combinación de venta y medio.

## 4. Tipos de datos y valores

Los importes `precio_lista`, `monto_total`, `precio_uni_historico` y `monto_abonado` usan `DECIMAL(12, 2)`. Las cantidades y existencias usan `INT`. El DNI/CUIT y el SKU se almacenan como texto.

`VENTA.estado` es `VARCHAR(10) NOT NULL`. Admite `Pendiente`, `Abonado` y `Cancelado`, con `Pendiente` como valor predeterminado. La fecha y hora usa `DATETIME` y tiene como valor predeterminado `CURRENT_TIMESTAMP`.

El precio histórico se guarda en el detalle, separado del precio de lista del producto. El stock disponible no se almacena: se calcula como `stock_actual - stock_reservado`.

El DDL establece claves, obligatoriedad y condiciones sobre los valores de las filas. La igualdad entre los totales de cabecera, detalles y pagos se comprueba con las consultas de control de esta etapa.

## 5. Contenido del lote de prueba

El DML contiene 10 categorías, 8 medios de pago, 10 clientes, 10 productos, 10 ventas, 17 detalles y 14 pagos. Las ventas están en estado `Abonado` y sus importes coinciden con los detalles y pagos.

Las existencias representan el stock al momento de la carga. Todos los productos tienen `stock_reservado = 0`, porque el lote no contiene ventas pendientes. No corresponde volver a descontar estas ventas históricas del stock cargado.
