# Integración y demostración — Etapa V

**Equipo:** 51  
**Coordinación del bloque:** Integrante 3

## Punto de partida

La versión de referencia es `TP Integrador/proyecto-bd1-equipo_51`, con siete tablas y los nombres `precio_uni_historico`, `monto_abonado` y `VENTA.estado`. Los SQL sueltos externos corresponden a otra versión y no se mezclan con esta entrega.

Los archivos de los integrantes se prepararon en carpetas separadas para que cada aporte sea revisable. Al integrarlos, conservar una sola copia de cada archivo en la estructura del proyecto. El README general explica su ubicación; no hay que ejecutar todos los SQL indistintamente.

Los registros iniciales del DML representan ventas históricas ya abonadas. No deben volver a descontarse sus existencias. Los casos de esta etapa emplean productos, clientes y códigos nuevos.

## Orden de instalación

Trabajar sobre una copia nueva del modelo, no sobre datos personales ni de producción. Los scripts técnicos incluyen `USE tienda_hardware`; si la copia tiene otro nombre, reemplazar esa línea en los archivos utilizados para la prueba y comprobar el nombre de la base seleccionada antes de ejecutar.

1. `sql/ddl/crear_bd.sql`, del proyecto vigente, adaptado al nombre de la copia. Se ejecuta una sola vez para construir el esquema.
2. `sql/dml/datos_prueba.sql`, del proyecto vigente, en esa copia. Se ejecuta una sola vez para la carga histórica.
3. `sql/tecnico/01_funciones.sql`, del integrante 1.
4. `sql/tecnico/02_registro_ventas.sql`, del integrante 1.
5. `sql/tecnico/03_pagos_y_vencimientos.sql`, del integrante 2.
6. `sql/tecnico/04_auditoria_producto.sql`, del integrante 3.
7. `sql/tecnico/90_datos_prueba_etapa05.sql`, del integrante 3.

El lote 90 agrega únicamente registros ausentes. No reinicia productos que ya existían, no borra ventas ni elimina auditorías. Si un código estaba ocupado o los datos de una copia se cambiaron manualmente, revisar la situación; no usar el lote como mecanismo de limpieza.

## Orden de pruebas

1. `sql/tecnico/pruebas/01_pruebas_registro_ventas.sql`.
2. `sql/tecnico/pruebas/02_pruebas_transacciones.sql`.
3. `sql/tecnico/pruebas/03_pruebas_auditoria.sql`.
4. `sql/tecnico/pruebas/04_prueba_integracion.sql`.

La cuarta prueba reúne el circuito de los tres integrantes: venta con varios renglones, un SKU repetido, reservas, pagos combinados, confirmación, precio histórico, auditoría y reversión; también comprueba vencimiento y repetición sin duplicar efectos. La documentación de cada bloque y los mensajes de sus pruebas permiten revisar qué ocurrió.

La ejecución conjunta del 3 de noviembre de 2026 en `tienda_hardware_etapa05_verificacion` completó los cinco bloques de comprobaciones: venta de 3.500 con tres renglones, pagos de 1.500 y 2.000, stock final de 47 y 29 con reservas en cero, reversión de cambios anidados y sus auditorías, y cancelación de una pendiente sin liberar dos veces sus unidades. La salida se conserva en `docs/etapa-05/evidencias/integracion/resultados.txt`.

## Separación de los datos

El lote compartido utiliza categoría `9051`, cliente `99000051` y métodos `9051` y `9052`.

| Área | Productos | Códigos reservados de ventas |
| --- | --- | --- |
| Registro, integrante 1 | ET5-REG-01 y ET5-REG-02 | 95101 a 95149 |
| Pagos y transacciones, integrante 2 | ET5-PAG-01 y ET5-PAG-02 | 95201 a 95249 |
| Auditoría, integrante 3 | ET5-AUD-01 y ET5-AUD-02 | 95301 a 95349 |
| Integración | ET5-INT-01 y ET5-INT-02 | 95401 y 95402 |

