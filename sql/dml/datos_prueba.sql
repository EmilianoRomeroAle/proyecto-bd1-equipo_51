-- =============================================================================
-- PROYECTO INTEGRADOR: BASES DE DATOS I (Año 2026)
-- Cátedra: Bases de Datos I - Lic. en Sistemas de Información (FaCENA - UNNE)
-- Equipo: 51
-- Dominio: Sistema de Gestión Comercial e Inventario de Hardware
-- Etapa III: Implementación Física (Script DML)
-- 
-- Archivo: 04_dml_datos_maestros.sql
-- Responsable (Tarea 4): Nuñez Tobias Nahuel (DNI: 46316154)
-- Descripción: Poblado inicial de datos de prueba en tablas maestras / catálogos
-- Motor: Compatible con Microsoft SQL Server / T-SQL Estándar
-- Herramienta: SQL Server Management Studio (SSMS)
-- =============================================================================

USE tienda_hardware;
GO

-- -----------------------------------------------------------------------------
-- 1. TABLA: CATEGORIA (10 Registros)
-- -----------------------------------------------------------------------------
INSERT INTO CATEGORIA (codigo_categoria, nombre_categoria) VALUES
(1, 'Procesadores'),
(2, 'Placas de Video'),
(3, 'Memorias RAM'),
(4, 'Placas Madre'),
(5, 'Almacenamiento SSD'),
(6, 'Almacenamiento HDD'),
(7, 'Fuentes de Poder'),
(8, 'Gabinetes'),
(9, 'Refrigeracion'),
(10, 'Monitores');
GO

-- -----------------------------------------------------------------------------
-- 2. TABLA: METODO_PAGO (8 Registros)
-- -----------------------------------------------------------------------------
INSERT INTO METODO_PAGO (codigo_metodo, nombre_metodo) VALUES
(1, 'Efectivo'),
(2, 'Transferencia Bancaria'),
(3, 'Tarjeta de Debito'),
(4, 'Tarjeta de Credito 1 Pago'),
(5, 'Tarjeta de Credito 3 Cuotas'),
(6, 'Tarjeta de Credito 6 Cuotas'),
(7, 'Mercado Pago'),
(8, 'Criptomonedas (USDT)');
GO

-- -----------------------------------------------------------------------------
-- 3. TABLA: CLIENTE (10 Registros - Personas particulares con DNI)
-- -----------------------------------------------------------------------------
INSERT INTO CLIENTE (dni_cuit, nombre, apellido, email, telefono) VALUES
('40123456', 'Carlos', 'Gomez', 'carlos.gomez@gmail.com', '3794112233'),
('38987654', 'Mariana', 'Lopez', 'mlopez@hotmail.com', '3794556677'),
('42555666', 'Lucas', 'Fernandez', 'lucas_f@yahoo.com.ar', '3794889900'),
('35444333', 'Sofia', 'Rodriguez', 'sofia.rodriguez@outlook.com', '3794223344'),
('43111222', 'Mateo', 'Benitez', 'mateo.benitez@gmail.com', '3794667788'),
('36777888', 'Esteban', 'Perez', 'esteban.perez@gmail.com', '3794001122'),
('39222333', 'Valeria', 'Acosta', 'valeria.acosta@gmail.com', '3794334455'),
('41888999', 'Joaquin', 'Romero', 'jromero_hw@gmail.com', '3794778899'),
('37666555', 'Camila', 'Vargas', 'camila.vargas@gmail.com', '3794990011'),
('44123987', 'Nicolas', 'Duarte', 'nicolas.duarte@hotmail.com', '3794445566');
GO

