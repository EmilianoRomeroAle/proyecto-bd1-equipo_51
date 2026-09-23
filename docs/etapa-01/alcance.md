# Alcance del Sistema

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  

---

## 1. Alcance Funcional (Inclusiones / In Scope)

El sistema contempla el soporte operativo y el almacenamiento ordenado de información para los siguientes procesos nucleares del ciclo comercial minorista:

### 1.1 Gestión del Catálogo de Hardware y Categorías
* Registro y mantenimiento del catálogo de productos (marca, modelo, descripción técnica, precio de lista vigente).
* Asignación obligatoria de cada producto a una única categoría comercial de hardware (ejemplos: Procesadores, Placas de Video, Almacenamiento, Periféricos, Fuentes de Alimentación).
* Identificación individual de cada producto mediante un código unívoco comercial (SKU).

### 1.2 Administración del Padrón de Clientes
* Registro de clientes particulares y corporativos que realizan transacciones en el local.
* Identificación fehaciente y unívoca de cada cliente a través de su documento o número fiscal (DNI o CUIT).
* Captura obligatoria de canales de contacto (correo electrónico y número telefónico).

### 1.3 Control de Stock y Disponibilidad de Existencias
* Seguimiento en tiempo real de las existencias físicas disponibles en depósito para cada producto comercializado.
* Reserva temporal inmediata de existencias al iniciar una orden de venta en estado pendiente.
* Descuento definitivo e irreversible del stock al confirmarse la cancelación total del importe adeudado.
* Bloqueo operativo de solicitudes de venta cuando la cantidad requerida supera el inventario disponible.

### 1.4 Procesamiento de Ventas y Comprobantes
* Creación de comprobantes de venta estructurados en encabezado general y renglones de detalle.
* Congelamiento explícito e inmutable del precio unitario pactado por cada producto al momento exacto de la operación (precio histórico).
* Cálculo consolidado de subtotales por producto y monto total acumulado del comprobante.
* Control del ciclo de vida de la transacción mediante estados formales: *Pendiente*, *Abonado* y *Cancelado*.

### 1.5 Gestión de Cobros y Métodos de Pago Diversificados
* Habilitación de modalidades de pago reconocidas: Efectivo, Transferencia Bancaria, Tarjeta de Débito y Tarjeta de Crédito.
* Soporte para transacciones con pagos combinados (multipago), permitiendo cancelar un mismo comprobante mediante dos o más métodos de pago.
* Registro de los importes imputados a cada medio de pago y verificación estricta de que la suma de los cobros iguale el total del pedido.

---

## 2. Exclusiones Explícitas (Fuera de Alcance / Out of Scope)

Con el fin de delimitar con precisión la complejidad del modelo a los requerimientos pedagógicos de la asignatura (manteniendo un esquema conceptual y relacional de entre 6 y 10 relaciones representativas), quedan formalmente fuera del alcance los siguientes aspectos:

* **Gestión de Compras y Proveedores:**  
  No se modelará el circuito de reabastecimiento mayorista, órdenes de compra a distribuidores externos ni recepción de mercadería. El ingreso de stock se asume preexistente o gestionado externamente.
* **Comercio Electrónico y Pasarelas de Pago en Línea:**  
  El sistema se enfoca en el registro comercial en salón de ventas; no comprende interfaces web para carritos de compra de autoservicio ni integración con pasarelas automáticas mediante API/webhooks externos (los pagos por tarjeta o transferencia se asientan tras la verificación del operador).
* **Logística de Envíos y Distribución Externa:**  
  No se incluye el seguimiento de despacho a domicilio, cálculo de tarifas por peso/distancia ni convenios con empresas de encomienda o transporte.
* **Servicio Técnico y Garantías RMA Complejas:**  
  No se modela el seguimiento de diagnósticos de laboratorio, reparaciones de hardware ni circuitos de gestión de garantías con el fabricante posterior a la venta.
