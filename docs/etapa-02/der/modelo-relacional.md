# Modelo Relacional - EmpresaHardware

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  
**Responsable:** Nuñez Tobias Nahuel (DNI: 46316154)  
**Repositorio:** https://github.com/EmilianoRomeroAle/proyecto-bd1-equipo_51  

---

## 1. Esquema Relacional de Tablas (Notación Estándar)

A partir del Diagrama Entidad-Relación (DER), se realizó la transformación a tablas relacionales definiendo Claves Primarias (PK) y Claves Foráneas (FK):

- **CLIENTE** (<u>dni_cuit</u>, nombre, apellido, email, telefono)
- **CATEGORIA** (<u>codigo_categoria</u>, nombre_categoria)
- **PRODUCTO** (<u>sku</u>, marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, *codigo_categoria*)
  - *FK:* `codigo_categoria` $\rightarrow$ `CATEGORIA(codigo_categoria)`
- **METODO_PAGO** (<u>codigo_metodo</u>, nombre_metodo)
- **VENTA** (<u>codigo_venta</u>, fecha_hora, monto_total, estado, *dni_cuit*)
  - *FK:* `dni_cuit` $\rightarrow$ `CLIENTE(dni_cuit)`
- **DETALLE_VENTA** (<u>*codigo_venta*</u>, <u>id</u>, *sku*, cantidad, precio_uni_historico)
  - *PK Compuesta:* (`codigo_venta`, `id`)
  - *FK1:* `codigo_venta` $\rightarrow$ `VENTA(codigo_venta)`
  - *FK2:* `sku` $\rightarrow$ `PRODUCTO(sku)`
- **PAGA_CON** (<u>*codigo_venta*</u>, <u>*codigo_metodo*</u>, monto_abonado)
  - *PK Compuesta:* (`codigo_venta`, `codigo_metodo`)
  - *FK1:* `codigo_venta` $\rightarrow$ `VENTA(codigo_venta)`
  - *FK2:* `codigo_metodo` $\rightarrow$ `METODO_PAGO(codigo_metodo)`

---

## 2. Justificación y Decisiones de Diseño por Tabla

A continuación se detallan las razones técnicas y reglas de negocio aplicadas para definir cada tabla y sus atributos:

### 2.1. CLIENTE
- **Clave Primaria (`dni_cuit`):** Se eligió el DNI/CUIT porque identifica de manera unívoca tanto a consumidores finales como a empresas y clientes mayoristas, evitando duplicados.
- **Descomposición de contacto:** En el DER original existía el atributo compuesto `contacto`. Durante el paso a tablas se dividió en dos columnas independientes (`email` y `telefono`), garantizando la atomicidad requerida por la Primera Forma Normal (1FN).

### 2.2. CATEGORIA
- **Separación en tabla independiente:** En lugar de guardar el nombre de la categoría como texto dentro de la tabla de productos, se aisló en una tabla propia con `codigo_categoria` como PK. Esto evita la repetición constante de nombres (redundancia) y previene anomalías de actualización o borrado (cumpliendo con 3FN).

### 2.3. PRODUCTO
- **Clave Primaria (`sku`):** Se utilizó el código comercial SKU (*Stock Keeping Unit*) ya que es el estándar de la industria de hardware para identificar de forma exacta cada componente o variante.
- **Exclusión de `stock_disponible`:** El stock disponible es un dato derivado que se calcula en tiempo real restando `stock_actual - stock_reservado`. No se almacena físicamente en la base de datos para evitar inconsistencias si uno de los valores cambia.
- **Clave Foránea (`codigo_categoria`):** Representa la relación 1 a N (`CATEGORIA` $\rightarrow$ `PRODUCTO`), permitiendo asociar cada artículo a su categoría correspondiente.

### 2.4. METODO_PAGO
- **Catálogo parametrizado:** Se creó como tabla independiente para registrar los medios de cobro habilitados (efectivo, transferencia, débito, crédito). Esto permite dar de alta nuevos medios de pago en el futuro sin modificar la estructura de las tablas principales.

### 2.5. VENTA
- **Clave Primaria (`codigo_venta`):** Identificador alfanumérico único para cada comprobante o transacción emitida.
- **Relación con Cliente (`dni_cuit` FK):** Mapea la relación 1 a N (`CLIENTE` $\rightarrow$ `VENTA`), indicando qué cliente efectuó la compra.
- **Atributos de control:** `fecha_hora` registra el instante de la operación, `monto_total` consolida el valor final de la orden y `estado` administra el flujo de vida del pedido (Pendiente, Abonado, Despachado, Cancelado).

### 2.6. DETALLE_VENTA (Entidad Débil)
- **Tratamiento de entidad débil y PK compuesta:** Un ítem vendido no tiene existencia independiente fuera de la venta que lo contiene. Por ello, se definió una clave primaria compuesta por `(codigo_venta, id)`, donde `codigo_venta` es al mismo tiempo parte de la PK y FK hacia `VENTA`.
- **Congelamiento de precio (`precio_uni_historico`):** **Decisión crítica de diseño.** Si el precio de lista de un producto sube en el futuro, las ventas pasadas deben conservar el valor exacto al que se vendieron. Almacenar el precio unitario histórico en el detalle evita que se recalculen o alteren facturas históricas y balances contables.
- **Clave Foránea (`sku`):** Vincula el renglón con el producto específico que se está comprando.

### 2.7. PAGA_CON (Resolución de Relación Muchos a Muchos)
- **Soporte de pagos combinados:** En el negocio, una venta puede abonarse utilizando múltiples métodos simultáneos (por ejemplo, parte en efectivo y parte con tarjeta), y un método de pago es utilizado en muchas ventas.
- **Estructura de tabla intermedia:** La relación N:M se resolvió con la tabla `PAGA_CON`, cuya clave primaria es compuesta por `(codigo_venta, codigo_metodo)`.
- **Atributo propio (`monto_abonado`):** Registra con exactitud el monto saldado con cada método específico, permitiendo validar que la suma de los pagos coincida con el `monto_total` de la venta.

---

## 3. Resumen de Reglas de Transformación Aplicadas

1. **Entidades fuertes:** Pasan directamente a tablas conservando sus atributos simples, asignando sus identificadores principales como PKs.
2. **Atributos compuestos:** Se descomponen en sus campos atómicos (`contacto` $\rightarrow$ `email`, `telefono`).
3. **Atributos derivados:** Se excluyen de la persistencia física (`stock_disponible`).
4. **Relaciones 1:N:** La clave primaria de la entidad con cardinalidad 1 migra como clave foránea (FK) a la tabla con cardinalidad N (ej. `CLIENTE` $\rightarrow$ `VENTA`, `CATEGORIA` $\rightarrow$ `PRODUCTO`).
5. **Entidades débiles:** Forman su PK compuesta combinando la PK de la entidad fuerte propietaria (`codigo_venta`) junto con su discriminador parcial (`id`).
6. **Relaciones N:M:** Generan una nueva tabla intermedia con clave compuesta formada por las PKs de ambas entidades (`codigo_venta` + `codigo_metodo`), alojando los atributos propios de la relación (`monto_abonado`).
