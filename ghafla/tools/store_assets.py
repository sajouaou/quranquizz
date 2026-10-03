#!/usr/bin/env python3
"""Génère les visuels du Play Store dans store/ : icône 512x512 et image de présentation 1024x500.

Dépendances : pip install cairosvg pillow
Les captures d'écran du téléphone sont à faire sur un vrai appareil (voir docs/PLAY_STORE.md).
"""
import io
import os

import cairosvg
from PIL import Image, ImageDraw, ImageFont

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "store")
os.makedirs(OUT, exist_ok=True)

svg = open(os.path.join(ROOT, "icon.svg"), encoding="utf-8").read().replace('rx="24"', 'rx="0"')  # Google arrondit lui-même
icon_png = cairosvg.svg2png(bytestring=svg.encode(), output_width=512, output_height=512)
Image.open(io.BytesIO(icon_png)).convert("RGB").save(os.path.join(OUT, "icon-512.png"))

# Image de présentation : ciel de rêve, l'icône à gauche, le nom et la phrase à droite
W, H = 1024, 500
img = Image.new("RGB", (W, H))
px = img.load()
top, mid, bot = (36, 28, 85), (123, 79, 154), (246, 181, 138)
for y in range(H):
    t = y / (H - 1)
    a, b, k = (top, mid, t / 0.6) if t < 0.6 else (mid, bot, (t - 0.6) / 0.4)
    c = tuple(int(a[i] + (b[i] - a[i]) * k) for i in range(3))
    for x in range(W):
        px[x, y] = c
mark = Image.open(io.BytesIO(cairosvg.svg2png(bytestring=svg.encode(), output_width=300, output_height=300))).convert("RGB")
img.paste(mark, (80, 100))
font_path = os.path.join(ROOT, "assets", "fonts", "Amiri-latin.fontbin")  # données TrueType brutes
d = ImageDraw.Draw(img)
big = ImageFont.truetype(font_path, 120)
small = ImageFont.truetype(font_path, 40)
d.text((430, 150), "Ghafla", font=big, fill=(245, 238, 220))
d.text((434, 290), "Un rêve. Des pages à retrouver.", font=small, fill=(255, 240, 200))
img.save(os.path.join(OUT, "feature-graphic-1024x500.png"))
print("Écrit dans", os.path.normpath(OUT))
