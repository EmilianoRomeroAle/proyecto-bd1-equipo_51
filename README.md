# Proyecto integrador — Bases de Datos I

**Equipo 51 · Licenciatura en Sistemas de Información · FaCENA, UNNE · 2026**

## Sistema de gestión comercial e inventario de hardware

El proyecto propone una base de datos para una empresa dedicada a la venta minorista de componentes informáticos y periféricos. El caso se centra en las operaciones de mostrador: registrar clientes, consultar productos y existencias, confeccionar ventas y distribuir los cobros entre distintos métodos de pago.

El repositorio reúne la descripción del negocio, el diseño conceptual y relacional, la normalización hasta Tercera Forma Normal (3FN), los scripts de implementación y las consultas en **Microsoft SQL Server**, para trabajar desde **SQL Server Management Studio (SSMS)**.

## Problema que se busca resolver

El negocio lleva sus ventas en planillas compartidas y anotaciones en papel. Esto dificulta conocer qué unidades están disponibles, distinguir los precios actuales de los aplicados en ventas anteriores y comprobar los importes de una operación abonada con varios medios de pago. También produce registros repetidos o incompletos de clientes.

La propuesta organiza esos datos en una misma base, con identificadores, relaciones y restricciones que permiten registrar las operaciones de forma consistente.

## Objetivos

- Organizar el catálogo de productos y sus categorías.
- Identificar a cada cliente mediante su DNI o CUIT y registrar sus datos de contacto.
- Representar las existencias físicas y las unidades reservadas de cada producto.
- Registrar ventas con sus renglones y el precio acordado en cada uno.
- Registrar el importe abonado con cada método de pago.
- Obtener un esquema en 3FN e implementarlo mediante sentencias DDL y DML.
- Consultar comprobantes, ventas por categoría, pagos y disponibilidad de productos.

## Alcance

| Área | Incluye | Queda fuera del proyecto |
| --- | --- | --- |
| Productos | SKU, marca, modelo, descripción, precio de lista y categoría. | Compras a proveedores y órdenes de reposición. |
| Clientes | Identificación por DNI o CUIT, nombre, apellido, correo y teléfono. | Gestión de cuentas de acceso de clientes. |
| Inventario | Stock actual, stock reservado y cálculo del disponible. | Recepción de mercadería y movimientos entre depósitos. |
| Ventas | Cabecera, renglones de detalle, precio histórico y estado de la venta. | Servicio técnico y gestión de garantías. |
| Cobros | Métodos de pago e importes registrados para una misma venta. | Integración con bancos y pasarelas de pago. |
| Atención | Operaciones comerciales del local. | Tienda web, logística y seguimiento de envíos. |

## Reglas principales del caso

- Cada venta corresponde a un único cliente registrado.
- Cada producto se identifica por un SKU único y pertenece a una categoría.
- El stock disponible se calcula como `stock_actual - stock_reservado`. El stock reservado no puede superar al stock actual.
- Cada renglón se identifica por el par `(codigo_venta, id)` y conserva el `precio_uni_historico` acordado, separado del precio de lista del producto.
- Una venta puede tener los estados `Pendiente`, `Abonado` o `Cancelado`.
- Una venta puede abonarse mediante uno o varios métodos. `PAGA_CON` registra el `monto_abonado` con cada uno.
- Para considerar una venta abonada, el total de sus renglones y la suma de sus cobros deben coincidir con el monto total de la cabecera.

La descripción completa se encuentra en [Reglas de negocio](docs/etapa-01/reglas-negocio.md).

## Modelo de datos

El esquema está formado por siete tablas:

| Tabla | Información que registra | Clave primaria |
| --- | --- | --- |
| `CLIENTE` | Datos de identificación y contacto. | `dni_cuit` |
| `CATEGORIA` | Categorías del catálogo. | `codigo_categoria` |
| `PRODUCTO` | Productos, precio vigente y existencias. | `sku` |
| `METODO_PAGO` | Medios de pago disponibles. | `codigo_metodo` |
| `VENTA` | Fecha, cliente, monto total y estado. | `codigo_venta` |
| `DETALLE_VENTA` | Producto, cantidad y precio histórico por renglón. | `(codigo_venta, id)` |
| `PAGA_CON` | Importe abonado por venta y método. | `(codigo_venta, codigo_metodo)` |

`DETALLE_VENTA` depende de la venta que contiene sus renglones. `PAGA_CON` resuelve la relación muchos a muchos entre ventas y métodos de pago. El [modelo relacional](docs/etapa-02/modelo-relacional.md) detalla los atributos y las claves foráneas.

## Documentación

| Etapa | Contenido | Archivos |
| --- | --- | --- |
| I — Análisis del caso | Contexto, alcance y reglas del negocio. | [Descripción del caso](docs/etapa-01/descripcion-caso.md) · [Alcance](docs/etapa-01/alcance.md) · [Reglas de negocio](docs/etapa-01/reglas-negocio.md) · [Decisiones de diseño](docs/etapa-01/decisiones-diseno.md) |
| II — Diseño conceptual y lógico | DER, transformación a tablas y normalización. | [DER conceptual](docs/etapa-02/der/der-parte1.jpeg) · [Diagrama relacional](docs/etapa-02/der/erdplus.png) · [Modelo relacional](docs/etapa-02/modelo-relacional.md) · [Normalización](docs/etapa-02/normalizacion.md) · [Decisiones de diseño](docs/etapa-02/decisiones-diseno.md) |
| III — Implementación física | Definición de tablas, restricciones y datos de prueba. | [Implementación](docs/etapa-03/implementacion.md) · [Restricciones de integridad](docs/etapa-03/restricciones-integridad.md) · [Pruebas de validación](docs/etapa-03/pruebas-validacion.md) |
| IV — Consultas y casos de uso | Recuperación y análisis de la información mediante SELECT. | Script de consultas y resumen de los ocho casos de uso en la sección siguiente. |

