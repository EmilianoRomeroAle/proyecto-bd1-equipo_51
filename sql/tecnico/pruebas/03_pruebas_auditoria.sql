-- Equipo 51 - Integrante 3 - Pruebas de auditoria.
-- Requisitos: DDL, DML, 04_auditoria_producto.sql y 90_datos_prueba_etapa05.sql.
-- Usa solamente ET5-AUD-01/02 y la venta 95301. Todo se revierte al finalizar.
-- Ejecutar en una copia de prueba, sin otras operaciones sobre esos productos.
USE tienda_hardware;
GO
SET NOCOUNT ON;

IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-AUD-01' AND precio_lista = 1000 AND stock_actual = 50 AND stock_reservado = 0)
    THROW 52310, 'Preparar ET5-AUD-01 con el lote 90 en una copia limpia.', 1;
IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-AUD-02' AND precio_lista = 500 AND stock_actual = 30 AND stock_reservado = 0)
    THROW 52311, 'Preparar ET5-AUD-02 con el lote 90 en una copia limpia.', 1;
IF EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95301)
    THROW 52312, 'El codigo de demostracion 95301 ya esta ocupado. No se borraran datos.', 1;

DECLARE @ultimo_id BIGINT = ISNULL((SELECT MAX(id_auditoria) FROM dbo.AUDITORIA_PRODUCTO), 0);
DECLARE @inicio DATETIME2(7) = SYSDATETIME();
DECLARE @usuario NVARCHAR(128) = SUSER_SNAME();

