-- Equipo 51 - Etapa V. Prueba del circuito completo.
-- Ejecutar despues de 01, 02, 03, 04 y 90.
-- Solo utiliza productos ET5-INT y ventas 95401 y 95402.
USE tienda_hardware;
GO
SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM VENTA WHERE codigo_venta IN (95401, 95402))
    THROW 54001, 'Los codigos de la prueba de integracion ya estan ocupados.', 1;
IF NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-01' AND stock_actual = 50 AND stock_reservado = 0 AND precio_lista = 1000)
   OR NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-02' AND stock_actual = 30 AND stock_reservado = 0 AND precio_lista = 500)
    THROW 54002, 'Revisar el lote 90: los productos de integracion no tienen sus valores iniciales.', 1;

PRINT 'I01. Venta de varios renglones y un SKU repetido.';
EXEC dbo.usp_RegistrarVentaPendiente 95401, '99000051', 'ET5-INT-01', 2, 1000;
EXEC dbo.usp_AgregarDetalleVenta 95401, 2, 'ET5-INT-01', 1, 1000;
EXEC dbo.usp_AgregarDetalleVenta 95401, 3, 'ET5-INT-02', 1, 500;
IF NOT EXISTS (SELECT 1 FROM VENTA WHERE codigo_venta = 95401 AND estado = 'Pendiente' AND monto_total = 3500)
    THROW 54003, 'No se obtuvo una pendiente de 3500.', 1;
IF NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-01' AND stock_actual = 50 AND stock_reservado = 3)
   OR NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-02' AND stock_actual = 30 AND stock_reservado = 1)
    THROW 54004, 'Las reservas iniciales no coinciden.', 1;
PRINT 'Correcto: total 3500; reservas de 3 y 1; sin baja fisica.';

PRINT 'I02. Pagos parciales, acumulacion por metodo y confirmacion.';
EXEC dbo.usp_RegistrarPago 95401, 9051, 1000;
EXEC dbo.usp_RegistrarPago 95401, 9051, 500;
IF NOT EXISTS (SELECT 1 FROM VENTA WHERE codigo_venta = 95401 AND estado = 'Pendiente')
   OR NOT EXISTS (SELECT 1 FROM PAGA_CON WHERE codigo_venta = 95401 AND codigo_metodo = 9051 AND monto_abonado = 1500)
    THROW 54005, 'El pago parcial no quedo acumulado en el mismo medio.', 1;
EXEC dbo.usp_RegistrarPago 95401, 9052, 2000;
IF NOT EXISTS (SELECT 1 FROM VENTA WHERE codigo_venta = 95401 AND estado = 'Abonado' AND monto_total = 3500)
    THROW 54006, 'La venta no quedo abonada.', 1;
IF (SELECT COUNT(*) FROM PAGA_CON WHERE codigo_venta = 95401) <> 2
   OR (SELECT SUM(monto_abonado) FROM PAGA_CON WHERE codigo_venta = 95401) <> 3500
    THROW 54007, 'El multipago no coincide con 3500 en dos medios.', 1;
IF NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-01' AND stock_actual = 47 AND stock_reservado = 0)
   OR NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-02' AND stock_actual = 29 AND stock_reservado = 0)
    THROW 54008, 'No se descontaron las cantidades agrupadas por SKU.', 1;
PRINT 'Correcto: Abonado; pagos 1500 y 2000; existencias 47 y 29, sin reservas.';

PRINT 'I03. Precio actual, precio historico y auditoria.';
UPDATE PRODUCTO SET precio_lista = 1200 WHERE sku = 'ET5-INT-01';
IF EXISTS (SELECT 1 FROM DETALLE_VENTA WHERE codigo_venta = 95401 AND sku = 'ET5-INT-01' AND precio_uni_historico <> 1000)
   OR dbo.fn_TotalVenta(95401) <> 3500
    THROW 54009, 'El cambio del catalogo altero el historial.', 1;
-- Los nombres de las columnas de auditoria se verifican en su prueba especifica.
IF NOT EXISTS (SELECT 1 FROM dbo.AUDITORIA_PRODUCTO WHERE sku = 'ET5-INT-01')
    THROW 54010, 'No se registraron los cambios del producto en la auditoria.', 1;
PRINT 'Correcto: precio actual 1200, historico 1000 y total historico 3500.';

DECLARE @rechazado BIT = 0;
BEGIN TRY
    EXEC dbo.usp_AgregarDetalleVenta 95401, 4, 'ET5-INT-01', 1, 1200;
END TRY
BEGIN CATCH
    IF ERROR_NUMBER() NOT BETWEEN 51000 AND 52999 THROW;
    SET @rechazado = 1;