## Etapa IV — Consultas y casos de uso

Las ocho consultas se reúnen en [sql/consultas/consultas.sql](sql/consultas/consultas.sql). Utilizan SELECT con uniones, cálculos, agrupamientos, filtros y subconsultas.

Los resultados esperados de la tabla corresponden al lote de `datos_prueba.sql`. Para los reportes con filtro temporal se toma septiembre de 2026: `fecha_hora >= '2026-09-01T00:00:00'` y `fecha_hora < '2026-10-01T00:00:00'`. Las ventas consideradas en esos reportes tienen estado `Abonado`.

| Consulta | Necesidad de información | Estrategia SQL | Resultado esperado con el lote inicial |
| --- | --- | --- | --- |
| C01 — Comprobante | Consultar la cabecera y los renglones de la venta 1 con sus precios históricos. | JOIN entre cliente, venta, detalle y producto; cálculo de subtotal y subconsulta SUM para el total. | 2 renglones y total de $305.000,00. |
| C02 — Ventas por categoría | Conocer unidades e importes vendidos por categoría durante septiembre de 2026. | JOIN, GROUP BY, SUM de cantidades y subtotales, y COUNT DISTINCT de ventas. | 7 categorías, 21 unidades y $3.589.000,00 en total. |
| C03 — Clientes y compras | Identificar clientes que compraron al menos dos SKU distintos y cuyo importe comprado supera el promedio de una venta del mismo período. | JOIN entre cliente, venta, detalle y producto; GROUP BY, HAVING y subconsulta AVG. | Sofia, Mateo, Joaquin y Nicolas; promedio de referencia de $358.900,00. |
| C04 — Multipago completo | Identificar ventas abonadas con más de un medio y con cobros que cubren su total. | JOIN entre venta, cliente, pago y método; GROUP BY y HAVING sobre COUNT y SUM. | Ventas 1, 5, 8 y 10. |
| C05 — Compras de distintas categorías | Identificar ventas que incluyen productos de dos o más categorías. | JOIN entre venta, detalle, producto y categoría; COUNT DISTINCT y HAVING. | Ventas 1, 4, 5, 8 y 10. |
| C06 — Productos sin ventas | Identificar productos sin ventas abonadas en el período. | Subconsulta correlacionada con NOT EXISTS sobre ventas y detalles. | 0 filas: todos los productos tienen ventas abonadas en ese período. |
| C07 — Precios por categoría | Identificar productos cuyo precio de lista supera el promedio de su propia categoría. | Subconsulta correlacionada con AVG del precio de lista. | 3 productos: CPU-INT-13400F, GPU-MSI-7600XT y RAM-COR-VEN32. |
| C08 — Disponibilidad actual | Consultar productos con un máximo de 20 unidades disponibles. | Cálculo `stock_actual - stock_reservado` y filtro por el umbral. | 7 productos. |

En C01, el total de la cabecera se repite en cada renglón para acompañar el detalle; no se deben sumar esas repeticiones. En los reportes, COUNT DISTINCT cuenta cada venta, SKU o categoría una sola vez dentro de su grupo. Los importes vendidos se calculan con `cantidad * precio_uni_historico`.

C04 reúne los cobros sin unirlos con los renglones de venta. De ese modo, una venta con varios productos no multiplica los importes de sus pagos. C07 y C08 consultan el estado actual del catálogo y del inventario.

## Organización del repositorio

Esta vista resume los materiales desarrollados de las etapas I a IV.

```text
proyecto-bd1-equipo_51/
├── README.md
├── docs/
│   ├── etapa-01/
│   ├── etapa-02/
│   │   └── der/
│   └── etapa-03/
└── sql/
    ├── ddl/
    │   └── crear_bd.sql
    ├── dml/
    │   └── datos_prueba.sql
    └── consultas/
        └── consultas.sql
```

## Ejecución en SQL Server

Se necesita una instancia de Microsoft SQL Server y SSMS para abrir y ejecutar los scripts.

1. Conectarse a la instancia desde SSMS.
2. Abrir y ejecutar [sql/ddl/crear_bd.sql](sql/ddl/crear_bd.sql). Este script crea la base `tienda_hardware`, sus tablas y restricciones.
3. Abrir y ejecutar [sql/dml/datos_prueba.sql](sql/dml/datos_prueba.sql) para cargar los datos de ejemplo, una vez creadas las tablas.
4. Consultar las comprobaciones de [Pruebas de validación](docs/etapa-03/pruebas-validacion.md).
5. Abrir `sql/consultas/consultas.sql` y ejecutar el script completo o seleccionar una consulta individual para ejecutarla.
6. Comparar cada resultado con la referencia de la tabla de Etapa IV.

Los scripts DDL y DML están preparados para crear tablas nuevas y realizar una única carga inicial. Si las tablas o los datos ya existen, volver a ejecutarlos puede producir errores por objetos o claves duplicadas.
