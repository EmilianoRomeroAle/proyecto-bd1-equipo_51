# Decisiones de Diseño y Delimitación del Dominio

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  

El presente documento fundamenta las decisiones tomadas durante el relevamiento y definición de requerimientos del sistema. Estas determinaciones establecen las fronteras operativas del negocio y sientan las bases conceptuales para las fases posteriores de modelado relacional e implementación física.

---

## 1. Justificación del Congelamiento del Precio Histórico en el Detalle

### Problema Operativo
En el comercio de componentes informáticos, los precios de lista fluctúan frecuentemente debido a variaciones cambiarias y actualizaciones de proveedores. Si el comprobante de venta leyera el precio de los artículos directamente desde el catálogo general de productos, cualquier ajuste futuro de precios alteraría retroactivamente los totales facturados en meses anteriores, destruyendo la consistencia contable.

### Decisión Adoptada
Se estableció que cada renglón de detalle de venta almacene de forma independiente y fija el precio unitario pactado al instante del cobro (RN.03). Esta decisión desacopla la información histórica de la venta respecto a la lista dinámica de precios de catálogo, garantizando la inmutabilidad de los comprobantes emitidos.

---

## 2. Justificación del Soporte para Cobros Diversificados (Multipago)

### Problema Operativo
Los componentes de hardware poseen un valor unitario elevado. Es habitual que un cliente abone una compra combinando medios de pago (por ejemplo, abonar un porcentaje en efectivo y financiar el remanente con tarjeta de crédito o transferencia bancaria). Forzar un único método de pago por comprobante obligaba al negocio a fraccionar artificialmente ventas en múltiples tickets o a registrar transacciones falsas en papel.

### Decisión Adoptada
Se determinó modelar los cobros como un registro independiente asociado al comprobante, permitiendo que una venta se liquide mediante uno o múltiples métodos de pago (RN.04). Para mantener la integridad económica, se exige la regla de cuadre exacto: la suma de los pagos debe ser idéntica al total facturado para validar el estado definitivo.

---

## 3. Justificación del Ciclo de Vida de Pedidos y Reserva de Stock

### Problema Operativo
El salón de ventas atiende clientes simultáneamente. Si una venta tarda en abonarse mientras el cliente aguarda autorización de pago, otro vendedor podría comercializar el mismo componente si el stock disponible no se actualiza inmediatamente, provocando el fenómeno de sobreviventa (*overselling*). Por otra parte, bloquear artículos indefinidamente por ventas no concretadas genera lucro cesante y distorsiona el inventario real.

### Decisión Adoptada
Se diseñó un mecanismo de estados transaccionales con reserva temporal:
* **Pendiente:** Bloquea las unidades solicitadas del stock disponible mediante reserva temporal (RN.08).
* **Abonado:** Confirma el cobro completo y consolida la baja definitiva del stock físico (RN.02).
* **Cancelado:** Si el pago no se completa en un plazo perentorio de 24 horas continuas, la reserva expira automáticamente y las existencias vuelven al inventario activo (RN.06).

---

## 4. Justificación de la Delimitación del Alcance (Fronteras del Sistema)

### Criterio de Complejidad de la Cátedra
El reglamento de la asignatura fija como pauta fundamental un esquema relacional de complejidad representativa y controlada, comprendido entre **6 y 10 relaciones/tablas normalizadas**.

### Decisión de Exclusión de Proveedores y Logística
Incluir en esta etapa los circuitos de compras mayoristas, órdenes de provisión a fabricantes, despacho logístico y servicio técnico de garantías habría disparado el esquema a más de 15 tablas, desvirtuando el foco pedagógico centrado en el ciclo comercial de ventas. Por ende:
* El reabastecimiento de stock se asume existente.
* El alcance se concentra exclusivamente en el **ciclo comercial minorista**: Clientes, Productos, Categorías, Comprobantes de Venta, Detalle de Venta, Métodos de Pago y Transacciones de Cobro.
* Esta delimitación garantiza que el modelo conceptual (DER) y lógico posterior cumpla estrictamente con la pauta de 6 a 10 relaciones con alta cohesión y normalización plena (3FN).

---

## 5. Unicidad Fiscal y Comercial

### Identificación Unívoca
Para prevenir la duplicidad de registros y facilitar auditorías:
* Cada cliente se identifica obligatoriamente mediante su identificador fiscal (DNI o CUIT), asegurando un padrón limpio y sin redundancias.
* Cada producto se identifica mediante su código comercial SKU (*Stock Keeping Unit*), lo que previene confusiones entre revisiones técnicas o versiones similares del mismo componente de hardware.
