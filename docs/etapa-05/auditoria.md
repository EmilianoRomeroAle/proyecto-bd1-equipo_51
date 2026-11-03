# Auditoría de productos — Etapa V

**Equipo:** 51  
**Responsable del bloque:** Integrante 3  
**Motor:** SQL Server Express

## Objetivo y aplicación

Un trigger es un programa que el motor ejecuta automáticamente al producirse un evento sobre una tabla. En este caso se utiliza un trigger `AFTER UPDATE` para conservar los valores anteriores y nuevos cuando se modifica el precio de lista o las existencias de un producto.

Permite identificar qué producto cambió, cuándo ocurrió, qué usuario de SQL Server realizó la operación y cuáles eran sus valores. Se aplica tanto a una modificación manual del catálogo como a las actualizaciones de reservas y existencias realizadas por los procedimientos de ventas.

Centralizar este registro evita depender de que cada operador recuerde escribir una auditoría. Su costo es una inserción adicional por cada producto cuyo precio o existencias cambien.

## Objetos implementados

`sql/tecnico/04_auditoria_producto.sql` incorpora:

- `dbo.AUDITORIA_PRODUCTO`: identificador generado por el motor; SKU; fecha y hora; usuario; tipo de operación; precio anterior y nuevo; stock físico anterior y nuevo; stock reservado anterior y nuevo.
- `dbo.trg_PRODUCTO_Auditoria`: trigger sobre `dbo.PRODUCTO`, ejecutado después de un `UPDATE` válido.

La tabla se crea solamente si no existe. `CREATE OR ALTER TRIGGER` permite volver a instalar la definición sin eliminar los registros previos. No se utiliza una clave foránea desde la auditoría hacia PRODUCTO: la conservación del registro no debe depender de una eliminación futura del artículo.

## Funcionamiento

SQL Server ofrece dos conjuntos temporales dentro del trigger:

- `deleted`: valores anteriores al UPDATE.
- `inserted`: valores posteriores al UPDATE.

Un `JOIN` por `sku` relaciona ambos conjuntos. El `INSERT ... SELECT` registra todas las filas cuyo `precio_lista`, `stock_actual` o `stock_reservado` realmente cambió. No usa variables para guardar un solo producto, por lo que una sentencia que modifica varios productos genera una fila de auditoría por cada producto modificado.

`SYSDATETIME()` captura la fecha y hora del servidor. `SUSER_SNAME()` identifica el contexto de acceso de SQL Server; no representa un empleado o cliente del negocio. El tipo de operación guardado es `UPDATE`.

Los cambios de descripción y los UPDATE que asignan los mismos valores no agregan registros, porque quedan fuera de los cambios relevantes definidos para este bloque.

## Instalación y demostración

En una copia de prueba con el DDL y DML vigentes:

1. Ejecutar `sql/tecnico/04_auditoria_producto.sql`.
2. Ejecutar `sql/tecnico/90_datos_prueba_etapa05.sql`.
3. Ejecutar `sql/tecnico/pruebas/03_pruebas_auditoria.sql`.

La demostración utiliza `ET5-AUD-01`, `ET5-AUD-02` y la venta de prueba `95301`. Requiere esos productos con los valores iniciales del lote 90. Los productos REG, PAG e INT pertenecen a las demostraciones de los otros bloques y no se modifican aquí.

La prueba muestra una consulta de los productos modificados y otra de las auditorías generadas antes de ejecutar ROLLBACK. Esas consultas permiten revisar los valores o tomar capturas reales desde SSMS. Al terminar se revierten los cambios de productos, la venta temporal y sus auditorías: no es necesario borrar registros para repetir la demostración.

## Pruebas y verificación realizada

Las siguientes pruebas se ejecutaron correctamente el 3 de noviembre de 2026 sobre SQL Server Express, en la copia aislada `tienda_hardware_etapa05_verificacion`:

| Caso | Comprobación | Resultado observado |
| --- | --- | --- |
| P1 | Precio 1.000 a 1.100; valores de existencias, fecha, usuario y operación. | Una auditoría con los valores correspondientes. |
| P2 | Stock físico 50 a 48 y reservado 0 a 1. | Cambio de existencias registrado aunque el precio se mantuvo. |
| P3 | Una sola sentencia modifica los dos productos. | Dos auditorías adicionales, con los valores propios de cada SKU. |
| P4 | Cambiar solamente la descripción. | No agregó auditorías. |
| P5 | Asignar nuevamente los mismos precios y existencias. | No agregó auditorías. |
| P6 | Cambiar el precio de lista después de cargar una venta histórica de prueba. | El precio histórico quedó en 1.000 y la venta en 2.000. |
| P7 | ROLLBACK del conjunto de demostración. | Productos restaurados; venta temporal y auditorías deshechas. |

La salida de ejecución correcta se conserva en `docs/etapa-05/evidencias/auditoria/resultados.txt`. Las consultas de la demostración permiten obtener capturas desde SSMS.

## Alcance y límites

Este bloque audita UPDATE de precio y existencias con SKU estable. No incorpora auditoría de INSERT, DELETE, cambios de SKU ni de otras columnas. La tabla de auditoría se guarda en la misma base y transacción: un ROLLBACK también revierte sus registros; no es un registro externo de intentos fallidos.

La auditoría no impide modificar ventas abonadas, no reemplaza restricciones ni controla permisos por sí misma. La protección del circuito autorizado corresponde a los procedimientos de 1 y 2 y al futuro bloque de seguridad del integrante 4. Este bloque tampoco afirma que un administrador quede impedido de modificar datos directamente.

## Material utilizado

Se sigue el caso de auditoría de productos de la guía técnica de la etapa V y la diapositiva de Canva que muestra `inserted`, `deleted`, `SYSDATETIME()` y `SUSER_SNAME()`. La lógica utiliza INSERT, SELECT, JOIN y comparaciones sobre el modelo vigente del equipo.
