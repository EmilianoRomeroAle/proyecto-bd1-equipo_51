USE tienda_hardware;
GO

-- Etapa V. Pagos y transacciones.
-- Requiere el DDL vigente y dbo.fn_TotalVenta del integrante 1.
-- Todos los cambios de una operación se confirman juntos o se revierten.

CREATE OR ALTER PROCEDURE dbo.usp_ConfirmarVenta
    @codigo_venta INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @estado VARCHAR(10), @fecha DATETIME;
        DECLARE @total_cabecera DECIMAL(12,2), @total_detalle DECIMAL(12,2);
        DECLARE @total_pagado DECIMAL(12,2);

        -- Se conserva el bloqueo de la cabecera hasta terminar la operación.
        -- Agregar renglones y registrar pagos usan el mismo criterio.
        SELECT @estado = estado, @fecha = fecha_hora, @total_cabecera = monto_total
        FROM dbo.VENTA WITH (UPDLOCK, HOLDLOCK)
        WHERE codigo_venta = @codigo_venta;

        IF @codigo_venta IS NULL OR @estado IS NULL
            THROW 52002, 'La venta no existe.', 1;
        IF @estado <> 'Pendiente'
            THROW 52003, 'Solo se puede confirmar una venta pendiente.', 1;
        IF @fecha IS NULL OR @fecha <= DATEADD(HOUR, -24, CURRENT_TIMESTAMP)
            THROW 52004, 'La venta alcanzo su plazo de 24 horas.', 1;

        SET @total_detalle = dbo.fn_TotalVenta(@codigo_venta);
        SELECT @total_pagado = COALESCE(SUM(monto_abonado), 0)
        FROM dbo.PAGA_CON WHERE codigo_venta = @codigo_venta;

        IF @total_detalle IS NULL OR @total_detalle <= 0
           OR @total_cabecera <> @total_detalle OR @total_pagado <> @total_detalle
            THROW 52005, 'Deben coincidir cabecera, detalles y pagos, con total positivo.', 1;

        -- La clave del detalle es (venta, id): un SKU puede estar repetido.
        DECLARE @cantidades TABLE (sku VARCHAR(50) PRIMARY KEY, cantidad INT);
        INSERT INTO @cantidades (sku, cantidad)
        SELECT sku, SUM(cantidad)
        FROM dbo.DETALLE_VENTA
        WHERE codigo_venta = @codigo_venta
        GROUP BY sku;

        UPDATE p
        SET stock_actual = p.stock_actual - c.cantidad,
            stock_reservado = p.stock_reservado - c.cantidad
        FROM dbo.PRODUCTO AS p
        INNER JOIN @cantidades AS c ON c.sku = p.sku
        WHERE p.stock_actual >= c.cantidad AND p.stock_reservado >= c.cantidad;

        -- Si algún producto no pudo actualizarse, también se deshacen los otros.
        IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @cantidades)
            THROW 52006, 'El stock o las reservas no alcanzan para confirmar.', 1;

        UPDATE dbo.VENTA SET estado = 'Abonado'
        WHERE codigo_venta = @codigo_venta AND estado = 'Pendiente';
        IF @@ROWCOUNT <> 1
            THROW 52009, 'No se pudo actualizar el estado de la venta.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_RegistrarPago
    @codigo_venta INT,
    @codigo_metodo INT,
    @monto_abonado DECIMAL(12,2)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        IF @monto_abonado IS NULL OR @monto_abonado <= 0
            THROW 52001, 'El importe del pago debe ser positivo.', 1;

        DECLARE @estado VARCHAR(10), @fecha DATETIME;
        DECLARE @total DECIMAL(12,2), @pagado DECIMAL(12,2);
        DECLARE @total_detalle DECIMAL(12,2);

        SELECT @estado = estado, @fecha = fecha_hora, @total = monto_total
        FROM dbo.VENTA WITH (UPDLOCK, HOLDLOCK)
        WHERE codigo_venta = @codigo_venta;

        IF @codigo_venta IS NULL OR @estado IS NULL
            THROW 52002, 'La venta no existe.', 1;
        IF @estado <> 'Pendiente'
            THROW 52003, 'Solo se pueden cobrar ventas pendientes.', 1;
        IF @fecha IS NULL OR @fecha <= DATEADD(HOUR, -24, CURRENT_TIMESTAMP)
            THROW 52004, 'La venta alcanzo su plazo de 24 horas.', 1;
        IF @codigo_metodo IS NULL OR NOT EXISTS
            (SELECT 1 FROM dbo.METODO_PAGO WHERE codigo_metodo = @codigo_metodo)
            THROW 52007, 'El metodo de pago no existe.', 1;

        SET @total_detalle = dbo.fn_TotalVenta(@codigo_venta);
        IF @total_detalle IS NULL OR @total_detalle <= 0 OR @total <> @total_detalle
            THROW 52005, 'El total de la cabecera no coincide con los detalles.', 1;

        SELECT @pagado = COALESCE(SUM(monto_abonado), 0)
        FROM dbo.PAGA_CON WHERE codigo_venta = @codigo_venta;
        IF @monto_abonado > @total - @pagado
            THROW 52008, 'El pago supera el saldo de la venta.', 1;

        -- La PK sólo permite una fila por venta y método. Los nuevos pagos
        -- del mismo medio se acumulan en esa fila, sin agregar otra igual.
        IF EXISTS (SELECT 1 FROM dbo.PAGA_CON
                   WHERE codigo_venta = @codigo_venta AND codigo_metodo = @codigo_metodo)
        BEGIN
            UPDATE dbo.PAGA_CON SET monto_abonado = monto_abonado + @monto_abonado
            WHERE codigo_venta = @codigo_venta AND codigo_metodo = @codigo_metodo;
            IF @@ROWCOUNT <> 1
                THROW 52009, 'No se pudo acumular el pago.', 1;
        END
        ELSE
            INSERT INTO dbo.PAGA_CON (codigo_venta, codigo_metodo, monto_abonado)
            VALUES (@codigo_venta, @codigo_metodo, @monto_abonado);

        -- La confirmación forma parte de esta misma transacción. Su COMMIT
        -- interno no hace permanente el pago antes del COMMIT de este bloque.
        IF @pagado + @monto_abonado = @total
            EXEC dbo.usp_ConfirmarVenta @codigo_venta = @codigo_venta;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO

