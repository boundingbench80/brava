# BRAVA — maqueta web

Ropa urbana personalizable de Cochabamba (canguros, poleras y gorras serigrafiadas por pedido). Maqueta de un solo archivo: `index.html` (HTML + CSS + JS sin dependencias).

## Verla en local

```bash
python -m http.server 5191
```

y abrir http://localhost:5191/index.html

## Qué hay

- `index.html`: la página completa (rutas por hash, personalizador, pedido con QR y cierre por WhatsApp).
- `prendas/`: fotos de maniquí fantasma de canguro, polera y gorra en 8 colores (WebP).
- `disenos/arte/`: dibujos de serigrafía que manda Matías, uno por departamento (`<id>.webp` para imprimir, `<id>-m.webp` para pantalla) más `bolivia` (rótulo de la gorra). Originales en `disenos/arte/originales/` (los PNG grandes no se suben al repositorio: están en el Drive).
- `disenos/nombres/`: rótulo con el nombre de cada departamento, dibujado por Codex (`v1/` es su entrega original; los de la carpeta raíz están re-espaciados con `tools/reespaciar_nombres.py`).
- `disenos/*.svg`: dibujos vectoriales anteriores (de Codex); siguen en uso para la polera.
- `tools/mapas_sombra.py`: saca de las fotos en blanco los mapas de sombra (`prendas/sombra-*.webp`) e inyecta los filtros `#tela-<prenda>-<vista>` que funden el estampado con la tela (sombra de pliegues, poros, manchas de lavado y borde suelto).
- `tools/`: `importar_arte.py` (foto de línea → arte con transparencia + símbolo en el HTML), `inyectar_nombres.py`, `reespaciar_nombres.py`, `colorear_prendas.py`.
- `prendas3d/`: pruebas de generación de las prendas (fotos recortadas, especificaciones).

## Estado (2026-10-26)

- **Colores a la venta:** blanco, negro, azul marino y verde pacay (`COLORES_PRENDA` en `index.html`; las fotos de los otros cuatro siguen en `prendas/`).
- **Cada prenda tiene su propio catálogo de diseños** (paso 4 del personalizador): el canguro usa los departamentos con arte; la polera, sus láminas a color (página **Poleras**); la gorra, tres diseños: BOLIVIA, BRAVA o el nombre de un departamento.
- **Canguro, espalda:** los 9 departamentos ya tienen su arte. Cochabamba, Santa Cruz, La Paz, Oruro, Potosí y Pando vienen de los PNG de 3780 px del Drive (tinta oscura con transparencia: `tools/importar_arte.py` usa su alfa, los recorta al trazo y guarda 2000 px para imprimir y 720 px para pantalla). Beni, Chuquisaca y Tarija siguen con su arte de 1086 × 1448 px.
- **Efecto de tela:** el estampado pasa por el filtro `#tela-<prenda>-<vista>` (sombra de pliegues, poros, manchas de lavado y borde suelto). El desplazamiento del borde es de 0,4 (con 1 los trazos finos de los PNG nuevos se quebraban).
- **Pecho:** el canguro lleva el nombre del departamento; **todas las poleras llevan «BRAVA» al frente** (`n-brava`, de `disenos/nombres/v1/brava.svg`). Opciones de la polera: «Pecho» (solo BRAVA) o «Espalda» (lámina + BRAVA al frente).
- **Polera, espalda:** La Paz (5 láminas) y Oruro (Carnaval 1956) a todo color, tal cual, en `disenos/polera/` (`tools/importar_polera.py`). `disenos/polera/originales/bolivia-cholita.jpg` está guardada sin usar.
- **Celular:** el `<head>` no tenía `meta viewport` y el teléfono dibujaba la página a 980 px (todo diminuto, sin barra «Agregar al pedido»); ya lo tiene. Al agregar una prenda se abre el panel «Tu pedido» (con cantidad, editar y quitar).
- **Copiar código/monto/mensaje:** usa el portapapeles moderno y, si el navegador lo niega (WhatsApp, Instagram), `execCommand`; si tampoco, deja el texto seleccionado.
- **Estampado «negrito»:** la versión de pantalla (`-m.webp`) engrosa el trazo, la tinta del filtro de tela ya no se pierde en parches, y las miniaturas usan una máscara chica (`-s.webp`, símbolo `s-<id>`) sin filtro de tela.
- **QR:** el botón «Ver el QR de ejemplo» (Cómo comprar y pedido vacío) abre el paso de pago sin armar un pedido; si el pedido está vacío carga un canguro de ejemplo.
- **Derechos:** esas láminas son obras de terceros (póster de Redbubble, libro «La Mamani» de Nelson y Pelon, sello de Correos de Bolivia, afiche Carnaval 1956, «Arte Sano Mutante»). Solo vista previa: no publicar ni vender sin permiso. Aviso: están en el repositorio público solo para la maqueta.
- **Tamaño de impresión:** todos los dibujos tienen el mismo ancho en la espalda (canguro 144 u., polera 134 u.); los verticales (3:4) quedan más altos, sin deformarse. El canguro arranca bajo la punta de la capucha.

## Pendientes y avisos

- El arte trae marcas registradas que hay que quitar o reemplazar antes de vender: la sirena de Starbucks (Santa Cruz, abajo a la derecha), la bolsa «Pilfrut» (La Paz, arriba), la botella de Coca-Cola (Cochabamba y Potosí) y la etiqueta «Rath» (Cochabamba).
- Los rótulos de nombres de Codex quedaron más finos y geométricos que el «BOLIVIA» de referencia; conviene una segunda pasada de diseño.
- El arte es de una sola tinta: la opción «2 tintas» no cambia el dibujo.
- Planos, `ARQUITECTURA.md` y `PRODUCT.md` siguen describiendo el modelo anterior.
- Prototipo académico: precios, plazos y contactos son de ejemplo.
