"""Importa el arte de serigrafía que manda Matías (dibujo de línea negra sobre papel blanco).

Uso:  python tools/importar_arte.py <departamento|bolivia> <ruta-de-la-imagen>
Ej.:  python tools/importar_arte.py beni C:/ruta/beni.webp

Qué hace (no retoca el dibujo, solo le quita el papel):
  1. guarda el original en disenos/arte/originales/<id>.<ext>
  2. escribe disenos/arte/<id>.webp: RGB blanco y alfa = oscuridad del trazo
     (la página lo usa como máscara y lo pinta con la tinta de la prenda).
     Si el archivo ya es un PNG con transparencia (tinta oscura sobre fondo transparente) se usa su alfa tal cual y se
     recorta al trazo; así entran los PNG de 3780 px del Drive sin perder calidad.
  3. reinyecta en index.html el símbolo <symbol id="a-<id>"> de todos los artes
"""
import re
import shutil
import sys
from pathlib import Path

import numpy as np
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
ARTE = RAIZ / 'disenos' / 'arte'
HTML = RAIZ / 'index.html'
IDS = ['cochabamba', 'lapaz', 'santacruz', 'oruro', 'potosi', 'chuquisaca', 'tarija', 'beni', 'pando']
# Niveles: por debajo de NEGRO el trazo es 100 % tinta, por encima de PAPEL no hay nada.
NEGRO, PAPEL = 70, 205
# Artes de gorra (un solo diseño para todos los departamentos): se recortan al trazo.
GORRA = ['bolivia']
ANCHO_MAX = 2000   # archivo de impresión; la versión de pantalla (-m) se saca de este


def a_alfa_png(origen: Path, destino: Path) -> tuple[int, int]:
    """PNG con transparencia real: alfa × oscuridad (lo opaco y claro, p. ej. un relleno blanco, no es tinta)."""
    Image.MAX_IMAGE_PIXELS = None
    rgba = np.asarray(Image.open(origen).convert('RGBA'), dtype=np.float32)
    lum = rgba[..., :3].mean(axis=2)
    a = rgba[..., 3] / 255 * np.clip((PAPEL - lum) / (PAPEL - NEGRO), 0, 1)
    ys, xs = np.where(a > 0.08)
    m = round(0.004 * (xs.max() - xs.min()))   # recorte al trazo: así todos los departamentos imprimen al mismo ancho
    a = a[max(ys.min() - m, 0):ys.max() + m + 1, max(xs.min() - m, 0):xs.max() + m + 1]
    img = Image.fromarray((a * 255 + 0.5).astype(np.uint8), 'L')
    if img.width > ANCHO_MAX:
        img = img.resize((ANCHO_MAX, round(img.height * ANCHO_MAX / img.width)), Image.LANCZOS)
    rgba_out = np.zeros((img.height, img.width, 4), dtype=np.uint8)
    rgba_out[..., :3] = 255
    rgba_out[..., 3] = np.asarray(img)
    Image.fromarray(rgba_out, 'RGBA').save(destino, 'WEBP', lossless=True, method=6)
    return img.size


def a_alfa(origen: Path, destino: Path) -> tuple[int, int]:
    probe = Image.open(origen)
    if probe.mode in ('RGBA', 'LA') or 'transparency' in probe.info:
        Image.MAX_IMAGE_PIXELS = None
        al = np.asarray(probe.convert('RGBA').getchannel('A'))
        if (al < 250).mean() > 0.05 and destino.stem not in GORRA:
            return a_alfa_png(origen, destino)
    rgb = Image.open(origen).convert('RGB')
    if rgb.width > ANCHO_MAX:
        rgb = rgb.resize((ANCHO_MAX, round(rgb.height * ANCHO_MAX / rgb.width)), Image.LANCZOS)
    c = np.asarray(rgb, dtype=np.float32)
    lum = np.asarray(rgb.convert('L'), dtype=np.float32)
    # Las imágenes chicas (<700 px) traen las líneas finas en gris: se aprieta el nivel de negro para que no se pierdan.
    negro = 120 if rgb.width < 700 else NEGRO
    a = np.clip((PAPEL - lum) / (PAPEL - negro), 0, 1)
    # El dibujo es gris/negro: lo que tenga color es un resto de captura de pantalla (marcos de selección, etc.).
    color = (c.max(axis=2) - c.min(axis=2)) > 45
    if color.any():
        from PIL import ImageFilter
        grueso = Image.fromarray((color * 255).astype(np.uint8)).filter(ImageFilter.MaxFilter(7))
        a[np.asarray(grueso) > 0] = 0
        print('quité', int(color.sum()), 'px de color (resto de captura)')
    a = (a * 255 + 0.5).astype(np.uint8)
    if destino.stem in GORRA:
        ys, xs = np.where(a > 20)
        m = round(0.03 * (xs.max() - xs.min()))
        a = a[max(ys.min() - m, 0):ys.max() + m + 1, max(xs.min() - m, 0):xs.max() + m + 1]
    rgba = np.zeros((*a.shape, 4), dtype=np.uint8)
    rgba[..., :3] = 255
    rgba[..., 3] = a
    Image.fromarray(rgba, 'RGBA').save(destino, 'WEBP', lossless=True, method=6)
    return rgb.width, rgb.height