Los productos terminados en `01` comienzan con precio 1.000, stock físico 50 y reserva 0. Los terminados en `02`, con precio 500, stock físico 30 y reserva 0. Si las pruebas necesitan otros valores, deben limitar el cambio a su caso y restaurarlo mediante la transacción de demostración.

## Qué revisar en la demostración

- La pendiente guarda total positivo, detalle y precio histórico desde su creación.
- Reservar unidades no disminuye el stock físico.
- Un nuevo renglón actualiza el total y reserva sus unidades.
- Los pagos parciales conservan el estado Pendiente y los pagos del mismo método se acumulan.
- La confirmación exige coincidencia entre detalle, cabecera y pagos; descuenta stock físico y retira reservas una sola vez.
- Los UPDATE relevantes de PRODUCTO producen auditorías con valores anteriores y nuevos.
- El cambio del catálogo no recalcula precios históricos de comprobantes.
- El error o la reversión no dejan pagos, reservas, descuentos o auditorías parcialmente aplicados.
- La cancelación de una pendiente vencida libera reservas sin aumentar stock físico ni borrar ventas o pagos.

## Cierre documental de la etapa IV

Se integra `docs/etapa-04/consultas_casos_uso.md` conservando las ocho explicaciones y las tablas de resultados aportadas al repositorio. Las comprobaciones repetidas se reunieron en una sola sección y se aclaró el efecto de los datos de etapa V. `sql/consultas/consultas.sql` conserva la versión remota de C01–C08; no se modifica su lógica ni se atribuye su autoría al desarrollo de auditoría. Su tabla de resultados esperados corresponde solamente al DML original, antes del lote 90 o de cualquier dato de etapa V. Los nuevos productos de demostración pueden cambiar, por ejemplo, la consulta de productos sin ventas.

Esta actualización documental no equivale a crear commits, subir cambios a GitHub ni entregar manifiestos. Cada integrante debe revisar y registrar sus contribuciones reales; no se preparan manifiestos atribuidos a otros integrantes.

## Lote opcional para el integrante 5

`sql/tecnico/91_lote_rendimiento.sql` sirve exclusivamente para preparar datos en una segunda copia llamada `tienda_hardware_rendimiento_etapa05`. Esa copia debe tener primero el DDL y DML originales adaptados a su nombre. El script rechaza otros nombres de base.

El volumen predeterminado es un millón de ventas históricas simuladas, cada una con un detalle y un pago coherentes, distribuidas por fecha durante cinco años. Utiliza un producto exclusivo `ET5-REN-01`. No descuenta existencias actuales y no crea índices adicionales: esas decisiones y mediciones pertenecen al integrante 5.

El parámetro local `@cantidad` permite una carga menor para verificar el script. Primero se comprobó una carga de 2.000 ventas, detalles y pagos y su repetición sin duplicados. Después se ejecutó el archivo completo: se cargaron 1.000.000 de ventas, 1.000.000 de detalles y 1.000.000 de pagos, con importe total de 1.000.000.000,00 y fechas entre el 1 de enero de 2021 y el 30 de diciembre de 2025. La salida está en `docs/etapa-05/evidencias/rendimiento/preparacion_lote.txt`. Esta comprobación valida la preparación del lote, no demuestra una mejora de rendimiento: los índices, planes y mediciones siguen a cargo del integrante 5. Repetir la misma carga coherente no duplica registros; una colisión o carga parcial genera error sin borrar datos.

## Trabajo que queda a cargo de 4 y 5

El integrante 4 debe implementar usuarios, permisos y roles y probar el circuito con una cuenta limitada. Ese bloque no se declara implementado en esta entrega.

El integrante 5 debe elegir una única consulta por fechas, mantener iguales sus columnas y filtros y comparar la estructura original con un índice adicional simple y otro con cobertura. Todavía debe generar sus planes, lecturas y tiempos reales. El lote preparado por 3 no constituye una medición de optimización.

Las capturas y manifiestos individuales deben producirse a partir de la ejecución y los aportes reales. Cada integrante completa sus referencias a archivos, commits y demás contribuciones cuando las registre.
