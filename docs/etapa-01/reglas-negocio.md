# Reglas de Negocio (Versión Final Aprobada)

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  

Las presentes Reglas de Negocio (RN) constituyen condiciones operativas, políticas comerciales y restricciones inviolables que el sistema debe hacer cumplir de forma estricta y permanente. Se encuentran redactadas mediante imperativos categóricos, asegurando claridad, especificidad y verificabilidad sin ambigüedades técnicas prematuras.

---

### RN.01 — Registro Obligatorio e Identificación Única de Clientes
Toda transacción comercial de venta debe estar vinculada de manera obligatoria a un único cliente previamente registrado en el padrón del sistema. Cada cliente debe identificarse unívocamente mediante su número de documento o identificación fiscal (DNI para personas físicas o CUIT para empresas), el cual no puede duplicarse bajo ninguna circunstancia. Asimismo, cada cliente debe tener registrado con carácter obligatorio al menos un correo electrónico válido para notificaciones y facturación.

### RN.02 — Control Severo de Disponibilidad y Descuento Automático de Stock
No se puede agregar un producto a una orden de venta si la cantidad solicitada supera las existencias disponibles en el inventario actual. Una vez que la transacción de venta pasa formalmente al estado 'Abonada', el sistema debe descontar de manera automática e inmediata la cantidad exacta de unidades comercializadas del stock del producto.

### RN.03 — Historial y Congelamiento de Precios Unitarios en el Detalle de Venta
Cada renglón del detalle de venta debe registrar y almacenar explícitamente el precio unitario acordado y cobrado al momento exacto de la operación. Este precio histórico se mantendrá inmutable a lo largo del tiempo, y no podrá ser recalculado ni sufrir modificaciones retroactivas si el precio de lista de dicho artículo es actualizado posteriormente en el catálogo general.

### RN.04 — Validación de Liquidación y Cobertura Exacta Multipago
Una venta debe ser cancelada en su totalidad empleando uno o más métodos de pago autorizados por la empresa (Efectivo, Transferencia Bancaria, Tarjeta de Débito, Tarjeta de Crédito). Cada cobro registrado debe especificar el medio empleado y el importe imputado. Una venta solamente podrá pasar al estado 'Abonada' si y solo si la sumatoria aritmética de los pagos registrados coincide de forma exacta con el importe total liquidado del comprobante. No se admiten ventas en estado definitivo con pagos parciales ni saldos descubiertos.

### RN.05 — Unicidad de Código SKU y Categorización Exclusiva de Artículos
Cada producto perteneciente al catálogo de hardware debe poseer un código comercial único denominado SKU (*Stock Keeping Unit*), que prohíbe cualquier colisión o ambigüedad entre modelos de características técnicas similares. Asimismo, todo producto debe pertenecer de forma obligatoria a una única categoría principal de componentes (ejemplos: Procesadores, Placas de Video, Almacenamiento, Fuentes de Alimentación, Periféricos).

### RN.06 — Expiración de Pedidos No Abonados y Liberación de Stock
Si una transacción iniciada en estado 'Pendiente' no registra la totalidad de los pagos requeridos para su cancelación dentro de un plazo límite e improrrogable de 24 horas continuas contadas a partir de su momento de creación, la orden debe pasar automáticamente al estado 'Cancelado' y la totalidad de las unidades de stock que se encontraban reservadas para dicha orden deben liberarse e integrarse de inmediato al stock disponible.

### RN.07 — Inmutabilidad de Comprobantes en Estado Abonado
Una vez que una orden de venta ha alcanzado el estado 'Abonada' y ha sido confirmada en el sistema, queda estrictamente prohibida su eliminación física y la modificación de cualquiera de sus atributos de cabecera (fecha, cliente asociado, importes totales) o renglones de detalle (artículos, cantidades o precios congelados), garantizando la auditabilidad permanente de las operaciones comerciales.

### RN.08 — Reserva Temporal de Existencias por Venta Pendiente
Al momento de confeccionarse una orden de venta en estado 'Pendiente', las cantidades solicitadas de cada artículo deben quedar inmediatamente catalogadas en concepto de stock reservado, bloqueándolas para impedir que sean vendidas a otros clientes en mostrador. El stock disponible para nuevas ventas debe calcularse en todo momento como la diferencia neta entre las existencias físicas en depósito y las cantidades comprometidas en órdenes pendientes activas. Dicha reserva temporal no constituye una baja definitiva del inventario hasta que la orden adquiera el estado 'Abonada'.
