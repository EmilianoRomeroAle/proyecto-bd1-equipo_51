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
