#!/usr/bin/env python3
"""Toma las fotos recortadas de prendas blancas (prendas3d/fotos/cut-*.png) y genera una versión por color
en prendas/<prenda>-<lado>-<color>.webp (800x880), conservando luces, sombras y textura de la foto."""
from pathlib import Path
import json
import numpy as np
from PIL import Image, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
SRC = ROOT / "prendas3d" / "fotos"
OUT = ROOT / "prendas"
OUT.mkdir(exist_ok=True)

COLORES = {
    "blanco": "#F4F2EC", "negro": "#1B1B1F", "pacay": "#5F9B3F", "celeste": "#8EC9EE",
    "rosado": "#F2A7C0", "amarillo": "#F2C230", "marino": "#14264A", "morado": "#6B3FA0",
}
# (archivo, nombre de salida, zonas a borrar (x0,y0,x1,y1) en px del original: restos del maniquí)
PIEZAS = [
    ("cut-hood-front.png", "canguro-frente", []),
    ("cut-hood-back.png", "canguro-espalda", [(900, 0, 1230, 224)]),
    ("cut-tee-front.png", "polera-frente", []),
    ("cut-tee-back.png", "polera-espalda", [(700, 0, 1350, 268)]),
    ("cut-cap.png", "gorra-frente", []),
]
W, H, MARG = 800, 880, 24


def hex2rgb(h):
    h = h.lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)], dtype=np.float32) / 255


def prepara(path, borrar):
    im = Image.open(path).convert("RGBA")
    a = np.array(im.getchannel("A"))
    for x0, y0, x1, y1 in borrar:
        a[y0:y1, x0:x1] = 0
    alpha = Image.fromarray(a).filter(ImageFilter.MinFilter(3)).filter(ImageFilter.GaussianBlur(0.8))
    im.putalpha(alpha)
    bb = im.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    im = im.crop(bb)
    s = min((W - 2 * MARG) / im.width, (H - 2 * MARG) / im.height)
    im = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    canvas = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ox, oy = (W - im.width) // 2, (H - im.height) // 2
    canvas.alpha_composite(im, (ox, oy))
    return canvas, (ox, oy, im.width, im.height)


def colorea(base, color):
    arr = np.array(base).astype(np.float32) / 255
    a = arr[..., 3]
    lum = arr[..., :3] @ np.array([0.299, 0.587, 0.114], dtype=np.float32)
    m = a > 0.5
    ref = np.percentile(lum[m], 96)
    ln = np.clip(lum / ref, 0, 1)
    c = hex2rgb(color)
    lc = float(c @ np.array([0.299, 0.587, 0.114]))
    sombra = ln ** 1.15
    out = c[None, None, :] * sombra[..., None]
    if lc < 0.35:   # colores oscuros: se levantan las luces para que se lean los pliegues
        luz = np.clip((ln - 0.62) / 0.38, 0, 1) ** 1.4
        out = out + (1 - c)[None, None, :] * (luz * (0.17 - lc * 0.3))[..., None]
        out = out + (1 - sombra)[..., None] * 0.0
    out = np.clip(out, 0, 1)
    res = np.dstack([out, a])
    return Image.fromarray((res * 255).astype(np.uint8), "RGBA")


def main():
    cajas = {}
    for archivo, nombre, borrar in PIEZAS:
        base, caja = prepara(SRC / archivo, borrar)
        cajas[nombre] = caja
        for cn, hx in COLORES.items():
            colorea(base, hx).save(OUT / f"{nombre}-{cn}.webp", quality=90, method=4)
    (OUT / "cajas.json").write_text(json.dumps(cajas, indent=1))
    print("listo", len(PIEZAS) * len(COLORES), "imágenes;", cajas)


if __name__ == "__main__":
    main()
