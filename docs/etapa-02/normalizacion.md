# Normalización del modelo relacional

## 1. Datos iniciales (0FN)

Se parte de una representación de la venta que reúne los datos del cliente, los renglones con sus productos y los importes abonados mediante cada método de pago:

```text
VENTA_GLOBAL (
    codigo_venta, fecha_hora, estado, monto_total,
    dni_cuit, nombre, apellido, contacto,
    RENGLONES {id, sku, marca, modelo, descripcion_tecnica, precio_lista,
               stock_actual, stock_reservado, codigo_categoria,
               nombre_categoria, cantidad, precio_uni_historico},
    PAGOS {codigo_metodo, nombre_metodo, monto_abonado}
)
```

Esta representación no está en 1FN porque contiene grupos repetitivos: `RENGLONES` y `PAGOS`. Además, `contacto` agrupa el correo y el teléfono.

Para el análisis, `id` es el número de renglón dentro de cada venta. Es un entero mayor que cero y puede repetirse en ventas diferentes. Los pagos se agrupan por venta y método: `monto_abonado` es el importe acumulado de cada medio, no un cobro individual. `precio_uni_historico` es el precio pactado al registrar el renglón y es independiente del precio vigente del catálogo (RN.03).

## 2. Primera Forma Normal (1FN)

Se separan los grupos repetitivos en relaciones propias y se divide `contacto` en `email` y `telefono`. Cada columna contiene un valor atómico.

```text
R_VENTA_1FN (
    codigo_venta, fecha_hora, monto_total, estado,
    dni_cuit, nombre, apellido, email, telefono
)
PK: codigo_venta

R_DETALLE_1FN (
    codigo_venta, id, sku, marca, modelo, descripcion_tecnica,
    precio_lista, stock_actual, stock_reservado,
    codigo_categoria, nombre_categoria, cantidad, precio_uni_historico
)
PK: (codigo_venta, id)

R_PAGO_1FN (
    codigo_venta, codigo_metodo, nombre_metodo, monto_abonado
)
PK: (codigo_venta, codigo_metodo)
```

Las dependencias funcionales que se utilizan en las siguientes descomposiciones son:

| Relación | Dependencias funcionales |
| :--- | :--- |
| R_VENTA_1FN | codigo_venta → fecha_hora, monto_total, estado, dni_cuit; dni_cuit → nombre, apellido, email, telefono |
| R_DETALLE_1FN | (codigo_venta, id) → sku, cantidad, precio_uni_historico; sku → marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria; codigo_categoria → nombre_categoria |
| R_PAGO_1FN | (codigo_venta, codigo_metodo) → monto_abonado; codigo_metodo → nombre_metodo |

Por transitividad, las claves de las relaciones intermedias también determinan los datos descriptivos asociados. Por ejemplo, `(codigo_venta, id)` determina `sku` y, a través de este, los datos del producto.

## 3. Segunda Forma Normal (2FN)

Una relación está en 2FN si está en 1FN y sus atributos no clave no dependen de una parte propia de una clave candidata. En las claves compuestas del modelo se revisa si alguno de sus componentes determina por sí solo un atributo no clave.

`R_VENTA_1FN` tiene clave simple y no presenta dependencias parciales. En `R_DETALLE_1FN`, ni `codigo_venta` ni `id` por separado determinan el producto, la cantidad o el precio del renglón. La dependencia de los datos del producto respecto de `sku` es transitiva, porque `sku` no forma parte de la clave `(codigo_venta, id)`; se trata en el paso a 3FN.

En `R_PAGO_1FN` existe la dependencia parcial `codigo_metodo → nombre_metodo`: el nombre depende de una parte de la clave `(codigo_venta, codigo_metodo)`. Se elimina separando `METODO_PAGO` y manteniendo el importe acumulado en `PAGA_CON`.

El resultado en 2FN es:

```text
R_VENTA_2FN (
    codigo_venta, fecha_hora, monto_total, estado,
    dni_cuit, nombre, apellido, email, telefono
)
PK: codigo_venta

R_DETALLE_2FN (
    codigo_venta, id, sku, marca, modelo, descripcion_tecnica,
    precio_lista, stock_actual, stock_reservado,
    codigo_categoria, nombre_categoria, cantidad, precio_uni_historico
)
PK: (codigo_venta, id)

METODO_PAGO (codigo_metodo, nombre_metodo)
PK: codigo_metodo
DF: codigo_metodo → nombre_metodo

PAGA_CON (codigo_venta, codigo_metodo, monto_abonado)
PK: (codigo_venta, codigo_metodo)
DF: (codigo_venta, codigo_metodo) → monto_abonado
```

