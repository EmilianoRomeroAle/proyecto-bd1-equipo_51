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
