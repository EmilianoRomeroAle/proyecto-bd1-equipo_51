# Reglas de Negocio (Versión Preliminar - Borrador Inicial)

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  

> **Nota de versión:** Documento de trabajo inicial correspondiente a la primera iteración de relevamiento de reglas operativas básicas.

---

### RN.01 — Registro Obligatorio de Clientes
Toda venta registrada en el sistema debe estar asociada a un cliente dado de alta previamente. Cada cliente debe contar con un número de identificación personal (DNI o CUIT) que no puede repetirse en el sistema.

### RN.02 — Control de Stock para la Venta
No se puede emitir una venta si la cantidad de artículos solicitada por el cliente es mayor a la cantidad disponible en el stock actual del negocio. Al registrarse la venta, se debe descontar la cantidad de unidades correspondiente del inventario.

### RN.03 — Registro de Precio Unitario de Venta
El detalle de cada venta debe almacenar el precio unitario del producto al momento de concretarse la transacción. Este valor no debe modificarse cuando cambie el precio de lista del catálogo general de productos.

### RN.04 — Asignación de Método de Pago
Toda venta debe registrar al menos un método de pago válido de los autorizados por la empresa (Efectivo, Tarjeta de Débito, Tarjeta de Crédito o Transferencia Bancaria). No se permiten ventas sin método de pago especificado.

### RN.05 — Identificación de Productos por SKU
Cada producto comercializado en el catálogo de hardware debe poseer un código comercial único (SKU) que lo distinga de cualquier otro artículo del inventario.