BEGIN TRY
    BEGIN TRANSACTION;

    -- P1. Un cambio de precio debe generar exactamente una fila con ambos valores.
    UPDATE dbo.PRODUCTO SET precio_lista = 1100 WHERE sku = 'ET5-AUD-01';
    IF (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku IN ('ET5-AUD-01','ET5-AUD-02')) <> 1
        THROW 52313, 'P1: falta el registro de cambio de precio o hay registros duplicados.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.AUDITORIA_PRODUCTO
                   WHERE id_auditoria > @ultimo_id AND sku = 'ET5-AUD-01'
                     AND precio_anterior = 1000 AND precio_nuevo = 1100
                     AND stock_actual_anterior = 50 AND stock_actual_nuevo = 50
                     AND stock_reservado_anterior = 0 AND stock_reservado_nuevo = 0
                     AND fecha_hora >= @inicio AND usuario = @usuario AND tipo_operacion = 'UPDATE')
        THROW 52314, 'P1: valores, fecha, usuario o tipo de operacion incorrectos.', 1;
    PRINT 'P1 OK: precio anterior/nuevo, existencias, fecha, usuario y operacion.';

    -- P2. El cambio de existencias tambien se registra aunque el precio no cambie.
    UPDATE dbo.PRODUCTO SET stock_actual = 48, stock_reservado = 1 WHERE sku = 'ET5-AUD-01';
    IF NOT EXISTS (SELECT 1 FROM dbo.AUDITORIA_PRODUCTO
                   WHERE id_auditoria > @ultimo_id AND sku = 'ET5-AUD-01'
                     AND precio_anterior = 1100 AND precio_nuevo = 1100
                     AND stock_actual_anterior = 50 AND stock_actual_nuevo = 48
                     AND stock_reservado_anterior = 0 AND stock_reservado_nuevo = 1)
        THROW 52315, 'P2: no se capturo correctamente el cambio de existencias.', 1;
    PRINT 'P2 OK: cambio de stock fisico y reservado.';

    -- P3. Una sola sentencia afecta dos productos: debe registrar dos filas nuevas.
    UPDATE dbo.PRODUCTO
       SET precio_lista = precio_lista + 50,
           stock_actual = stock_actual + 1,
           stock_reservado = stock_reservado + 1
     WHERE sku IN ('ET5-AUD-01','ET5-AUD-02');
    IF (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku IN ('ET5-AUD-01','ET5-AUD-02')) <> 4
        THROW 52316, 'P3: el UPDATE de varias filas no produjo una auditoria por producto.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku = 'ET5-AUD-01'
                   AND precio_anterior = 1100 AND precio_nuevo = 1150
                   AND stock_actual_anterior = 48 AND stock_actual_nuevo = 49
                   AND stock_reservado_anterior = 1 AND stock_reservado_nuevo = 2)
        THROW 52317, 'P3: valores de ET5-AUD-01 incorrectos.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku = 'ET5-AUD-02'
                   AND precio_anterior = 500 AND precio_nuevo = 550
                   AND stock_actual_anterior = 30 AND stock_actual_nuevo = 31
                   AND stock_reservado_anterior = 0 AND stock_reservado_nuevo = 1)
        THROW 52318, 'P3: valores de ET5-AUD-02 incorrectos.', 1;
    PRINT 'P3 OK: UPDATE de varias filas, con sus valores correspondientes.';

    -- P4. Cambiar solamente la descripcion queda fuera del alcance de esta auditoria.
    UPDATE dbo.PRODUCTO SET descripcion_tecnica = 'Descripcion modificada para la prueba' WHERE sku = 'ET5-AUD-01';
    IF (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku IN ('ET5-AUD-01','ET5-AUD-02')) <> 4
        THROW 52319, 'P4: se audito un cambio sin modificacion de precio ni existencias.', 1;
    PRINT 'P4 OK: un cambio de descripcion no genera registros irrelevantes.';

    -- P5. Asignar los mismos valores tampoco es un cambio relevante.
    UPDATE dbo.PRODUCTO SET precio_lista = precio_lista, stock_actual = stock_actual, stock_reservado = stock_reservado
     WHERE sku IN ('ET5-AUD-01','ET5-AUD-02');
    IF (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku IN ('ET5-AUD-01','ET5-AUD-02')) <> 4
        THROW 52320, 'P5: se genero auditoria sin cambiar los valores.', 1;
    PRINT 'P5 OK: UPDATE sin cambios no agrega auditoria.';

    -- P6. Venta historica de prueba: el cambio del catalogo no toca su comprobante.
    -- La carga historica no descuenta nuevamente existencias.
    INSERT INTO dbo.VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit)
    VALUES (95301, '2026-09-15T10:00:00', 2000, 'Abonado', '99000051');
    INSERT INTO dbo.DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico)
    VALUES (95301, 1, 'ET5-AUD-01', 2, 1000);
    INSERT INTO dbo.PAGA_CON (codigo_venta, codigo_metodo, monto_abonado) VALUES (95301, 9051, 2000);
    UPDATE dbo.PRODUCTO SET precio_lista = 1175 WHERE sku = 'ET5-AUD-01';
    IF NOT EXISTS (SELECT 1 FROM dbo.DETALLE_VENTA WHERE codigo_venta = 95301 AND id = 1 AND precio_uni_historico = 1000 AND cantidad = 2)
       OR NOT EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95301 AND monto_total = 2000)
        THROW 52321, 'P6: se modifico el precio historico o el total de la venta.', 1;
    IF (SELECT COUNT(*) FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku IN ('ET5-AUD-01','ET5-AUD-02')) <> 5
        THROW 52322, 'P6: falta la auditoria del nuevo precio.', 1;
    PRINT 'P6 OK: precio historico y total conservados.';

    SELECT sku, precio_lista, stock_actual, stock_reservado FROM dbo.PRODUCTO WHERE sku IN ('ET5-AUD-01','ET5-AUD-02') ORDER BY sku;
    SELECT * FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku IN ('ET5-AUD-01','ET5-AUD-02') ORDER BY id_auditoria;

    -- P7. La auditoria participa de la misma transaccion que el UPDATE.
    ROLLBACK TRANSACTION;
    IF EXISTS (SELECT 1 FROM dbo.AUDITORIA_PRODUCTO WHERE id_auditoria > @ultimo_id AND sku IN ('ET5-AUD-01','ET5-AUD-02'))
        THROW 52323, 'P7: quedaron auditorias de una operacion revertida.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-AUD-01' AND precio_lista = 1000 AND stock_actual = 50 AND stock_reservado = 0)
       OR NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-AUD-02' AND precio_lista = 500 AND stock_actual = 30 AND stock_reservado = 0)
       OR EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = 95301)
        THROW 52324, 'P7: el ROLLBACK no restauro productos y venta de prueba.', 1;
    PRINT 'P7 OK: ROLLBACK revierte productos, venta y auditorias.';
    PRINT 'AUDITORIA: 7 pruebas correctas. Datos de demostracion revertidos.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
