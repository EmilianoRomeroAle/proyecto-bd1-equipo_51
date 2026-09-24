
## 1. Introducción y Justificación Teórica

El proceso de normalización busca estructurar las relaciones del sistema minimizando la redundancia y evitando anomalías en las operaciones básicas de manipulación de datos (inserción, modificación y borrado). 

En este informe preliminar se documenta el análisis formal de las dependencias funcionales partiendo de una estructura desnormalizada hasta alcanzar la Segunda Forma Normal (2FN).

---

## 2. Estado Inicial: Relación No Normalizada (0FN)

Se parte de una vista universal desnormalizada del comprobante de venta:

VENTA_GLOBAL (codigo_venta, fecha_hora, estado, monto_total, dni_cuit, nombre_cli, apellido_cli, contacto, ITEMS {id, sku, marca, modelo, desc_tecnica, precio_lista, stock_act, stock_res, cod_cat, nom_cat, cantidad}, PAGOS {cod_metodo, nom_metodo, monto_abonado})

### Problemas detectados en 0FN:
* Presencia de colecciones y grupos repetitivos (ITEMS y PAGOS).
* Atributo compuesto contacto (teléfono y correo agrupados).
* Alta redundancia en los datos del catálogo y del cliente.

---

## 3. Primera Forma Normal (1FN)

### 3.1 Criterio Aplicado
Una relación está en 1FN si:
1. Todos los atributos poseen valores atómicos.
2. Se eliminan los grupos repetitivos extrayendo las listas anidadas a tablas propias.
3. Se define una clave primaria unívoca.

### 3.2 Descomposición a 1FN:
* Se descompone contacto en email y telefono.
* Se extraen los grupos repetitivos generando tablas con clave compuesta vinculadas a codigo_venta.

Esquemas resultantes en 1FN:
* R_VENTA_1FN (codigo_venta, fecha_hora, monto_total, estado, dni_cuit, nombre_cli, apellido_cli, email, telefono)
  PK: codigo_venta
* R_DETALLE_1FN (codigo_venta, id, sku, marca, modelo, desc_tecnica, precio_lista, stock_act, stock_res, cod_cat, nom_cat, cantidad)
  PK: (codigo_venta, id)
* R_PAGO_1FN (codigo_venta, cod_metodo, nom_metodo, monto_abonado)
  PK: (codigo_venta, cod_metodo)

---

## 4. Segunda Forma Normal (2FN)

### 4.1 Criterio Aplicado
Una relación está en 2FN si está en 1FN y no posee dependencias funcionales parciales (todo atributo no clave debe depender de la totalidad de la clave primaria compuesta).

### 4.2 Análisis de Dependencias y Descomposición:
1. R_VENTA_1FN: Al poseer clave primaria simple (codigo_venta), no presenta dependencias parciales. Pasa directamente a 2FN.
2. R_PAGO_1FN: Clave (codigo_venta, cod_metodo).
   * El atributo nom_metodo depende solo de cod_metodo (dependencia parcial). Se separa en METODO_PAGO.
3. R_DETALLE_1FN: Clave (codigo_venta, id).
   * Los atributos de catálogo (marca, modelo, desc_tecnica, precio_lista, stock, cod_cat, nom_cat) dependen funcionalmente del producto (sku) y no de la línea del comprobante.
   * Decisión de diseño tomada: Se traslada el precio únicamente a la tabla PRODUCTO para no duplicarlo, dejando en el detalle solo la cantidad y el sku.

### 4.3 Esquema Obtenido en 2FN:

* METODO_PAGO (codigo_metodo, nombre_metodo)
  PK: codigo_metodo
* PAGA_CON (codigo_venta, codigo_metodo, monto_abonado)
  PK: (codigo_venta, codigo_metodo)
* DETALLE_VENTA (codigo_venta, id, sku, cantidad)
  PK: (codigo_venta, id)
* PRODUCTO (sku, marca, modelo, descripcion_tecnica, precio_lista, stock_actual, stock_reservado, codigo_categoria, nombre_categoria)
  PK: sku
* VENTA (codigo_venta, fecha_hora, monto_total, estado, dni_cuit, nombre, apellido, email, telefono)
  PK: codigo_venta

---

## 5. Próximos Pasos (Hacia 3FN)
Queda pendiente para la entrega final del equipo realizar la revisión de dependencias transitivas (3FN) sobre las tablas con claves simples (VENTA y PRODUCTO) y revisar el comportamiento de los precios en las líneas de venta.
