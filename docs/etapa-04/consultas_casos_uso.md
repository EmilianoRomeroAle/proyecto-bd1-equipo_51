# Consultas y casos de uso — Etapa IV

**Asignatura:** Bases de Datos I, año 2026

**Equipo:** 51

**Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware

**Fecha:** 2026-10-15

## C01 — Comprobante de venta

**Necesidad:** consultar el cliente, la cabecera y los productos de una venta, con el subtotal de cada renglón y el total calculado del comprobante. El ejemplo utiliza la venta 1.

**Estrategia:** unir `VENTA`, `CLIENTE`, `DETALLE_VENTA` y `PRODUCTO`. El subtotal se calcula con `cantidad * precio_uni_historico`. Una subconsulta correlacionada suma los renglones de la misma venta para obtener el total. No se incorporan los pagos a ese conjunto de renglones, evitando multiplicarlos por cada medio usado.

**Columnas:** `codigo_venta`, `fecha_hora`, `estado`, `dni_cuit`, `nombre`, `apellido`, `renglon`, `sku`, `marca`, `modelo`, `cantidad`, `precio_uni_historico`, `subtotal`, `total_calculado` y `total_registrado`.

**Resultado esperado:** dos filas. Los datos de cabecera se repiten en cada renglón.

| Renglón | SKU | Cantidad | Precio histórico | Subtotal | Total de la venta |
| ---: | --- | ---: | ---: | ---: | ---: |
| 1 | RAM-KIN-FURY16 | 2 | 45.000,00 | 90.000,00 | 305.000,00 |
| 2 | CPU-AMD-5600X | 1 | 215.000,00 | 215.000,00 | 305.000,00 |

El cliente es Carlos Gomez, DNI 40123456. El total calculado y el guardado en cabecera coinciden en 305.000,00; no deben sumarse los totales repetidos en ambas filas.

## C02 — Ventas por categoría

**Necesidad:** conocer cuánto se vendió de cada categoría durante septiembre, cuántas unidades se comercializaron y en cuántas ventas participó.

**Estrategia:** unir `CATEGORIA`, `PRODUCTO`, `DETALLE_VENTA` y `VENTA`; filtrar estado y período; agrupar por categoría. Se usa `SUM` para unidades e importes históricos y `COUNT(DISTINCT codigo_venta)` para contar comprobantes sin repetirlos dentro de la categoría.

**Columnas:** `codigo_categoria`, `nombre_categoria`, `cantidad_ventas`, `unidades_vendidas` y `total_vendido`. El orden es de mayor a menor importe.

**Resultado esperado:** siete categorías con ventas.

| Código | Categoría | Unidades | Importe vendido | Ventas |
| ---: | --- | ---: | ---: | ---: |
| 2 | Placas de Video | 3 | 1.217.000,00 | 3 |
| 1 | Procesadores | 3 | 678.000,00 | 3 |
| 3 | Memorias RAM | 6 | 450.000,00 | 3 |
| 10 | Monitores | 2 | 396.000,00 | 2 |
| 5 | Almacenamiento SSD | 3 | 310.000,00 | 2 |
| 7 | Fuentes de Poder | 2 | 290.000,00 | 2 |
| 4 | Placas Madre | 2 | 248.000,00 | 2 |

La suma de los importes es 3.589.000,00. La cantidad de ventas por categoría no debe sumarse para obtener el número de ventas del período, porque un comprobante puede incluir varias categorías.

## C03 — Clientes con compras variadas sobre el promedio de venta

**Necesidad:** identificar clientes que compraron al menos dos productos diferentes y cuyo importe acumulado supera el promedio de una venta abonada del período.

**Estrategia:** unir `CLIENTE`, `VENTA`, `DETALLE_VENTA` y `PRODUCTO`; aplicar los filtros de estado y fechas; agrupar por cliente. `HAVING` exige al menos dos SKU distintos y una suma de subtotales superior a una subconsulta con `AVG(monto_total)`. La subconsulta calcula el promedio por venta, con el mismo estado y período. Si un cliente tiene varias ventas, se acumulan sus renglones y se cuentan sus comprobantes distintos.

**Columnas:** `dni_cuit`, `nombre`, `apellido`, `cantidad_ventas`, `productos_distintos` y `total_comprado`. El resultado se ordena por total comprado descendente.

**Resultado esperado:** cuatro clientes, cada uno con una venta en el lote. El promedio de las diez cabeceras es 358.900,00.

| Cliente | DNI/CUIT | Ventas | SKU distintos | Total comprado |
| --- | --- | ---: | ---: | ---: |
| Nicolas Duarte | 44123987 | 1 | 3 | 655.000,00 |
| Mateo Benitez | 43111222 | 1 | 2 | 575.000,00 |
| Joaquin Romero | 41888999 | 1 | 3 | 443.000,00 |
| Sofia Rodriguez | 35444333 | 1 | 2 | 378.000,00 |

Comprar dos unidades del mismo SKU no alcanza para cumplir la condición de dos productos distintos.

