-- Equipo 51 - Etapa V - Integrante 5 (Romero Alegre Ubaldo Diego Emiliano, DNI 43930524).
-- Optimizacion mediante indices: definicion de los dos indices no agrupados que se
-- comparan sobre la tabla VENTA de la copia de rendimiento.
-- Requisitos: base tienda_hardware_rendimiento_etapa05 con el DDL y el DML originales
-- (adaptando el USE) y el lote sql/tecnico/91_lote_rendimiento.sql ya cargado
-- (un millon de ventas con fechas entre 2021 y el 30-12-2025).
-- Este script no elimina ni reemplaza la clave primaria agrupada PK_VENTA y no crea
-- otros indices agrupados. Repetirlo no duplica indices.
-- Las mediciones corresponden a sql/tecnico/pruebas/06_pruebas_rendimiento.sql.
USE tienda_hardware_rendimiento_etapa05;
GO

IF DB_NAME() <> 'tienda_hardware_rendimiento_etapa05'
    THROW 52360, 'Este script solo se ejecuta en la copia de rendimiento de etapa V.', 1;

-- Los metodos de tipo XML de la consulta de revision exigen estos ajustes,
-- necesarios tambien para sqlcmd (SSMS ya los define con estos valores).
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ------------------------------------------------------------------
-- 1. Revision previa de los indices existentes en las siete tablas.
--    VENTA solo tiene su clave primaria agrupada PK_VENTA por codigo_venta:
--    por eso el escenario base se llama "sin indice adicional".
--    SQL Server no crea indices automaticos para las claves foraneas.
-- ------------------------------------------------------------------
SELECT
    OBJECT_SCHEMA_NAME(i.object_id) AS esquema,
    OBJECT_NAME(i.object_id) AS tabla,
    i.name AS indice,
    i.type_desc AS tipo,
    CAST(i.is_primary_key AS VARCHAR(3)) AS es_clave_primaria,
    CAST(i.is_unique AS VARCHAR(3)) AS es_unico,
    STUFF(
        (SELECT ', ' + c.name
         FROM sys.index_columns ic
         JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
         WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 0
         ORDER BY ic.key_ordinal
         FOR XML PATH(''), TYPE).value('.', 'varchar(max)'), 1, 2, '') AS columnas_clave,
    STUFF(
        (SELECT ', ' + c.name
         FROM sys.index_columns ic
         JOIN sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
         WHERE ic.object_id = i.object_id AND ic.index_id = i.index_id AND ic.is_included_column = 1
         ORDER BY ic.index_column_id
         FOR XML PATH(''), TYPE).value('.', 'varchar(max)'), 1, 2, '') AS columnas_incluidas
FROM sys.indexes i
WHERE i.index_id > 0
  AND OBJECT_NAME(i.object_id) IN ('CATEGORIA', 'CLIENTE', 'METODO_PAGO', 'PRODUCTO',
                                   'VENTA', 'DETALLE_VENTA', 'PAGA_CON')
ORDER BY tabla, indice;
GO

-- ------------------------------------------------------------------
-- 2. Escenario 2: indice no agrupado simple sobre la columna del filtro
--    (fecha_hora). Es el equivalente de la guia adaptado a VENTA, que ya
--    tiene su propia clave primaria agrupada por codigo_venta.
-- ------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.VENTA') AND name = 'IX_VENTA_fecha_hora')
    CREATE NONCLUSTERED INDEX IX_VENTA_fecha_hora
        ON dbo.VENTA (fecha_hora);
GO

-- ------------------------------------------------------------------
-- 3. Escenario 3: indice no agrupado con cobertura para la misma consulta
--    (mismas columnas, filtro y lote).codigo_venta no se incluye porque el
--    localizador de todo indice no agrupado guarda la clave primaria agrupada;
--    estado y monto_total se agregan para responder la consulta sin visitar
--    la tabla.
-- ------------------------------------------------------------------
IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.VENTA') AND name = 'IX_VENTA_fecha_cobertura')
    CREATE NONCLUSTERED INDEX IX_VENTA_fecha_cobertura
        ON dbo.VENTA (fecha_hora)
        INCLUDE (estado, monto_total);
GO

-- ------------------------------------------------------------------
-- 4. Espacio ocupado por la estructura de VENTA, incluidos los indices nuevos.
-- ------------------------------------------------------------------
SELECT
    OBJECT_NAME(ps.object_id) AS tabla,
    ISNULL(i.name, 'Estructura base') AS indice,
    ps.row_count AS filas,
    ps.reserved_page_count * 8 / 1024.0 AS espacio_reservado_MB,
    ps.used_page_count * 8 / 1024.0 AS espacio_usado_MB
FROM sys.dm_db_partition_stats ps
LEFT JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE ps.object_id = OBJECT_ID('dbo.VENTA')
ORDER BY ps.index_id;
GO

-- ------------------------------------------------------------------
-- 5. Limpieza opcional: para restaurar la estructura original, descomentar.
-- ------------------------------------------------------------------
-- DROP INDEX IX_VENTA_fecha_cobertura ON dbo.VENTA;
-- GO
-- DROP INDEX IX_VENTA_fecha_hora ON dbo.VENTA;
-- GO
