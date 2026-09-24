
## 1. Introducción y Marco Metodológico

La normalización es la técnica formal del diseño relacional que garantiza la consistencia lógica de los datos, previene anomalías operacionales (inserción, actualización y borrado) y asegura que cada hecho se almacene en un único lugar lógico mediante uniones sin pérdida de información (lossless-join).

En esta entrega final se consolida el proceso completo desde la relación no normalizada (0FN) hasta la Tercera Forma Normal (3FN), incorporando la revisión crítica y corrección de las observaciones del informe preliminar.

---

## 2. Estado Inicial: Relación Universal Desnormalizada (0FN)

Partimos de la estructura global del comprobante comercial:

VENTA_GLOBAL (codigo_venta, fecha_hora, estado, monto_total, dni_cuit, nombre, apellido, contacto, RENGLONES {id, sku, marca, modelo, desc_tecnica, precio_lista, stock_act, stock_res, cod_cat, nom_cat, cantidad, precio_uni_hist}, PAGOS {cod_metodo, nom_metodo, monto_abonado})

---

## 3. Primera Forma Normal (1FN)

### 3.1 Regla Aplicada:
* Garantizar atomicidad de los valores en todas las columnas.
* Eliminar grupos repetitivos (RENGLONES y PAGOS) mediante relaciones independientes.
* Descomponer el atributo compuesto contacto en email y telefono.

### 3.2 Esquemas en 1FN:
* R_VENTA_1FN (codigo_venta, fecha_hora, monto_total, estado, dni_cuit, nombre, apellido, email, telefono)
* R_DETALLE_1FN (codigo_venta, id, sku, marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria, nombre_categoria, cantidad, precio_uni_historico)
* R_PAGO_1FN (codigo_venta, codigo_metodo, nombre_metodo, monto_abonado)

---

## 4. Segunda Forma Normal (2FN) y Corrección de Diseño

### 4.1 Regla Aplicada:
* Estar en 1FN y asegurar que todos los atributos no clave dependan funcionalmente de la totalidad de la clave primaria (eliminación de dependencias parciales).

### 4.2 Revisión y Corrección Crítica del Modelo Preliminar:
* Corrección del error preliminar: En el análisis preliminar se había omitido precio_uni_historico en DETALLE_VENTA confundiéndolo con una redundancia de PRODUCTO.precio_lista.
* Fundamento de la corrección: PRODUCTO.precio_lista es el precio de catálogo (mutable), mientras que DETALLE_VENTA.precio_uni_historico es el precio acordado e inmutable al momento exacto de la venta (Regla RN.06). Depende funcionalmente de la línea de venta (codigo_venta, id) y debe conservarse en la tabla de detalle para preservar la integridad histórica y contable.

### 4.3 Descomposición a 2FN:
* METODO_PAGO (codigo_metodo, nombre_metodo)
* PAGA_CON (codigo_venta, codigo_metodo, monto_abonado)
* DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico)
* PRODUCTO_2FN (sku, marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria, nombre_categoria)
* VENTA_2FN (codigo_venta, fecha_hora, monto_total, estado, dni_cuit, nombre, apellido, email, telefono)

---

## 5. Tercera Forma Normal (3FN)

### 5.1 Regla Aplicada:
* Estar en 2FN y eliminar dependencias funcionales transitivas (ningún atributo no clave puede depender funcionalmente de otro atributo no clave: no debe existir X -> Y -> Z).

### 5.2 Detección y Resolución de Transitividades:

1. Dependencia Transitiva en VENTA_2FN:
   * codigo_venta -> dni_cuit
   * dni_cuit -> {nombre, apellido, email, telefono}
   * codigo_venta -> dni_cuit -> datos_cliente (Transitiva).
   * Solución 3FN: Se aísla la tabla CLIENTE con PK dni_cuit, manteniendo en VENTA la clave foránea dni_cuit.

2. Dependencia Transitiva en PRODUCTO_2FN:
   * sku -> codigo_categoria
   * codigo_categoria -> nombre_categoria
   * sku -> codigo_categoria -> nombre_categoria (Transitiva).
   * Solución 3FN: Se aísla la tabla CATEGORIA con PK codigo_categoria, manteniendo en PRODUCTO la clave foránea codigo_categoria.

---

## 6. Esquema Relacional Final Normalizado (3FN)

El diseño relacional final normalizado en 3FN queda definido formalmente por las 7 tablas siguientes:

1. CLIENTE (dni_cuit, nombre, apellido, email, telefono)
   PK: dni_cuit

2. CATEGORIA (codigo_categoria, nombre_categoria)
   PK: codigo_categoria

3. PRODUCTO (sku, marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria)
   PK: sku
   FK: codigo_categoria -> CATEGORIA(codigo_categoria)

4. METODO_PAGO (codigo_metodo, nombre_metodo)
   PK: codigo_metodo

5. VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit)
   PK: codigo_venta
   FK: dni_cuit -> CLIENTE(dni_cuit)

6. DETALLE_VENTA (codigo_venta, id, sku, cantidad, precio_uni_historico)
   PK: (codigo_venta, id)
   FK1: codigo_venta -> VENTA(codigo_venta)
   FK2: sku -> PRODUCTO(sku)

7. PAGA_CON (codigo_venta, codigo_metodo, monto_abonado)
   PK: (codigo_venta, codigo_metodo)
   FK1: codigo_venta -> VENTA(codigo_venta)
   FK2: codigo_metodo -> METODO_PAGO(codigo_metodo)

---

## 7. Matriz de Síntesis del Proceso

| Nivel | Estado del Esquema | Condición Evaluada | Justificación / Corrección |
| :--- | :--- | :--- | :--- |
| 0FN | VENTA_GLOBAL | Sin normalizar | Contiene grupos repetitivos (ITEMS, PAGOS) y datos compuestos (contacto). |
| 1FN | Tablas intermedias de Venta, Detalle y Pagos | Atomicidad y eliminación de grupos repetitivos | Descomposición en filas atómicas; separación de email y telefono. |
| 2FN | VENTA, DETALLE_VENTA, PAGA_CON, PRODUCTO_2FN, METODO_PAGO | Dependencia Funcional Completa de PKs compuestas | Se corrigen datos descriptivos de métodos de pago y catálogo; se preserva precio_uni_historico en el detalle por inmutabilidad comercial (RN.06). |
| 3FN | Esquema Final (7 tablas) | Eliminación de dependencias transitivas | Se aíslan CLIENTE y CATEGORIA en tablas independientes con sus respectivas PKs y FKs. |

---

## 8. Conclusiones
El esquema final en 3FN garantiza la integridad referencial, la eliminación de redundancias y la total conformidad con el Diagrama Entidad-Relación (DER) en notación Chen y las reglas del negocio de la Etapa I.
