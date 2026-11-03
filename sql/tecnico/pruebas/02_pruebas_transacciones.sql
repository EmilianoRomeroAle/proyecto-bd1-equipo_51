USE tienda_hardware;
GO
SET NOCOUNT ON;
SET XACT_ABORT ON;

-- Ejecutar antes 90_datos_prueba_etapa05.sql del integrante 3.
-- Estos códigos pertenecen solamente a las pruebas de transacciones.
-- Las expectativas son importes y cantidades calculados a mano.
IF OBJECT_ID('dbo.usp_RegistrarPago', 'P') IS NULL
    THROW 52900, 'Falta desarrollar usp_RegistrarPago.', 1;
IF OBJECT_ID('dbo.usp_ConfirmarVenta', 'P') IS NULL
    THROW 52900, 'Falta desarrollar usp_ConfirmarVenta.', 1;
IF OBJECT_ID('dbo.usp_CancelarVentasVencidas', 'P') IS NULL
    THROW 52900, 'Falta desarrollar usp_CancelarVentasVencidas.', 1;

IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01')
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-02')
    THROW 52900, 'Faltan los productos de prueba del integrante 2.', 1;

IF OBJECT_ID('dbo.CK_ET5_Rollback_95203', 'C') IS NOT NULL
    ALTER TABLE dbo.VENTA DROP CONSTRAINT CK_ET5_Rollback_95203;
DELETE FROM dbo.PAGA_CON WHERE codigo_venta BETWEEN 95201 AND 95249;
DELETE FROM dbo.DETALLE_VENTA WHERE codigo_venta BETWEEN 95201 AND 95249;
DELETE FROM dbo.VENTA WHERE codigo_venta BETWEEN 95201 AND 95249;
UPDATE dbo.PRODUCTO
SET stock_actual = CASE sku WHEN 'ET5-PAG-01' THEN 50 ELSE 30 END,
    stock_reservado = 0
WHERE sku IN ('ET5-PAG-01', 'ET5-PAG-02');

-- 1. Un SKU ocupa dos renglones: al confirmar se descuentan 3 unidades,
-- no solamente las 2 del primer renglón. El otro producto suma 2 unidades.
INSERT INTO dbo.VENTA VALUES (95201, CURRENT_TIMESTAMP, 4000, 'Pendiente', '99000051');
INSERT INTO dbo.DETALLE_VENTA VALUES
    (95201, 1, 'ET5-PAG-01', 2, 1000),
    (95201, 2, 'ET5-PAG-01', 1, 1000),
    (95201, 3, 'ET5-PAG-02', 2, 500);
UPDATE dbo.PRODUCTO SET stock_reservado = 3 WHERE sku = 'ET5-PAG-01';
UPDATE dbo.PRODUCTO SET stock_reservado = 2 WHERE sku = 'ET5-PAG-02';
EXEC dbo.usp_RegistrarPago 95201, 9051, 1000;
IF NOT EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95201 AND estado = 'Pendiente')
    THROW 52901, 'El pago parcial cambio el estado.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01' AND stock_actual = 50 AND stock_reservado = 3)
    THROW 52901, 'El pago parcial modifico el stock.', 1;
PRINT 'OK 01: pago parcial sin descontar existencias.';

EXEC dbo.usp_RegistrarPago 95201, 9051, 500;
IF (SELECT COUNT(*) FROM dbo.PAGA_CON WHERE codigo_venta = 95201) <> 1
   OR (SELECT monto_abonado FROM dbo.PAGA_CON WHERE codigo_venta = 95201 AND codigo_metodo = 9051) <> 1500
    THROW 52902, 'El mismo metodo no acumulo el pago.', 1;
PRINT 'OK 02: acumulacion en un mismo metodo.';

