**Equipo:** 51  
**Integrante 5:** Romero Alegre Ubaldo Diego Emiliano (DNI 43930524)

---

## 1. Definición y Objetivo

Un **índice** es una estructura auxiliar y ordenada (un árbol B en disco) que SQL Server mantiene junto a la tabla para acelerar el acceso a los datos. Hay dos tipos:

- **Agrupado (clustered):** ordena físicamente los datos de la tabla; solo puede existir uno por tabla. En `VENTA` es `PK_VENTA`, ordenada por `codigo_venta`.
- **No agrupado (nonclustered):** estructura aparte con las columnas elegidas ordenadas; cada entrada guarda además un **localizador** hacia la fila (en esta base, la clave primaria agrupada). Puede haber varios por tabla y admite columnas adicionales con `INCLUDE`.

El objetivo de la actividad es **medir el efecto real de los índices sobre una única consulta representativa** (reporte de ventas por rango de fechas), comparando tres escenarios con la misma proyección, el mismo filtro y el mismo lote, con las estadísticas y los planes de ejecución indicados por la guía.

## 2. Ventajas y Aplicaciones

- **Consultas por rango:** cuando el primer componente del índice es la columna del filtro, el motor localiza el primer registro del rango y recorre en orden hasta el final, sin leer el resto de la tabla.
- **Índice de cobertura (`INCLUDE`):** si el índice también contiene las columnas que proyecta la consulta, esta se responde leyendo solo el índice (`Index Seek`), sin visitar la tabla ni hacer «key lookups».
- **Aplicación en el sistema:** los reportes y listados fechados sobre `VENTA` (ventas de un mes o trimestre, cierres, facturación) son el caso de uso natural.

## 3. Problema Concreto del Sistema que Resuelve

El historial de ventas crece con cada operación. Con la estructura original, un reporte por período obliga a un **escaneo del índice agrupado**: sobre el lote de rendimiento (1.000.010 filas), el motor leyó **6.441 páginas lógicas** para devolver las 49.320 ventas del trimestre elegido. Con el índice de cobertura la misma consulta necesita **236 lecturas**: el beneficio crece a medida que el historial crece y la fracción consultada se mantiene chica.

## 4. Objetos y Tablas Involucrados

| Objeto | Rol en la medición |
| --- | --- |
| `tienda_hardware_rendimiento_etapa05` | Copia de rendimiento (DDL y DML originales + lote `91_lote_rendimiento.sql` del integrante 3) |
| `dbo.VENTA` | Tabla medida: `codigo_venta`, `fecha_hora`, `estado`, `monto_total` |
| `PK_VENTA` | Índice agrupado preexistente por `codigo_venta` (intacto) |
| `IX_VENTA_fecha_hora` | Índice creado: clave `fecha_hora` (escenario 2) |
| `IX_VENTA_fecha_cobertura` | Índice creado: clave `fecha_hora`, `INCLUDE (estado, monto_total)` (escenario 3) |

Distribución real del lote por año: 2021: 200.020 · 2022: 200.020 · 2023: 200.020 · 2024: 200.568 · 2025: 199.372 · 2026 (ventas originales del DML): 10.

Ventana elegida: **primer trimestre de 2023 → 49.320 filas (4,93 % del lote)**, con la misma forma de rango fechado que los reportes de la etapa IV.

## 5. Implementación en SQL Server

Consulta representativa, idéntica en los tres escenarios (mismas columnas, filtro y lote):

```sql
SELECT codigo_venta, fecha_hora, estado, monto_total
FROM dbo.VENTA
WHERE fecha_hora >= '2023-01-01T00:00:00'
  AND fecha_hora < '2023-04-01T00:00:00';
```

Índices creados por `sql/tecnico/06_indices.sql`:

```sql
CREATE NONCLUSTERED INDEX IX_VENTA_fecha_hora
    ON dbo.VENTA (fecha_hora);

CREATE NONCLUSTERED INDEX IX_VENTA_fecha_cobertura
    ON dbo.VENTA (fecha_hora)
    INCLUDE (estado, monto_total);
```

