# Cambios de la maqueta BRAVA

- Se agregó `tools/inyectar_disenos.py`. Lee los SVG de los nueve departamentos, limpia comentarios y `preview-bg`, informa archivos faltantes y reemplaza el contenido entre marcadores de forma repetible.
- Se añadieron los marcadores en `index.html`; el inyector insertó los 18 símbolos de cuadrados e insignias disponibles. No se modificaron archivos dentro de `disenos/`.
- Se sustituyó el catálogo de seis diseños por `DEPS`, con nombres, contenidos y palabras para los nueve departamentos. El estado y cada ítem usan `dep`; el almacenamiento cambió a `brava-pedido-v2`.
- Se actualizaron ubicaciones, medidas, órdenes, mensajes, chips, miniaturas y rutas para cuadrado de espalda e insignia de pecho o gorra. Se quitó el paso de texto.
- Inicio, el catálogo de departamentos y las fichas ahora muestran los nueve cuadrados y sus opciones de estampado. Se conservaron intactos los planos y el flujo de compra con QR de cuatro pasos.
- Se mantuvieron los estilos SVG existentes, agregando grillas de tres columnas en la selección y en Inicio, con objetivos táctiles y reglas de movimiento reducido ya presentes.

## Verificación

- `node --check` sobre el `<script>` extraído de `index.html`: pasó.
- `tools/inyectar_disenos.py`: ejecutado varias veces; cada ejecución insertó los 18 símbolos sin duplicarlos.
- Auditoría de HTML: 18 símbolos nuevos, sin símbolos antiguos ni estado o rutas antiguas en el personalizador y el catálogo; tampoco quedan rayas largas o medias en los textos de la página.
- Se intentó una captura con Chrome headless a 375 px, pero el proceso terminó con un error fatal del GPU antes de producir la captura. La apariencia visual real en navegador y el desplazamiento horizontal no quedaron verificados visualmente.
- Los wireframes dentro de la vista Planos conservan su texto de Colecciones y diseños anterior, según la instrucción de no actualizarlos. Sus anclas antiguas de ficha ahora caen en la lista Departamentos por la ruta de respaldo.
