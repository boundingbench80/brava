"""Inyecta en index.html los rótulos con el nombre de cada departamento (disenos/nombres/<id>.svg).

Uso: python tools/inyectar_nombres.py
Cada archivo pasa a ser <symbol id="n-<id>"> con su viewBox; la página los usa en el pecho y en la gorra.
"""
import re
from pathlib import Path

RAIZ = Path(__file__).resolve().parent.parent
HTML = RAIZ / 'index.html'
IDS = ['brava', 'cochabamba', 'lapaz', 'santacruz', 'oruro', 'potosi', 'chuquisaca', 'tarija', 'beni', 'pando']


def simbolo(id_: str) -> str:
    svg = (RAIZ / 'disenos' / 'nombres' / f'{id_}.svg').read_text(encoding='utf-8')
    svg = re.sub(r'<\?xml[^>]*\?>|<!--.*?-->|<title>.*?</title>|<desc>.*?</desc>', '', svg, flags=re.S)
    m = re.search(r'<svg\b[^>]*\bviewBox="([^"]+)"[^>]*>(.*)</svg>', svg, flags=re.S)
    assert m, f'{id_}: no encontré viewBox'
    vb, cuerpo = m.group(1), re.sub(r'\s+', ' ', m.group(2)).strip()
    assert '<text' not in cuerpo and '<style' not in cuerpo, f'{id_}: trae texto o estilos'
    ancho = float(vb.split()[2])
    sw = round(min(3.8, max(3.0, ancho / 200 + 1.0)), 1)   # palabras largas: trazo apenas más grueso (más no, las letras se pegan)
    return f'<symbol id="n-{id_}" viewBox="{vb}" style="--sw:{sw}"><g class="arte">{cuerpo}</g></symbol>'


def main() -> None:
    html = HTML.read_text(encoding='utf-8')
    html = re.sub(r'<!-- nombres:inicio -->.*?<!-- nombres:fin -->\s*', '', html, flags=re.S)
    hechos = [i for i in IDS if (RAIZ / 'disenos' / 'nombres' / f'{i}.svg').exists()]
    bloque = '<!-- nombres:inicio -->\n' + '\n'.join(simbolo(i) for i in hechos) + '\n<!-- nombres:fin -->\n'
    ancla = '<!-- BEGIN DISENOS -->'
    assert ancla in html
    HTML.write_text(html.replace(ancla, bloque + ancla, 1), encoding='utf-8')
    print('nombres inyectados:', ', '.join(hechos))


if __name__ == '__main__':
    main()
