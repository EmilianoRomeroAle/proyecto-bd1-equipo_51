USE tienda_hardware;
GO

-- El alta incluye el primer renglon: monto_total nunca comienza en cero.
CREATE OR ALTER PROCEDURE dbo.usp_RegistrarVentaPendiente
    @codigo_venta INT,
    @dni_cuit VARCHAR(20),
    @sku VARCHAR(50),
    @cantidad INT,
    @precio_uni_historico DECIMAL(12, 2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @codigo_venta IS NULL OR @codigo_venta <= 0
           OR @dni_cuit IS NULL OR LTRIM(RTRIM(@dni_cuit)) = ''
           OR @sku IS NULL OR LTRIM(RTRIM(@sku)) = ''
           OR @cantidad IS NULL OR @cantidad <= 0
           OR @precio_uni_historico IS NULL OR @precio_uni_historico < 0
            THROW 51001, 'Revisar codigo, cliente, producto, cantidad y precio.', 1;

        IF EXISTS (SELECT 1 FROM dbo.VENTA WHERE codigo_venta = @codigo_venta)
            THROW 51002, 'El codigo de venta ya existe.', 1;

        IF NOT EXISTS (SELECT 1 FROM dbo.CLIENTE WHERE dni_cuit = @dni_cuit)
            THROW 51003, 'El cliente no esta registrado.', 1;

        IF dbo.fn_StockDisponible(@sku) IS NULL
            THROW 51004, 'El producto no existe.', 1;

        IF @cantidad * @precio_uni_historico <= 0
            THROW 51010, 'El primer renglon debe generar un total positivo.', 1;

        -- La condicion se repite en el UPDATE para no reservar por encima
        -- de las existencias si la disponibilidad cambia desde la consulta.
        UPDATE dbo.PRODUCTO
        SET stock_reservado = stock_reservado + @cantidad
        WHERE sku = @sku
          AND stock_actual - stock_reservado >= @cantidad;

        IF @@ROWCOUNT <> 1
            THROW 51005, 'No hay stock disponible para la cantidad solicitada.', 1;

        INSERT INTO dbo.VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit)
        VALUES (@codigo_venta, CURRENT_TIMESTAMP,
                @cantidad * @precio_uni_historico, 'Pendiente', @dni_cuit);

        INSERT INTO dbo.DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico)
        VALUES (@codigo_venta, 1, @sku, @cantidad, @precio_uni_historico);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Si el llamador inicio otra transaccion, el error tambien la revierte.
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_AgregarDetalleVenta
    @codigo_venta INT,
    @id INT,
    @sku VARCHAR(50),
    @cantidad INT,
    @precio_uni_historico DECIMAL(12, 2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @estado VARCHAR(10);
    DECLARE @fecha_hora DATETIME;
    DECLARE @total DECIMAL(12, 2);

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @codigo_venta IS NULL OR @codigo_venta <= 0
           OR @id IS NULL OR @id <= 0
           OR @sku IS NULL OR LTRIM(RTRIM(@sku)) = ''
           OR @cantidad IS NULL OR @cantidad <= 0
           OR @precio_uni_historico IS NULL OR @precio_uni_historico < 0
            THROW 51001, 'Revisar venta, renglon, producto, cantidad y precio.', 1;

        -- Se conserva el bloqueo de esta venta hasta terminar la operacion.
        -- Los procedimientos de pagos utilizan el mismo criterio.
        SELECT @estado = estado, @fecha_hora = fecha_hora
        FROM dbo.VENTA WITH (UPDLOCK, HOLDLOCK)
        WHERE codigo_venta = @codigo_venta;

        IF @estado IS NULL
            THROW 51006, 'La venta no existe.', 1;

        IF @estado <> 'Pendiente'
            THROW 51007, 'Solo se pueden agregar renglones a una venta pendiente.', 1;

        IF @fecha_hora <= DATEADD(HOUR, -24, CURRENT_TIMESTAMP)
            THROW 51008, 'La venta pendiente cumplio 24 horas y esta vencida.', 1;

        IF EXISTS (SELECT 1 FROM dbo.DETALLE_VENTA
                   WHERE codigo_venta = @codigo_venta AND id = @id)
            THROW 51009, 'El numero de renglon ya existe en esta venta.', 1;

        IF dbo.fn_StockDisponible(@sku) IS NULL
            THROW 51004, 'El producto no existe.', 1;

        UPDATE dbo.PRODUCTO
        SET stock_reservado = stock_reservado + @cantidad
        WHERE sku = @sku
          AND stock_actual - stock_reservado >= @cantidad;

        IF @@ROWCOUNT <> 1
            THROW 51005, 'No hay stock disponible para la cantidad solicitada.', 1;

        INSERT INTO dbo.DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico)
        VALUES (@codigo_venta, @id, @sku, @cantidad, @precio_uni_historico);

        SET @total = dbo.fn_TotalVenta(@codigo_venta);
        IF @total IS NULL OR @total <= 0
            THROW 51010, 'La venta debe conservar un total positivo.', 1;

        UPDATE dbo.VENTA
        SET monto_total = @total
        WHERE codigo_venta = @codigo_venta;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        -- Un error deshace tambien las reservas y el nuevo detalle.
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
