-- Equipo 51 - Integrante 3 - Lote opcional para el trabajo del integrante 5.
-- SOLO en la copia tienda_hardware_rendimiento_etapa05, con DDL y DML originales.
-- El volumen predeterminado es UN MILLON de ventas, detalles y pagos.
-- Para una verificacion pequena, cambiar solamente @cantidad en una COPIA del archivo.
-- No crea indices, no descuenta stock y no modifica ni borra registros existentes.
USE tienda_hardware_rendimiento_etapa05;
GO
SET NOCOUNT ON;

IF DB_NAME() <> 'tienda_hardware_rendimiento_etapa05'
    THROW 52350, 'Este lote solo se ejecuta en la copia de rendimiento de etapa V.', 1;

DECLARE @cantidad INT = 1000000;
DECLARE @codigo_inicial INT = 900000001;
DECLARE @codigo_final INT = 900000000 + @cantidad;

IF @cantidad < 1 OR @cantidad > 1000000
    THROW 52351, 'La cantidad debe estar entre 1 y 1000000.', 1;

-- CROSS JOIN genera un conjunto de hasta un millon de numeros.
-- ROW_NUMBER los enumera y se usa la misma lista para las tres tablas.
-- Es una carga por conjuntos; no utiliza cursores ni WHILE.
;WITH Digitos AS
(
    SELECT valor FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) d(valor)
), Numeros AS
(
    SELECT TOP (@cantidad)
           CAST(ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS INT) AS numero
    FROM Digitos a CROSS JOIN Digitos b CROSS JOIN Digitos c
    CROSS JOIN Digitos d CROSS JOIN Digitos e CROSS JOIN Digitos f
)
SELECT @codigo_inicial + numero - 1 AS codigo_venta,
       CAST(DATEADD(DAY, (numero - 1) % 1825, '2021-01-01T12:00:00') AS DATETIME) AS fecha_hora
INTO #LoteRendimiento
FROM Numeros;

BEGIN TRY
    BEGIN TRANSACTION;

    -- Identificadores exclusivos. Si estaban ocupados por otro caso, se informa
    -- el conflicto y se revierte todo, sin reemplazar su contenido.
    IF EXISTS (SELECT 1 FROM dbo.CATEGORIA WHERE codigo_categoria = 900000001 AND nombre_categoria <> 'Rendimiento Etapa V')
        THROW 52352, 'La categoria reservada para rendimiento esta ocupada.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.CATEGORIA WHERE codigo_categoria = 900000001)
        INSERT INTO dbo.CATEGORIA (codigo_categoria, nombre_categoria) VALUES (900000001, 'Rendimiento Etapa V');

    IF EXISTS (SELECT 1 FROM dbo.CLIENTE WHERE dni_cuit = '99000515'
                AND (nombre <> 'Cliente' OR apellido <> 'Rendimiento Etapa V' OR email <> 'rendimiento.et5@prueba.local' OR telefono <> '3794000515'))
        THROW 52353, 'El cliente reservado para rendimiento esta ocupado.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.CLIENTE WHERE dni_cuit = '99000515')
        INSERT INTO dbo.CLIENTE (dni_cuit, nombre, apellido, email, telefono)
        VALUES ('99000515', 'Cliente', 'Rendimiento Etapa V', 'rendimiento.et5@prueba.local', '3794000515');

    IF EXISTS (SELECT 1 FROM dbo.METODO_PAGO WHERE codigo_metodo = 900000001 AND nombre_metodo <> 'Efectivo rendimiento ET5')
        THROW 52354, 'El metodo reservado para rendimiento esta ocupado.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.METODO_PAGO WHERE codigo_metodo = 900000001)
        INSERT INTO dbo.METODO_PAGO (codigo_metodo, nombre_metodo) VALUES (900000001, 'Efectivo rendimiento ET5');

    IF EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-REN-01'
                AND (marca <> 'Prueba' OR modelo <> 'Rendimiento' OR precio_lista <> 1000
                     OR stock_actual <> 0 OR stock_reservado <> 0 OR codigo_categoria <> 900000001))
        THROW 52355, 'El producto reservado para rendimiento tiene otros datos.', 1;
    IF NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO WHERE sku = 'ET5-REN-01')
        INSERT INTO dbo.PRODUCTO (sku, marca, modelo, precio_lista, stock_actual, stock_reservado, codigo_categoria)
        VALUES ('ET5-REN-01', 'Prueba', 'Rendimiento', 1000, 0, 0, 900000001);

    IF EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final)
    BEGIN
        -- Solo se admite repetir si el rango completo ya contiene este lote.
        IF (SELECT COUNT(*) FROM dbo.VENTA WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final) <> @cantidad
            THROW 52356, 'El rango de ventas esta ocupado parcialmente. No se borraran datos.', 1;

        IF EXISTS (SELECT 1 FROM #LoteRendimiento l JOIN dbo.VENTA v ON v.codigo_venta = l.codigo_venta
                   WHERE v.fecha_hora <> l.fecha_hora OR v.monto_total <> 1000
                      OR v.estado <> 'Abonado' OR v.dni_cuit <> '99000515')
            THROW 52357, 'Las ventas existentes no corresponden al lote solicitado.', 1;

        IF (SELECT COUNT(*) FROM dbo.DETALLE_VENTA WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final) <> @cantidad
           OR EXISTS (SELECT 1 FROM dbo.DETALLE_VENTA WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final
                        AND (id <> 1 OR sku <> 'ET5-REN-01' OR cantidad <> 1 OR precio_uni_historico <> 1000))
            THROW 52358, 'El detalle del rango existente no corresponde al lote solicitado.', 1;

        IF (SELECT COUNT(*) FROM dbo.PAGA_CON WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final) <> @cantidad
           OR EXISTS (SELECT 1 FROM dbo.PAGA_CON WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final
                        AND (codigo_metodo <> 900000001 OR monto_abonado <> 1000))
            THROW 52359, 'Los pagos del rango existente no corresponden al lote solicitado.', 1;

        PRINT 'El mismo lote coherente ya existe. No se agregaron ventas, detalles ni pagos.';
    END
    ELSE
    BEGIN
        INSERT INTO dbo.VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit)
        SELECT codigo_venta, fecha_hora, 1000, 'Abonado', '99000515' FROM #LoteRendimiento;

        INSERT INTO dbo.DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico)
        SELECT codigo_venta, 1, 'ET5-REN-01', 1, 1000 FROM #LoteRendimiento;

        INSERT INTO dbo.PAGA_CON (codigo_venta, codigo_metodo, monto_abonado)
        SELECT codigo_venta, 900000001, 1000 FROM #LoteRendimiento;

        PRINT 'Lote historico cargado con una venta, un detalle y un pago por operacion.';
    END;

    COMMIT TRANSACTION;

    SELECT @cantidad AS cantidad_solicitada,
           COUNT(*) AS ventas_del_rango,
           MIN(fecha_hora) AS primera_fecha,
           MAX(fecha_hora) AS ultima_fecha,
           SUM(CAST(monto_total AS DECIMAL(20,2))) AS importe_total
    FROM dbo.VENTA WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final;

    SELECT (SELECT COUNT(*) FROM dbo.DETALLE_VENTA WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final) AS detalles_del_rango,
           (SELECT COUNT(*) FROM dbo.PAGA_CON WHERE codigo_venta BETWEEN @codigo_inicial AND @codigo_final) AS pagos_del_rango;
    PRINT 'El lote no incluye mediciones ni indices. Esa demostracion corresponde al integrante 5.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;

DROP TABLE #LoteRendimiento;
