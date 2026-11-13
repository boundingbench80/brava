"""Diseños a todo color para la espalda de la polera (disenos/polera/originales/ -> disenos/polera/<id>.webp).

Uso: python tools/importar_polera.py
Recorta el borde blanco o de papel de cada imagen, la guarda tal cual (sin retocar colores) y la inyecta en
index.html como <symbol id="p-<id>"> entre <!-- polera:inicio --> y <!-- polera:fin -->.
La lista DISENOS manda: el orden es el de las opciones en la web. Los ids de departamento son los de DEPS en index.html.
"""
import re
from pathlib import Path
from PIL import Image

RAIZ = Path(__file__).resolve().parent.parent
CARPETA = RAIZ / 'disenos' / 'polera'
HTML = RAIZ / 'index.html'

# id del diseño, departamento, nombre en la web, archivo original, recorte (izq, arriba, der, abajo) o None
DISENOS = [
    ('lapaz-poster',  'lapaz', 'La Paz, Illimani',   'lapaz-poster.jpg',   (133, 15, 602, 720)),
    ('lapaz-ajayu',   'lapaz', 'Ciudad Ajayu',       'lapaz-ajayu.jpg',    None),
    ('lapaz-saltena', 'lapaz', 'Salteña',            'lapaz-saltena.jpg',  None),
    ('lapaz-mamani',  'lapaz', 'La Mamani',          'lapaz-mamani.jpg',   None),
    ('lapaz-kusillo', 'lapaz', 'Kusillo',            'lapaz-kusillo.jpg',  (19, 17, 334, 433)),
    ('oruro-carnaval', 'oruro', 'Carnaval 1956',     'oruro-carnaval.jpg', (82, 62, 658, 946)),
]
LADO_MAX = 1100


def procesa(id_, jpg, recorte) -> tuple[int, int]:
    im = Image.open(CARPETA / 'originales' / jpg).convert('RGB')
    if recorte:
        im = im.crop(recorte)
    if max(im.size) > LADO_MAX:
        im.thumbnail((LADO_MAX, LADO_MAX), Image.LANCZOS)
    im.save(CARPETA / f'{id_}.webp', 'WEBP', quality=90)
    return im.size


def main() -> None:
    simbolos = []
    for id_, dep, nombre, jpg, recorte in DISENOS:
        w, h = procesa(id_, jpg, recorte)
        alto = round(400 * h / w, 2)
        simbolos.append(f'<symbol id="p-{id_}" viewBox="0 0 400 {alto}"><image href="disenos/polera/{id_}.webp" x="0" y="0" width="400" height="{alto}"/></symbol>')
        print(id_, (w, h))
    html = HTML.read_text(encoding='utf-8')
    html = re.sub(r'<!-- polera:inicio -->.*?<!-- polera:fin -->\s*', '', html, flags=re.S)
    ancla = '<!-- BEGIN DISENOS -->'
    assert ancla in html
    bloque = '<!-- polera:inicio -->\n' + '\n'.join(simbolos) + '\n<!-- polera:fin -->\n'
    HTML.write_text(html.replace(ancla, bloque + ancla, 1), encoding='utf-8')
    print('símbolos inyectados:', len(simbolos))


if __name__ == '__main__':
    main()