CREATE OR ALTER PROCEDURE dbo.usp_CancelarVentasVencidas
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRY
        BEGIN TRANSACTION;

        DECLARE @limite DATETIME = DATEADD(HOUR, -24, CURRENT_TIMESTAMP);
        DECLARE @vencidas TABLE (codigo_venta INT PRIMARY KEY);

        -- Se guarda una sola fila por venta. La suma de pagos se calcula
        -- aparte de los detalles para evitar multiplicar importes o unidades.
        INSERT INTO @vencidas (codigo_venta)
        SELECT v.codigo_venta
        FROM dbo.VENTA AS v WITH (UPDLOCK, HOLDLOCK)
        WHERE v.estado = 'Pendiente' AND v.fecha_hora <= @limite
          AND COALESCE((SELECT SUM(pc.monto_abonado)
                        FROM dbo.PAGA_CON AS pc
                        WHERE pc.codigo_venta = v.codigo_venta), 0) < v.monto_total;

        DECLARE @cantidades TABLE (sku VARCHAR(50) PRIMARY KEY, cantidad INT);
        INSERT INTO @cantidades (sku, cantidad)
        SELECT d.sku, SUM(d.cantidad)
        FROM dbo.DETALLE_VENTA AS d
        INNER JOIN @vencidas AS v ON v.codigo_venta = d.codigo_venta
        GROUP BY d.sku;

        UPDATE p SET stock_reservado = p.stock_reservado - c.cantidad
        FROM dbo.PRODUCTO AS p
        INNER JOIN @cantidades AS c ON c.sku = p.sku
        WHERE p.stock_reservado >= c.cantidad;
        IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @cantidades)
            THROW 52010, 'Las reservas de las ventas vencidas son inconsistentes.', 1;

        UPDATE v SET estado = 'Cancelado'
        FROM dbo.VENTA AS v
        INNER JOIN @vencidas AS c ON c.codigo_venta = v.codigo_venta
        WHERE v.estado = 'Pendiente';
        IF @@ROWCOUNT <> (SELECT COUNT(*) FROM @vencidas)
            THROW 52009, 'No se pudieron cancelar todas las ventas seleccionadas.', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH;
END;
GO
