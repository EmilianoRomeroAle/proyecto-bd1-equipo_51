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
