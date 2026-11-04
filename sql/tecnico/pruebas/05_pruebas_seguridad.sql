USE tienda_hardware;
GO
  
PRINT 'INICIO DE PRUEBAS DE SEGURIDAD Y CONTROL DE ACCESO';
GO

-- PRUEBA 1: Consulta de catálogo permitida mediante rol
PRINT '--- Prueba 1: SELECT sobre PRODUCTO con usuario_lector (Resultado esperado: ÉXITO) ---';
EXECUTE AS USER = 'usuario_lector';
BEGIN TRY
    SELECT TOP 3 sku, marca, modelo, precio_lista FROM dbo.PRODUCTO;
    PRINT '>> PRUEBA 1 EXITOSA: Consulta de productos permitida.';
END TRY
BEGIN CATCH
    PRINT '>> ERROR EN PRUEBA 1: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- PRUEBA 2: Intento de INSERT directo denegado al usuario lector
PRINT '--- Prueba 2: INSERT directo en VENTA con usuario_lector (Resultado esperado: DENEGADO) ---';
EXECUTE AS USER = 'usuario_lector';
BEGIN TRY
    INSERT INTO dbo.VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit)
    VALUES (9999, CURRENT_TIMESTAMP, 15000.00, 'Pendiente', '20-12345678-9');
    PRINT '>> ERROR: Se permitió una inserción no autorizada.';
END TRY
BEGIN CATCH
    PRINT '>> CORRECTO (DENEGADO): SQL Server bloqueó la operación por falta de permisos de inserción.';
    PRINT '   Mensaje del motor: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

-- PRUEBA 3: Ejecución de procedimiento almacenado por el usuario operador
PRINT '--- Prueba 3: EXEC de procedimiento autorizado con usuario_operador (Resultado esperado: ÉXITO) ---';
EXECUTE AS USER = 'usuario_operador';
BEGIN TRY
    -- Ejemplo de llamada controlada al procedimiento de alta de venta pendiente
    EXEC dbo.usp_RegistrarVentaPendiente 
         @codigo_venta = 8888, 
         @dni_cuit = '20-12345678-9', 
         @sku = 'PROD01', 
         @cantidad = 1, 
         @precio_pactado = 25000.00;
         
    PRINT '>> PRUEBA 3 EXITOSA: El operador ejecutó el procedimiento almacenado correctamente.';
END TRY
BEGIN CATCH
    PRINT '>> AVISO / ERROR EN PRUEBA 3 (Verificar datos de prueba previos si aplica): ' + ERROR_MESSAGE();
END CATCH;
REVERT;

-- PRUEBA 4: Acceso total denegado a usuario sin rol ni privilegios
PRINT '--- Prueba 4: SELECT sobre PRODUCTO con usuario_sin_rol (Resultado esperado: DENEGADO) ---';
EXECUTE AS USER = 'usuario_sin_rol';
BEGIN TRY
    SELECT * FROM dbo.PRODUCTO;
    PRINT '>> ERROR: Se permitió el acceso a un usuario sin privilegios.';
END TRY
BEGIN CATCH
    PRINT '>> CORRECTO (DENEGADO): Acceso denegado correctamente por falta de asignación en rol.';
    PRINT '   Mensaje del motor: ' + ERROR_MESSAGE();
END CATCH;
REVERT;
GO

PRINT 'FIN DE LAS PRUEBAS DE SEGURIDAD';
GO
