"""Reordena las letras que dibujó Codex en disenos/nombres/<id>.svg.

Codex puso cada letra en una celda fija de 53 unidades, y la I (muy estrecha) quedaba con un hueco enorme.
Aquí cada letra se coloca según su ancho real, con la misma separación entre todas, la I pasa a ser un
contorno redondeado (como las otras letras cerradas) y el viewBox se ajusta al dibujo.
Parte siempre de disenos/nombres/v1/ (la entrega original de Codex) y escribe en disenos/nombres/.
"""
import re
from pathlib import Path

CARPETA = Path(__file__).resolve().parent.parent / 'disenos' / 'nombres'
GAP = 6        # separación entre contornos de letras
MARGEN = 4
ESPACIO = 24   # separación entre palabras
PALABRAS = {'lapaz': [2], 'santacruz': [5]}   # tras cuántas letras va un espacio
I_LETRA = 'M13,5 Q20,2.5 27,5 L27,77 Q20,79.5 13,77 Z'   # I como contorno cerrado, 14 de ancho

GRUPO = re.compile(r'<g transform="translate\(([-\d.]+),([-\d.]+)\) (rotate\([^)]*\))">(.*?)</g>', re.S)
NUM = re.compile(r'-?\d+(?:\.\d+)?')


def pares(d: str):
    n = [float(x) for x in NUM.findall(d)]
    return list(zip(n[0::2], n[1::2]))


def procesa(origen: Path, destino: Path) -> None:
    svg = origen.read_text(encoding='utf-8-sig')
    letras = []
    for tx, ty, rot, cuerpo in GRUPO.findall(svg):
        cuerpo = cuerpo.strip()
        if re.fullmatch(r'<path class="s1" d="M\d+,\d+ L\d+,\d+"/>', cuerpo) or (
                'L' in cuerpo and cuerpo.count('M') == 1 and cuerpo.count('L') == 1 and 'Q' not in cuerpo and '<path class="i1"' not in cuerpo
                and abs(pares(re.search(r'd="([^"]+)"', cuerpo).group(1))[0][0] - pares(re.search(r'd="([^"]+)"', cuerpo).group(1))[1][0]) < 3
                and abs(pares(re.search(r'd="([^"]+)"', cuerpo).group(1))[0][1] - pares(re.search(r'd="([^"]+)"', cuerpo).group(1))[1][1]) > 60):
            cuerpo = cuerpo.replace(re.search(r'd="([^"]+)"', cuerpo).group(1), I_LETRA, 1)
        todos = [p for d in re.findall(r' d="([^"]+)"', cuerpo) for p in pares(d)]
        s1 = [p for m in re.finditer(r'<path class="s1" d="([^"]+)"', cuerpo) for p in pares(m.group(1))]
        xs = [p[0] for p in s1]
        letras.append(dict(ty=float(ty), rot=rot, cuerpo=cuerpo, x0=min(xs), x1=max(xs),
                           ymin=min(p[1] for p in todos), ymax=max(p[1] for p in todos)))
    cortes = PALABRAS.get(destino.stem, [])
    cursor, salida = MARGEN, []
    ymin, ymax = 1e9, -1e9
    for n, L in enumerate(letras):
        tx = cursor - L['x0']
        salida.append(f'<g transform="translate({tx:.1f},{L["ty"]:g}) {L["rot"]}">{L["cuerpo"]}</g>')
        cursor += (L['x1'] - L['x0']) + (ESPACIO if n + 1 in cortes else GAP)
        ymin, ymax = min(ymin, L['ty'] + L['ymin']), max(ymax, L['ty'] + L['ymax'])
    ancho = cursor - GAP + MARGEN
    y0, alto = ymin - MARGEN, (ymax - ymin) + 2 * MARGEN
    destino.write_text(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 {y0:.1f} {ancho:.1f} {alto:.1f}">'
                       + ''.join(salida) + '</svg>', encoding='utf-8')
    print(destino.name, f'viewBox 0 {y0:.1f} {ancho:.1f} {alto:.1f}', len(letras), 'letras')


if __name__ == '__main__':
    for f in sorted((CARPETA / 'v1').glob('*.svg')):
        procesa(f, CARPETA / f.name)
