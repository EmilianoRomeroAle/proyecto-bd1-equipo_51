# Pagos, confirmación y vencimiento de ventas

El objetivo de este bloque es que los cambios de una venta se realicen juntos. Por ejemplo, al recibir el último pago deben quedar registrados el cobro, el descuento del stock, la liberación de la reserva y el estado Abonado. Si alguna de esas operaciones falla, se deben deshacer también las anteriores.

El desarrollo usa las tablas VENTA, DETALLE_VENTA, PAGA_CON, PRODUCTO y METODO_PAGO del modelo vigente. No agrega otra forma de registrar ventas ni modifica los precios históricos.

## Archivos y requisitos

- [Procedimientos de pagos y vencimientos](../../sql/tecnico/03_pagos_y_vencimientos.sql).
- [Pruebas de transacciones](../../sql/tecnico/pruebas/02_pruebas_transacciones.sql).
- [Salida de la ejecución verificada](./evidencias/transacciones/resultados.txt).

Primero se debe instalar el DDL vigente, que incluye VENTA.estado, DETALLE_VENTA.id, DETALLE_VENTA.precio_uni_historico y PAGA_CON.monto_abonado. La versión anterior del DDL que está fuera del repositorio no tiene esos mismos campos.

Después se ejecutan las funciones y los procedimientos del integrante 1. Este bloque utiliza `dbo.fn_TotalVenta(@codigo_venta)` para calcular la suma de cantidades por precios históricos. Los procedimientos de ambos integrantes comparten los estados Pendiente, Abonado y Cancelado, y el plazo de 24 horas.

Para las pruebas se necesita el archivo `90_datos_prueba_etapa05.sql` del integrante 3, con el cliente 99000051, los métodos 9051 y 9052 y los productos ET5-PAG-01 y ET5-PAG-02. Sus precios iniciales son 1000 y 500, y su stock inicial es 50 y 30, respectivamente, sin reservas. Las ventas 95201 a 95249 quedan destinadas a las pruebas de este bloque.

El orden de ejecución es:

1. DDL vigente y lote inicial del proyecto.
2. Funciones y registro de ventas del integrante 1.
3. `03_pagos_y_vencimientos.sql`.
4. Datos de prueba del integrante 3.
5. `02_pruebas_transacciones.sql`.

Los scripts contienen `USE tienda_hardware`. Para verificar se ejecutaron en una base separada llamada `tienda_hardware_etapa05_verificacion`, cambiando únicamente ese nombre. No se probaron sobre las diez ventas históricas del lote original.

## Transacciones y manejo de errores

Una transacción agrupa varias sentencias como una sola operación. `BEGIN TRANSACTION` marca el comienzo, `COMMIT TRANSACTION` confirma los cambios y `ROLLBACK TRANSACTION` los deshace cuando hay un error.

Los procedimientos usan la siguiente estructura:

```sql
SET XACT_ABORT ON;
BEGIN TRY
    BEGIN TRANSACTION;
    -- Validaciones y cambios de la operación.
    COMMIT TRANSACTION;
END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
    THROW;
END CATCH;
```

`TRY...CATCH` permite tratar el error. `@@TRANCOUNT` indica si todavía hay una transacción abierta y `THROW` informa el problema al que llamó al procedimiento. `XACT_ABORT ON` evita que ciertos errores de ejecución dejen confirmada sólo una parte del trabajo. `NOCOUNT ON` reduce los mensajes de cantidad de filas afectadas.

En términos de ACID, la atomicidad se observa al revertir todos los cambios de una operación que falla. La consistencia se apoya en los controles de importes, estados y existencias, además de las claves y restricciones del DDL. Para el aislamiento se conserva un bloqueo sobre la venta mientras se agregan renglones, se cobra, se confirma o se cancela. La durabilidad corresponde al almacenamiento de los cambios que el motor confirma. Las pruebas de este bloque no incluyen reinicios del servidor ni recuperación ante una caída.

La lectura de VENTA utiliza `WITH (UPDLOCK, HOLDLOCK)` dentro de la transacción. Así se reserva la cabecera para actualizarla y se mantiene ese bloqueo hasta el final. Los procedimientos del integrante 1 usan el mismo criterio. Esta coordinación se aplica al circuito previsto de procedimientos; no sustituye los permisos ni impide cambios directos de una cuenta administradora. No se hizo una prueba de carga con muchas sesiones simultáneas.