Decisiones de adaptación de la guía:

- **No se toca la PK agrupada ni se create otro índice agrupado**: el escenario base se llama «sin índice adicional», porque la tabla ya tiene la estructura asociada a su clave primaria.
- `codigo_venta` no se incluye en la cobertura: el localizador de todo índice no agrupado ya guarda la clave primaria agrupada.
- `estado` y `monto_total` se agregan con `INCLUDE` para responder la consulta sin visitar la tabla.

Los scripts solo usan características generales de SQL Server (compatibles también con Express); las mediciones reales se ejecutaron en una instancia local de SQL Server 2022.

## 6. Requisitos Previos y Ejemplo de Ejecución

1. Base `tienda_hardware_rendimiento_etapa05` con el DDL y el DML originales (adaptando el `USE`) y el lote `sql/tecnico/91_lote_rendimiento.sql` ya cargado.
2. Instalar los índices (opcional; el script de mediciones también los gestiona): `sqlcmd -S localhost -E -i sql\tecnico\06_indices.sql`.
3. Medir: `sqlcmd -S localhost -E -i sql\tecnico\pruebas\06_pruebas_rendimiento.sql`, o ejecutarlo en SSMS con «Incluir plan de ejecución real» (CTRL+M) para ver el plan gráfico.
4. La prueba se numeró `06_pruebas_rendimiento.sql` porque `05_pruebas_seguridad.sql` ya ocupa el número 05 en esa carpeta.

Antes de cada corrida fría se ejecuta `CHECKPOINT; DBCC DROPCLEANBUFFERS; DBCC FREEPROCCACHE;` (sin plan ni páginas en caché) y se realizan 3 corridas por escenario (1 fría + 2 con caché cálida) sobre una única consulta.

## 7. Pruebas, Resultados Esperados y Resultados Obtenidos

Antes de comparar, el script verificó que los tres escenarios devuelvan **exactamente el mismo conjunto** (condición cumplida): 49.320 filas; suma de `codigo_venta` 44.412.655.709.160; suma de `monto_total` 49.320.000,00; mínima `2023-01-01 12:00:00`; máxima `2023-03-31 12:00:00`.

### 7.1 Tabla comparativa (métricas reales)

| Escenario | Corrida | Lecturas lógicas | CPU (ms) | Tiempo total (ms) | Operación de acceso | ¿Usa el índice? |
| --- | --- | --- | --- | --- | --- | --- |
| 1. Sin índice adicional | 1 (fría) | 6.441 | 218 | 22.973 | Parallelism + Clustered Index Scan | — |
| 1. Sin índice adicional | 2 | 6.433 | 220 | 22.941 | Parallelism + Clustered Index Scan | — |
| 1. Sin índice adicional | 3 | 6.441 | 344 | 22.532 | Parallelism + Clustered Index Scan | — |
| 2. Índice simple de fecha | 1 (fría) | 6.441 | 326 | 18.414 | Parallelism + Clustered Index Scan | **No** |
| 2. Índice simple de fecha | 2 | 6.413 | 391 | 12.422 | Parallelism + Clustered Index Scan | No |
| 2. Índice simple de fecha | 3 | 6.409 | 219 | 9.811 | Parallelism + Clustered Index Scan | No |
| 3. Índice con cobertura | 1 (fría) | 236 | 32 | 11.211 | **Index Seek** (serial) | **Sí** |
| 3. Índice con cobertura | 2 | 236 | 47 | 10.877 | Index Seek (serial) | Sí |
| 3. Índice con cobertura | 3 | 236 | 78 | 11.864 | Index Seek (serial) | Sí |

Compilación de la corrida fría (parse + compile): E1 15/81 ms · E2 16/90 ms · E3 15/444 ms.

Nota sobre los tiempos totales: en esta máquina fluctuaron mucho más que CPU y lecturas (corridas equivalentes se diferencian hasta un ~50 %). Las conclusiones se apoyan en lecturas, CPU y plan, que fueron estables; aun así, el escenario 3 mostró el menor tiempo de forma consistente.

