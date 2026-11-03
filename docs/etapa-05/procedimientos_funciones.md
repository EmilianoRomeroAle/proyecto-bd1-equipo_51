# Procedimientos y funciones almacenadas

Equipo 51 — Bases de Datos I — Etapa V

## Objetivo

Esta parte resuelve el registro de una venta pendiente y sus renglones. La idea es reunir en una operacion el detalle, el total y la reserva de productos, para que un error no deje datos incompletos.

Una funcion almacenada recibe parametros y devuelve un valor que se puede usar en una consulta. Un procedimiento almacenado permite ejecutar una operacion con varios pasos, validaciones y modificaciones. Guardar esta logica en la base facilita reutilizarla y evita escribir las mismas sentencias en cada venta.

Las funciones de este bloque consultan datos. Los procedimientos cambian las tablas `VENTA`, `DETALLE_VENTA` y `PRODUCTO`; tambien consultan `CLIENTE` para comprobar el comprador.

## Archivos y requisitos

- `sql/tecnico/01_funciones.sql`: funciones de stock disponible y total de venta.
- `sql/tecnico/02_registro_ventas.sql`: alta de venta y agregado de renglones.
- `sql/tecnico/pruebas/01_pruebas_registro_ventas.sql`: demostracion con controles y resultados esperados.

Primero deben existir la base `tienda_hardware`, las siete tablas y el lote de las etapas anteriores. Se usan los nombres actuales: `precio_uni_historico`, `monto_abonado` y la clave del detalle `(codigo_venta, id)`.

El orden de instalacion de este bloque es `01_funciones.sql` y despues `02_registro_ventas.sql`. Para ejecutar la prueba tambien se necesita el lote de demostracion `90_datos_prueba_etapa05.sql` del integrante 3. No se deben volver a cargar los datos iniciales sobre una base ya poblada.

Los objetos se crean con `CREATE OR ALTER`, por lo que sus definiciones se pueden actualizar sin borrar las tablas. Esto no limpia datos ni reemplaza el lote anterior.

## Funcion de stock disponible

`dbo.fn_StockDisponible(@sku VARCHAR(50))` devuelve un entero con el resultado de `stock_actual - stock_reservado`. Si el producto no existe, devuelve `NULL`. De esta manera, un producto sin existencias se distingue de uno que no esta registrado.

```sql
SELECT sku, stock_actual, stock_reservado,
       dbo.fn_StockDisponible(sku) AS disponible
FROM dbo.PRODUCTO;
```

Esta funcion permite mostrar la disponibilidad, pero no reserva unidades. El procedimiento comprueba nuevamente la disponibilidad en el mismo `UPDATE` que aumenta la reserva.

## Funcion de total de venta

`dbo.fn_TotalVenta(@codigo_venta INT)` devuelve `DECIMAL(12,2)`. Suma `cantidad * precio_uni_historico` de los renglones de esa venta.

- Venta existente con renglones: devuelve la suma.
- Venta existente sin renglones: devuelve 0.
- Venta inexistente: devuelve `NULL`.

El calculo no usa `PRODUCTO.precio_lista`, porque ese precio puede cambiar. Conservar el precio pactado en cada renglon permite mantener el importe de las ventas anteriores.

```sql
SELECT codigo_venta, monto_total,
       dbo.fn_TotalVenta(codigo_venta) AS total_calculado
FROM dbo.VENTA;
```

## Alta de una venta pendiente

El procedimiento recibe estos parametros, en este orden:

```sql
dbo.usp_RegistrarVentaPendiente
    @codigo_venta INT,
    @dni_cuit VARCHAR(20),
    @sku VARCHAR(50),
    @cantidad INT,
    @precio_uni_historico DECIMAL(12,2)
```

Comprueba que el codigo sea positivo y este libre, que existan el cliente y el producto, que la cantidad sea positiva y que el precio no sea negativo. Los parametros obligatorios no admiten `NULL` ni identificadores vacios.

La cabecera se crea junto con el primer detalle, cuyo numero de renglon es 1. El importe inicial debe ser mayor que cero, porque el `CHECK` de `VENTA.monto_total` exige esa condicion. Por eso no se crea primero una cabecera vacia con total cero.

El procedimiento aumenta `stock_reservado` y mantiene `stock_actual`. Luego inserta la cabecera en estado `Pendiente` y el primer detalle con el precio recibido. Todas estas modificaciones pertenecen a una misma transaccion.

Ejemplo con los productos del lote de demostracion:

```sql
EXEC dbo.usp_RegistrarVentaPendiente
     @codigo_venta = 95101,
     @dni_cuit = '99000051',
     @sku = 'ET5-REG-01',
     @cantidad = 2,
     @precio_uni_historico = 900;
```

El resultado esperado es una pendiente de 1800, con su renglon 1 y dos unidades reservadas. El producto tiene precio de lista 1000, pero el detalle guarda 900, que es el precio pactado del ejemplo.

## Agregado de otro renglon

```sql
dbo.usp_AgregarDetalleVenta
    @codigo_venta INT,
    @id INT,
    @sku VARCHAR(50),
    @cantidad INT,
    @precio_uni_historico DECIMAL(12,2)
```

Solo permite agregar renglones a una venta `Pendiente` que todavia no cumplio 24 horas. Rechaza ventas inexistentes, abonadas, canceladas o vencidas. El numero de renglon debe ser positivo y no repetirse dentro de esa venta.