## Registro de pagos

`dbo.usp_RegistrarPago` recibe el código de venta, el código del método y el monto abonado, de tipo DECIMAL(12,2).

Antes de cobrar, verifica que el importe no sea NULL y sea mayor que cero, que la venta exista, siga Pendiente y todavía no haya cumplido 24 horas. También comprueba que el método esté registrado y que el total de cabecera coincida con el de los renglones.

La clave de PAGA_CON es `(codigo_venta, codigo_metodo)`. Por eso, si ya hay un pago con ese método, el nuevo importe se suma en esa misma fila. Si es otro método, se inserta una fila nueva. Se rechaza cualquier importe que supere el saldo pendiente.

Mientras el pago sea parcial, el estado queda Pendiente y el stock no cambia. Cuando la suma pagada alcanza exactamente el total, el procedimiento llama a `dbo.usp_ConfirmarVenta` dentro de la misma transacción.

Ejemplo de uso, para una venta pendiente y vigente preparada previamente con total suficiente:

```sql
EXEC dbo.usp_RegistrarPago
    @codigo_venta = 95201,
    @codigo_metodo = 9051,
    @monto_abonado = 1000.00;
```

No se debe ejecutar ese ejemplo suponiendo que la venta existe: el archivo de pruebas prepara 95201 y la elimina al finalizar. Para una demostración completa y repetible se utiliza el archivo de pruebas.

## Confirmación de la venta

`dbo.usp_ConfirmarVenta(@codigo_venta)` comprueba que la venta esté Pendiente y vigente. Exige un total positivo y la siguiente igualdad:

`total de VENTA = suma de cantidad × precio_uni_historico = suma de pagos`

Una venta sin detalles o con pago incompleto no puede confirmarse. El cálculo usa los precios guardados en los renglones, aunque después cambie el precio de lista de PRODUCTO.

Un producto puede aparecer en varios renglones porque la clave del detalle es `(codigo_venta, id)`. Por eso se agrupan las cantidades por SKU antes de modificar PRODUCTO. Por cada producto se descuentan las mismas unidades del stock físico y de la reserva.

La actualización incluye las condiciones `stock_actual >= cantidad` y `stock_reservado >= cantidad`. Después se compara `@@ROWCOUNT` con la cantidad de productos que debían cambiar. Si falta alguno, se genera un error y se revierte la operación entera. Consultar el stock previamente no sería suficiente para dar por realizada la actualización.

Cuando todos los productos se actualizaron correctamente, VENTA pasa a Abonado. Una segunda confirmación se rechaza porque la venta ya no está Pendiente.

Aunque ConfirmarVenta tiene su propio BEGIN y COMMIT, al llamarlo desde RegistrarPago se mantiene una sola transacción exterior. El COMMIT interno disminuye el contador de transacciones; el cambio queda confirmado cuando termina también RegistrarPago. Si la confirmación falla, el ROLLBACK alcanza al último pago y a los demás cambios de esa operación. Esta versión usa reversión completa, sin puntos de guardado: si otro programa la llama dentro de una transacción propia y ocurre un error, también se revierte esa transacción.

## Cancelación por vencimiento

`dbo.usp_CancelarVentasVencidas` no recibe parámetros. Selecciona las ventas Pendientes cuya fecha sea menor o igual a la fecha actual menos 24 horas y que todavía no tengan el pago completo.

Primero guarda los códigos seleccionados en una variable de tabla. Esto mantiene el mismo conjunto de ventas durante toda la operación. Luego obtiene las cantidades a liberar, agrupadas por SKU, en otra variable de tabla. Son listas auxiliares del procedimiento, no tablas permanentes del modelo.

Los pagos se suman por separado de los detalles. Unir directamente pagos y renglones antes de sumar podría multiplicar las filas y liberar más unidades de las que corresponden.

La cancelación resta las cantidades de `stock_reservado` y cambia el estado a Cancelado. No cambia `stock_actual`, porque reservar una venta todavía no había descontado el stock físico. Si las reservas son insuficientes, la operación falla y vuelve atrás por completo.

