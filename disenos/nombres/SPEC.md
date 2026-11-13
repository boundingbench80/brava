# Encargo: nombre de cada departamento como letrero de serigrafía (BRAVA)

Estás en la carpeta `Brava Proyect/`. Tarea: dibujar **solo el nombre** de cada departamento de Bolivia, como letras dibujadas a mano, para estamparlo chico en el pecho de un canguro y en una gorra (10 × 6 cm). Nada de íconos, marcos, banderas ni adornos: **solo las letras**.

## Referencia de estilo
La imagen adjunta (`disenos/arte/originales/bolivia.png`) es el rótulo «BOLIVIA» que ya usamos en la gorra. Copia su **espíritu**: letras altas y condensadas, de mano, con las esquinas redondeadas, **solo contorno** (letras huecas con una línea negra de grosor parejo), un poco irregulares y con una ligera inclinación hacia arriba hacia la derecha. No copies la palabra ni dibujes «BOLIVIA».

## Las 9 palabras (mayúsculas, una sola línea)
`COCHABAMBA`, `LA PAZ`, `SANTA CRUZ`, `ORURO`, `POTOSÍ` (con tilde sobre la I), `CHUQUISACA`, `TARIJA`, `BENI`, `PANDO`.

Para que se vean como una misma marca: dibuja **una sola vez cada letra que haga falta** (A B C D E H I J L M N O P Q R S T U Z y la tilde) con el mismo alto, el mismo grosor de línea y el mismo carácter, y arma cada palabra reutilizando esas letras con una separación pareja (unas 6 unidades). Una pequeña variación de altura o de giro entre letras de una misma palabra está bien, si da sensación de rótulo a mano; que no se pierda la lectura.

## Archivos a entregar
Uno por departamento en `disenos/nombres/<id>.svg`, con estos ids: `cochabamba`, `lapaz`, `santacruz`, `oruro`, `potosi`, `chuquisaca`, `tarija`, `beni`, `pando`.

Reglas técnicas (la página recolorea el SVG con CSS):
- `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 W H">` **ajustado al dibujo** (margen de 4 unidades por lado). Las letras miden unas 80 unidades de alto, así que H ronda 90; W depende de la palabra. Sin `width`/`height`.
- **Sin `<text>`**, sin fuentes, sin `<style>`, sin colores, sin degradados, sin opacidad, sin filtros, sin imágenes.
- Solo `<path>` (puedes agrupar con `<g>` y usar `transform` simple).
- Contorno de las letras: `<path class="s1" d="…"/>` (trazo de la tinta, sin relleno, grosor 3 ya incluido; para ajustar usa `style="stroke-width:3.4"`, nunca menos de 2.6). Cada letra es un contorno cerrado (más el hueco interior cuando lo lleve: O, A, B, D, P, R, Q).
- Si quieres un detalle relleno (por ejemplo la tilde o un punto), usa `class="i1"`.
- Cada letra debe quedar bien cerrada y legible aunque se reduzca a 10 cm de ancho en una prenda.

## Verificación
1. Comprueba que cada SVG parsea como XML.
2. Genera `disenos/nombres/prueba.html` con los 9 SVG en línea sobre fondo claro, con la clase `.s1{fill:none;stroke:#1A1917;stroke-width:3;stroke-linecap:round;stroke-linejoin:round}` y `.i1{fill:#1A1917}`, y toma una captura con Edge headless (`C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe --headless=new --screenshot=… --window-size=1200,900`) en `disenos/nombres/captura.png`. Revísala y corrige lo que se lea mal (letras pegadas, huecos sin cerrar, tilde mal puesta).
3. Escribe `disenos/nombres/RESULTADO.md` (corto): qué hiciste y qué quedó flojo.

No toques ningún otro archivo del proyecto.