-- -----------------------------------------------------------------------------
-- 4. TABLA: PRODUCTO (10 Registros)
-- -----------------------------------------------------------------------------
INSERT INTO PRODUCTO (sku, marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria) VALUES
('CPU-AMD-5600X', 'AMD', 'Ryzen 5 5600X', '6 nucleos, 12 hilos, 3.7GHz Base, 4.6GHz Boost, Socket AM4', 215000.00, 25, 2, 1),
('CPU-INT-13400F', 'Intel', 'Core i5-13400F', '10 nucleos, 16 hilos, hasta 4.6GHz, Socket LGA1700', 248000.00, 18, 0, 1),
('GPU-ASU-4060', 'ASUS', 'GeForce RTX 4060 Dual OC', '8GB GDDR6, 128-bit, PCIe 4.0, DLSS 3', 420000.00, 12, 1, 2),
('GPU-MSI-7600XT', 'MSI', 'Radeon RX 7600 XT Mech', '16GB GDDR6, 128-bit, PCIe 4.0, FSR 3', 465000.00, 8, 0, 2),
('RAM-KIN-FURY16', 'Kingston', 'Fury Beast DDR4 16GB', '1x16GB 3200MHz CL16 Disipador Negro', 45000.00, 50, 4, 3),
('RAM-COR-VEN32', 'Corsair', 'Vengeance DDR5 32GB Kit', '2x16GB 6000MHz CL36 Intel XMP / AMD Expo', 135000.00, 20, 2, 3),
('MB-GIG-B550M', 'Gigabyte', 'B550M DS3H AC', 'Socket AM4, Micro ATX, 4 slots DDR4, PCIe 4.0, WiFi', 118000.00, 15, 1, 4),
('SSD-SAM-980PRO', 'Samsung', '980 PRO 1TB M.2 NVMe', 'Lectura hasta 7000MB/s, PCIe Gen 4.0 x4, V-NAND', 110000.00, 30, 3, 5),
('PSU-COR-RM750E', 'Corsair', 'RM750e 750W 80 Plus Gold', 'Completamente modular, ATX 3.0, PCIe 5.0 compatible', 145000.00, 14, 0, 7),
('MON-LG-24GN60R', 'LG', 'UltraGear 24GN60R-B', '24 pulgadas IPS FHD, 144Hz, 1ms, FreeSync Premium', 198000.00, 10, 1, 10);
GO

-- =============================================================================
-- PARTE 2: TABLAS TRANSACCIONALES (Responsable: Martín Miño)
-- =============================================================================

-- 5. VENTA
INSERT INTO VENTA (codigo_venta, fecha_hora, monto_total, dni_cuit) VALUES
(1,  '2026-09-01 10:15:00', 305000.00, '40123456'),
(2,  '2026-09-02 11:30:00', 420000.00, '38987654'),
(3,  '2026-09-05 14:20:00', 200000.00, '42555666'),
(4,  '2026-09-08 16:45:00', 378000.00, '35444333'),
(5,  '2026-09-10 09:10:00', 575000.00, '43111222'),
(6,  '2026-09-12 18:00:00', 145000.00, '36777888'),
(7,  '2026-09-15 12:25:00', 270000.00, '39222333'),
(8,  '2026-09-18 15:50:00', 443000.00, '41888999'),
(9,  '2026-09-20 17:10:00', 198000.00, '37666555'),
(10, '2026-09-22 19:35:00', 655000.00, '44123987');
GO

-- 6. DETALLE_VENTA
INSERT INTO DETALLE_VENTA (codigo_venta, sku, cantidad, precio_unitario) VALUES
(1, 'RAM-KIN-FURY16', 2, 45000.00),
(1, 'CPU-AMD-5600X',  1, 215000.00),
(2, 'GPU-ASU-4060',   1, 420000.00),
(3, 'SSD-SAM-980PRO', 2, 100000.00),
(4, 'MB-GIG-B550M',   1, 130000.00),
(4, 'CPU-INT-13400F', 1, 248000.00),
(5, 'MON-LG-24GN60R', 1, 198000.00),
(5, 'GPU-MSI-7600XT', 1, 377000.00),
(6, 'PSU-COR-RM750E', 1, 145000.00),
(7, 'RAM-COR-VEN32',  2, 135000.00),
(8, 'CPU-AMD-5600X',  1, 215000.00),
(8, 'MB-GIG-B550M',   1, 118000.00),
(8, 'SSD-SAM-980PRO', 1, 110000.00),
(9, 'MON-LG-24GN60R', 1, 198000.00),
(10, 'GPU-ASU-4060',  1, 420000.00),
(10, 'RAM-KIN-FURY16', 2, 45000.00),
(10, 'PSU-COR-RM750E', 1, 145000.00);
GO

-- 7. PAGA_CON
INSERT INTO PAGA_CON (codigo_venta, codigo_metodo, monto) VALUES
(1, 1, 105000.00),
(1, 2, 200000.00),
(2, 5, 420000.00),
(3, 7, 200000.00),
(4, 3, 378000.00),
(5, 6, 400000.00),
(5, 2, 175000.00),
(6, 1, 145000.00),
(7, 8, 270000.00),
(8, 1, 143000.00),
(8, 3, 300000.00),
(9, 4, 198000.00),
(10, 7, 355000.00),
(10, 2, 300000.00);
GO
