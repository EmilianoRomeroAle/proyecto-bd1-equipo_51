# Modelo Relacional - EmpresaHardware

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  
**Responsable:** Nuñez Tobias Nahuel (DNI: 46316154)  
**Repositorio:** https://github.com/EmilianoRomeroAle/proyecto-bd1-equipo_51  

## 1. Tablas, claves primarias y claves foráneas

El modelo relacional contiene siete tablas. Las claves primarias identifican cada fila y las claves foráneas representan las relaciones entre ellas.

| Tabla y atributos | Clave primaria | Claves foráneas |
| :--- | :--- | :--- |
| CLIENTE (dni_cuit, nombre, apellido, email, telefono) | dni_cuit | — |
| CATEGORIA (codigo_categoria, nombre_categoria) | codigo_categoria | — |
| PRODUCTO (sku, marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria) | sku | codigo_categoria → CATEGORIA(codigo_categoria) |
| METODO_PAGO (codigo_metodo, nombre_metodo) | codigo_metodo | — |
| VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit) | codigo_venta | dni_cuit → CLIENTE(dni_cuit) |
| DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico) | (codigo_venta, id) | codigo_venta → VENTA(codigo_venta); sku → PRODUCTO(sku) |
| PAGA_CON (codigo_venta, codigo_metodo, monto_abonado) | (codigo_venta, codigo_metodo) | codigo_venta → VENTA(codigo_venta); codigo_metodo → METODO_PAGO(codigo_metodo) |

## 2. Significado de las tablas

### CLIENTE

Guarda los datos del cliente identificado por su `dni_cuit`. El atributo compuesto `contacto` del modelo conceptual se representa con dos columnas: `email` y `telefono`. Cada venta se vincula con un único cliente mediante `dni_cuit`.

### CATEGORIA y PRODUCTO

Cada categoría tiene un código y un nombre. Cada producto se identifica por su `sku` y pertenece a una única categoría. El nombre de la categoría se guarda en `CATEGORIA`, para evitar repetirlo en todos los productos de la misma clasificación.

`precio_lista` representa el precio vigente del catálogo. `stock_actual` indica las existencias físicas y `stock_reservado` las unidades comprometidas en ventas pendientes. El atributo derivado `stock_disponible` se obtiene como `stock_actual - stock_reservado`, por lo que no se incluye como columna almacenada.

### METODO_PAGO

Es el catálogo de medios de pago autorizados. Su clave es `codigo_metodo`. Separar este catálogo permite utilizar el mismo método en distintas ventas sin repetir su nombre en cada registro de cobro.

### VENTA

Representa la cabecera de la operación. `codigo_venta` es un identificador entero, definido como `INT` en la implementación. `fecha_hora` registra la creación de la venta y `monto_total` su importe total.

El atributo `estado` admite `Pendiente`, `Abonado` y `Cancelado`. Estos valores representan una venta en espera de completar el pago, una venta pagada y una venta cancelada, respectivamente.

### DETALLE_VENTA

Es una entidad débil identificada dentro de la venta a la que pertenece. Su clave primaria es `(codigo_venta, id)`. El atributo `id` es un número de renglón entero mayor que cero y es único dentro de cada venta; puede repetirse en ventas distintas. Por ejemplo, `(1, 1)` y `(2, 1)` identifican renglones diferentes. No es un identificador global.

`sku` es una clave foránea hacia `PRODUCTO` y no forma parte de la clave primaria del detalle. Un mismo producto puede aparecer en distintos renglones de una venta si cada renglón tiene un `id` diferente.

`cantidad` indica las unidades del renglón. `precio_uni_historico` guarda el precio unitario pactado al registrar ese detalle, según RN.03. Es un dato independiente de `PRODUCTO.precio_lista`: cambiar el precio vigente del catálogo no cambia el importe almacenado en los detalles anteriores.

### PAGA_CON

Resuelve la relación N:M entre ventas y métodos de pago. Su clave primaria `(codigo_venta, codigo_metodo)` permite una fila por método en cada venta. `monto_abonado` representa el importe acumulado de ese método para la venta; si se usa nuevamente el mismo medio, el importe se acumula en esa fila. La tabla no representa cobros individuales separados.

Una venta puede tener varios registros en `PAGA_CON`, uno por cada método utilizado. La suma de sus importes permite comparar lo abonado con `VENTA.monto_total`, de acuerdo con RN.04.

## 3. Transformación del modelo conceptual

Las entidades regulares se transforman en tablas con sus identificadores como claves primarias. En las relaciones 1:N, la clave de la entidad del lado 1 se incorpora como clave foránea en la tabla del lado N. Así se obtienen las referencias de `VENTA` a `CLIENTE` y de `PRODUCTO` a `CATEGORIA`.

La entidad débil `DETALLE_VENTA` incorpora la clave de su propietaria `VENTA` y su discriminador parcial `id`. La relación N:M `paga_con` genera la tabla `PAGA_CON`, que incluye las claves de las entidades participantes y el atributo propio `monto_abonado`.

El análisis de las dependencias funcionales y el paso a 3FN se presentan en [normalizacion.md](normalizacion.md).