Las cabeceras, los detalles y los pagos se conservan. Una segunda ejecución no vuelve a liberar las mismas unidades porque las ventas canceladas ya no cumplen el filtro Pendiente. Una pendiente con pago completo se excluye de la cancelación. Si se generó manualmente esa inconsistencia y además ya venció, debe revisarse su origen; el procedimiento no inventa un cierre ni una devolución.

La ejecución se hace expresamente:

```sql
EXEC dbo.usp_CancelarVentasVencidas;
```

No se instaló un trabajo programado. Si una venta vencida tiene un pago parcial, éste permanece registrado. El reintegro necesita una decisión y un registro que el modelo actual no incluye.

## Pruebas realizadas

El 3 de noviembre de 2026 se ejecutaron los scripts en SQL Server Express, mediante autenticación de Windows y en la base aislada indicada. La ejecución completa terminó con código de salida 0 y el mensaje `PRUEBAS DE TRANSACCIONES COMPLETADAS.`. El registro de resultados se adjunta en la carpeta de evidencias.

| Grupo | Caso y resultado observado |
| --- | --- |
| 01 | Pago parcial: conserva Pendiente, stock físico y reservas. |
| 02 | Dos pagos con el mismo método: queda una fila con 1500. |
| 03 | Multipago de 4000: pasa a Abonado, agrupa el SKU repetido y deja stocks físicos 47 y 28, con reservas 0. |
| 04 | Segunda confirmación y nuevo pago de una Abonada: rechazados sin otro descuento. |
| 05 | Último pago con reserva insuficiente: se rechaza y no queda el pago insertado. |
| 06 | Error provocado al cambiar el estado, después de modificar existencias: vuelven atrás pago, stock, reserva y estado. No queda una transacción abierta. |
| 07 | Sobrepago, importe NULL, cero, negativo y método inexistente: rechazados sin pagos residuales. |
| 08 | Confirmación con pago incompleto o total de cabecera distinto: rechazada. |
| 09 | Venta sin renglones y venta inexistente: rechazadas. |
| 10 | Pago a las 24 horas cumplidas, confirmación vencida y pago de Cancelada: rechazados. |
| 11 | Dos vencidas con producto compartido, renglones repetidos y varios pagos: libera 4 y 2 unidades, conserva detalles y pagos, y mantiene el stock físico. |
| 12 | Nueva cancelación: no duplica efectos ni deja transacciones abiertas. |
| 13 | Cancelación con reserva insuficiente en un producto: revierte todo el lote, sin liberaciones parciales. |

Para el grupo 06 se agrega temporalmente una restricción que impide pasar a Abonado únicamente a la venta 95203. Así el error se produce después de ejecutar el descuento de existencias. Se comprueba el ROLLBACK y se retira la restricción. No forma parte del desarrollo comercial.

Las pruebas muestran las ventas, los pagos y el stock resultantes antes de la limpieza. Algunas filas se preparan con inconsistencias deliberadas para comprobar los rechazos. Al final se eliminan las ventas de prueba de este bloque y se restablecen sus dos productos a stock 50 y 30, reservas 0. No se borran las filas de auditoría que pueda generar el trigger del integrante 3.

La cantidad y la fecha de una venta no son parámetros de estos tres procedimientos. Su validación al registrar se encuentra en el bloque del integrante 1; el DDL también define cantidad y fecha como NOT NULL. Aquí se prueba el importe NULL y el vencimiento de una fecha existente.

## Alcance y relación con los demás bloques

Se utilizan SELECT, SUM, GROUP BY, JOIN, EXISTS, INSERT y UPDATE sobre el modelo existente. Las transacciones, TRY...CATCH y procedimientos corresponden al material técnico de la etapa V y a la introducción de la Unidad 5. No se agregaron cursores, SQL dinámico, otra base comercial ni una aplicación externa.

El integrante 1 mantiene el registro inicial, los detalles, las reservas y las funciones. Este bloque se ocupa de pagos, cierre y vencimiento. El integrante 3 puede auditar automáticamente los UPDATE de PRODUCTO y comprobar que esos registros también se revierten cuando falla una transacción. El integrante 4 deberá limitar al operador a los procedimientos autorizados, evitando modificaciones directas de las tablas.

Los resultados registrados corresponden a las pruebas indicadas. Quedan fuera de esta implementación la programación automática de vencimientos, devoluciones de pagos, modificación de ventas abonadas, prueba de recuperación ante caídas y mediciones con múltiples sesiones concurrentes.