### 7.2 Planes de ejecución reales (`SET STATISTICS PROFILE`)

Escenarios 1 y 2, plan idéntico (estimación de 49.877 filas en E1 y 49.594 en E2/E3; costo total del subárbol 5,8374 / 5,8367):

```text
Parallelism (Gather Streams)
  └─ Clustered Index Scan (OBJECT: PK_VENTA, WHERE fecha_hora >= ... AND fecha_hora < ...)
```

Escenario 3 (serial; costo total 0,22968726, unas 25 veces menor):

```text
Index Seek (OBJECT: IX_VENTA_fecha_cobertura,
            SEEK: fecha_hora >= '2023-01-01 00:00:00.000'
              AND fecha_hora < '2023-04-01 00:00:00.000')
```

El detalle por operador y por corrida está en `docs/etapa-05/evidencias/rendimiento/resultados_indices.txt`.

### 7.3 Resultado esperado vs. obtenido

- **Esperado y cumplido:** el escenario 3 produce `Index Seek` sin leer la tabla: 236 lecturas lógicas (las hojas del índice; en la corrida fría, 1 física con read-ahead 232).
- **No esperado y documentado:** el escenario 2 **no produjo `Index Seek`**. Con un 4,93 % de selectividad, usar el índice habría exigido unas 49.000 «key lookups» contra la tabla, más caras que el escaneo; el optimizador conservó el plan original. Sus lecturas y CPU son las del escaneo, y la diferencia de tiempo frente al escenario 1 es ruido del entorno, no mejora del índice.
- La distancia entre «existe un índice» y «el índice cubre la consulta» quedó demostrada con métricas: es el corazón de esta actividad.

### 7.4 Espacio adicional real

| Índice | Filas | Reservado (MB) | Usado (MB) |
| --- | --- | --- | --- |
| `PK_VENTA` (estructura base) | 1.000.010 | 49,82 | 49,65 |
| `IX_VENTA_fecha_hora` | 1.000.010 | 17,59 | 17,48 |
| `IX_VENTA_fecha_cobertura` | 1.000.010 | 36,90 | 36,83 |

### 7.5 Beneficio observado y costo de mantener los índices

- **Beneficio (misma consulta y mismo resultado):** lecturas 6.441 → 236 (÷27); CPU 218–344 ms → 32–78 ms (÷4 a ÷7); costo estimado del plan 5,837 → 0,230 (÷25); tiempo total ~22,5–23,0 s → ~10,9–11,9 s (aprox. ÷2).
- **Costo de espacio:** los dos índices suman 54,48 MB, aproximadamente otro `VENTA` entero (49,82 MB). El de cobertura pesa más porque duplica `estado` y `monto_total` en cada registro.
- **Costo de modificación:** cada `INSERT`, `UPDATE` o `DELETE` sobre `VENTA` ahora mantiene tres estructuras en lugar de una; las escrituras extra en `fecha_hora`, `estado` y `monto_total` son el precio de las lecturas rápidas. Cada índice debe justificarse con un patrón de consulta real (aquí: reportes fechados) y evitarse «por si acaso».

## 8. Limitaciones de la Implementación

- Se midió **una sola consulta**: demuestra el patrón por rango fechado; no generaliza a cualquier consulta sobre `VENTA`.
- El índice simple no ayuda con esta selectividad; filtros más selectivos (un día, un rango chico) podrían aprovecharlo con Seek + lookups (no medido).
- Los tiempos totales dependen del estado de la máquina de prueba; CPU y lecturas son las métricas repetibles.
- La primera versión del script capturaba el plan desde `sys.dm_exec_query_stats`, pero esta instancia expulsa esos planes casi de inmediato; se cambió a `SET STATISTICS PROFILE`, que entrega el plan real de cada corrida sin depender de la caché. En SSMS el equivalente visual es CTRL+M.
- Edición real del entorno: SQL Server 2022; los scripts no usan características exclusivas de una edición (válido también en Express), pero las cifras concretas varían según el hardware.
