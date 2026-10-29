# Recolor a flat-color wallpaper: map a background and accent colors onto new
# ones, keeping antialiased edges. Each pixel is modeled as background plus a
# fraction of the nearest accent and rebuilt from the replacement colors.
#
# usage: recolor.py in.png out.png BG:BG' SRC:DST [SRC:DST ...]  (hex, no #)
# A replacement may be a mix, A+B@T: A blended toward B by fraction T.
import sys

import numpy as np
from PIL import Image


def rgb(h):
    if "+" in h:
        a, rest = h.split("+")
        b, t = rest.split("@")
        return rgb(a) + (rgb(b) - rgb(a)) * float(t)
    return np.array([int(h[i : i + 2], 16) for i in (0, 2, 4)], dtype=np.float32)


src, dst, bg, *accents = sys.argv[1:]
bg_from, bg_to = map(rgb, bg.split(":"))
pairs = [tuple(map(rgb, a.split(":"))) for a in accents]

p = np.asarray(Image.open(src).convert("RGB"), dtype=np.float32) - bg_from
best_err = np.full(p.shape[:2], np.inf, dtype=np.float32)
out = np.broadcast_to(bg_to, p.shape).copy()

for c_from, c_to in pairs:
    d = c_from - bg_from
    a = np.clip(p @ d / (d @ d), 0.0, 1.0).astype(np.float32)
    err = ((p - a[..., None] * d) ** 2).sum(-1)
    win = err < best_err
    best_err[win] = err[win]
    out[win] = bg_to + a[win, None] * (c_to - bg_to)

Image.fromarray(out.round().clip(0, 255).astype(np.uint8)).save(dst)
