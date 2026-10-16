# Decisiones de Diseño y Transformación Conceptual a Lógico

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  
**Autor:** Nuñez Axel Gabriel  
**Etapa:** Etapa II — Modelado Conceptual y Lógico  

## 1. Transformación de entidades y relaciones

Las entidades `CLIENTE`, `CATEGORIA`, `PRODUCTO`, `METODO_PAGO` y `VENTA` se representan mediante tablas propias. Sus claves primarias son `dni_cuit`, `codigo_categoria`, `sku`, `codigo_metodo` y `codigo_venta`, respectivamente. `codigo_venta` es un identificador entero y se implementa con el tipo `INT`.

En las relaciones 1:N, la clave primaria del lado 1 se agrega como clave foránea en el lado N. Por eso `VENTA` contiene `dni_cuit` y `PRODUCTO` contiene `codigo_categoria`.

### Identificación de los renglones de venta

`DETALLE_VENTA` se mantiene como entidad débil de `VENTA`. La relación identificadora `contiene` se transforma incorporando `codigo_venta` a la clave del detalle. Su clave primaria queda formada por `(codigo_venta, id)`.

`id` es el número de renglón dentro de una venta. Es un entero mayor que cero, no se repite dentro de esa venta y puede repetirse en otras ventas. No identifica por sí solo un detalle de toda la base. Esta decisión permite que dos renglones de una misma venta hagan referencia al mismo producto. La relación con el producto se representa mediante `sku`, que es clave foránea y no integra la clave primaria del detalle.

### Relación entre ventas y métodos de pago

La relación N:M `paga_con` se representa con la tabla `PAGA_CON`. Su clave primaria es `(codigo_venta, codigo_metodo)` y ambos atributos son también claves foráneas hacia sus tablas de origen.

El atributo propio `monto_abonado` indica el total acumulado por ese método en esa venta. Si hay más de un cobro con el mismo método, se acumulan en una única fila. Para una venta con distintos medios de pago existe una fila por cada método utilizado. Esta estructura permite calcular la suma abonada y compararla con el total de la venta, como establece RN.04.

## 2. Tratamiento de los atributos

El atributo compuesto `contacto` se divide en `email` y `telefono`, para representar cada dato en una columna. El atributo derivado `stock_disponible` no se almacena: se calcula como `stock_actual - stock_reservado`. Ambos valores se guardan en `PRODUCTO` y representan las existencias físicas y las unidades reservadas, respectivamente, según RN.08.

`VENTA.estado` utiliza los valores `Pendiente`, `Abonado` y `Cancelado`, que corresponden al ciclo de venta definido en el alcance. La reserva de existencias se asocia a las ventas pendientes; el pago completo, al estado abonado; y la expiración de una venta sin completar el pago, al estado cancelado.

### Precio de catálogo y precio histórico

`PRODUCTO.precio_lista` guarda el precio vigente del catálogo. `DETALLE_VENTA.precio_uni_historico` guarda el precio unitario pactado al registrar el renglón. Se conservan ambos porque representan hechos distintos, de acuerdo con RN.03.

El precio histórico depende de `(codigo_venta, id)`, mientras que el precio de lista depende de `sku`. Un cambio en el catálogo no cambia el precio guardado en un detalle anterior. Almacenar estos valores por separado expresa esa diferencia; la normalización no impide por sí sola que se modifiquen datos almacenados.

## 3. Separación de datos por normalización

En `R_PAGO_1FN`, cuya clave es `(codigo_venta, codigo_metodo)`, el nombre del método depende solamente de `codigo_metodo`. Esta dependencia parcial se elimina en 2FN separando `METODO_PAGO` de `PAGA_CON`.

En la relación intermedia del detalle, la clave `(codigo_venta, id)` determina `sku`, y `sku` determina los datos del producto. Como `sku` no es parte de la clave del detalle, se trata de una dependencia transitiva. En 3FN se extrae `PRODUCTO`, manteniendo `sku` como clave foránea en `DETALLE_VENTA`. También se separan los datos personales en `CLIENTE` y el nombre de la categoría en `CATEGORIA`.

El resultado contiene siete tablas: `CLIENTE`, `CATEGORIA`, `PRODUCTO`, `METODO_PAGO`, `VENTA`, `DETALLE_VENTA` y `PAGA_CON`. Cada tabla reúne los atributos que dependen de su clave, sin repetir los datos del cliente, el producto, la categoría o el método en cada operación. El desarrollo de las dependencias se encuentra en [normalizacion.md](normalizacion.md).
