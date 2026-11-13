# Segunda pasada: nombres de departamentos (corrige lo de la primera)

Estás en `Brava Proyect/`. Ya hiciste `disenos/nombres/<id>.svg` (9 archivos) y `captura.png`. Lee `disenos/nombres/SPEC.md` (el encargo original) y mira la imagen adjunta `disenos/arte/originales/bolivia.png`, que es **la referencia de estilo**. Compara tu `captura.png` con ella: no es lo mismo y hay que corregirlo. Reescribe los 9 SVG.

## Qué está mal
1. **Estilo**: la referencia son **letras gruesas** (cada trazo de la letra tiene cuerpo, unas 14 a 18 unidades de ancho) dibujadas **solo en contorno**: se ven dos líneas paralelas por cada palo de la letra y el interior queda hueco. Las tuyas son una línea fina simple (monolineal); parecen un tipo de letra de máquina. Tienen que parecer un **rótulo dibujado a mano**: letras condensadas (ancho ≈ 0,55 del alto), esquinas muy redondeadas, contorno de grosor parejo (trazo ~3,4), pequeñas irregularidades (cada letra con un giro de ±1,5° y una variación de alto de ±2 unidades), y la línea de base subiendo suavemente hacia la derecha (unos 2° por palabra). Alto de las letras: ~80 unidades.
2. **La letra I**: queda con un hueco enorme a cada lado (`CHUQUI SACA`, `TARI JA`, `BEN I`, `POTOS Í`). La I es una letra estrecha: un óvalo/rectángulo redondeado alargado (ancho ~16 con el contorno), y la separación entre **todas** las letras es la misma (unas 5 unidades entre contornos). Revisa también la separación alrededor de J, L y T, que tienen huecos naturales.
3. **Tilde de POTOSÍ**: debe quedar **encima de la I**, centrada sobre ella, inclinada, del mismo trazo que las letras (puede ser un contorno de trazo grueso pequeño). Ahora está desplazada.
4. Las letras cerradas (A, B, D, O, P, Q, R) deben conservar su hueco interior de contraestampa, bien visible; la barra de la A y de la R, igual, con contorno.

## Formato (igual que antes)
- Mismos nombres de archivo, mismos ids, `viewBox` ajustado al dibujo (margen 4), sin `width`/`height`, sin `<text>`, sin `<style>`, sin colores.
- Solo `<path>` con `class="s1"` (trazo, sin relleno; grosor con `style="stroke-width:3.4"` si hace falta) y, si quieres, `class="i1"` para rellenos pequeños.
- Mantén el mismo alfabeto compartido (misma letra = mismo dibujo base, con una micro variación de giro/alto por aparición).

## Verificación
Regenera `disenos/nombres/prueba.html` y `captura.png` (Edge headless como antes, `--window-size=1200,900`), **míralas** y compara con la referencia. Corrige hasta que (a) se lean los 9 nombres sin dudar, (b) la I esté bien espaciada, (c) la tilde esté sobre la I, (d) el grosor y el aire se parezcan a BOLIVIA. Actualiza `RESULTADO.md` con una línea sobre lo que aún diferencia tu rótulo de la referencia. No toques ningún otro archivo.
