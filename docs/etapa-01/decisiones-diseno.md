# Decisiones de diseño

**Asignatura:** Bases de Datos I, año 2026

**Equipo:** 51

**Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware

## 1. Precio de lista y precio histórico

El precio de lista pertenece al catálogo y puede cambiar. El precio histórico corresponde al valor acordado al registrar un renglón de venta. Se distinguen ambos datos para que un cambio del catálogo no altere ventas anteriores (RN.03).

El subtotal de un renglón se obtiene multiplicando la cantidad por el precio histórico. El total corresponde a la suma de esos subtotales.

## 2. Pagos combinados

Un cliente puede usar varios medios para abonar una venta. Por eso se registra cuánto se aplica con cada medio, en lugar de guardar un único método en la cabecera. La venta solo puede quedar como `Abonado` cuando la suma coincide con su total (RN.04).

El catálogo contiene ocho opciones, incluidas las variantes de tarjeta por cuotas, Mercado Pago y Criptomonedas (USDT). Estas opciones identifican cobros que el operador verifica y registra. No implican conexión con servicios externos ni cálculo de financiación. Para una misma venta y un mismo medio se mantiene un monto acumulado.

## 3. Estados y reserva de stock

Se utilizan tres estados:

- `Pendiente`: estado inicial. Las unidades de sus renglones quedan reservadas (RN.08).
- `Abonado`: el pago está completo. Corresponde descontar las unidades del stock físico y retirar su reserva (RN.02 y RN.04).
- `Cancelado`: la venta no se concreta. Al cumplirse las 24 horas sin pago completo, corresponde liberar las unidades reservadas (RN.06).

La reserva se distingue del stock físico porque una venta pendiente todavía no representa una salida definitiva. Esto permite calcular las unidades disponibles sin ofrecer productos ya comprometidos. Las ventas abonadas deben conservarse sin cambios para consultar su historial (RN.07).

## 4. Identificación y datos obligatorios

Se utiliza el DNI o CUIT para identificar clientes y el SKU para identificar productos. Ambos deben ser únicos dentro de sus respectivos registros. El correo electrónico y el teléfono son obligatorios para cada cliente (RN.01). Cada producto pertenece a una única categoría (RN.05).

## 5. Límite del proyecto

El trabajo se concentra en ventas minoristas e inventario. Las compras a proveedores, los envíos, las reparaciones y las garantías quedan fuera del caso. Esta delimitación permite trabajar con siete tablas relacionadas: clientes, categorías, productos, métodos de pago, ventas, detalles y pagos por medio.
