# Encargo: 5 prendas con efecto 3D «maniquí fantasma» (SVG)

Trabajas en la carpeta `prendas3d/` (la actual). Contexto: tienda de ropa urbana BRAVA. La página hoy dibuja canguro, polera y gorra como íconos planos. Quiero versiones que **parezcan una prenda real con volumen, como si alguien la tuviera puesta pero sin nadie** (foto de producto «ghost mannequin»): hombros redondeados, mangas con caída, pliegues suaves, cuello/capucha con interior visible, costuras, puños y cintura acanalados, sombras y luces suaves.

## Archivos a crear (SVG independientes, `viewBox="0 0 400 440"`, sin ancho/alto fijo)
1. `canguro-frente.svg`  (hoodie con capucha, bolsillo canguro, cordones, puños y cintura acanalados)
2. `canguro-espalda.svg` (capucha caída atrás con volumen, costura central, sin bolsillo)
3. `polera-frente.svg`   (polera de cuello redondo, manga corta, cuello acanalado con interior visible)
4. `polera-espalda.svg`  (cuello trasero, costuras de hombro)
5. `gorra-frente.svg`    (gorra de béisbol de 6 paneles vista 3/4 leve o frontal, visera curva con volumen, ojales, botón superior, banda interior visible bajo la visera)

Puedes tomar de punto de partida las siluetas actuales de `../index.html` (símbolos `s-hood-front`, `s-hood-back`, `s-tee-front`, `s-tee-back`, `s-cap`, líneas ~584-632): conserva su **encuadre y proporción** (la prenda ocupa casi todo el 400×440), pero redibújalas con mucho más realismo.

## Reglas técnicas (obligatorias)
- **Una sola fuente de color**: todo el cuerpo de la tela se rellena con `fill="var(--garment, #8a8a8a)"`. Nada de colores fijos para la tela. El usuario cambiará `--garment` por blanco, negro, verde, celeste, rosado, amarillo, azul marino y morado, así que el aspecto 3D debe salir **solo de capas superpuestas**:
  - capa de **sombras**: negro con opacidad (gradientes lineales/radiales `stop-color="#000"` con `stop-opacity`), para pliegues, bajo mangas, bajo capucha, bajo visera, bordes laterales;
  - capa de **luces**: blanco con opacidad (`stop-color="#fff"`) en hombros, pecho, frente de la gorra, crestas de pliegues. Tiene que verse bien también sobre NEGRO y AZUL MARINO (por eso las luces son blancas translúcidas y no solo sombras multiplicadas) y sobre BLANCO (por eso las sombras son suficientemente marcadas, ~0.25–0.45 en las zonas profundas).
  - Interiores (interior del cuello, de la capucha, bajo la visera): `fill="#000"` con opacidad, o el garment oscurecido con una capa negra translúcida encima.
- Contorno: trazo fino `stroke="#000" stroke-opacity=".28"` (no un color fijo duro). Costuras: línea punteada o continua fina con `stroke="#000" stroke-opacity=".3"` y, al lado, una línea blanca de `stroke-opacity=".15"` para dar relieve.
- Textura de tejido: opcional y barata, por ejemplo un `<pattern>` de líneas muy finas con opacidad ≤ .06 en las zonas acanaladas (puños, cintura, cuello). **Prohibido** `feTurbulence`/filtros pesados; sí se permite `feGaussianBlur` pequeño (stdDeviation ≤ 4) en pocas capas.
- Sin imágenes raster, sin fuentes, sin scripts, sin referencias externas. Solo `<defs>`, `<path>`, `<ellipse>`, `<rect>`, `<g>`, gradientes, `<clipPath>` y un `<pattern>` si hace falta.
- **Todos los `id` con prefijo único por archivo** (`cf-` canguro frente, `ce-` canguro espalda, `pf-` polera frente, `pe-` polera espalda, `gf-` gorra) para poder incrustar los cinco en la misma página sin colisiones.
- Usa `clip-path` con la silueta para que sombras y luces no se salgan del contorno.
- Peso razonable: cada archivo < 25 KB.

## Zonas de estampado: déjalas limpias (sin costuras ni pliegues fuertes dentro)
Coordenadas en el viewBox 400×440:
- canguro-frente: pecho x 230–294, y 118–156 (insignia 10×6 cm, lado izquierdo del que lo usa).
- canguro-espalda: cuadrado x 120–280, y 108–268 (30×30 cm). Aquí la tela debe verse lisa; el volumen va en los costados y la capucha.
- polera-frente: pecho x 224–288, y 96–134.
- polera-espalda: cuadrado x 120–280, y 76–236.
- gorra-frente: panel frontal x 130–270, y 132–216.
Un degradado muy suave y de baja opacidad sí puede pasar por ahí (da volumen), pero sin líneas.

## Calidad
Que se lea como producto de tienda real: el volumen viene de gradientes bien puestos (más oscuro hacia los costados y debajo de mangas/capucha, más claro en hombros/pecho), pliegues en codos/cintura/axilas, la capucha del canguro con interior profundo, la gorra con la visera curva proyectando sombra sobre la banda. Evita el look de ícono o clip-art.

## Verificación que debes hacer tú
1. Abre cada SVG en un HTML de prueba `prueba.html` (créalo) mostrando las 5 prendas en una grilla con 8 valores de `--garment` en `style` (`#F4F2EC`, `#17171A`, `#5F9B3F`, `#8EC9EE`, `#F2A7C0`, `#F2C230`, `#14264A`, `#6B3FA0`), incrustando los SVG inline (no `<img>`, porque `<img>` no hereda variables CSS).
2. Si hay Chrome/Edge disponible, genera una captura con `--headless --screenshot` y revisa que blanco y negro se vean bien.
3. Valida que cada SVG parsea como XML.
Escribe al final `RESULTADO.md` con qué hiciste y qué quedó flojo. No toques nada fuera de `prendas3d/`.