## C04 — Ventas con varios medios de pago

**Necesidad:** encontrar las ventas abonadas mediante más de un medio y comprobar que los importes registrados cubren su total.

**Estrategia:** unir `VENTA`, `CLIENTE`, `PAGA_CON` y `METODO_PAGO`; filtrar estado y período; agrupar por venta y sus datos de cliente. `HAVING` exige más de un medio de pago y que `SUM(monto_abonado)` coincida con `monto_total`.

**Columnas:** `codigo_venta`, `fecha_hora`, `dni_cuit`, `nombre`, `apellido`, `cantidad_metodos`, `total_abonado` y `total_venta`.

**Resultado esperado:** cuatro ventas, cada una con dos medios y sin diferencia de importes.

| Venta | Medios | Total de cabecera | Suma abonada |
| ---: | ---: | ---: | ---: |
| 1 | 2 | 305.000,00 | 305.000,00 |
| 5 | 2 | 575.000,00 | 575.000,00 |
| 8 | 2 | 443.000,00 | 443.000,00 |
| 10 | 2 | 655.000,00 | 655.000,00 |

## C05 — Ventas de varias categorías

**Necesidad:** reconocer comprobantes que combinan productos de dos o más categorías.

**Estrategia:** unir `VENTA`, `DETALLE_VENTA`, `PRODUCTO` y `CATEGORIA`; filtrar estado y período; agrupar por venta. Se cuentan categorías distintas y se seleccionan los grupos con al menos dos mediante `HAVING`.

**Columnas:** `codigo_venta`, `fecha_hora`, `categorias_distintas`, `unidades_vendidas` y `total_calculado`.

**Resultado esperado:** cinco ventas.

| Venta | Categorías distintas | Unidades | Importe |
| ---: | ---: | ---: | ---: |
| 1 | 2 | 3 | 305.000,00 |
| 4 | 2 | 2 | 378.000,00 |
| 5 | 2 | 2 | 575.000,00 |
| 8 | 3 | 3 | 443.000,00 |
| 10 | 3 | 4 | 655.000,00 |

## Comprobación de resultados

Para comprobar las consultas, se comparan sus resultados con el lote de referencia después de cargarlo en una base de prueba. Cada consulta se ejecuta por separado. La repetición de datos de cabecera en un comprobante no implica ventas nuevas.

| Consulta | Comprobación sobre el lote |
| --- | --- |
| C01 | Dos renglones: 90.000,00 + 215.000,00 = 305.000,00. El total repetido en cada fila no se suma nuevamente. |
| C02 | Siete categorías, 21 unidades y 3.589.000,00. La suma de ventas por categoría no equivale al número de comprobantes. |
| C03 | Promedio por venta de 358.900,00 y cuatro clientes seleccionados. Se cuentan SKU distintos, no unidades. |
| C04 | Ventas 1, 5, 8 y 10, con dos medios cada una y suma abonada igual a la cabecera. |
| C05 | Ventas 1, 4, 5, 8 y 10; incluyen 2, 2, 2, 3 y 3 categorías, respectivamente. |

Al contrastar importes no se unen los pagos con los renglones de detalle en una misma suma: esa combinación puede multiplicar filas. C04 mantiene separados ambos conjuntos. En las consultas agrupadas por venta o categoría se suman los subtotales históricos del detalle, evitando sumar cabeceras repetidas.

Los conteos con `DISTINCT` deben conservarse aunque un producto se divida en varios renglones. Para revisar el filtro temporal, una venta del último instante de septiembre debe quedar incluida y una del comienzo de octubre debe quedar excluida.

## C06 — Productos sin ventas en el período

**Necesidad:** consultar productos del catálogo que no participaron en ventas abonadas durante septiembre.

**Estrategia:** unir `PRODUCTO` con `CATEGORIA` y usar una subconsulta correlacionada con `NOT EXISTS` sobre `DETALLE_VENTA` y `VENTA`. La ausencia se evalúa para cada SKU dentro del estado y período indicados.

**Columnas:** `sku`, `marca`, `modelo`, `codigo_categoria`, `nombre_categoria` y `precio_lista`.

**Resultado esperado:** cero filas. Los diez productos del lote aparecen al menos una vez en las ventas abonadas del período. La condición significa que no hubo ventas en ese período, no que el producto nunca se vendió.

## C07 — Productos sobre el promedio de su categoría

**Necesidad:** comparar el precio de lista de un producto con el precio promedio del catálogo de su propia categoría.

**Estrategia:** unir `PRODUCTO` y `CATEGORIA`. Una subconsulta correlacionada calcula `AVG(precio_lista)` para la categoría del producto; se conservan los precios superiores a ese promedio. Se comparan precios vigentes, sin usar los precios históricos de ventas.

**Columnas:** `sku`, `marca`, `modelo`, `codigo_categoria`, `nombre_categoria`, `precio_lista` y `promedio_categoria`.

**Resultado esperado:** tres productos.