def version_pantalla(id_: str) -> None:
    """<id>-m.webp: lado mayor de 720 px, reducida con filtro de calidad (el navegador reduce mal los trazos finos
    cuando la imagen es 4x más grande que el espacio donde se dibuja). El archivo grande queda para imprimir."""
    im = Image.open(ARTE / f'{id_}.webp')
    k = 720 / max(im.size)
    if k < 1:
        im = im.resize((round(im.width * k), round(im.height * k)), Image.LANCZOS)
    # «Negrito»: en la prenda el dibujo se ve a ~125 px de ancho y el trazo fino se pierde; se engruesa un poco
    # (y se afirma el borde) solo en la versión de pantalla. El archivo grande de impresión no se toca.
    from PIL import ImageFilter
    a = im.getchannel('A')
    grueso = a.filter(ImageFilter.MaxFilter(3))
    a = Image.fromarray(np.clip(np.maximum(np.asarray(a, dtype=np.float32), 0.8 * np.asarray(grueso, dtype=np.float32)) * 1.25, 0, 255).astype(np.uint8))
    im.putalpha(a)
    im.save(ARTE / f'{id_}-m.webp', 'WEBP', lossless=True, method=6)


def version_chica(id_: str) -> None:
    """<id>-s.webp: 96 px, para miniaturas de ~40 px (carrito, fichas). Una máscara de 720 px reducida de golpe a 40 px
    sale con bloques; así la reducción es chica y el trazo, que a ese tamaño casi desaparece, se refuerza."""
    im = Image.open(ARTE / f'{id_}.webp')
    k = 96 / max(im.size)
    im = im.resize((max(1, round(im.width * k)), max(1, round(im.height * k))), Image.LANCZOS)
    a = np.clip(np.asarray(im.getchannel('A'), dtype=np.float32) * 1.0, 0, 255).astype(np.uint8)
    im.putalpha(Image.fromarray(a))
    im.save(ARTE / f'{id_}-s.webp', 'WEBP', lossless=True, method=6)


def simbolo(id_: str) -> str:
    version_pantalla(id_)
    if id_ not in GORRA:
        version_chica(id_)
    w, h = Image.open(ARTE / f'{id_}-m.webp').size
    # Cabe en el cuadrado de 400, centrado, sin deformar.
    k = min(400 / w, 400 / h)
    sw, sh = round(w * k, 2), round(h * k, 2)
    x, y = round((400 - sw) / 2, 2), round((400 - sh) / 2, 2)
    if id_ in GORRA:  # el símbolo toma la proporción del recorte
        sw, sh, x, y = 400, round(400 * h / w, 2), 0, 0
    grande = (
        f'<symbol id="a-{id_}" viewBox="0 0 400 {sh if id_ in GORRA else 400}">'
        f'<mask id="am-{id_}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{sw}" height="{sh}">'
        f'<image href="disenos/arte/{id_}-m.webp" x="{x}" y="{y}" width="{sw}" height="{sh}"/></mask>'
        f'<g class="arte"><rect class="i1" x="{x}" y="{y}" width="{sw}" height="{sh}" mask="url(#am-{id_})"/></g></symbol>'
    )
    if id_ in GORRA:
        return grande
    chico = (
        f'<symbol id="s-{id_}" viewBox="0 0 400 400">'
        f'<mask id="sm-{id_}" maskUnits="userSpaceOnUse" x="{x}" y="{y}" width="{sw}" height="{sh}">'
        f'<image href="disenos/arte/{id_}-s.webp" x="{x}" y="{y}" width="{sw}" height="{sh}"/></mask>'
        f'<g class="arte"><rect class="i1" x="{x}" y="{y}" width="{sw}" height="{sh}" mask="url(#sm-{id_})"/></g></symbol>'
    )
    return grande + chr(10) + chico


def inyectar() -> None:
    html = HTML.read_text(encoding='utf-8')
    html = re.sub(r'<!-- arte:inicio -->.*?<!-- arte:fin -->\s*', '', html, flags=re.S)
    hechos = [i for i in IDS + GORRA if (ARTE / f'{i}.webp').exists()]
    bloque = ('<!-- arte:inicio -->' + chr(10)
              + '<defs><filter id="arte-f" color-interpolation-filters="sRGB"><feComponentTransfer>'
              + '<feFuncA type="linear" slope="2.2"/></feComponentTransfer></filter></defs>' + chr(10)
              + chr(10).join(simbolo(i) for i in hechos) + chr(10)
              + '<!-- arte:fin -->' + chr(10))
    # Va dentro del mismo <svg> de símbolos, antes de los dibujos vectoriales.
    ancla = '<!-- BEGIN DISENOS -->'
    assert ancla in html, 'no encontré el ancla de símbolos'
    html = html.replace(ancla, bloque + ancla, 1)
    HTML.write_text(html, encoding='utf-8')
    print('artes inyectados:', ', '.join(hechos))


if __name__ == '__main__':
    if len(sys.argv) == 3:
        id_, src = sys.argv[1], Path(sys.argv[2])
        assert id_ in IDS or id_ in GORRA, f'departamento desconocido: {id_}'
        (ARTE / 'originales').mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, ARTE / 'originales' / f'{id_}{src.suffix}')
        print('tamaño final', a_alfa(src, ARTE / f'{id_}.webp'))
    inyectar()
