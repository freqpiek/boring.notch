"""Exportiert Kopf, Körper und Arm des Teddys als transparente PNG-Ebenen.

Aufruf: python3 export_layers.py [Ausgabeordner]
Benötigt: playwright (chromium) und Pillow.
"""
import asyncio, json, os, sys
from PIL import Image
from playwright.async_api import async_playwright

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "layers")
K = 1.5  # Pixel pro SVG-Einheit

# Welche Kinder von #teddy zu welcher Ebene gehören (Reihenfolge wie im SVG)
HIDE_JS = {
    "head": "[...document.querySelectorAll('#teddy > *')].forEach(e => { if (e.id !== 'head') e.style.display='none'; });",
    "arm":  "[...document.querySelectorAll('#teddy > *')].forEach(e => { if (e.id !== 'arm-l') e.style.display='none'; });",
    "body": "[...document.querySelectorAll('#teddy > *')].forEach((e,i) => { if (i === 0 || e.id === 'arm-l' || e.id === 'arm-r' || e.id === 'head') e.style.display='none'; });",
}

async def main():
    os.makedirs(OUT, exist_ok=True)
    svg = open(os.path.join(HERE, "teddy-full.svg")).read()
    meta = {"k": K}
    async with async_playwright() as p:
        b = await p.chromium.launch()
        for name, js in HIDE_JS.items():
            pg = await b.new_page(viewport={"width": 400, "height": 500}, device_scale_factor=K)
            await pg.set_content(f"<body style='margin:0;background:transparent'>{svg}</body>")
            await pg.evaluate("document.querySelector('svg > rect').style.display='none'")
            await pg.evaluate(js)
            path = os.path.join(OUT, f"{name}_full.png")
            await pg.screenshot(path=path, omit_background=True)
            im = Image.open(path).convert("RGBA")
            x0, y0, x1, y1 = im.getchannel("A").point(lambda v: 255 if v > 3 else 0).getbbox()
            x0, y0 = max(0, x0 - 2), max(0, y0 - 2)
            x1, y1 = min(im.width, x1 + 2), min(im.height, y1 + 2)
            im.crop((x0, y0, x1, y1)).save(os.path.join(OUT, f"{name}.png"), optimize=True)
            os.remove(path)
            meta[name] = {"ox": x0 / K, "oy": y0 / K, "w": (x1 - x0) / K, "h": (y1 - y0) / K}
            await pg.close()
        await b.close()
    json.dump(meta, open(os.path.join(OUT, "layers.json"), "w"), indent=1)
    print(json.dumps(meta, indent=1))

asyncio.run(main())
