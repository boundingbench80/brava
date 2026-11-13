# Guía de arte BRAVA: un cuadrado de dibujos por departamento

Se necesitan, por cada departamento de Bolivia, **dos** diseños de serigrafía:
1. **Cuadrado** para la espalda de canguros y poleras: `disenos/<id>.svg`.
2. **Insignia** para gorras (y pecho): `disenos/gorra-<id>.svg`.

Ids: `cochabamba`, `lapaz`, `santacruz`, `oruro`, `potosi`, `chuquisaca`, `tarija`, `beni`, `pando`.

## Referencia visual
`referencia-estilo.jpg` es un canguro de otra marca con un cuadrado de dibujos blancos sobre negro: muchos dibujos pequeños de línea, íconos de lugares y objetos, letras a mano dentro de cintas y etiquetas, estrellitas, destellos, líneas punteadas que conectan y confeti. **Tomamos solo el formato** (un cuadrado denso, cada cosa en su espacio). No copies ningún dibujo ni frase de esa imagen: todo debe ser original y del departamento.

## Cuadrado: `viewBox="0 0 400 400"`
- Sin `width`/`height`, sin `<style>`, sin degradados, sin `opacity`, sin filtros, sin imágenes, sin marco exterior.
- La composición ocupa de 12 a 388 en ambos ejes y se siente llena y ordenada, como un pliego de stickers.
- 11 a 14 elementos principales, más relleno (estrellitas de cuatro puntas, destellos, puntos, confeti, ondas, líneas punteadas que unen elementos).
- Un elemento ancla grande (110 a 140 de alto) en el centro o en un tercio, 3 o 4 medianos (70 a 100) y el resto chicos (35 a 60).
- Separación mínima de 6 entre elementos. Los solapes tipo sticker se hacen adrede, con calado `g`.
- 3 a 5 palabras o frases cortas, escritas a mano o en cintas, banderines o etiquetas. Son nombres de lugares, comidas, fiestas o motivos del departamento.
- Una etiqueta chica con la palabra `BRAVA` abajo, como firma de marca.
- **Detalle real**: cada dibujo debe reconocerse y tener detalle de grabado (plumas, pelaje, vetas de madera, tejas, ventanas, texturas con rayitas o puntos). Nada de siluetas planas de ícono. Piensa en un sticker bien dibujado, no en un pictograma.
- Prohibido: política, lemas de partido, marcas registradas, logos reales y burlas. Las personas con vestimenta tradicional se dibujan con respeto y con detalle fiel.

## Tintas y clases (obligatorio)
La página recolorea el SVG con CSS. **No uses colores.** Usá solo estas clases:
- `i1`: relleno de la tinta principal (clara sobre prenda oscura). Es el 80 % del dibujo.
- `i2`: relleno de la tinta de acento. Entre el 15 y el 20 %: un detalle por elemento, un sol, una flor, una cinta.
- `s1`, `s2`: trazo sin relleno con tinta 1 o 2. Grosor 3 por defecto. Para otro grosor: `style="stroke-width:2"`, nunca menos de 1.8. Los extremos ya vienen redondeados.
- `g`: relleno del color de la prenda. Sirve para **calar** (ojos, ventanas, huecos dentro de una mancha de tinta).
- `sg`: trazo del color de la prenda para calar líneas finas dentro de una mancha.
- Texto: `<text class="pt i1">` (display condensada gruesa) o `class="pm i2"` (monoespaciada). Poné `text-anchor`, `font-size` (mínimo 11) y `textLength` con `lengthAdjust="spacingAndGlyphs"` para fijar el ancho. No uses otras fuentes: el texto se pasa a curvas después.
- `transform` simple (`translate`, `scale`, `rotate`) está bien.
- Solo dos tintas visibles: `i1` e `i2`.

## Insignia de gorra: `viewBox="0 0 200 120"`
El espacio es chico (10 × 6 cm). Contiene solo:
- El **nombre del departamento** en letras grandes, una línea, que ocupa el ancho, legible aunque se vea muy chico (`pt i1`).
- **Un** adorno significativo (el ícono más reconocible del departamento) arriba o al costado, con un toque de `i2`.
- Dos o tres detalles mínimos (estrellitas, una línea).
- Trazos de 2.4 o más y huecos de 2 o más. Sin detalle fino.
Adornos: cochabamba = Cristo de la Concordia; lapaz = sombrero bombín con trenzas; santacruz = toborochi florido; oruro = máscara de diablo; potosi = Cerro Rico; chuquisaca = Casa de la Libertad simple; tarija = racimo de uvas; beni = bufeo; pando = erizo de castaña.