EXEC dbo.usp_RegistrarPago 95201, 9052, 2500;
IF NOT EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95201 AND estado = 'Abonado')
   OR (SELECT SUM(monto_abonado) FROM dbo.PAGA_CON WHERE codigo_venta = 95201) <> 4000
    THROW 52903, 'El multipago no confirmo la venta.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01' AND stock_actual = 47 AND stock_reservado = 0)
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-02' AND stock_actual = 28 AND stock_reservado = 0)
    THROW 52903, 'Descuento incorrecto al agrupar renglones por SKU.', 1;
PRINT 'OK 03: multipago, cuadre y descuento agrupado por producto.';

DECLARE @rechazado BIT = 0;
BEGIN TRY
    EXEC dbo.usp_ConfirmarVenta 95201;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52904, 'Se permitio confirmar dos veces.', 1;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95201, 9051, 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 OR (SELECT stock_actual FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01') <> 47
    THROW 52904, 'Una venta abonada volvio a modificarse.', 1;
PRINT 'OK 04: venta abonada protegida frente a otro pago o confirmacion.';

-- 2. El pago se inserta primero, pero la confirmación detecta una reserva
-- insuficiente. Debe volver atrás también el pago insertado.
INSERT INTO dbo.VENTA VALUES (95202, CURRENT_TIMESTAMP, 2000, 'Pendiente', '99000051');
INSERT INTO dbo.DETALLE_VENTA VALUES (95202, 1, 'ET5-PAG-01', 2, 1000);
UPDATE dbo.PRODUCTO SET stock_reservado = 1 WHERE sku = 'ET5-PAG-01';
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95202, 9051, 2000;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 OR EXISTS (SELECT 1 FROM dbo.PAGA_CON WHERE codigo_venta = 95202)
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01' AND stock_actual = 47 AND stock_reservado = 1)
    THROW 52905, 'No se revirtio el ultimo pago ante stock inconsistente.', 1;
PRINT 'OK 05: reserva insuficiente y ROLLBACK del pago final.';

-- 3. Fallo provocado DESPUÉS de descontar stock. La restricción temporal
-- sólo impide el cierre de esta venta y se retira al terminar la prueba.
INSERT INTO dbo.VENTA VALUES (95203, CURRENT_TIMESTAMP, 1000, 'Pendiente', '99000051');
INSERT INTO dbo.DETALLE_VENTA VALUES (95203, 1, 'ET5-PAG-01', 1, 1000);
UPDATE dbo.PRODUCTO SET stock_reservado = 2 WHERE sku = 'ET5-PAG-01';
ALTER TABLE dbo.VENTA ADD CONSTRAINT CK_ET5_Rollback_95203
    CHECK (codigo_venta <> 95203 OR estado <> 'Abonado');
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95203, 9051, 1000;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() = 547 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
ALTER TABLE dbo.VENTA DROP CONSTRAINT CK_ET5_Rollback_95203;
IF @rechazado = 0 OR EXISTS (SELECT 1 FROM dbo.PAGA_CON WHERE codigo_venta = 95203)
   OR NOT EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95203 AND estado = 'Pendiente')
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01' AND stock_actual = 47 AND stock_reservado = 2)
   OR @@TRANCOUNT <> 0
    THROW 52906, 'El error intermedio dejo cambios o transacciones abiertos.', 1;
PRINT 'OK 06: ROLLBACK de pago, stock, reserva y estado ante fallo intermedio.';

-- 4. Rechazos sobre la misma pendiente: nada debe cambiar.
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95203, 9051, 1001;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52907, 'Se acepto un sobrepago.', 1;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95203, 9051, NULL;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52907, 'Se acepto un importe NULL.', 1;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95203, 9051, 0;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52907, 'Se acepto un importe cero.', 1;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95203, 9051, -10;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52907, 'Se acepto un importe negativo.', 1;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95203, 999999, 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 OR EXISTS (SELECT 1 FROM dbo.PAGA_CON WHERE codigo_venta = 95203)
    THROW 52907, 'Se acepto un metodo inexistente o quedaron pagos.', 1;
PRINT 'OK 07: sobrepago, NULL, cero, negativo y metodo inexistente rechazados.';

SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_ConfirmarVenta 95203;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52908, 'Se confirmo sin pago completo.', 1;
INSERT INTO dbo.PAGA_CON VALUES (95203, 9051, 1000);
UPDATE dbo.VENTA SET monto_total = 1100 WHERE codigo_venta = 95203;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_ConfirmarVenta 95203;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52908, 'Se confirmo con cabecera y detalle distintos.', 1;
PRINT 'OK 08: confirmacion rechazada por pago incompleto y total inconsistente.';

INSERT INTO dbo.VENTA VALUES (95204, CURRENT_TIMESTAMP, 1000, 'Pendiente', '99000051');
INSERT INTO dbo.PAGA_CON VALUES (95204, 9051, 1000);
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_ConfirmarVenta 95204;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52909, 'Se confirmo una venta sin renglones.', 1;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95249, 9051, 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52909, 'Se pago una venta inexistente.', 1;
PRINT 'OK 09: venta sin renglones y venta inexistente rechazadas.';

-- Retirar los casos inconsistentes anteriores antes de probar vencimientos.
DELETE FROM dbo.PAGA_CON WHERE codigo_venta BETWEEN 95202 AND 95204;
DELETE FROM dbo.DETALLE_VENTA WHERE codigo_venta BETWEEN 95202 AND 95204;
DELETE FROM dbo.VENTA WHERE codigo_venta BETWEEN 95202 AND 95204;
UPDATE dbo.PRODUCTO SET stock_reservado = 0 WHERE sku IN ('ET5-PAG-01', 'ET5-PAG-02');

-- 5. Dos ventas vencidas comparten un SKU y hay varios renglones y pagos.
-- Cantidad a liberar: ET5-PAG-01=4 y ET5-PAG-02=2, sin multiplicaciones.
DECLARE @ahora DATETIME = CURRENT_TIMESTAMP;
INSERT INTO dbo.VENTA VALUES
    (95210, DATEADD(HOUR, -24, @ahora), 3000, 'Pendiente', '99000051'),
    (95211, DATEADD(HOUR, -25, @ahora), 2000, 'Pendiente', '99000051'),
    (95212, @ahora, 1000, 'Pendiente', '99000051'),
    (95213, DATEADD(HOUR, -25, @ahora), 1000, 'Pendiente', '99000051'),
    (95214, DATEADD(HOUR, -25, @ahora), 1000, 'Cancelado', '99000051');
INSERT INTO dbo.DETALLE_VENTA VALUES
    (95210, 1, 'ET5-PAG-01', 1, 1000), (95210, 2, 'ET5-PAG-01', 1, 1000),
    (95210, 3, 'ET5-PAG-02', 2, 500), (95211, 1, 'ET5-PAG-01', 2, 1000),
    (95212, 1, 'ET5-PAG-01', 1, 1000), (95213, 1, 'ET5-PAG-01', 1, 1000);
INSERT INTO dbo.PAGA_CON VALUES
    (95210, 9051, 200), (95210, 9052, 300), (95213, 9051, 1000);
UPDATE dbo.PRODUCTO SET stock_reservado = 6 WHERE sku = 'ET5-PAG-01';
UPDATE dbo.PRODUCTO SET stock_reservado = 2 WHERE sku = 'ET5-PAG-02';
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95210, 9051, 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 OR (SELECT SUM(monto_abonado) FROM dbo.PAGA_CON WHERE codigo_venta = 95210) <> 500
    THROW 52910, 'Se acepto un pago a las 24 horas cumplidas.', 1;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_ConfirmarVenta 95213;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52910, 'Se confirmo una venta vencida.', 1;
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_RegistrarPago 95214, 9051, 1;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0 THROW 52910, 'Se pago una venta cancelada.', 1;
PRINT 'OK 10: pago vencido, confirmacion vencida y pago cancelado rechazados.';

