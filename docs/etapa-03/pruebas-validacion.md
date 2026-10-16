# Pruebas y validación de datos

**Asignatura:** Bases de Datos I, año 2026

**Equipo:** 51

**Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware

**Autor:** Martín Miño

**Etapa:** III

## 1. Alcance de la revisión

La validación se divide en la revisión del lote y las pruebas para ejecutar en SQL Server. Los conteos y cálculos siguientes se obtienen de los valores escritos en `sql/dml/datos_prueba.sql`. Cada control SQL indica el resultado esperado después de cargar los datos.

| Tabla | Filas del lote |
| --- | ---: |
| `CATEGORIA` | 10 |
| `METODO_PAGO` | 8 |
| `CLIENTE` | 10 |
| `PRODUCTO` | 10 |
| `VENTA` | 10 |
| `DETALLE_VENTA` | 17 |
| `PAGA_CON` | 14 |

Las claves del lote no se repiten dentro de sus tablas y las referencias corresponden a registros incluidos en la carga. En los detalles se considera la clave completa `(codigo_venta, id)`, por lo que `id = 1` puede aparecer en distintas ventas.

Las 10 ventas tienen estado `Abonado`. Los 10 productos tienen `stock_reservado = 0`; sus existencias representan el stock al momento de la carga, sin reservas pendientes.

## 2. Cuadre de ventas

La RN.04 exige que el importe abonado coincida con el total para que la venta quede en estado `Abonado`. También se comprueba que el total de cabecera corresponda a la suma de cantidad por precio histórico de los renglones.

Los importes de esta tabla están expresados en pesos. Cada fila resume los valores presentes en el DML.

| Venta | Total de cabecera | Suma de detalles | Suma de pagos | Diferencia |
| ---: | ---: | --- | --- | ---: |
| 1 | 305.000,00 | 2 × 45.000 + 215.000 = 305.000 | 105.000 + 200.000 = 305.000 | 0,00 |
| 2 | 420.000,00 | 420.000 | 420.000 | 0,00 |
| 3 | 200.000,00 | 2 × 100.000 = 200.000 | 200.000 | 0,00 |
| 4 | 378.000,00 | 130.000 + 248.000 = 378.000 | 378.000 | 0,00 |
| 5 | 575.000,00 | 198.000 + 377.000 = 575.000 | 400.000 + 175.000 = 575.000 | 0,00 |
| 6 | 145.000,00 | 145.000 | 145.000 | 0,00 |
| 7 | 270.000,00 | 2 × 135.000 = 270.000 | 270.000 | 0,00 |
| 8 | 443.000,00 | 215.000 + 118.000 + 110.000 = 443.000 | 143.000 + 300.000 = 443.000 | 0,00 |
| 9 | 198.000,00 | 198.000 | 198.000 | 0,00 |
| 10 | 655.000,00 | 420.000 + 2 × 45.000 + 145.000 = 655.000 | 355.000 + 300.000 = 655.000 | 0,00 |

El cálculo del lote coincide en las 10 ventas. Las ventas 1, 5, 8 y 10 combinan dos medios de pago.

## 3. Consultas de control

Después de ejecutar los scripts en una base de prueba, seleccionar `tienda_hardware` en SSMS y ejecutar cada consulta por separado.

### Cabecera y detalles

```sql
SELECT v.codigo_venta,
       v.monto_total AS total_cabecera,
       COALESCE(SUM(d.cantidad * d.precio_uni_historico), 0) AS total_detalle,
       v.monto_total - COALESCE(SUM(d.cantidad * d.precio_uni_historico), 0) AS diferencia
FROM VENTA v
LEFT JOIN DETALLE_VENTA d ON d.codigo_venta = v.codigo_venta
GROUP BY v.codigo_venta, v.monto_total
HAVING COUNT(d.id) = 0
    OR v.monto_total <> COALESCE(SUM(d.cantidad * d.precio_uni_historico), 0);
```

Resultado esperado para el lote: cero filas. El `LEFT JOIN` conserva ventas sin detalle y `COUNT(d.id) = 0` permite detectarlas. El control considera todas las ventas registradas.

### Cabecera y pagos de ventas abonadas

