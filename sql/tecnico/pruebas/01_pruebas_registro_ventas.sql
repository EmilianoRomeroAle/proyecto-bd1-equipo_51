USE tienda_hardware;
GO
SET NOCOUNT ON;

-- Ejecutar en una base de prueba, despues del DDL, los datos de demostracion
-- y los archivos 01_funciones.sql y 02_registro_ventas.sql.
-- Este bloque usa exclusivamente las ventas 95101 a 95104 y ET5-REG-01/02.
-- Detecta reservas omitidas, totales calculados con precios actuales y
-- validaciones que permiten cambios parciales al rechazar una operacion.
IF EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta BETWEEN 95101 AND 95104)
    THROW 51901, 'Las ventas de esta prueba ya existen. Revisar antes de repetir.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO
               WHERE sku = 'ET5-REG-01' AND precio_lista = 1000
                 AND stock_actual = 50 AND stock_reservado = 0)
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO
                  WHERE sku = 'ET5-REG-02' AND precio_lista = 500
                    AND stock_actual = 30 AND stock_reservado = 0)
    THROW 51902, 'Faltan los productos de prueba o no estan en su estado inicial.', 1;

DECLARE @error INT;

SELECT sku, precio_lista, stock_actual, stock_reservado
FROM dbo.PRODUCTO WHERE sku IN ('ET5-REG-01', 'ET5-REG-02') ORDER BY sku;

-- Alta con precio pactado diferente del precio de lista.
EXEC dbo.usp_RegistrarVentaPendiente 95101, '99000051', 'ET5-REG-01', 2, 900;
IF NOT EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95101
               AND estado = 'Pendiente' AND monto_total = 1800)
    THROW 51903, 'El alta no guardo estado y total esperados.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.DETALLE_VENTA WHERE codigo_venta = 95101
               AND id = 1 AND cantidad = 2 AND precio_uni_historico = 900)
    THROW 51904, 'El primer renglon o su precio historico son incorrectos.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-REG-01'
               AND stock_actual = 50 AND stock_reservado = 2)
    THROW 51905, 'La reserva debe aumentar sin descontar stock fisico.', 1;
IF dbo.fn_StockDisponible('ET5-REG-01') IS NULL
   OR dbo.fn_StockDisponible('ET5-REG-01') <> 48
    THROW 51906, 'La disponibilidad debe ser 48.', 1;
IF dbo.fn_TotalVenta(95101) IS NULL OR dbo.fn_TotalVenta(95101) <> 1800
    THROW 51907, 'El total debe usar el precio pactado.', 1;
IF dbo.fn_StockDisponible('ET5-NO-EXISTE') IS NOT NULL
   OR dbo.fn_TotalVenta(95149) IS NOT NULL
    THROW 51908, 'Las funciones deben devolver NULL para datos inexistentes.', 1;
PRINT 'OK 1: alta, primer renglon, reserva y funciones.';

-- Segundo producto y repeticion del mismo SKU con otro numero de renglon.
EXEC dbo.usp_AgregarDetalleVenta 95101, 2, 'ET5-REG-02', 3, 400;
EXEC dbo.usp_AgregarDetalleVenta 95101, 3, 'ET5-REG-01', 1, 800;
-- Un renglon de precio cero es valido si la venta mantiene total positivo.
EXEC dbo.usp_AgregarDetalleVenta 95101, 4, 'ET5-REG-02', 1, 0;
IF (SELECT COUNT(*) FROM dbo.DETALLE_VENTA WHERE codigo_venta = 95101) <> 4
   OR (SELECT monto_total FROM dbo.VENTA WHERE codigo_venta = 95101) <> 3800
   OR dbo.fn_TotalVenta(95101) IS NULL OR dbo.fn_TotalVenta(95101) <> 3800
    THROW 51909, 'El agregado de renglones no conserva el total esperado.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-REG-01'
               AND stock_actual = 50 AND stock_reservado = 3)
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-REG-02'
                  AND stock_actual = 30 AND stock_reservado = 4)
    THROW 51910, 'Las reservas acumuladas son incorrectas.', 1;
UPDATE dbo.PRODUCTO SET precio_lista = 1500 WHERE sku = 'ET5-REG-01';
IF dbo.fn_TotalVenta(95101) IS NULL OR dbo.fn_TotalVenta(95101) <> 3800
   OR NOT EXISTS (SELECT 1 FROM dbo.DETALLE_VENTA WHERE codigo_venta = 95101
                  AND id = 1 AND precio_uni_historico = 900)
    THROW 51911, 'El cambio de catalogo altero el historico.', 1;
UPDATE dbo.PRODUCTO SET precio_lista = 1000 WHERE sku = 'ET5-REG-01';
PRINT 'OK 2: varios renglones, SKU repetido y precio historico.';