END CATCH;
IF @rechazado = 0 OR (SELECT COUNT(*) FROM DETALLE_VENTA WHERE codigo_venta = 95401) <> 3
    THROW 54011, 'Se permitio modificar una venta abonada.', 1;
PRINT 'Correcto: se rechazo el agregado posterior a la venta abonada.';

PRINT 'I04. Error de pago y reversion de una operacion con varios pasos.';
EXEC dbo.usp_RegistrarVentaPendiente 95402, '99000051', 'ET5-INT-01', 1, 1000;
DECLARE @auditoria_antes INT = (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE sku IN ('ET5-INT-01', 'ET5-INT-02'));
SET @rechazado = 0;
BEGIN TRY
    BEGIN TRANSACTION;
    EXEC dbo.usp_AgregarDetalleVenta 95402, 2, 'ET5-INT-02', 1, 500;
    EXEC dbo.usp_RegistrarPago 95402, 999999, 100;
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    IF ERROR_NUMBER() NOT BETWEEN 51000 AND 52999 THROW;
    SET @rechazado = 1;
END CATCH;
IF @rechazado = 0
    THROW 54012, 'Se acepto un medio de pago inexistente.', 1;
IF (SELECT COUNT(*) FROM DETALLE_VENTA WHERE codigo_venta = 95402) <> 1
   OR NOT EXISTS (SELECT 1 FROM VENTA WHERE codigo_venta = 95402 AND monto_total = 1000 AND estado = 'Pendiente')
   OR EXISTS (SELECT 1 FROM PAGA_CON WHERE codigo_venta = 95402)
    THROW 54013, 'Quedaron cambios parciales tras el error.', 1;
IF NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-02' AND stock_actual = 29 AND stock_reservado = 0)
   OR (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE sku IN ('ET5-INT-01', 'ET5-INT-02')) <> @auditoria_antes
    THROW 54014, 'No se revirtieron juntos reserva y auditoria.', 1;
IF @@TRANCOUNT <> 0
    THROW 54015, 'Quedo una transaccion abierta.', 1;
PRINT 'Correcto: se revirtieron renglon, total, reserva y auditoria del segundo paso.';

PRINT 'I05. Vencimiento y segunda ejecucion sin duplicar la liberacion.';
UPDATE VENTA SET fecha_hora = DATEADD(HOUR, -25, CURRENT_TIMESTAMP) WHERE codigo_venta = 95402;
EXEC dbo.usp_CancelarVentasVencidas;
IF NOT EXISTS (SELECT 1 FROM VENTA WHERE codigo_venta = 95402 AND estado = 'Cancelado')
   OR NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-01' AND stock_actual = 47 AND stock_reservado = 0)
    THROW 54016, 'El vencimiento no libero la reserva correctamente.', 1;
SET @auditoria_antes = (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE sku IN ('ET5-INT-01', 'ET5-INT-02'));
EXEC dbo.usp_CancelarVentasVencidas;
IF NOT EXISTS (SELECT 1 FROM PRODUCTO WHERE sku = 'ET5-INT-01' AND stock_actual = 47 AND stock_reservado = 0)
   OR (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE sku IN ('ET5-INT-01', 'ET5-INT-02')) <> @auditoria_antes
    THROW 54017, 'La segunda ejecucion altero nuevamente las reservas.', 1;
PRINT 'Correcto: pendiente vencida cancelada, sin aumentar stock fisico ni liberar dos veces.';

SELECT codigo_venta, estado, monto_total FROM VENTA WHERE codigo_venta IN (95401, 95402);
SELECT codigo_venta, codigo_metodo, monto_abonado FROM PAGA_CON WHERE codigo_venta = 95401 ORDER BY codigo_metodo;
SELECT sku, precio_lista, stock_actual, stock_reservado FROM PRODUCTO WHERE sku IN ('ET5-INT-01', 'ET5-INT-02') ORDER BY sku;

-- Limpieza limitada a los datos exclusivos de esta prueba.
DELETE FROM VENTA WHERE codigo_venta IN (95401, 95402);
UPDATE PRODUCTO SET precio_lista = 1000, stock_actual = 50, stock_reservado = 0 WHERE sku = 'ET5-INT-01';
UPDATE PRODUCTO SET precio_lista = 500, stock_actual = 30, stock_reservado = 0 WHERE sku = 'ET5-INT-02';
DELETE FROM dbo.AUDITORIA_PRODUCTO WHERE sku IN ('ET5-INT-01', 'ET5-INT-02');
PRINT 'Prueba de integracion terminada. Productos de prueba restaurados.';
GO
