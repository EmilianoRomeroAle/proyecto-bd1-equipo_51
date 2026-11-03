-- Equipo 51 - Datos nuevos de demostracion para los integrantes 1, 2 y 3.
-- Ejecutar despues del DDL/DML, en una COPIA de prueba.
-- Es repetible: agrega solamente claves ausentes; no reinicia ni borra datos.
-- Los ocho productos permiten que las pruebas usen grupos separados.
USE tienda_hardware;
GO
SET NOCOUNT ON;

BEGIN TRY
    BEGIN TRANSACTION;

    IF NOT EXISTS (SELECT 1 FROM dbo.CATEGORIA WHERE codigo_categoria = 9051)
        INSERT INTO dbo.CATEGORIA (codigo_categoria, nombre_categoria)
        VALUES (9051, 'Pruebas Etapa V');

    IF NOT EXISTS (SELECT 1 FROM dbo.METODO_PAGO WHERE codigo_metodo = 9051)
        INSERT INTO dbo.METODO_PAGO (codigo_metodo, nombre_metodo)
        VALUES (9051, 'Efectivo prueba ET5');
    IF NOT EXISTS (SELECT 1 FROM dbo.METODO_PAGO WHERE codigo_metodo = 9052)
        INSERT INTO dbo.METODO_PAGO (codigo_metodo, nombre_metodo)
        VALUES (9052, 'Transferencia prueba ET5');

    IF NOT EXISTS (SELECT 1 FROM dbo.CLIENTE WHERE dni_cuit = '99000051')
        INSERT INTO dbo.CLIENTE (dni_cuit, nombre, apellido, email, telefono)
        VALUES ('99000051', 'Cliente', 'Prueba Etapa V', 'etapa5@prueba.local', '3794000051');

    INSERT INTO dbo.PRODUCTO
        (sku, marca, modelo, precio_lista, stock_actual, stock_reservado, codigo_categoria)
    SELECT nuevo.sku, 'Prueba', nuevo.modelo, nuevo.precio, nuevo.stock, 0, 9051
    FROM (VALUES
        ('ET5-REG-01', 'Registro 1', 1000, 50),
        ('ET5-REG-02', 'Registro 2', 500, 30),
        ('ET5-PAG-01', 'Pagos 1', 1000, 50),
        ('ET5-PAG-02', 'Pagos 2', 500, 30),
        ('ET5-AUD-01', 'Auditoria 1', 1000, 50),
        ('ET5-AUD-02', 'Auditoria 2', 500, 30),
        ('ET5-INT-01', 'Integracion 1', 1000, 50),
        ('ET5-INT-02', 'Integracion 2', 500, 30)
    ) AS nuevo(sku, modelo, precio, stock)
    WHERE NOT EXISTS (SELECT 1 FROM dbo.PRODUCTO p WHERE p.sku = nuevo.sku);

    COMMIT TRANSACTION;
    PRINT 'Datos ET5 preparados. Los registros existentes no fueron modificados.';
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
GO

SELECT sku, precio_lista, stock_actual, stock_reservado
FROM dbo.PRODUCTO
WHERE sku IN ('ET5-REG-01','ET5-REG-02','ET5-PAG-01','ET5-PAG-02',
              'ET5-AUD-01','ET5-AUD-02','ET5-INT-01','ET5-INT-02')
ORDER BY sku;
