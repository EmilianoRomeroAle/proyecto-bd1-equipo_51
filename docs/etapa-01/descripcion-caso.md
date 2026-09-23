# Descripción del Caso de Negocio

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Carrera:** Licenciatura en Sistemas de Información  
**Institución:** Universidad Nacional del Nordeste (UNNE)  
**Equipo de Proyecto:** Equipo 51  
**Título del Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware  
**Rubro Seleccionado:** Venta minorista de componentes informáticos y periféricos  

---

## 1. Identificación y Contexto de la Organización

La organización bajo estudio es una empresa comercial dedicada a la venta minorista y distribución de componentes de hardware informático, partes de ensamble y periféricos de alto rendimiento (procesadores, placas de video, placas madre, unidades de almacenamiento en estado sólido, fuentes de alimentación certificadas, módulos de memoria RAM, gabinetes y periféricos gaming).

La empresa opera principalmente a través de un salón de ventas y mostrador de atención directa a clientes particulares, profesionales y empresas que demandan asesoramiento técnico y productos de alta precisión. Debido a las características particulares del rubro tecnológico:
* Los artículos comercializados poseen un elevado valor monetario unitario y sufren depreciación o fluctuaciones periódicas de precios según cotizaciones y listas de proveedores.
* El público comprador requiere especificaciones técnicas exactas y disponibilidad inmediata para la integración o actualización de equipos.
* La empresa precisa una administración rigurosa de sus existencias físicas para sostener la credibilidad operativa y la rentabilidad del negocio.

---

## 2. Situación Actual y Problemática Operativa

Actualmente, la empresa gestiona sus operaciones de comercialización y control de inventario mediante registros informales basados en planillas de cálculo de acceso compartido y notas de mostrador en papel. Este mecanismo rudimentario ha provocado cuellos de botella e ineficiencias críticas:

1. **Sobrevenda de mercadería (Overselling):**  
   Al no contar con un control centralizado de inventario en tiempo real, se concretan compromisos de venta sobre artículos cuyo stock físico en depósito ya se encuentra agotado o reservado por otro vendedor. Esto ocasiona cancelaciones forzadas, reclamos de clientes y demoras operativas.

2. **Alteración y distorsión de registros históricos de venta:**  
   Cuando se actualiza el precio de lista de un componente en la planilla de catálogo general, las ventas registradas en fechas anteriores se ven afectadas o recalculadas de forma errónea, ya que no se congela de forma independiente el precio unitario pactado al momento exacto de la transacción. Esto invalida los balances contables y auditorías.

3. **Inconsistencias en operaciones con pagos combinados (Multipago):**  
   Una gran proporción de las ventas se abona combinando medios de pago (por ejemplo, una fracción en efectivo y el saldo mediante tarjeta de crédito o transferencia bancaria). En el esquema actual, no existe una validación que garantice que la sumatoria de los cobros asentados cubra de forma exacta el monto total del comprobante, registrándose diferencias de caja.

4. **Falta de unicidad y dispersión de datos de clientes:**  
   No existe un padrón formal de clientes. Un mismo comprador suele quedar registrado con nombres dispares o sin un identificador fiscal fehaciente (DNI o CUIT), lo que imposibilita la emisión correcta de comprobantes y el análisis del historial de compra.

---

## 3. Solución Propuesta y Objetivos de Negocio

Frente a la problemática descrita, se proyecta el diseño de una solución integral que permita a la empresa estructurar, centralizar y transparentar el ciclo completo de sus operaciones de venta.

### Objetivo General
Garantizar la integridad, inmutabilidad y consistencia de las operaciones comerciales de la empresa, asegurando el control estricto de existencias, la inmutabilidad de los precios pactados en cada venta y el registro exhaustivo de los clientes y sus medios de pago.

### Objetivos Específicos
* Centralizar el catálogo de artículos con categorización unívoca y códigos identificadores comerciales.
* Establecer un registro formal y unívoco de clientes con validación de identidad fiscal y vías de contacto.
* Descontar y reservar existencias de forma certera al iniciar y confirmar operaciones comerciales.
* Congelar de forma inmutable el precio unitario cobrado en cada renglón de detalle de venta.
* Garantizar que toda venta cerrada cuente con el respaldo de cobros registrados que cubran con exactitud el total liquidado.