## Contenido por departamento (elegí los que mejor se dibujen y usá la mayoría)
- **cochabamba**: ancla Cristo de la Concordia sobre el cerro San Pedro con sus gradas; cordillera del Tunari; cabina de teleférico colgada de su cable; **paraba frente roja con mucho detalle** (partí de `_referencia-paraba.svg`: adaptala a las clases y dale el mejor detalle del cuadrado); silpancho (plato con arroz, papa, milanesa, huevo, tomate y cebolla); vaso de chicha; charango (Aiquile es su capital); Palacio Portales; kantuta; choclo con queso; puesto de la Cancha con toldo. Palabras: COCHA, Qhochala, Eterna primavera, La Cancha.
- **lapaz**: ancla Illimani nevado; cholita paceña con bombín, trenzas, pollera y manta bordada; cabinas del teleférico sobre la ciudad; Puerta del Sol de Tiwanaku; Plaza Murillo con palomas; bote de totora en el Titicaca con sol; llama con aguayo; Valle de la Luna; salteña. Palabras: LA PAZ, Illimani, Jallalla, Titicaca.
- **santacruz**: ancla toborochi (palo borracho) florido; fachada de misión jesuítica chiquitana de madera; jaguar sobre una rama; guacamayo azul y amarillo; tipoy cruceño; cuñapé; plaza 24 de Septiembre con catedral y palmeras; tajibo florido; majadito; serpentinas de carnaval. Palabras: SANTA CRUZ, Camba, Chiquitanía, Cuñapé.
- **oruro**: ancla máscara de diablo de la Diablada con cuernos, serpientes, sapos y dientes; Virgen del Socavón con aureola de rayos; bailarín de morenada con matraca; flamencos en la laguna; volcán Sajama nevado; llama; chullpa; minero con casco. Palabras: ORURO, Diablada, Capital del Folklore, Socavón.
- **potosi**: ancla Cerro Rico con bocaminas; Casa Nacional de Moneda con arco y patio; Salar de Uyuni (hexágonos de sal y cielo reflejado); flamencos de la Laguna Colorada; Árbol de Piedra; minero con casco, lámpara y pico; vicuña; Cementerio de Trenes de Uyuni; quinua. Palabras: POTOSÍ, Cerro Rico, Uyuni, Vale un Potosí.
- **chuquisaca**: ancla Casa de la Libertad con su balcón; plaza 25 de Mayo con catedral y palmeras; Virgen de Guadalupe con corona; huellas de dinosaurio y un titanosaurio de Cal Orck'o; poncho de Tarabuco con guardas geométricas; montera de Tarabuco; tableta y taza de chocolate; cráter de Maragua. Palabras: SUCRE, Ciudad Blanca, 25 de Mayo, Tarabuco, Pujllay.
- **tarija**: ancla viñedo con racimos de uva; copa y botella de singani; guitarra chapaca; iglesia de San Francisco de Tarija; San Roque con su perro y su bastón; chancho a la cruz; cañón de Sama; pañuelo de la cueca chapaca. Palabras: TARIJA, Chapaco, Singani, Valle de la Concepción, Cueca chapaca.
- **beni**: ancla bufeo (delfín rosado) saltando; paraba barba azul con detalle; carpincho; caimán negro; moto de Trinidad; palmera de motacú; hamaca; loma de los Llanos de Moxos con su monte; canoa en el Mamoré; surubí. Palabras: BENI, Llanos de Moxos, Mamoré, Trinidad, Paraba azul.
- **pando**: ancla erizo de castaña abierto con las nueces; siringuero con su cuchillo junto al árbol de goma y su tarro; tucán; mono aullador; lobo de río; canoa en el río Orthon; mariposa Morpho; heliconia; hoja de asaí; casa y palmeras de Cobija. Palabras: PANDO, Cobija, Castaña, Amazonía, Siringa.

## Qué verificar antes de terminar
1. Cada SVG es XML válido: `python -c "import xml.dom.minidom,sys;xml.dom.minidom.parse(sys.argv[1])" archivo.svg`.
2. Sin colores fijos ni atributos de pintura: `grep -nE 'fill="|stroke="|#[0-9a-fA-F]{3,6}|opacity|<style|gradient' archivo.svg` no debe devolver nada (el color va solo por clases).
3. Renderizá una prueba y mirala. Armá `_pruebas/<id>.html` con este CSS y el SVG en línea sobre fondo verde, y sacá un PNG con Chrome headless (`chrome.exe --headless --screenshot=... --window-size=800,800 archivo.html`): `.i1{fill:#F1E9DA}.i2{fill:#D9A93F}.g{fill:#264A3B}.s1{fill:none;stroke:#F1E9DA;stroke-width:3;stroke-linecap:round;stroke-linejoin:round}.s2{fill:none;stroke:#D9A93F;stroke-width:3;stroke-linecap:round;stroke-linejoin:round}.sg{fill:none;stroke:#264A3B;stroke-width:2.6;stroke-linecap:round}.pt{font-family:Archivo,'Arial Narrow',sans-serif;font-weight:900;font-stretch:62%}.pm{font-family:monospace;font-weight:500}`. Si ves vacío, desorden, cosas irreconocibles o texto que se sale, corregí y repetí.
