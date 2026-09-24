# Decisiones de Diseño y Transformación Conceptual a Lógico

## Proyecto Integrador — Bases de Datos I (Año 2026)
**Equipo de Proyecto:** Equipo 51  
**Dominio:** Sistema de Gestión Comercial e Inventario de Hardware  
**Autor:** Nuñez Axel Gabriel  
**Etapa:** Etapa II — Modelado Conceptual y Lógico  

El presente documento fundamenta las decisiones metodológicas, técnicas y operativas adoptadas durante la transición desde el Diagrama Entidad-Relación (DER) en notación Peter Chen (ERDPlus) hacia el Modelo Relacional normalizado en Tercera Forma Normal (3FN), garantizando la integridad semántica de las reglas de negocio de la Etapa I y el cumplimiento estricto de las pautas de cátedra.

---

## 1. Reglas de Transformación Aplicadas (DER a Modelo Relacional)

La derivación del esquema lógico se realizó aplicando de forma rigurosa las reglas formales de transformación del modelo conceptual al modelo relacional:

### 1.1 Transformación de Entidades Regulares (Fuertes)
Cada entidad regular del DER se transformó en una relación (tabla) independiente, adoptando su atributo identificador único como Clave Primaria (PK):
* **CLIENTE:** Atributo identificador `dni_cuit` $\rightarrow$ PK `dni_cuit`.
* **CATEGORIA:** Atributo identificador `codigo_categoria` $\rightarrow$ PK `codigo_categoria`.
* **PRODUCTO:** Atributo identificador `sku` $\rightarrow$ PK `sku`.
* **METODO_PAGO:** Atributo identificador `codigo_metodo` $\rightarrow$ PK `codigo_metodo`.
* **VENTA:** Atributo identificador `codigo_venta` $\rightarrow$ PK `codigo_venta`.

### 1.2 Transformación de la Entidad Débil (`DETALLE_VENTA`)
La entidad débil `Detalle_venta` se encuentra vinculada a `Venta` a través de la relación identificadora `contiene` (1:N):
* **Composición de la Clave Primaria:** Conforme a la regla de transformación para entidades débiles por existencia e identificación, la PK de `DETALLE_VENTA` se conforma mediante una **clave primaria compuesta** integrada por la clave foránea de la entidad fuerte propietaria (`codigo_venta`) junto con el discriminador o clave parcial de la entidad débil (`id` o número de renglón):  
  $$\text{PK} = (\text{codigo\_venta}, \text{id})$$
* **Referencia al Producto (`incluye`):** Como cada renglón de detalle especifica obligatoriamente el producto adquirido, se propaga `sku` hacia `DETALLE_VENTA` como Clave Foránea (FK) referenciando a `PRODUCTO(sku)`.

### 1.3 Transformación de Relaciones Muchos a Muchos (N:M)
La relación `paga_con` entre `Venta` y `Metodo_Pago` es de cardinalidad N:M (una venta puede cancelarse mediante múltiples métodos de pago, y un método de pago es utilizado en múltiples ventas):
* **Creación de Tabla Intermedia (`PAGA_CON`):** Se deriva en una tabla puente cuya clave primaria compuesta está formada por las claves primarias de ambas entidades participantes:  
  $$\text{PK} = (\text{codigo\_venta}, \text{codigo\_metodo})$$
* **Atributo Propio de la Relación:** El atributo `monto_abonado` se aloja directamente en esta tabla puente, permitiendo auditar cuánto dinero exacto se liquidó con cada medio de pago individual.

### 1.4 Tratamiento del Atributo Compuesto (`contacto` en `Cliente`)
En el DER conceptual se modeló `(contacto)` como un atributo compuesto del cual se desprenden `email` y `telefono`:
* **Aplanamiento por Atomicidad (1FN):** En cumplimiento estricto de la Primera Forma Normal, el atributo compuesto no genera tablas accesorias, sino que se descompone atómicamente en sus dos columnas escalares dentro de la tabla `CLIENTE`: `email` y `telefono`.

### 1.5 Tratamiento del Atributo Derivado (`stock_disponible` en `Producto`)
En el DER conceptual, `stock_disponible` fue modelado como un atributo derivado (representado gráficamente con óvalo punteado):
* **Omisión Física en el Modelo Relacional:** En conformidad con las buenas prácticas de diseño relacional y 3FN, **no se incluye `stock_disponible` como columna fija** en la tabla física `PRODUCTO`. Almacenar valores derivados calculables introduce redundancia y anomalías de actualización.  
  El sistema persiste exclusivamente `stock_actual` (existencias reales físicas) y `stock_reservado` (comprometidas en pedidos pendientes), calculándose el stock disponible de forma dinámica mediante vistas o consultas SQL (`stock_actual - stock_reservado`).

---

## 2. Decisiones de Normalización y Semántica de Datos

### 2.1 Preservación del Precio Histórico vs. Precio de Catálogo
Uno de los puntos de análisis más críticos del proceso fue la diferenciación semántica entre `precio_lista` y `precio_uni_historico`:
* **No hay redundancia ni dependencia indebida:** Si bien a nivel superficial podría pensarse que almacenar un precio en `DETALLE_VENTA` duplica el `precio_lista` de `PRODUCTO`, ambos atributos representan hechos conceptuales distintos:
  * `PRODUCTO.precio_lista`: Es un valor dinámico y modificable en el tiempo (precio de catálogo vigente).
  * `DETALLE_VENTA.precio_uni_historico`: Es un hecho transaccional inmutable que fija la cotización acordada al instante del cobro (RN.03).
* **Dependencia Funcional Plena:** En `DETALLE_VENTA`, el atributo `precio_uni_historico` depende funcionalmente de la totalidad de la clave compuesta `(codigo_venta, id)`, por lo que **cumple formalmente con la 2FN y la 3FN**. Su omisión destruiría la consistencia contable del negocio ante cualquier cambio de precios futuro.

### 2.2 Descomposición de Transitividades en 3FN
* En la etapa intermedia (2FN), `VENTA` contenía datos personales del cliente (`dni_cuit -> nombre, apellido, email, telefono`) y `PRODUCTO` contenía la descripción de la categoría (`sku -> codigo_categoria -> nombre_categoria`).
* Se aplicó la descomposición formal extrayendo las relaciones `CLIENTE` y `CATEGORIA`. Esto elimina anomalías de actualización y permite registrar clientes o categorías sin necesidad de que existan ventas o productos activos de forma previa.

---

## 3. Conformidad con las Restricciones y Pautas de la Cátedra

1. **Rango de Complejidad (6 a 10 Relaciones):**  
   El modelo final resultante consta exactamente de **7 tablas normalizadas en 3FN**:
   1. `CLIENTE`
   2. `CATEGORIA`
   3. `PRODUCTO`
   4. `METODO_PAGO`
   5. `VENTA`
   6. `DETALLE_VENTA`
   7. `PAGA_CON`  
   Este esquema cumple con la complejidad suficiente demandada por el equipo docente, sin introducir entidades artificiales que dispersen el foco en la venta minorista de hardware.

2. **Inmutabilidad y Trazabilidad:**  
   Se asegura el congelamiento de precios, la integridad referencial mediante claves foráneas rigurosas y la trazabilidad de operaciones multipago, dejando el esquema listo para la implementación física (DDL/DML) de la Etapa III.
