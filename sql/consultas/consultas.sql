-- Proyecto integrador - Bases de Datos I - Equipo 51
-- Etapa IV: consultas y casos de uso.
-- Motor: Microsoft SQL Server.
-- Ejecutar despues del DDL y el DML de la Etapa III actualizada.
-- Las consultas no modifican los datos.

USE tienda_hardware;
GO

-- C01. Comprobante de una venta
-- Se consulta la venta 1. Cambiar el codigo para consultar otra venta.
-- El total calculado se repite en cada renglon; no debe sumarse de nuevo.
SELECT v.codigo_venta,
       v.fecha_hora,
       v.estado,
       c.dni_cuit,
       c.nombre,
       c.apellido,
       d.id AS renglon,
       p.sku,
       p.marca,
       p.modelo,
       d.cantidad,
       d.precio_uni_historico,
       d.cantidad * d.precio_uni_historico AS subtotal,
       (SELECT SUM(d2.cantidad * d2.precio_uni_historico)
        FROM DETALLE_VENTA d2
        WHERE d2.codigo_venta = v.codigo_venta) AS total_calculado,
       v.monto_total AS total_registrado
FROM VENTA v
JOIN CLIENTE c ON c.dni_cuit = v.dni_cuit
JOIN DETALLE_VENTA d ON d.codigo_venta = v.codigo_venta
JOIN PRODUCTO p ON p.sku = d.sku
WHERE v.codigo_venta = 1
ORDER BY d.id;
GO

-- C02. Ventas abonadas por categoria en un rango de fechas
-- Se incluye septiembre de 2026 completo y se excluye el inicio de octubre.
-- Se cuentan ventas distintas, aunque tengan varios renglones en la categoria.
SELECT c.codigo_categoria,
       c.nombre_categoria,
       COUNT(DISTINCT v.codigo_venta) AS cantidad_ventas,
       SUM(d.cantidad) AS unidades_vendidas,
       SUM(d.cantidad * d.precio_uni_historico) AS total_vendido
FROM CATEGORIA c
JOIN PRODUCTO p ON p.codigo_categoria = c.codigo_categoria
JOIN DETALLE_VENTA d ON d.sku = p.sku
JOIN VENTA v ON v.codigo_venta = d.codigo_venta
WHERE v.estado = 'Abonado'
  AND v.fecha_hora >= '2026-09-01T00:00:00'
  AND v.fecha_hora < '2026-10-01T00:00:00'
GROUP BY c.codigo_categoria, c.nombre_categoria
ORDER BY total_vendido DESC, c.codigo_categoria;
GO

-- C03. Clientes con compras variadas y un importe superior al promedio de venta
-- Se compara el total comprado por cliente con el promedio de una venta.
-- Tanto la consulta como la subconsulta consideran abonadas del mismo periodo.
SELECT c.dni_cuit,
       c.nombre,
       c.apellido,
       COUNT(DISTINCT v.codigo_venta) AS cantidad_ventas,
       COUNT(DISTINCT p.sku) AS productos_distintos,
       SUM(d.cantidad * d.precio_uni_historico) AS total_comprado
FROM CLIENTE c
JOIN VENTA v ON v.dni_cuit = c.dni_cuit
JOIN DETALLE_VENTA d ON d.codigo_venta = v.codigo_venta
JOIN PRODUCTO p ON p.sku = d.sku
WHERE v.estado = 'Abonado'
  AND v.fecha_hora >= '2026-09-01T00:00:00'
  AND v.fecha_hora < '2026-10-01T00:00:00'
GROUP BY c.dni_cuit, c.nombre, c.apellido
HAVING COUNT(DISTINCT p.sku) >= 2
   AND SUM(d.cantidad * d.precio_uni_historico) >
       (SELECT AVG(v2.monto_total)
        FROM VENTA v2
        WHERE v2.estado = 'Abonado'
          AND v2.fecha_hora >= '2026-09-01T00:00:00'
          AND v2.fecha_hora < '2026-10-01T00:00:00')
ORDER BY total_comprado DESC, c.dni_cuit;
GO

-- C04. Ventas abonadas mediante varios medios de pago
-- Se muestran las ventas con dos o mas medios y cuyo pago coincide con el total.
-- No se unen los detalles, para evitar multiplicar los importes de los pagos.
SELECT v.codigo_venta,
       v.fecha_hora,
       c.dni_cuit,
       c.nombre,
       c.apellido,
       COUNT(m.codigo_metodo) AS cantidad_metodos,
       SUM(pc.monto_abonado) AS total_abonado,
       v.monto_total AS total_venta
FROM VENTA v
JOIN CLIENTE c ON c.dni_cuit = v.dni_cuit
JOIN PAGA_CON pc ON pc.codigo_venta = v.codigo_venta
JOIN METODO_PAGO m ON m.codigo_metodo = pc.codigo_metodo
WHERE v.estado = 'Abonado'
  AND v.fecha_hora >= '2026-09-01T00:00:00'
  AND v.fecha_hora < '2026-10-01T00:00:00'
GROUP BY v.codigo_venta, v.fecha_hora, c.dni_cuit,
         c.nombre, c.apellido, v.monto_total
HAVING COUNT(m.codigo_metodo) > 1
   AND SUM(pc.monto_abonado) = v.monto_total
ORDER BY v.codigo_venta;
GO

-- C05. Ventas que incluyen productos de varias categorias
-- Una categoria se cuenta una sola vez aunque tenga varios productos vendidos.
SELECT v.codigo_venta,
       v.fecha_hora,
       COUNT(DISTINCT c.codigo_categoria) AS categorias_distintas,
       SUM(d.cantidad) AS unidades_vendidas,
       SUM(d.cantidad * d.precio_uni_historico) AS total_calculado
FROM VENTA v
JOIN DETALLE_VENTA d ON d.codigo_venta = v.codigo_venta
JOIN PRODUCTO p ON p.sku = d.sku
JOIN CATEGORIA c ON c.codigo_categoria = p.codigo_categoria
WHERE v.estado = 'Abonado'
  AND v.fecha_hora >= '2026-09-01T00:00:00'
  AND v.fecha_hora < '2026-10-01T00:00:00'
GROUP BY v.codigo_venta, v.fecha_hora
HAVING COUNT(DISTINCT c.codigo_categoria) >= 2
ORDER BY v.codigo_venta;
GO
