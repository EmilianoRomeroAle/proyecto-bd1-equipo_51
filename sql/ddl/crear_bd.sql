-- ====================================================================
-- PROYECTO INTEGRADOR: BASES DE DATOS I (Año 2026)
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Equipo: 51
-- Dominio: Sistema de Gestión Comercial e Inventario de Hardware
-- Etapa III: Implementación Física (Script DDL)
-- 
-- Archivo: sql/ddl/crear_bd.sql
-- Responsable Inicial (Tarea 1): Nuñez Axel Gabriel (DNI: 43275213)
-- Descripción: Creación de la base de datos y definición de tablas maestras/independientes
-- Motor: Compatible con Microsoft SQL Server / T-SQL Estándar
-- ====================================================================

-- --------------------------------------------------------------------
-- 1. CREACIÓN Y POSICIONAMIENTO EN LA BASE DE DATOS
-- --------------------------------------------------------------------
IF NOT EXISTS (SELECT name FROM sys.databases WHERE name = 'tienda_hardware')
BEGIN
    CREATE DATABASE tienda_hardware;
END
GO

USE tienda_hardware;
GO

-- ====================================================================
-- BLOQUE 1: TABLAS BASE / MAESTRAS (INTEGRANTE 1 - Nuñez Axel Gabriel)
-- ====================================================================

-- --------------------------------------------------------------------
-- Tabla: CATEGORIA
-- Catálogo de clasificación de componentes de hardware (RN.05)
-- --------------------------------------------------------------------
CREATE TABLE CATEGORIA
(
    codigo_categoria INT NOT NULL,
    nombre_categoria VARCHAR(100) NOT NULL,
    
    -- Clave Primaria
    CONSTRAINT PK_CATEGORIA PRIMARY KEY (codigo_categoria),
    
    -- Restricción de Unicidad
    CONSTRAINT UQ_CATEGORIA_nombre UNIQUE (nombre_categoria)
);
GO

-- --------------------------------------------------------------------
-- Tabla: METODO_PAGO
-- Catálogo de medios de pago autorizados en el negocio (RN.04)
-- --------------------------------------------------------------------
CREATE TABLE METODO_PAGO
(
    codigo_metodo INT NOT NULL,
    nombre_metodo VARCHAR(100) NOT NULL,
    
    -- Clave Primaria
    CONSTRAINT PK_METODO_PAGO PRIMARY KEY (codigo_metodo),
    
    -- Restricción de Unicidad
    CONSTRAINT UQ_METODO_PAGO_nombre UNIQUE (nombre_metodo)
);
GO

-- --------------------------------------------------------------------
-- Tabla: CLIENTE
-- Padrón unificado de clientes particulares y corporativos (RN.01)
-- Derivado del atributo compuesto 'contacto' en 1FN (email y telefono atómicos)
-- --------------------------------------------------------------------
CREATE TABLE CLIENTE
(
    dni_cuit VARCHAR(20) NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    apellido VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    
    -- Clave Primaria
    CONSTRAINT PK_CLIENTE PRIMARY KEY (dni_cuit),
    
    -- Restricción de Unicidad para contacto digital
    CONSTRAINT UQ_CLIENTE_email UNIQUE (email)
);
GO

-- --------------------------------------------------------------------
-- Tabla: PRODUCTO
-- Catálogo de componentes informáticos y periféricos con control de stock (RN.02, RN.05, RN.08)
-- Nota: 'stock_disponible' es atributo derivado, no se persiste físicamente.
-- --------------------------------------------------------------------
CREATE TABLE PRODUCTO
(
    sku VARCHAR(50) NOT NULL,
    marca VARCHAR(100) NOT NULL,
    modelo VARCHAR(100) NOT NULL,
    descripcion_tecnica VARCHAR(255) NULL,
    precio_lista DECIMAL(12, 2) NOT NULL,
    stock_actual INT NOT NULL,
    stock_reservado INT NOT NULL,
    codigo_categoria INT NOT NULL,
    
    -- Clave Primaria
    CONSTRAINT PK_PRODUCTO PRIMARY KEY (sku)
);
GO

-- ====================================================================
-- ESPACIO ASIGNADO A INTEGRANTES 2 Y 3:
-- (A continuación se incorporan las tablas transaccionales, FKs y restricciones CHECK/DEFAULT)
-- 
-- Integrante 2 agregará:
--   - Tabla VENTA (con FK hacia CLIENTE)
--   - Tabla DETALLE_VENTA (con FKs hacia VENTA y PRODUCTO, PK compuesta)
--   - Tabla PAGA_CON (con FKs hacia VENTA y METODO_PAGO, PK compuesta)
--   - FK de PRODUCTO hacia CATEGORIA (ALTER TABLE PRODUCTO ADD CONSTRAINT FK_PRODUCTO_CATEGORIA...)
--
-- Integrante 3 agregará:
--   - Restricciones CHECK (precio_lista > 0, stock_actual >= 0, etc.)
--   - Restricciones DEFAULT (fecha_hora, estados, stock_reservado = 0, etc.)
-- ====================================================================