| SKU | Precio de lista | Promedio de su categoría |
| --- | ---: | ---: |
| CPU-INT-13400F | 248.000,00 | 231.500,00 |
| GPU-MSI-7600XT | 465.000,00 | 442.500,00 |
| RAM-COR-VEN32 | 135.000,00 | 90.000,00 |

## Comprobación de resultados

Para comprobar las consultas, se comparan sus resultados con el lote de referencia después de cargarlo en una base de prueba. Cada consulta se ejecuta por separado. La repetición de datos de cabecera en un comprobante no implica ventas nuevas.

| Consulta | Comprobación sobre el lote |
| --- | --- |
| C01 | Dos renglones: 90.000,00 + 215.000,00 = 305.000,00. El total repetido en cada fila no se suma nuevamente. |
| C02 | Siete categorías, 21 unidades y 3.589.000,00. La suma de ventas por categoría no equivale al número de comprobantes. |
| C03 | Promedio por venta de 358.900,00 y cuatro clientes seleccionados. Se cuentan SKU distintos, no unidades. |
| C04 | Ventas 1, 5, 8 y 10, con dos medios cada una y suma abonada igual a la cabecera. |
| C05 | Ventas 1, 4, 5, 8 y 10; incluyen 2, 2, 2, 3 y 3 categorías, respectivamente. |
| C06 | Cero filas: todos los productos tienen ventas abonadas dentro del período. |
| C07 | Tres productos superan el promedio de su propia categoría: CPU Intel, GPU MSI y RAM Corsair. |

## C08 — Inventario disponible hasta 20 unidades

**Necesidad:** consultar los productos que tienen como máximo 20 unidades disponibles para la venta.

**Estrategia:** consultar `PRODUCTO`, calcular `stock_actual - stock_reservado` y filtrar los valores menores o iguales a 20. El resultado se ordena por disponibilidad. Es una consulta de existencias actuales y no aplica el período de ventas.

**Columnas:** `sku`, `marca`, `modelo`, `stock_actual`, `stock_reservado` y `stock_disponible`.

**Resultado esperado:** siete productos. Como todas las reservas del lote son cero, el stock disponible coincide con el actual.

| SKU | Stock actual | Reservado | Disponible |
| --- | ---: | ---: | ---: |
| GPU-MSI-7600XT | 8 | 0 | 8 |
| MON-LG-24GN60R | 10 | 0 | 10 |
| GPU-ASU-4060 | 12 | 0 | 12 |
| PSU-COR-RM750E | 14 | 0 | 14 |
| MB-GIG-B550M | 15 | 0 | 15 |
| CPU-INT-13400F | 18 | 0 | 18 |
| RAM-COR-VEN32 | 20 | 0 | 20 |

## Comprobación de resultados

Para comprobar las consultas, se comparan sus resultados con el lote de referencia después de cargarlo en una base de prueba. Cada consulta se ejecuta por separado. La repetición de datos de cabecera en un comprobante no implica ventas nuevas.

| Consulta | Comprobación sobre el lote |
| --- | --- |
| C01 | Dos renglones: 90.000,00 + 215.000,00 = 305.000,00. El total repetido en cada fila no se suma nuevamente. |
| C02 | Siete categorías, 21 unidades y 3.589.000,00. La suma de ventas por categoría no equivale al número de comprobantes. |
| C03 | Promedio por venta de 358.900,00 y cuatro clientes seleccionados. Se cuentan SKU distintos, no unidades. |
| C04 | Ventas 1, 5, 8 y 10, con dos medios cada una y suma abonada igual a la cabecera. |
| C05 | Ventas 1, 4, 5, 8 y 10; incluyen 2, 2, 2, 3 y 3 categorías, respectivamente. |
| C06 | Cero filas: todos los productos tienen ventas abonadas dentro del período. |
| C07 | Tres productos superan el promedio de su propia categoría: CPU Intel, GPU MSI y RAM Corsair. |
| C08 | Siete productos tienen hasta 20 unidades disponibles. El cálculo utiliza stock actual menos reservado. |

Al contrastar importes no se unen los pagos con los renglones de detalle en una misma suma: esa combinación puede multiplicar filas. C04 mantiene separados ambos conjuntos. En las consultas agrupadas por venta o categoría se suman los subtotales históricos del detalle, evitando sumar cabeceras repetidas.

Los conteos con `DISTINCT` deben conservarse aunque un producto se divida en varios renglones. Para revisar el filtro temporal, una venta del último instante de septiembre debe quedar incluida y una del comienzo de octubre debe quedar excluida.

Al contrastar importes no se unen los pagos con los renglones de detalle en una misma suma: esa combinación puede multiplicar filas. C04 mantiene separados ambos conjuntos. En las consultas agrupadas por venta o categoría se suman los subtotales históricos del detalle, evitando sumar cabeceras repetidas.

Los conteos con `DISTINCT` deben conservarse aunque un producto se divida en varios renglones. Para revisar el filtro temporal, una venta del último instante de septiembre debe quedar incluida y una del comienzo de octubre debe quedar excluida.
