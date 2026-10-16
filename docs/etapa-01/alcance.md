# Alcance del sistema

**Asignatura:** Bases de Datos I, año 2026

**Equipo:** 51

**Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware

## 1. Procesos incluidos

### Catálogo y categorías

Se registran el SKU, la marca, el modelo, la descripción técnica y el precio de lista de cada producto. Cada artículo pertenece a una única categoría, como Procesadores, Almacenamiento o Periféricos.

### Clientes

Se registran los datos de los compradores particulares y de empresas. El DNI o CUIT identifica a cada cliente y no puede repetirse. El correo electrónico y el teléfono son obligatorios.

### Existencias

Se distinguen el stock físico, el stock reservado y el stock disponible. Las cantidades de una venta `Pendiente` se reservan para evitar que sean ofrecidas a otro cliente. El stock disponible se calcula como stock actual menos stock reservado.

Al pasar la venta a `Abonado`, corresponde descontar del stock físico las unidades vendidas y dejar de considerarlas reservadas. Si una venta sigue sin abonarse por completo a las 24 horas de su creación, debe pasar a `Cancelado` y liberar la reserva.

### Ventas

Cada venta tiene una cabecera y renglones de detalle. La cabecera contiene su código, fecha y hora, cliente, total y estado. Los únicos estados admitidos son `Pendiente`, `Abonado` y `Cancelado`; el estado inicial es `Pendiente`.

Cada renglón identifica un producto y registra su cantidad y precio unitario histórico. Este precio se acuerda al registrar el detalle y se conserva aunque después cambie el precio de lista. El total de la venta corresponde a la suma de cantidad por precio unitario histórico de sus renglones.

### Pagos

Una venta puede abonarse con uno o varios medios. El catálogo utilizado contiene ocho opciones:

1. Efectivo.
2. Transferencia Bancaria.
3. Tarjeta de Debito.
4. Tarjeta de Credito 1 Pago.
5. Tarjeta de Credito 3 Cuotas.
6. Tarjeta de Credito 6 Cuotas.
7. Mercado Pago.
8. Criptomonedas (USDT).

El operador verifica cada cobro y registra el importe aplicado a la venta, expresado en la misma moneda que su total. Mercado Pago y USDT se tratan como medios de registro manual. No se procesan pagos ni conversiones mediante servicios externos. Para un mismo medio y una misma venta se registra el monto acumulado.

## 2. Procesos excluidos

- Compras a proveedores y órdenes de reabastecimiento. El ingreso de existencias se considera externo al circuito de ventas.
- Tienda en línea, carritos de autoservicio e integración con pasarelas de pago, bancos, billeteras o redes de criptomonedas.
- Cálculo de financiación, intereses o planes de tarjeta. Las opciones de cuotas solo identifican el medio registrado.
- Envíos, distribución y seguimiento de entregas.
- Reparaciones y gestión de garantías con fabricantes.

El modelo se concentra en siete tablas: `CLIENTE`, `CATEGORIA`, `PRODUCTO`, `METODO_PAGO`, `VENTA`, `DETALLE_VENTA` y `PAGA_CON`.
