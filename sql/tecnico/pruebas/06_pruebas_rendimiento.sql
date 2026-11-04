-- Equipo 51 - Etapa V - Integrante 5 (Romero Alegre Ubaldo Diego Emiliano, DNI 43930524).
-- Medicion de la optimizacion por indices sobre VENTA en la copia de rendimiento.
-- Compara tres escenarios con la MISMA consulta (mismas columnas, filtro y lote):
--   Escenario 1: sin indice adicional (estructura original, solo la PK agrupada).
--   Escenario 2: indice no agrupado simple sobre fecha_hora, la columna del filtro.
--   Escenario 3: indice no agrupado con cobertura para las columnas de la consulta.
-- Metodo de la guia:
--   * SET STATISTICS TIME y SET STATISTICS IO para CPU, tiempo total y lecturas.
--   * SET STATISTICS PROFILE para el plan real por operador de cada corrida
--     (en SSMS tambien puede activarse el plan grafico con CTRL+M).
--   * Limpieza de cache de planes y de paginas antes de la corrida fria de cada
--     escenario, para que las tres comparaciones arranquen en igualdad.
-- El script gestiona los indices por si mismo: puede ejecutarse desde la estructura
-- original o despues de instalar sql/tecnico/06_indices.sql. Verifica ademas que los
-- tres escenarios devuelvan el mismo contenido antes de comparar metricas.
-- Requisitos del entorno: DDL y DML originales en tienda_hardware_rendimiento_etapa05
-- y lote 91 cargado (ventas 2021-2025). Salida real en
-- docs/etapa-05/evidencias/rendimiento/resultados_indices.txt.
USE tienda_hardware_rendimiento_etapa05;
GO

IF DB_NAME() <> 'tienda_hardware_rendimiento_etapa05'
    THROW 52361, 'El script de mediciones solo se ejecuta en la copia de rendimiento de etapa V.', 1;

-- Los metodos de tipo XML de las capturas de plan exigen estos ajustes,
-- necesarios tambien para sqlcmd (SSMS ya los define con estos valores).
SET QUOTED_IDENTIFIER ON;
SET ANSI_NULLS ON;
GO

-- ------------------------------------------------------------------
-- 0. Contexto del lote y de la ventana elegida.
--    Ventana trimestral: 2023-01-01 a 2023-04-01, la misma forma de rango
--    mensual/trimestral que usan los reportes de etapa IV por fecha.
-- ------------------------------------------------------------------
PRINT '=== 0. Contexto de los datos ===';
SELECT COUNT(*) AS ventas_totales, MIN(fecha_hora) AS primera, MAX(fecha_hora) AS ultima
FROM dbo.VENTA;
SELECT DATEPART(YEAR, fecha_hora) AS anio, COUNT(*) AS ventas
FROM dbo.VENTA
GROUP BY DATEPART(YEAR, fecha_hora)
ORDER BY anio;
GO

-- Tabla de apoyo para comprobar que los tres escenarios devuelven lo mismo.
IF OBJECT_ID('tempdb..#Verificacion') IS NOT NULL
    DROP TABLE #Verificacion;
CREATE TABLE #Verificacion
(
    escenario VARCHAR(40) NOT NULL,
    filas INT NOT NULL,
    suma_codigo_venta BIGINT NOT NULL,
    suma_monto_total DECIMAL(38, 2) NOT NULL,
    min_fecha_hora DATETIME NOT NULL,
    max_fecha_hora DATETIME NOT NULL
);
GO

-- ==================================================================
-- ESCENARIO 1: SIN INDICE ADICIONAL
-- ==================================================================
PRINT '=== 1. Escenario 1: sin indice adicional ===';

DROP INDEX IF EXISTS IX_VENTA_fecha_cobertura ON dbo.VENTA;
DROP INDEX IF EXISTS IX_VENTA_fecha_hora ON dbo.VENTA;
GO

-- Limpieza de plan y de paginas de datos para que la corrida fria sea comparable.
CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
SET STATISTICS PROFILE ON;
GO

PRINT 'Escenario 1 - corrida 1 (fria: sin plan y sin paginas en cache)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

PRINT 'Escenario 1 - corrida 2 (cache tibia: mismas columnas y filtro)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

PRINT 'Escenario 1 - corrida 3 (cache tibia: mismas columnas y filtro)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
SET STATISTICS PROFILE OFF;
GO

-- Comprobacion del contenido devuelto (mismo conjunto que los otros escenarios).
INSERT INTO #Verificacion (escenario, filas, suma_codigo_venta, suma_monto_total, min_fecha_hora, max_fecha_hora)
SELECT '1 sin indice adicional', COUNT(*), SUM(CAST(codigo_venta AS BIGINT)),
       SUM(monto_total), MIN(fecha_hora), MAX(fecha_hora)
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

-- ==================================================================
-- ESCENARIO 2: INDICE NO AGRUPADO SIMPLE SOBRE LA FECHA
-- ==================================================================
PRINT '=== 2. Escenario 2: indice no agrupado simple sobre fecha_hora ===';

