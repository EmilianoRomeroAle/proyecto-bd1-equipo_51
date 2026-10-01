# Informe de Pruebas y Validación de Datos

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  
**Autor:** Martín Miño  
**Etapa:** Etapa III — Implementación Física  

Este documento presenta los resultados de las pruebas empíricas de consistencia realizadas sobre el lote de datos de prueba cargado en `sql/dml/datos_prueba.sql`, verificando que ninguna restricción del SGBD haya sido vulnerada y demostrando la exactitud matemática de las operaciones comerciales, el cuadre multipago y el congelamiento de precios históricos.

---

## 1. Validación de No Violación de Restricciones DDL

Se verificó el comportamiento del motor de base de datos tras la ejecución completa del lote DML:

1. **Integridad de Entidad (Primary Keys):**  
   Los 10 registros de `CATEGORIA`, 8 de `METODO_PAGO`, 10 de `CLIENTE`, 10 de `PRODUCTO`, 10 de `VENTA`, 17 de `DETALLE_VENTA` y 14 de `PAGA_CON` poseen claves primarias únicas y no nulas. No se produjeron colisiones ni intentos de inserción con claves duplicadas.
2. **Integridad Referencial (Foreign Keys):**  
   Todas las referencias foráneas vincularon registros preexistentes:
   * Cada `codigo_categoria` en `PRODUCTO` corresponde a una categoría cargada.
   * Cada `dni_cuit` en `VENTA` corresponde a un cliente del padrón.
   * Cada `sku` y `codigo_venta` en `DETALLE_VENTA` y `PAGA_CON` apuntan a filas válidas en sus respectivas tablas maestras y transaccionales.
3. **Restricciones CHECK:**  
   * Ningún precio o monto registrado fue negativo ni igual a cero (`CHK_precio_lista`, `CHK_monto_total`, `CHK_cantidad`, `CHK_monto`).
   * En los 10 productos se cumple estrictamente la condición:  
     $$\text{stock\_actual} \ge \text{stock\_reservado} \ge 0$$
   * Todos los correos electrónicos cumplen con el patrón `@` y dominio.

---

## 2. Matriz de Cuadre Matemático de Ventas y Multipagos

La regla de negocio **RN.07** establece que una venta debe saldarse en su totalidad y que la suma de los montos abonados debe ser **exactamente igual** al total liquidado en la cabecera. Asimismo, la suma de los subtotales de los renglones de detalle debe coincidir con dicho total.

A continuación se detalla la comprobación aritmética comprobante por comprobante de los datos cargados en `datos_prueba.sql`:

| Venta ID | Fecha / Hora | Total Cabecera (`VENTA.monto_total`) | Suma Renglones (`DETALLE_VENTA`) | Suma Cobros (`PAGA_CON`) | Tipo de Pago | Discrepancia ($\Delta$) | Estado de Validación |
| :---: | :---: | :---: | :---: | :---: | :---: | :---: | :---: |
| **#1** | 2026-09-01 10:15 | **$305.000,00** | 2x$45k (RAM) + 1x$215k (CPU) = **$305.000,00** | $105k (Efectivo) + $200k (Transferencia) = **$305.000,00** | **Multipago (2 medios)** | **$0,00** | **VÁLIDA** |
| **#2** | 2026-09-02 11:30 | **$420.000,00** | 1x$420k (GPU RTX 4060) = **$420.000,00** | $420k (Crédito 3 Cuotas) = **$420.000,00** | Unipago | **$0,00** | **VÁLIDA** |
| **#3** | 2026-09-05 14:20 | **$200.000,00** | 2x$100k (SSD NVMe) = **$200.000,00** | $200k (Mercado Pago) = **$200.000,00** | Unipago | **$0,00** | **VÁLIDA** |
| **#4** | 2026-09-08 16:45 | **$378.000,00** | 1x$130k (Motherboard) + 1x$248k (CPU i5) = **$378.000,00** | $378k (Débito) = **$378.000,00** | Unipago | **$0,00** | **VÁLIDA** |
| **#5** | 2026-09-10 09:10 | **$575.000,00** | 1x$198k (Monitor) + 1x$377k (GPU MSI) = **$575.000,00** | $400k (Crédito 6 Cuotas) + $175k (Transferencia) = **$575.000,00** | **Multipago (2 medios)** | **$0,00** | **VÁLIDA** |
| **#6** | 2026-09-12 18:00 | **$145.000,00** | 1x$145k (Fuente Corsair) = **$145.000,00** | $145k (Efectivo) = **$145.000,00** | Unipago | **$0,00** | **VÁLIDA** |
| **#7** | 2026-09-15 12:25 | **$270.000,00** | 2x$135k (RAM Corsair DDR5) = **$270.000,00** | $270k (Cripto USDT) = **$270.000,00** | Unipago | **$0,00** | **VÁLIDA** |
| **#8** | 2026-09-18 15:50 | **$443.000,00** | 1x$215k (CPU) + 1x$118k (MB) + 1x$110k (SSD) = **$443.000,00** | $143k (Efectivo) + $300k (Débito) = **$443.000,00** | **Multipago (2 medios)** | **$0,00** | **VÁLIDA** |
| **#9** | 2026-09-20 17:10 | **$198.000,00** | 1x$198k (Monitor LG) = **$198.000,00** | $198k (Crédito 1 Pago) = **$198.000,00** | Unipago | **$0,00** | **VÁLIDA** |
| **#10** | 2026-09-22 19:35 | **$655.000,00** | 1x$420k (GPU) + 2x$45k (RAM) + 1x$145k (Fuente) = **$655.000,00** | $355k (Mercado Pago) + $300k (Transferencia) = **$655.000,00** | **Multipago (2 medios)** | **$0,00** | **VÁLIDA** |

