# Descripción del caso de negocio

**Asignatura:** Bases de Datos I, año 2026

**Carrera:** Licenciatura en Sistemas de Información

**Institución:** Universidad Nacional del Nordeste (UNNE)

**Equipo:** 51

**Proyecto:** Sistema de Gestión Comercial e Inventario de Hardware

## 1. Organización

El proyecto representa un comercio minorista de componentes informáticos y periféricos. Vende procesadores, placas de video, memorias, unidades de almacenamiento, fuentes, gabinetes y otros artículos de hardware. La atención se realiza en un local, donde compran particulares, profesionales y empresas.

Los productos tienen distintas marcas, modelos y especificaciones técnicas. Sus precios cambian con frecuencia, por lo que el comercio necesita distinguir el precio de lista actual del precio acordado en cada venta. También necesita conocer las existencias disponibles antes de comprometer un producto con un cliente.

## 2. Problemas que se buscan resolver

El caso parte de un comercio que registra ventas e inventario en planillas y notas de mostrador. Esta forma de trabajo puede producir los siguientes problemas:

- Vender unidades que ya están reservadas para otro cliente.
- Alterar los importes de ventas anteriores al actualizar el precio del catálogo.
- Registrar pagos combinados cuya suma no coincide con el total de la venta.
- Repetir clientes o registrar sus datos de contacto de manera incompleta.

## 3. Objetivo del proyecto

Diseñar una base de datos que organice el catálogo, los clientes, las ventas y sus pagos. Cada producto debe tener un SKU único y una categoría; cada cliente debe identificarse por DNI o CUIT y contar con correo electrónico y teléfono.

Una venta se registra inicialmente como `Pendiente`. Sus renglones indican el producto, la cantidad y el precio unitario pactado al registrar el detalle. Las unidades quedan reservadas hasta que la venta pasa a `Abonado` o `Cancelado`. Una venta solo puede quedar en estado `Abonado` cuando la suma de sus pagos coincide con el total.

El comercio admite pagos combinados y registra los cobros después de que el operador los verifica. El proyecto contempla ese registro, sin conectarse con bancos, billeteras ni redes de criptomonedas.
