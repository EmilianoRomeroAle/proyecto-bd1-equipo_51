USE tienda_hardware;
GO

-- Disponibilidad actual. NULL indica que el producto no existe.
CREATE OR ALTER FUNCTION dbo.fn_StockDisponible (@sku VARCHAR(50))
RETURNS INT
AS
BEGIN
    DECLARE @disponible INT;

    SELECT @disponible = stock_actual - stock_reservado
    FROM dbo.PRODUCTO
    WHERE sku = @sku;

    RETURN @disponible;
END;
GO

-- Se calcula con los precios pactados, no con el catalogo actual.
-- Una venta inexistente devuelve NULL; una existente sin renglones, 0.
CREATE OR ALTER FUNCTION dbo.fn_TotalVenta (@codigo_venta INT)
RETURNS DECIMAL(12, 2)
AS
BEGIN
    DECLARE @total DECIMAL(12, 2);

    IF EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = @codigo_venta)
    BEGIN
        SELECT @total = ISNULL(SUM(cantidad * precio_uni_historico), 0)
        FROM dbo.DETALLE_VENTA
        WHERE codigo_venta = @codigo_venta;
    END;

    RETURN @total;
END;
GO
