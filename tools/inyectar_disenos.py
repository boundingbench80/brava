#!/usr/bin/env python3
"""Inject department artwork SVGs into index.html between the DISENOS markers."""
from pathlib import Path
import re
import sys
import xml.etree.ElementTree as ET

# ET serializa el espacio de nombres SVG como «ns0:»; en HTML eso rompe las etiquetas, así que va sin prefijo.
ET.register_namespace("", "http://www.w3.org/2000/svg")

ROOT = Path(__file__).resolve().parent.parent
HTML = ROOT / "index.html"
IDS = ("cochabamba", "lapaz", "santacruz", "oruro", "potosi", "chuquisaca", "tarija", "beni", "pando")
START = "<!-- BEGIN DISENOS -->"
END = "<!-- END DISENOS -->"


def contents(path: Path) -> str:
    root = ET.parse(path).getroot()
    # ET omits comments by default. Remove only the preview background rectangle.
    for parent in root.iter():
        for child in list(parent):
            if child.tag.rsplit("}", 1)[-1] == "rect" and child.attrib.get("id") == "preview-bg":
                parent.remove(child)
    parts = [ET.tostring(child, encoding="unicode", short_empty_elements=True) for child in list(root)]
    # El xmlns repetido en cada hijo es redundante dentro de un documento HTML.
    return re.sub(r'\s+xmlns="http://www\.w3\.org/2000/svg"', "", "\n".join(parts))


def main() -> int:
    html = HTML.read_text(encoding="utf-8")
    if html.count(START) != 1 or html.count(END) != 1:
        print("Error: no se encontró un único par de marcadores DISENOS en index.html", file=sys.stderr)
        return 1
    symbols = []
    for dep in IDS:
        for filename, symbol, viewbox in ((f"{dep}.svg", f"d-{dep}", "0 0 400 400"),
                                          (f"gorra-{dep}.svg", f"c-{dep}", "0 0 200 120")):
            path = ROOT / "disenos" / filename
            if not path.is_file():
                print(f"Falta: disenos/{filename}")
                continue
            try:
                inner = contents(path)
            except (ET.ParseError, OSError) as exc:
                print(f"No se pudo leer disenos/{filename}: {exc}", file=sys.stderr)
                continue
            symbols.append(f'<symbol id="{symbol}" viewBox="{viewbox}">\n{inner}\n</symbol>')
    a = html.index(START) + len(START)
    b = html.index(END, a)
    html = html[:a] + "\n" + "\n".join(symbols) + "\n  " + html[b:]
    HTML.write_text(html, encoding="utf-8")
    print(f"Insertados {len(symbols)} símbolos en index.html")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