-- Cada rechazo comprueba el numero de error y luego sus efectos.
-- La asercion queda fuera del CATCH para no confundirla con el error esperado.
SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarVentaPendiente 95101, '99000051', 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51002 THROW 51912, 'No se rechazo el codigo duplicado.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95101, 2, 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51009 THROW 51913, 'No se rechazo el renglon duplicado.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarVentaPendiente 95102, '99000051', 'ET5-REG-01', 0, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51001 THROW 51914, 'No se rechazo cantidad cero.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarVentaPendiente NULL, '99000051', 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51001 THROW 51915, 'No se rechazo el codigo NULL.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95101, NULL, 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51001 THROW 51928, 'No se rechazo el renglon NULL.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95101, 5, 'ET5-REG-01', 1, -1;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51001 THROW 51929, 'No se rechazo el precio negativo.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95102, 1, 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51006 THROW 51930, 'No se rechazo la venta inexistente.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarVentaPendiente 95102, 'ET5-NO-EXISTE', 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51003 THROW 51916, 'No se rechazo el cliente inexistente.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarVentaPendiente 95102, '99000051', 'ET5-NO-EXISTE', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51004 THROW 51917, 'No se rechazo el producto inexistente.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarVentaPendiente 95102, '99000051', 'ET5-REG-01', 48, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51005 THROW 51918, 'No se rechazo el stock insuficiente.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarVentaPendiente 95102, '99000051', 'ET5-REG-01', 1, 0;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51010 THROW 51919, 'El primer total no puede ser cero.', 1;

SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95101, 5, 'ET5-REG-02', 27, 500;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51005 THROW 51920, 'El agregado debe controlar disponibilidad.', 1;
IF EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95102)
   OR (SELECT COUNT(*) FROM dbo.DETALLE_VENTA WHERE codigo_venta = 95101) <> 4
   OR (SELECT monto_total FROM dbo.VENTA WHERE codigo_venta = 95101) <> 3800
   OR (SELECT stock_reservado FROM dbo.PRODUCTO WHERE sku = 'ET5-REG-01') <> 3
   OR (SELECT stock_reservado FROM dbo.PRODUCTO WHERE sku = 'ET5-REG-02') <> 4
    THROW 51921, 'Un rechazo dejo cambios parciales.', 1;
PRINT 'OK 3: duplicados, datos invalidos y stock insuficiente sin cambios.';

-- Se altera el estado solo para construir estas pruebas de rechazo.
UPDATE dbo.VENTA SET estado = 'Abonado' WHERE codigo_venta = 95101;
SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95101, 5, 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51007 THROW 51922, 'No se bloqueo la venta abonada.', 1;
UPDATE dbo.VENTA SET estado = 'Cancelado' WHERE codigo_venta = 95101;
SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95101, 5, 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51007 THROW 51923, 'No se bloqueo la venta cancelada.', 1;
UPDATE dbo.VENTA SET estado = 'Pendiente', fecha_hora = DATEADD(HOUR, -25, CURRENT_TIMESTAMP)
WHERE codigo_venta = 95101;
SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95101, 5, 'ET5-REG-01', 1, 1000;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 51008 THROW 51924, 'No se bloqueo la venta vencida.', 1;
UPDATE dbo.VENTA SET fecha_hora = CURRENT_TIMESTAMP WHERE codigo_venta = 95101;
PRINT 'OK 4: bloqueo de ventas abonadas, canceladas y vencidas.';

-- Caso aislado para mostrar 0 en una venta existente sin renglones.
INSERT INTO dbo.VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit)
VALUES (95104, CURRENT_TIMESTAMP, 1, 'Pendiente', '99000051');
IF dbo.fn_TotalVenta(95104) IS NULL OR dbo.fn_TotalVenta(95104) <> 0
    THROW 51925, 'Una venta existente sin renglones debe devolver cero.', 1;
DELETE FROM dbo.VENTA WHERE codigo_venta = 95104;

-- Error de DDL despues de reservar: el importe supera DECIMAL(12,2).
SET @error = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarVentaPendiente 95103, '99000051', 'ET5-REG-01', 2, 9999999999.99;
END TRY
BEGIN CATCH
    SET @error = ERROR_NUMBER();
END CATCH;
IF @error <> 8115 THROW 51926, 'Se esperaba rechazo por desbordamiento del importe.', 1;
IF EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95103)
   OR (SELECT stock_reservado FROM dbo.PRODUCTO WHERE sku = 'ET5-REG-01') <> 3
    THROW 51927, 'El error de importe dejo una reserva o venta parcial.', 1;
PRINT 'OK 5: funcion sin renglones y reversion ante error de importe.';

SELECT codigo_venta, estado, monto_total FROM dbo.VENTA WHERE codigo_venta = 95101;
SELECT codigo_venta, id, sku, cantidad, precio_uni_historico
FROM dbo.DETALLE_VENTA WHERE codigo_venta = 95101 ORDER BY id;
SELECT sku, stock_actual, stock_reservado, dbo.fn_StockDisponible(sku) AS disponible
FROM dbo.PRODUCTO WHERE sku IN ('ET5-REG-01', 'ET5-REG-02') ORDER BY sku;

-- Limpieza solo de los registros creados por esta prueba.
BEGIN TRANSACTION;
DELETE FROM dbo.VENTA WHERE codigo_venta = 95101;
UPDATE dbo.PRODUCTO SET stock_reservado = 0 WHERE sku IN ('ET5-REG-01', 'ET5-REG-02');
COMMIT TRANSACTION;
IF EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta BETWEEN 95101 AND 95104)
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-REG-01'
                   AND precio_lista = 1000 AND stock_actual = 50 AND stock_reservado = 0)
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-REG-02'
                   AND precio_lista = 500 AND stock_actual = 30 AND stock_reservado = 0)
    THROW 51931, 'La limpieza no dejo los productos en su estado inicial.', 1;
PRINT 'OK FINAL: pruebas completas; ventas eliminadas y reservas en cero.';
GO
