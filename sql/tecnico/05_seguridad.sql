USE tienda_hardware;
GO

-- Inicio de sesión y usuario Administrador
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usuario_admin_login')
    CREATE LOGIN usuario_admin_login WITH PASSWORD = 'AdminTienda123*';
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_admin')
    CREATE USER usuario_admin FOR LOGIN usuario_admin_login;
GO

-- Inicio de sesión y usuario Lector / Consulta de Catálogo
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usuario_lector_login')
    CREATE LOGIN usuario_lector_login WITH PASSWORD = 'LectorTienda123*';
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_lector')
    CREATE USER usuario_lector FOR LOGIN usuario_lector_login;
GO

-- Inicio de sesión y usuario Operador (Ventas y Pagos)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usuario_operador_login')
    CREATE LOGIN usuario_operador_login WITH PASSWORD = 'OperadorTienda123*';
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_operador')
    CREATE USER usuario_operador FOR LOGIN usuario_operador_login;
GO

-- Usuario de prueba sin roles ni permisos (para verificar denegaciones)
IF NOT EXISTS (SELECT * FROM sys.server_principals WHERE name = 'usuario_sin_permisos_login')
    CREATE LOGIN usuario_sin_permisos_login WITH PASSWORD = 'SinPermisos123*';
GO
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'usuario_sin_rol')
    CREATE USER usuario_sin_rol FOR LOGIN usuario_sin_permisos_login;
GO

-- A. Asignar rol fijo de base de datos 'db_owner' al administrador
ALTER ROLE db_owner ADD MEMBER usuario_admin;
GO

-- B. Crear rol personalizado para consulta de catálogo (Productos, Categorías, Clientes)
IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_consulta_catalogo' AND type = 'R')
    CREATE ROLE rol_consulta_catalogo;
GO

GRANT SELECT ON dbo.PRODUCTO TO rol_consulta_catalogo;
GRANT SELECT ON dbo.CATEGORIA TO rol_consulta_catalogo;
GRANT SELECT ON dbo.CLIENTE TO rol_consulta_catalogo;
GO

-- Incorporar al usuario lector al rol de consulta
ALTER ROLE rol_consulta_catalogo ADD MEMBER usuario_lector;
GO

-- El operador NO tiene permisos directos de INSERT, UPDATE o DELETE sobre las tablas
-- comerciales. Toda modificación se realiza estrictamente a través de los SPs.

IF NOT EXISTS (SELECT * FROM sys.database_principals WHERE name = 'rol_operador_ventas' AND type = 'R')
    CREATE ROLE rol_operador_ventas;
GO

-- Otorgar permisos de lectura necesarios para las validaciones internas de los SPs
GRANT SELECT ON dbo.PRODUCTO TO rol_operador_ventas;
GRANT SELECT ON dbo.CLIENTE TO rol_operador_ventas;
GRANT SELECT ON dbo.METODO_PAGO TO rol_operador_ventas;
GRANT SELECT ON dbo.VENTA TO rol_operador_ventas;
GRANT SELECT ON dbo.DETALLE_VENTA TO rol_operador_ventas;
GRANT SELECT ON dbo.PAGA_CON TO rol_operador_ventas;
GO

-- Otorgar permisos de ejecución (EXECUTE) sobre los procedimientos del sistema de ventas
-- (Asumiendo los nombres acordados con los integrantes 1 y 2)
GRANT EXECUTE ON dbo.usp_RegistrarVentaPendiente TO rol_operador_ventas;
GRANT EXECUTE ON dbo.usp_AgregarDetalleVenta TO rol_operador_ventas;
GRANT EXECUTE ON dbo.usp_RegistrarPago TO rol_operador_ventas;
GRANT EXECUTE ON dbo.usp_ConfirmarVenta TO rol_operador_ventas;
GRANT EXECUTE ON dbo.usp_CancelarVentasVencidas TO rol_operador_ventas;
GO

-- Asignar el usuario operador al rol operativo
ALTER ROLE rol_operador_ventas ADD MEMBER usuario_operador;
GO