**Resultado del Cuadre:** El 100% de las transacciones (10 de 10) presentan una discrepancia de **$\Delta = \$0,00$**, demostrando total consistencia contable tanto a nivel de detalle de productos como de asignación de medios de pago.

---

## 3. Demostración de Casos Críticos de Negocio

### 3.1. Casos de Multipago Exitoso (RN.07)
El lote de prueba incluyó intencionalmente 4 ventas que requirieron pagos fraccionados:
* **Venta #1:** Cliente abonó $105.000,00 en mostrador (Efectivo) y liquidó el saldo de $200.000,00 mediante Transferencia Bancaria inmediata.
* **Venta #5:** Venta de $575.000,00 financiada con $400.000,00 en Tarjeta de Crédito 6 Cuotas y $175.000,00 en Transferencia Bancaria.
* **Venta #8:** Compra de $443.000,00 saldada con $143.000,00 en Efectivo y $300.000,00 con Tarjeta de Débito.
* **Venta #10:** Operación mayor de $655.000,00 cubierta mediante $355.000,00 por Mercado Pago y $300.000,00 por Transferencia Bancaria.

### 3.2. Congelamiento de Precios Históricos (RN.06)
En la **Venta #3**, el cliente adquirió dos unidades del producto `'SSD-SAM-980PRO'` facturadas a un precio unitario de **$100.000,00**.  
Sin embargo, en el catálogo actual de la tabla `PRODUCTO`, dicho artículo posee un `precio_lista` de **$110.000,00**.
* **Comprobación:** La venta mantiene congelado el precio acordado de $100.000,00 en su comprobante, evidenciando de forma práctica que el aumento posterior del precio en el catálogo no distorsiona el histórico de ventas.

---

## 4. Scripts SQL de Validación Automática

Para verificar automáticamente en el motor que no existen discrepancias aritméticas en la base de datos, se ejecutaron las siguientes consultas de control:

```sql
-- -----------------------------------------------------------------------------
-- CONSULTA DE CONTROL 1: Validar que Cabecera = Suma de Detalles
-- (Debe devolver 0 registros si todas las ventas cuadran)
-- -----------------------------------------------------------------------------
SELECT 
    v.codigo_venta,
    v.monto_total AS total_cabecera,
    SUM(d.cantidad * d.precio_unitario) AS total_detalle,
    (v.monto_total - SUM(d.cantidad * d.precio_unitario)) AS diferencia
FROM VENTA v
INNER JOIN DETALLE_VENTA d ON v.codigo_venta = d.codigo_venta
GROUP BY v.codigo_venta, v.monto_total
HAVING v.monto_total <> SUM(d.cantidad * d.precio_unitario);

-- -----------------------------------------------------------------------------
-- CONSULTA DE CONTROL 2: Validar que Cabecera = Suma de Pagos
-- (Debe devolver 0 registros si todos los cobros coinciden)
-- -----------------------------------------------------------------------------
SELECT 
    v.codigo_venta,
    v.monto_total AS total_cabecera,
    SUM(p.monto) AS total_pagado,
    (v.monto_total - SUM(p.monto)) AS diferencia
FROM VENTA v
INNER JOIN PAGA_CON p ON v.codigo_venta = p.codigo_venta
GROUP BY v.codigo_venta, v.monto_total
HAVING v.monto_total <> SUM(p.monto);
```

**Resultado de Ejecución:** Ambas consultas devuelven **0 filas**, ratificando la consistencia absoluta de los datos de prueba implementados para la Etapa III.