`R_VENTA_2FN` y `R_DETALLE_2FN` conservan las dependencias funcionales indicadas para 1FN. En `PAGA_CON`, `codigo_metodo` queda como referencia a `METODO_PAGO` y `codigo_venta` como referencia a la venta.

## 4. Tercera Forma Normal (3FN)

En este modelo, para pasar de 2FN a 3FN se eliminan las dependencias transitivas de los atributos no clave respecto de la clave: un atributo descriptivo no debe depender de otro atributo no clave que no identifica la relación.

### 4.1. Datos del cliente

En `R_VENTA_2FN` se cumple:

```text
codigo_venta → dni_cuit
dni_cuit → nombre, apellido, email, telefono
```

Los datos personales dependen de `dni_cuit`, no son datos propios de cada venta. Se crea `CLIENTE` con clave `dni_cuit` y se mantiene ese atributo como clave foránea en `VENTA`.

### 4.2. Datos del producto

En `R_DETALLE_2FN` se cumple:

```text
(codigo_venta, id) → sku
sku → marca, modelo, descripcion_tecnica, precio_lista,
      stock_actual, stock_reservado, codigo_categoria
```

Se extraen los datos del catálogo a `PRODUCTO`, cuya clave es `sku`. El detalle conserva `sku` como clave foránea, además de `cantidad` y `precio_uni_historico`, que dependen del renglón completo.

El precio histórico no se elimina del detalle: representa el precio pactado en esa operación. `precio_lista` representa el precio vigente del producto. Ambos tienen distinto significado y distinta dependencia funcional.

### 4.3. Datos de la categoría

La relación de producto que se obtiene al separar el catálogo todavía contiene esta dependencia:

```text
sku → codigo_categoria
codigo_categoria → nombre_categoria
```

Se crea `CATEGORIA` con clave `codigo_categoria`, y `PRODUCTO` conserva ese código como clave foránea. De esta manera, el nombre de cada categoría se almacena una sola vez.

En cada descomposición por dependencia funcional de 2FN y 3FN, el atributo común es clave de la relación extraída. Por ejemplo, `dni_cuit` identifica `CLIENTE` y permanece en `VENTA`. Esto permite reunir los datos separados sin pérdida mediante sus atributos comunes.

## 5. Esquema final en 3FN

| Relación | Clave primaria | Dependencias funcionales de sus atributos no clave | Claves foráneas |
| :--- | :--- | :--- | :--- |
| CLIENTE (dni_cuit, nombre, apellido, email, telefono) | dni_cuit | dni_cuit → nombre, apellido, email, telefono | — |
| CATEGORIA (codigo_categoria, nombre_categoria) | codigo_categoria | codigo_categoria → nombre_categoria | — |
| PRODUCTO (sku, marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria) | sku | sku → marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria | codigo_categoria → CATEGORIA(codigo_categoria) |
| METODO_PAGO (codigo_metodo, nombre_metodo) | codigo_metodo | codigo_metodo → nombre_metodo | — |
| VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit) | codigo_venta | codigo_venta → fecha_hora, monto_total, estado, dni_cuit | dni_cuit → CLIENTE(dni_cuit) |
| DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico) | (codigo_venta, id) | (codigo_venta, id) → sku, cantidad, precio_uni_historico | codigo_venta → VENTA(codigo_venta); sku → PRODUCTO(sku) |
| PAGA_CON (codigo_venta, codigo_metodo, monto_abonado) | (codigo_venta, codigo_metodo) | (codigo_venta, codigo_metodo) → monto_abonado | codigo_venta → VENTA(codigo_venta); codigo_metodo → METODO_PAGO(codigo_metodo) |

En este esquema, `codigo_venta` se implementa como `INT`, `id` es el número de renglón positivo dentro de cada venta y `VENTA.estado` admite `Pendiente`, `Abonado` y `Cancelado`. `stock_disponible` no se almacena porque se obtiene como `stock_actual - stock_reservado`.

## 6. Resultado del proceso

| Forma | Cambio realizado |
| :--- | :--- |
| 1FN | Se separan los renglones y los pagos, y se divide contacto en email y telefono. |
| 2FN | Se elimina la dependencia parcial del nombre del método de pago. |
| 3FN | Se separan los datos del cliente, del producto y de la categoría por sus dependencias transitivas. |

Las siete tablas finales evitan repetir los datos descriptivos en cada venta y conservan el precio pactado como dato propio de cada renglón. La normalización organiza los datos según sus dependencias funcionales; las claves foráneas y las restricciones de la implementación son las que controlan las referencias y los valores permitidos.