-- La cobertura del escenario 3 se aparta para que la medicion quede limpia.
DROP INDEX IF EXISTS IX_VENTA_fecha_cobertura ON dbo.VENTA;
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.VENTA') AND name = 'IX_VENTA_fecha_hora')
    CREATE NONCLUSTERED INDEX IX_VENTA_fecha_hora
        ON dbo.VENTA (fecha_hora);
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
SET STATISTICS PROFILE ON;
GO

PRINT 'Escenario 2 - corrida 1 (fria: sin plan y sin paginas en cache)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

PRINT 'Escenario 2 - corrida 2 (cache tibia: mismas columnas y filtro)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

PRINT 'Escenario 2 - corrida 3 (cache tibia: mismas columnas y filtro)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
SET STATISTICS PROFILE OFF;
GO

INSERT INTO #Verificacion (escenario, filas, suma_codigo_venta, suma_monto_total, min_fecha_hora, max_fecha_hora)
SELECT '2 indice no agrupado de fecha', COUNT(*), SUM(CAST(codigo_venta AS BIGINT)),
       SUM(monto_total), MIN(fecha_hora), MAX(fecha_hora)
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

-- ==================================================================
-- ESCENARIO 3: INDICE NO AGRUPADO CON COBERTURA
-- ==================================================================
PRINT '=== 3. Escenario 3: indice no agrupado con cobertura ===';

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.VENTA') AND name = 'IX_VENTA_fecha_hora')
    CREATE NONCLUSTERED INDEX IX_VENTA_fecha_hora
        ON dbo.VENTA (fecha_hora);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes
               WHERE object_id = OBJECT_ID('dbo.VENTA') AND name = 'IX_VENTA_fecha_cobertura')
    CREATE NONCLUSTERED INDEX IX_VENTA_fecha_cobertura
        ON dbo.VENTA (fecha_hora)
        INCLUDE (estado, monto_total);
GO

CHECKPOINT;
DBCC DROPCLEANBUFFERS;
DBCC FREEPROCCACHE;
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
SET STATISTICS PROFILE ON;
GO

PRINT 'Escenario 3 - corrida 1 (fria: sin plan y sin paginas en cache)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

PRINT 'Escenario 3 - corrida 2 (cache tibia: mismas columnas y filtro)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

PRINT 'Escenario 3 - corrida 3 (cache tibia: mismas columnas y filtro)';
GO

-- REPORTE_TRIMESTRAL: consulta identica en los tres escenarios (Integrante 5, etapa V).
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

SET STATISTICS TIME OFF;
SET STATISTICS IO OFF;
SET STATISTICS PROFILE OFF;
GO

INSERT INTO #Verificacion (escenario, filas, suma_codigo_venta, suma_monto_total, min_fecha_hora, max_fecha_hora)
SELECT '3 indice con cobertura', COUNT(*), SUM(CAST(codigo_venta AS BIGINT)),
       SUM(monto_total), MIN(fecha_hora), MAX(fecha_hora)
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
GO

-- ------------------------------------------------------------------
-- Resultados de la comprobacion: si los tres conjuntos coinciden, la
-- comparacion de metricas es valida.
-- ------------------------------------------------------------------
PRINT '=== Verificacion de contenido entre escenarios ===';
SELECT escenario, filas, suma_codigo_venta, suma_monto_total, min_fecha_hora, max_fecha_hora
FROM #Verificacion;
GO

IF (SELECT COUNT(DISTINCT CONCAT(filas, '|', suma_codigo_venta, '|',
                                CAST(suma_monto_total AS VARCHAR(40)), '|',
                                CAST(min_fecha_hora AS VARCHAR(25)), '|',
                                CAST(max_fecha_hora AS VARCHAR(25))))
    FROM #Verificacion) = 1
    PRINT 'Los tres escenarios devolvieron exactamente el mismo conjunto: las metricas se pueden comparar.';
ELSE
    PRINT 'ATENCION: los escenarios no devolvieron el mismo conjunto; no se deben comparar metricas.';
GO

PRINT '=== Espacio ocupado por la estructura de VENTA al terminar ===';
SELECT
    ISNULL(i.name, 'Estructura base') AS indice,
    ps.row_count AS filas,
    ps.reserved_page_count * 8 / 1024.0 AS espacio_reservado_MB,
    ps.used_page_count * 8 / 1024.0 AS espacio_usado_MB
FROM sys.dm_db_partition_stats ps
LEFT JOIN sys.indexes i ON i.object_id = ps.object_id AND i.index_id = ps.index_id
WHERE ps.object_id = OBJECT_ID('dbo.VENTA')
ORDER BY ps.index_id;
GO

PRINT 'Mediciones terminadas';
PRINT 'Los dos indices quedan instalados en la copia de rendimiento';
PRINT 'Para restaurar la estructura original, ejecutar la seccion 5 de sql/tecnico/06_indices.sql';
GO