```sql
SELECT v.codigo_venta,
       v.monto_total AS total_cabecera,
       COALESCE(SUM(p.monto_abonado), 0) AS total_pagado,
       v.monto_total - COALESCE(SUM(p.monto_abonado), 0) AS diferencia
FROM VENTA v
LEFT JOIN PAGA_CON p ON p.codigo_venta = v.codigo_venta
WHERE v.estado = 'Abonado'
GROUP BY v.codigo_venta, v.monto_total
HAVING COUNT(p.codigo_metodo) = 0
    OR v.monto_total <> COALESCE(SUM(p.monto_abonado), 0);
```

Resultado esperado para el lote: cero filas. Incluye ventas abonadas sin pagos y detecta diferencias de importes. Las ventas pendientes pueden tener pagos parciales, por lo que no se les exige aquí el cuadre completo.

### Precio histórico

```sql
SELECT d.codigo_venta, d.id, d.sku, d.cantidad,
       d.precio_uni_historico, p.precio_lista
FROM DETALLE_VENTA d
JOIN PRODUCTO p ON p.sku = d.sku
WHERE d.codigo_venta = 3
  AND d.sku = 'SSD-SAM-980PRO';
```

Resultado esperado: un renglón de la venta 3, con cantidad 2, `precio_uni_historico = 100000.00` y `precio_lista = 110000.00`. El ejemplo muestra la separación de los dos precios de RN.03. El total usa el precio histórico y resulta 200.000,00.

### Valores predeterminados

```sql
EXEC sp_help 'VENTA';
EXEC sp_help 'PRODUCTO';
```

En los resultados, revisar las restricciones `DEFAULT`: `DF_VENTA_estado` debe indicar `Pendiente`, `DF_VENTA_fecha_hora` la fecha y hora actuales, y `DF_PRODUCTO_stock_reservado` el valor 0. `sp_help` muestra información de las tablas sin insertar ni modificar datos.

## 4. Pruebas negativas manuales

Estas prácticas se realizan después de la carga, en una base de prueba que conserve el lote original. Ejecutar una sola sentencia por vez y revisar el mensaje. El resultado esperado en cada caso es el rechazo de la sentencia, sin modificar las filas del lote.

### Clave primaria compuesta

```sql
INSERT INTO DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico)
VALUES (1, 1, 'CPU-AMD-5600X', 1, 215000.00);
```

Resultado esperado: rechazo por `PK_DETALLE_VENTA`, porque el renglón `(1, 1)` ya existe.

### Clave foránea

```sql
UPDATE PRODUCTO
SET codigo_categoria = 9999
WHERE sku = 'CPU-AMD-5600X';
```

Resultado esperado: rechazo por `FK_PRODUCTO_CATEGORIA`, porque la categoría 9999 no está en el lote.

### Dato obligatorio

```sql
UPDATE CLIENTE
SET telefono = NULL
WHERE dni_cuit = '40123456';
```

Resultado esperado: rechazo por `NOT NULL` en `CLIENTE.telefono`.

### Estado no admitido

```sql
UPDATE VENTA
SET estado = 'Otro'
WHERE codigo_venta = 1;
```

Resultado esperado: rechazo por `CHK_VENTA_estado`.

### Número de renglón no positivo

```sql
UPDATE DETALLE_VENTA
SET id = 0
WHERE codigo_venta = 1 AND id = 1;
```

Resultado esperado: rechazo por `CHK_DETALLE_VENTA_id`.

### Precio histórico negativo

```sql
UPDATE DETALLE_VENTA
SET precio_uni_historico = -1
WHERE codigo_venta = 1 AND id = 1;
```

Resultado esperado: rechazo por `CHK_DETALLE_VENTA_precio_uni_historico`.

### Pago sin importe positivo

```sql
UPDATE PAGA_CON
SET monto_abonado = 0
WHERE codigo_venta = 1 AND codigo_metodo = 1;
```

Resultado esperado: rechazo por `CHK_PAGA_CON_monto_abonado`.

### Correo duplicado

```sql
UPDATE CLIENTE
SET email = 'carlos.gomez@gmail.com'
WHERE dni_cuit = '38987654';
```

Resultado esperado: rechazo por `UQ_CLIENTE_email`, porque el correo ya pertenece al cliente con DNI 40123456.
