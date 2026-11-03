-- Equipo 51 - Etapa V - Integrante 3.
-- Requisito: PRODUCTO del DDL actualizado.
-- Instalar antes de las demostraciones. Repetir no borra la auditoria existente.
USE tienda_hardware;
GO

IF OBJECT_ID('dbo.AUDITORIA_PRODUCTO', 'U') IS NULL
BEGIN
    CREATE TABLE dbo.AUDITORIA_PRODUCTO
    (
        id_auditoria BIGINT IDENTITY(1,1) NOT NULL,
        sku VARCHAR(50) NOT NULL,
        fecha_hora DATETIME2(7) NOT NULL,
        usuario NVARCHAR(128) NOT NULL,
        tipo_operacion VARCHAR(10) NOT NULL,
        precio_anterior DECIMAL(12,2) NOT NULL,
        precio_nuevo DECIMAL(12,2) NOT NULL,
        stock_actual_anterior INT NOT NULL,
        stock_actual_nuevo INT NOT NULL,
        stock_reservado_anterior INT NOT NULL,
        stock_reservado_nuevo INT NOT NULL,
        CONSTRAINT PK_AUDITORIA_PRODUCTO PRIMARY KEY (id_auditoria),
        CONSTRAINT CHK_AUDITORIA_PRODUCTO_operacion CHECK (tipo_operacion = 'UPDATE')
    );
    -- No lleva FK a PRODUCTO: la evidencia no debe depender de conservar
    -- el articulo en el catalogo ni desaparecer con una eliminacion futura.
END;
GO

CREATE OR ALTER TRIGGER dbo.trg_PRODUCTO_Auditoria
ON dbo.PRODUCTO
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- inserted contiene los valores nuevos y deleted los anteriores.
    -- El JOIN trabaja con todas las filas afectadas por la sentencia.
    INSERT INTO dbo.AUDITORIA_PRODUCTO
    (
        sku, fecha_hora, usuario, tipo_operacion,
        precio_anterior, precio_nuevo,
        stock_actual_anterior, stock_actual_nuevo,
        stock_reservado_anterior, stock_reservado_nuevo
    )
    SELECT i.sku, SYSDATETIME(), SUSER_SNAME(), 'UPDATE',
           d.precio_lista, i.precio_lista,
           d.stock_actual, i.stock_actual,
           d.stock_reservado, i.stock_reservado
    FROM inserted i
    JOIN deleted d ON d.sku = i.sku
    WHERE i.precio_lista <> d.precio_lista
       OR i.stock_actual <> d.stock_actual
       OR i.stock_reservado <> d.stock_reservado;
END;
GO