El mismo producto puede aparecer en mas de un renglon si cada uno tiene un `id` diferente. Se reservan las unidades adicionales y se vuelve a calcular el total con `fn_TotalVenta`. Un renglon adicional puede tener precio cero si el total de la venta sigue siendo positivo.

```sql
EXEC dbo.usp_AgregarDetalleVenta 95101, 2, 'ET5-REG-02', 3, 400;
```

En este ejemplo se agregan 1200 al total anterior, por lo que la cabecera queda en 3000.

## Transacciones y control de errores

Ambos procedimientos usan `BEGIN TRANSACTION`, `COMMIT`, `TRY...CATCH`, `ROLLBACK` y `THROW`. `SET XACT_ABORT ON` acompana el manejo de errores. Si falla una validacion o una sentencia, se deshacen los cambios de la operacion y se informa el error al llamador.

La reserva se hace con un `UPDATE` que incluye la condicion `stock_actual - stock_reservado >= @cantidad`. Se consulta `@@ROWCOUNT` inmediatamente despues: si no se actualizo un producto, se informa falta de stock. Una consulta previa de disponibilidad, por si sola, no alcanza para hacer la reserva.

En el agregado se lee la venta con `UPDLOCK, HOLDLOCK`. Esto mantiene un bloqueo sobre la venta durante la transaccion y coordina el cambio con los procedimientos de pagos del integrante 2. Es un apoyo de SQL Server al manejo de transacciones. No se realizo una prueba simultanea con varias sesiones, por lo que no se presenta como una validacion completa de concurrencia.

Si otro procedimiento inicia una transaccion y llama a estos procedimientos, el `COMMIT` interno no confirma por separado la transaccion exterior. Ante un error, el `ROLLBACK` revierte toda la transaccion activa del llamador. No se usan puntos de guardado ni reversiones parciales.

| Error | Motivo |
| --- | --- |
| 51001 | Parametros obligatorios, cantidad, precio o identificadores invalidos. |
| 51002 | Codigo de venta repetido. |
| 51003 | Cliente inexistente. |
| 51004 | Producto inexistente. |
| 51005 | Stock disponible insuficiente. |
| 51006 | Venta inexistente. |
| 51007 | Venta que no esta pendiente. |
| 51008 | Pendiente vencida. |
| 51009 | Numero de renglon repetido. |
| 51010 | Total que no es positivo. |

El motor tambien puede informar errores propios, por ejemplo 8115 si un importe supera la capacidad de `DECIMAL(12,2)`. Esos errores tambien se revierten y se vuelven a informar.

## Pruebas realizadas

Se ejecuto el archivo de prueba sobre una base separada llamada `tienda_hardware_etapa05_verificacion`, en la instancia local SQL Server Express. Para esa verificacion se cambio solamente el nombre de base de las copias de ejecucion. Los archivos de entrega conservan `USE tienda_hardware`.

La prueba completa termino sin errores. La salida de SQL Server se conserva en `docs/etapa-05/evidencias/procedimientos_funciones/resultados.txt`.

| Caso | Resultado obtenido |
| --- | --- |
| Alta con 2 unidades a 900 | Venta pendiente de 1800 y renglon 1. |
| Agregar 3 unidades a 400, otra del primer SKU a 800 y una a 0 | Cuatro renglones y total de 3800. |
| Reservas acumuladas | 3 unidades en ET5-REG-01 y 4 en ET5-REG-02; stock fisico 50 y 30. |
| Cambio del precio de lista de 1000 a 1500 | Los precios historicos y el total 3800 se conservaron. |
| Funciones con identificadores inexistentes | `NULL`. |
| Venta existente sin renglones, preparada solo para el caso | Total 0. |
| Venta/renglon duplicados; cantidad 0; codigo o renglon NULL; precio negativo | Rechazo con el error esperado. |
| Cliente, producto o venta inexistentes | Rechazo con el error esperado. |
| Stock insuficiente en alta y agregado | Rechazo, sin nuevos renglones ni reservas parciales. |
| Primer renglon de total 0 | Rechazo. |
| Agregado a abonada, cancelada o vencida | Rechazo y conservacion del detalle. |
| Importe que desborda despues de intentar reservar | Error 8115; se comprobo que no quedaran venta ni reserva parcial. |

La prueba muestra los valores iniciales y los obtenidos. Al terminar elimina exclusivamente sus ventas y deja sus dos productos con los precios y las reservas iniciales. Si alguna comprobacion falla, el archivo se detiene para revisar los datos antes de repetirlo. Los cambios directos de estado que aparecen en las pruebas sirven para preparar rechazos; no forman parte del circuito de operacion.

## Dependencias y limites

El integrante 2 usa estas funciones y el contrato de ventas para registrar pagos, confirmar y cancelar pendientes vencidas. Este bloque solo reserva productos: no descuenta existencias fisicas, no registra pagos y no cancela automaticamente las ventas vencidas.

Los procedimientos evitan modificar ventas cerradas por este circuito. Un administrador con permisos directos sobre las tablas todavia puede alterarlas. El integrante 4 debe limitar las modificaciones directas del operador y darle permiso para ejecutar los procedimientos autorizados.

Se probaron operaciones secuenciales y reversion ante errores. Quedan fuera de estas pruebas la ejecucion simultanea entre sesiones, la recuperacion despues de una caida del servidor y la programacion automatica del vencimiento. No se modificaron las diez ventas historicas del lote original.
