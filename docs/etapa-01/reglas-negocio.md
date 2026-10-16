# Reglas de negocio

**Asignatura:** Bases de Datos I, año 2026

**Equipo:** 51

**Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware

Estas reglas describen los requisitos del negocio. Los estados utilizados son `Pendiente`, `Abonado` y `Cancelado`.

## RN.01 — Identificación y contacto de clientes

Toda venta debe estar asociada a un único cliente registrado. El DNI o CUIT de cada cliente debe ser único. El correo electrónico y el teléfono son obligatorios.

## RN.02 — Disponibilidad y descuento de stock

No se puede agregar un producto a una venta si la cantidad solicitada supera el stock disponible. Cuando la venta pasa a `Abonado`, se deben descontar del stock físico las unidades vendidas y retirar esas unidades del stock reservado.

## RN.03 — Precio histórico del detalle

Cada renglón debe guardar el precio unitario pactado al registrar el detalle de venta. Ese valor debe conservarse aunque posteriormente se modifique el precio de lista del producto. Los importes de ventas anteriores no deben recalcularse con precios actuales.

## RN.04 — Medios de pago e importe abonado

Se admiten los ocho medios del catálogo: Efectivo, Transferencia Bancaria, Tarjeta de Debito, Tarjeta de Credito 1 Pago, Tarjeta de Credito 3 Cuotas, Tarjeta de Credito 6 Cuotas, Mercado Pago y Criptomonedas (USDT). Todos se registran manualmente después de verificar el cobro, sin integraciones con servicios externos.

Cada venta debe registrar uno o varios medios de pago. Mientras está `Pendiente`, puede tener pagos parciales. Solo puede pasar a `Abonado` si la suma de los importes registrados coincide exactamente con su total. Cada importe debe ser positivo y expresarse en la moneda del comprobante. Para cada combinación de venta y medio de pago se registra un único monto acumulado.

## RN.05 — SKU y categoría de productos

Cada producto debe tener un SKU único y pertenecer a una única categoría. El SKU distingue los artículos del catálogo, aunque compartan marca o características similares.

## RN.06 — Vencimiento de ventas pendientes

Si transcurren 24 horas desde la creación de una venta `Pendiente` sin que se complete su pago, la venta debe pasar a `Cancelado`. Las unidades reservadas para esa venta deben liberarse y volver a estar disponibles. La liberación no aumenta el stock físico, porque la reserva no lo había descontado.

## RN.07 — Conservación de ventas abonadas

Una venta en estado `Abonado` no debe eliminarse ni modificarse. La restricción comprende su cabecera y sus renglones: fecha y hora, cliente, total, estado, productos, cantidades y precios históricos.

## RN.08 — Reserva de existencias

Al registrar los renglones de una venta `Pendiente`, sus cantidades deben quedar reservadas para ese cliente. El stock disponible es la diferencia entre el stock actual y el reservado por ventas pendientes activas. La reserva impide comprometer esas unidades en otra venta y no constituye una baja del stock físico.
