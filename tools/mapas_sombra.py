"""Mapas de sombra de cada prenda (prendas/sombra-<prenda>-<frente|espalda>.webp), sacados de la foto en blanco.

Uso: python tools/mapas_sombra.py
En cada mapa, 1 (blanco) = tela plana y a la luz; menos que 1 = pliegue o sombra. La web multiplica el estampado por este mapa
(filtro #tela en index.html) para que la tinta siga los pliegues y la trama de la tela en vez de verse pegada encima.
"""
from pathlib import Path
import numpy as np
from PIL import Image, ImageFilter

PRENDAS = Path(__file__).resolve().parent.parent / 'prendas'
VISTAS = ['canguro-espalda', 'canguro-frente', 'polera-espalda', 'polera-frente', 'gorra-frente']
CONTRASTE = 1.35   # >1 marca más los pliegues


def mapa(vista: str) -> None:
    im = Image.open(PRENDAS / f'{vista}-blanco.webp').convert('RGBA')
    a = np.asarray(im, dtype=np.float32) / 255
    lum = a[..., 0] * .2126 + a[..., 1] * .7152 + a[..., 2] * .0722
    dentro = a[..., 3] > .9
    ref = np.percentile(lum[dentro], 92)
    s = np.clip(lum / ref, 0, 1) ** CONTRASTE
    s = np.where(dentro, s, 1.0)
    out = Image.fromarray((s * 255).astype(np.uint8), 'L')
    out.save(PRENDAS / f'sombra-{vista}.webp', 'WEBP', lossless=True)
    print(vista, 'ref', round(float(ref), 3), 'min', round(float(s[dentro].min()), 3), 'media', round(float(s[dentro].mean()), 3))




def filtros() -> str:
    """Un filtro por vista. La tinta (1) se ensancha y se afloja en el borde, (2) se multiplica por el mapa de sombra de la prenda,
    (3) deja ver la tela por poros muy finos y (4) pierde fuerza en manchas grandes, como una serigrafía lavada."""
    f = []
    for v in VISTAS:
        f.append(
            f'<filter id="tela-{v}" filterUnits="userSpaceOnUse" x="0" y="0" width="400" height="440" color-interpolation-filters="sRGB">'
            '<feTurbulence type="fractalNoise" baseFrequency="0.8" numOctaves="2" seed="4" result="rugoso"/>'
            '<feDisplacementMap in="SourceGraphic" in2="rugoso" scale="0.4" xChannelSelector="R" yChannelSelector="G" result="borde"/>'
            '<feGaussianBlur in="borde" stdDeviation="0.28" result="suave"/>'
            f'<feImage href="prendas/sombra-{v}.webp" x="0" y="0" width="400" height="440" preserveAspectRatio="none" result="sombra"/>'
            '<feBlend in="suave" in2="sombra" mode="multiply" result="pliegue"/>'
            '<feComposite in="pliegue" in2="suave" operator="in" result="sobre"/>'
            '<feTurbulence type="fractalNoise" baseFrequency="1.8" numOctaves="1" seed="7" result="trama"/>'
            '<feColorMatrix in="trama" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 0 1" result="poros"/>'
            '<feTurbulence type="fractalNoise" baseFrequency="0.09" numOctaves="3" seed="21" result="lavado"/>'
            '<feColorMatrix in="lavado" type="matrix" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0.2 0 0 0 0.88" result="manchas"/>'
            '<feComposite in="poros" in2="manchas" operator="arithmetic" k1="1" k2="0" k3="0" k4="0" result="cobertura"/>'
            '<feComposite in="sobre" in2="cobertura" operator="in" result="tinta"/>'
            '<feComponentTransfer in="tinta"><feFuncA type="linear" slope="1"/></feComponentTransfer>'
            '</filter>')
    return '<!-- tela:inicio --><defs>' + ''.join(f) + '</defs><!-- tela:fin -->' + chr(10)


def inyectar() -> None:
    import re
    html_path = PRENDAS.parent / 'index.html'
    html = html_path.read_text(encoding='utf-8')
    html = re.sub(r'<!-- tela:inicio -->.*?<!-- tela:fin -->\s*', '', html, flags=re.S)
    ancla = '<!-- BEGIN DISENOS -->'
    assert ancla in html
    html_path.write_text(html.replace(ancla, filtros() + ancla, 1), encoding='utf-8')
    print('filtros de tela inyectados:', len(VISTAS))


if __name__ == '__main__':
    for v in VISTAS:
        mapa(v)
    inyectar()