EXEC dbo.usp_CancelarVentasVencidas;
IF (SELECT COUNT(*) FROM dbo.VENTA WHERE codigo_venta IN (95210, 95211) AND estado = 'Cancelado') <> 2
   OR (SELECT COUNT(*) FROM dbo.VENTA WHERE codigo_venta IN (95212, 95213) AND estado = 'Pendiente') <> 2
    THROW 52911, 'Seleccion incorrecta de pendientes vencidas sin pago completo.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01' AND stock_actual = 47 AND stock_reservado = 2)
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-02' AND stock_actual = 28 AND stock_reservado = 0)
   OR (SELECT COUNT(*) FROM dbo.DETALLE_VENTA WHERE codigo_venta IN (95210, 95211)) <> 4
   OR (SELECT SUM(monto_abonado) FROM dbo.PAGA_CON WHERE codigo_venta = 95210) <> 500
    THROW 52911, 'Cancelacion altero fisico, detalles, pagos o libero mal la reserva.', 1;
PRINT 'OK 11: vencimiento de 24 horas, liberacion agrupada y conservacion de registros.';

EXEC dbo.usp_CancelarVentasVencidas;
IF (SELECT stock_reservado FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01') <> 2
   OR (SELECT stock_actual FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01') <> 47
   OR @@TRANCOUNT <> 0
    THROW 52912, 'Segunda cancelacion duplico efectos o dejo una transaccion.', 1;
PRINT 'OK 12: nueva ejecucion de cancelacion sin duplicar efectos.';

-- 6. Si una reserva de vencimientos no coincide, no debe cancelarse
-- ninguna de las ventas ni liberarse parcialmente el otro producto.
INSERT INTO dbo.VENTA VALUES
    (95215, DATEADD(HOUR, -25, CURRENT_TIMESTAMP), 2500, 'Pendiente', '99000051');
INSERT INTO dbo.DETALLE_VENTA VALUES
    (95215, 1, 'ET5-PAG-01', 2, 1000), (95215, 2, 'ET5-PAG-02', 1, 500);
UPDATE dbo.PRODUCTO SET stock_reservado = 4 WHERE sku = 'ET5-PAG-01';
SET @rechazado = 0;
BEGIN TRY
    EXEC dbo.usp_CancelarVentasVencidas;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() BETWEEN 52000 AND 52099 SET @rechazado = 1;
    ELSE THROW;
END CATCH;
IF @rechazado = 0
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-01' AND stock_actual = 47 AND stock_reservado = 4)
   OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-PAG-02' AND stock_actual = 28 AND stock_reservado = 0)
   OR NOT EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95215 AND estado = 'Pendiente')
    THROW 52913, 'La cancelacion dejo cambios parciales ante una reserva inconsistente.', 1;
PRINT 'OK 13: cancelacion con reservas inconsistentes revierte todo el lote.';

SELECT codigo_venta, estado, monto_total FROM dbo.VENTA
WHERE codigo_venta BETWEEN 95201 AND 95249 ORDER BY codigo_venta;
SELECT codigo_venta, codigo_metodo, monto_abonado FROM dbo.PAGA_CON
WHERE codigo_venta BETWEEN 95201 AND 95249 ORDER BY codigo_venta, codigo_metodo;
SELECT sku, stock_actual, stock_reservado FROM dbo.PRODUCTO
WHERE sku IN ('ET5-PAG-01', 'ET5-PAG-02') ORDER BY sku;

-- Se deja la base lista para repetir la demostración.
DELETE FROM dbo.PAGA_CON WHERE codigo_venta BETWEEN 95201 AND 95249;
DELETE FROM dbo.DETALLE_VENTA WHERE codigo_venta BETWEEN 95201 AND 95249;
DELETE FROM dbo.VENTA WHERE codigo_venta BETWEEN 95201 AND 95249;
UPDATE dbo.PRODUCTO
SET stock_actual = CASE sku WHEN 'ET5-PAG-01' THEN 50 ELSE 30 END,
    stock_reservado = 0
WHERE sku IN ('ET5-PAG-01', 'ET5-PAG-02');
PRINT 'PRUEBAS DE TRANSACCIONES COMPLETADAS.';
GO
