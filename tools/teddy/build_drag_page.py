"""Baut teddy-drag.html: die Vorlage plus die Ebenen als eingebettete Bilder.

Aufruf: python3 build_drag_page.py [Ebenen-Ordner] [Ausgabedatei]
Vorher: python3 export_layers.py
"""
import base64, json, os, sys

HERE = os.path.dirname(os.path.abspath(__file__))
LAYER_DIR = sys.argv[1] if len(sys.argv) > 1 else os.path.join(HERE, "layers")
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(HERE, "..", "..", "boringNotch", "teddy", "teddy-drag.html")

meta = json.load(open(os.path.join(LAYER_DIR, "layers.json")))
for name in ("head", "body", "arm"):
    data = base64.b64encode(open(os.path.join(LAYER_DIR, f"{name}.png"), "rb").read()).decode()
    meta[name]["src"] = "data:image/png;base64," + data

tpl = open(os.path.join(HERE, "teddy-drag.template.html")).read()
assert "/*LAYERS*/" in tpl
open(OUT, "w").write(tpl.replace("/*LAYERS*/", json.dumps(meta)))
print("geschrieben:", os.path.abspath(OUT), round(os.path.getsize(OUT) / 1024), "KB")
