# Draw a generated wallpaper from a base16 palette. Each style is a function of
# the scheme's colors, a seed and a few settings, so it recolors with every
# theme and comes out the same on every build. The styles are ported from the
# canvas code of the wallpaper studies board; rng() and Noise reproduce its
# random numbers exactly, so a seed gives the same layout it did there.
#
# usage: generate.py STYLE OUT WxH SEED PARAMS_JSON base00 ... base0F  (hex, no #)
import json
import math
import re
import sys

import cairo
import numpy as np
from PIL import Image, ImageFilter

ANG = math.radians(30)  # the diagonal the styles share
# The board's preview was 1600 px wide. Sizes scale with the width (s = W / 1920),
# so anything the board did not scale is pinned to this to keep its look.
BOARD_S = 1600 / 1920
DX, DY = math.cos(ANG), math.sin(ANG)
KEYS = [f"{i:02X}" for i in range(16)]


# --- random numbers and noise (same sequences as the board) -----------------


def rng(seed):
    """mulberry32, as in the board: a function returning floats in [0, 1)."""
    state = [seed & 0xFFFFFFFF]

    def r():
        state[0] = (state[0] + 0x6D2B79F5) & 0xFFFFFFFF
        a = state[0]
        t = ((a ^ (a >> 15)) * (1 | a)) & 0xFFFFFFFF
        t = ((t + (((t ^ (t >> 7)) * (61 | t)) & 0xFFFFFFFF)) & 0xFFFFFFFF) ^ t
        return ((t ^ (t >> 14)) & 0xFFFFFFFF) / 4294967296

    return r


def gauss(r):
    a = math.sqrt(-2 * math.log(1 - r()))
    return a * math.cos(2 * math.pi * r())


def js_round(x):
    return math.floor(x + 0.5)


# Perlin gradient directions, indexed by hash & 7.
GXL = [1, -1, 1, -1, 1, -1, 0, 0]
GYL = [1, 1, -1, -1, 0, 0, 1, -1]
GX, GY = np.array(GXL, float), np.array(GYL, float)


class Noise:
    """2D Perlin noise with a seeded permutation; scalar calls and numpy grids."""

    def __init__(self, seed):
        r = rng(seed * 7919 + 13)
        perm = list(range(256))
        for i in range(255, 0, -1):
            j = math.floor(r() * (i + 1))
            perm[i], perm[j] = perm[j], perm[i]
        self.p = [perm[i & 255] for i in range(512)]
        self.pa = np.array(self.p)

    def __call__(self, x, y):
        p = self.p
        fx, fy = math.floor(x), math.floor(y)
        X, Y = fx & 255, fy & 255
        x -= fx
        y -= fy
        u = x * x * x * (x * (x * 6 - 15) + 10)
        v = y * y * y * (y * (y * 6 - 15) + 10)
        a, b = p[X] + Y, p[X + 1] + Y
        h00, h10, h01, h11 = p[a] & 7, p[b] & 7, p[a + 1] & 7, p[b + 1] & 7
        n00 = GXL[h00] * x + GYL[h00] * y
        n10 = GXL[h10] * (x - 1) + GYL[h10] * y
        n01 = GXL[h01] * x + GYL[h01] * (y - 1)
        n11 = GXL[h11] * (x - 1) + GYL[h11] * (y - 1)
        top = n00 + (n10 - n00) * u
        return top + (n01 + (n11 - n01) * u - top) * v

    def grid(self, x, y):
        p = self.pa
        fx, fy = np.floor(x), np.floor(y)
        X, Y = fx.astype(int) & 255, fy.astype(int) & 255
        x, y = x - fx, y - fy
        u = x * x * x * (x * (x * 6 - 15) + 10)
        v = y * y * y * (y * (y * 6 - 15) + 10)
        a, b = p[X] + Y, p[X + 1] + Y

        def g(h, x, y):
            h = h & 7
            return GX[h] * x + GY[h] * y

        n00, n10 = g(p[a], x, y), g(p[b], x - 1, y)
        n01, n11 = g(p[a + 1], x, y - 1), g(p[b + 1], x - 1, y - 1)
        top = n00 + (n10 - n00) * u
        return top + (n01 + (n11 - n01) * u - top) * v


def fbm(n, x, y, octaves=4):
    s, a, f, t = 0.0, 1.0, 1.0, 0.0
    for _ in range(octaves):
        s += a * (n.grid(x * f, y * f) if isinstance(x, np.ndarray) else n(x * f, y * f))
        t += a
        a *= 0.5
        f *= 2
    return s / t


# --- colors -------------------------------------------------------------------


def mix(a, b, t):
    return [v + (w - v) * t for v, w in zip(a, b)]


def shade(c, f):
    return [max(0.0, min(255.0, v * f)) for v in c]


def rgba(c, a=1.0):
    """A color as the board's css() made it: channels truncated to integers."""
    return (int(c[0]), int(c[1]), int(c[2]), a)


def source(cr, col):
    cr.set_source_rgba(col[0] / 255, col[1] / 255, col[2] / 255, col[3])


def gradient(pattern, stops):
    for off, col in stops:
        pattern.add_color_stop_rgba(off, col[0] / 255, col[1] / 255, col[2] / 255, col[3])
    return pattern


def linear(x0, y0, x1, y1, stops):
    return gradient(cairo.LinearGradient(x0, y0, x1, y1), stops)


def radial(x0, y0, r0, x1, y1, r1, stops):
    return gradient(cairo.RadialGradient(x0, y0, r0, x1, y1, r1), stops)


def diag(W, H, u, v):
    """A point at (u along the stripe diagonal, v across it), from the screen center."""
    return W / 2 + u * DX - v * DY, H / 2 + u * DY + v * DX


def band_of(W, H, x, y, width):
    v = ((x - W / 2) * -DY + (y - H / 2) * DX) / H
    return math.exp(-v * v / width)


# --- layers, shadows and blur -------------------------------------------------


class Layer:
    """A full-size ARGB surface with its context, like a canvas."""

    def __init__(self, W, H):
        self.W, self.H = W, H
        self.surface = cairo.ImageSurface(cairo.FORMAT_ARGB32, W, H)
        self.cr = cairo.Context(self.surface)

    def pixels(self):
        """(H, W, 4) uint8 view of the premultiplied BGRA pixels."""
        self.surface.flush()
        stride = self.surface.get_stride()
        return np.ndarray((self.H, self.W, 4), np.uint8, self.surface.get_data(), 0, (stride, 4, 1))


_kept = []  # numpy buffers behind surfaces made by surface_of()


def surface_of(px):
    px = np.array(px, np.uint8, order="C")  # a writable copy; cairo needs one
    _kept.append(px)
    h, w = px.shape[:2]
    return cairo.ImageSurface.create_for_data(memoryview(px), cairo.FORMAT_ARGB32, w, h, w * 4)


def blur(px, sigma):
    """Gaussian blur of an (H, W) or (H, W, 4) uint8 array."""
    mode = "L" if px.ndim == 2 else "RGBA"
    return np.asarray(Image.fromarray(np.ascontiguousarray(px), mode).filter(ImageFilter.GaussianBlur(sigma)))


def shadow(cr, layer, col, blur_px, ox=0, oy=0):
    """Paint the canvas-style shadow of a layer's alpha: blur is shadowBlur (sigma = blur / 2)."""
    alpha = layer.pixels()[..., 3]
    if blur_px > 0:
        alpha = blur(alpha, blur_px / 2)
    a = alpha.astype(np.float32) * col[3]
    px = np.empty(alpha.shape + (4,), np.uint8)
    px[..., 0] = a * col[2] / 255
    px[..., 1] = a * col[1] / 255
    px[..., 2] = a * col[0] / 255
    px[..., 3] = a
    cr.set_source_surface(surface_of(px), ox, oy)
    cr.paint()


def with_shadow(dst, draw, col, blur_px, ox=0, oy=0):
    """Run draw on its own layer, then paint its shadow and the layer onto dst."""
    if col[3] <= 0 or (blur_px <= 0 and not ox and not oy):
        draw(dst.cr)
        return
    layer = Layer(dst.W, dst.H)
    draw(layer.cr)
    shadow(dst.cr, layer, col, blur_px, ox, oy)
    dst.cr.set_source_surface(layer.surface, 0, 0)
    dst.cr.paint()


def glow_path(dst, build, col, blur_px, width):
    """Only the shadow of a stroke: a soft line of light."""
    layer = Layer(dst.W, dst.H)
    cr = layer.cr
    cr.set_line_cap(cairo.LINE_CAP_ROUND)
    cr.set_line_join(cairo.LINE_JOIN_ROUND)
    cr.set_line_width(width)
    build(cr)
    cr.set_source_rgba(0, 0, 0, 1)
    cr.stroke()
    shadow(dst.cr, layer, col, blur_px)


def fill_all(cr, pattern_or_col):
    cr.rectangle(0, 0, cr.get_target().get_width(), cr.get_target().get_height())
    if isinstance(pattern_or_col, cairo.Pattern):
        cr.set_source(pattern_or_col)
    else:
        source(cr, pattern_or_col)
    cr.fill()


def vignette(L, amt):
    W, H = L.W, L.H
    fill_all(L.cr, radial(W / 2, H / 2, min(W, H) * 0.35, W / 2, H / 2, math.hypot(W, H) * 0.58,
                          [(0, (0, 0, 0, 0)), (1, (0, 0, 0, amt))]))


def grain(L, amt):
    r = rng(99)
    v = np.clip(np.rint([128 + (r() - 0.5) * 255 for _ in range(160 * 160)]), 0, 255).astype(np.uint8)
    px = np.empty((160, 160, 4), np.uint8)
    px[..., 0] = px[..., 1] = px[..., 2] = v.reshape(160, 160)
    px[..., 3] = 255
    pattern = cairo.SurfacePattern(surface_of(px))
    pattern.set_extend(cairo.EXTEND_REPEAT)
    cr = L.cr
    cr.save()
    cr.set_operator(cairo.OPERATOR_OVERLAY)
    cr.set_source(pattern)
    cr.paint_with_alpha(amt)
    cr.restore()


def poly(cr, pts):
    cr.move_to(*pts[0])
    for p in pts[1:]:
        cr.line_to(*p)
    cr.close_path()


# --- the NixOS flake ----------------------------------------------------------

# The six lambdas from lunik1/nix-wallpaper's wallpaper.svg (viewBox 2304 wide).
# The NixOS logo: "NixOS Logo" by the NixOS Project and contributors, from
# https://github.com/NixOS/branding, CC BY 4.0. See the README's License section.
FLAKE_SVG = [
    "M624-249.415 496-27.713-64-997.66h256L320-775.96 448-997.66h128l64 110.851-192 332.554z",
    "M528 415.692H272l560-969.948 128 221.702L832-110.85h256L1152 0l-64 110.851H704z",
    "m-96 665.108-128-221.703H896L768 665.108H512L640 886.81l-64 110.851H448L256 665.108z",
    "m-624 249.415 128-221.702L64 997.66h-256L-320 775.96-448 997.66h-128l-64-110.851 192-332.554z",
    "M-528-415.692h256l-560 969.948-128-221.702 128-221.703h-256L-1152 0l64-110.851h384z",
    "m96-665.108 128 221.703H-896l128-221.703h256L-640-886.81l64-110.851h128l192 332.553z",
]


def parse_svg_polygon(d):
    """One closed subpath of M/L/H/V commands (absolute or relative) as points."""
    tokens = re.findall(r"[MmLlHhVvZz]|-?(?:\d+\.?\d*|\.\d+)", d)
    pts, x, y, cmd, i = [], 0.0, 0.0, None, 0
    while i < len(tokens):
        t = tokens[i]
        if t.isalpha():
            cmd = t
            i += 1
            continue
        if cmd in "MmLl":
            nx, ny = float(tokens[i]), float(tokens[i + 1])
            i += 2
            x, y = (x + nx, y + ny) if cmd.islower() else (nx, ny)
            cmd = {"M": "L", "m": "l"}.get(cmd, cmd)
        elif cmd in "Hh":
            x = float(t) + (x if cmd == "h" else 0)
            i += 1
        elif cmd in "Vv":
            y = float(t) + (y if cmd == "v" else 0)
            i += 1
        pts.append((x, y))
    return pts


FLAKE = [parse_svg_polygon(d) for d in FLAKE_SVG]


def lambdas(cx, cy, width):
    """The six lambdas in device coordinates, for a flake of this width centered at (cx, cy)."""
    k = width / 2304
    return [[(cx + x * k, cy + y * k) for x, y in lam] for lam in FLAKE]


def draw_flake(cr, cx, cy, width, fills=None, halo=None, halo_w=0):
    lams = lambdas(cx, cy, width)
    cr.save()
    cr.set_line_join(cairo.LINE_JOIN_ROUND)
    if halo:
        cr.set_line_width(halo_w)
        for lam in lams:
            poly(cr, lam)
            source(cr, halo)
            cr.stroke_preserve()
            cr.fill()
    for i, lam in enumerate(lams if fills else []):
        poly(cr, lam)
        source(cr, fills[i % len(fills)])
        cr.fill()
    cr.restore()


def flake_cutout(cr, cx, cy, width, col, halo_w):
    """Every lambda dilated by halo_w, plus the inner hexagon so the center has no hole."""
    k = width / 2304
    draw_flake(cr, cx, cy, width, halo=col, halo_w=halo_w)
    poly(cr, [(cx + math.cos(i * math.pi / 3) * 560 * k, cy + math.sin(i * math.pi / 3) * 560 * k) for i in range(6)])
    source(cr, col)
    cr.fill()


def center_glow_background(L, P):
    W, H = L.W, L.H
    fill_all(L.cr, radial(W / 2, H / 2, 0, W / 2, H / 2, W * 0.7,
                          [(0, rgba(mix(P["00"], P["01"], 0.9))), (1, rgba(P["00"]))]))


# --- styles -------------------------------------------------------------------


def layered_ridges(L, W, H, P, k, seed):
    """Hazy ridges with the flake as a sun setting behind the first range, at the screen center."""
    s, n, cr = W / 1920, Noise(seed), L.cr
    fw = 380 * s
    rise = 175 * s * fw / (300 * s)
    hz = H / 2 + rise
    fy = hz - rise
    span = (H - hz + 40 * s) * 0.9
    fill_all(cr, rgba(P["00"]))
    sky = linear(0, 0, 0, hz + 60 * s, [(0, rgba(P["00"])), (0.55, rgba(mix(P["00"], P["01"], 0.9))),
                                        (1, rgba(mix(P["02"], P["0D"], 0.45 * k["glow"])))])
    cr.rectangle(0, 0, W, hz + 60 * s)
    cr.set_source(sky)
    cr.fill()
    fill_all(cr, radial(W / 2, fy + 25 * s, 0, W / 2, fy + 25 * s, W * 0.45,
                        [(0, rgba(P["0D"], 0.55 * k["glow"])), (0.3, rgba(P["0D"], 0.18 * k["glow"])),
                         (1, rgba(P["0D"], 0))]))
    draw_flake(cr, W / 2, fy, fw, [rgba(mix(P["0D"], P["07"], 0.25)), rgba(mix(P["04"], P["07"], 0.2))])
    layers = int(k["layers"])
    for i in range(layers):
        t = i / (layers - 1)
        base = hz - 40 * s + t * span
        amp = (80 + 160 * t) * s * k["rough"]
        col = mix(mix(P["03"], P["0D"], 0.25 * (1 - t)), P["00"], t**0.7 * 0.92)
        cr.move_to(0, H)
        x = 0.0
        while x <= W + 8 * s:
            rd = 1 - abs(fbm(n, x / W * (2 + t * 3) + i * 7.3, i * 3.1, 4))
            cr.line_to(x, base - rd * rd * amp * 1.6)
            x += 8 * s
        cr.line_to(W, H)
        cr.close_path()
        source(cr, rgba(col))
        cr.fill()
        haze = mix(P["02"], P["0D"], 0.2)
        cr.rectangle(0, base - amp, W, amp + 60 * s)
        cr.set_source(linear(0, base - amp, 0, base + 60 * s,
                             [(0, rgba(haze, 0)), (1, rgba(haze, 0.25 * (1 - t) * k["glow"]))]))
        cr.fill()
    vignette(L, 0.4)
    grain(L, 0.06)


# Marching squares: for each corner pattern (top-left 8, top-right 4,
# bottom-right 2, bottom-left 1 above the level), the cell edges to join.
MARCHING = {
    1: ("LB",), 14: ("LB",), 2: ("BR",), 13: ("BR",), 3: ("LR",), 12: ("LR",), 4: ("TR",), 11: ("TR",),
    6: ("TB",), 9: ("TB",), 7: ("LT",), 8: ("LT",), 5: ("LT", "BR"), 10: ("TR", "LB"),
}


def cell_edge(e, x, y, g, lv, a, b, c, d):
    """Where the level crosses one edge of the cell with corner values a b / d c."""
    if e == "T":
        return x + g * (lv - a) / (b - a), y
    if e == "R":
        return x + g, y + g * (lv - b) / (c - b)
    if e == "B":
        return x + g * (lv - d) / (c - d), y + g
    return x, y + g * (lv - a) / (d - a)


def contours(L, W, H, P, k, seed):
    """Topographic lines on tinted terraces, rising to the flake on the summit."""
    s, n, cr = W / 1920, Noise(seed), L.cr
    g = max(3, 7 * s)
    cols, rows = math.ceil(W / g) + 1, math.ceil(H / g) + 1
    X, Y = np.meshgrid(np.arange(cols) * g, np.arange(rows) * g)
    d = np.hypot(X - W / 2, (Y - H / 2) * 1.2) / (W * 0.2)
    F = fbm(n, X / W * k["relief"] * 1.6, Y / H * k["relief"], 5) + 0.55 * np.exp(-d * d)
    F = ((F - F.min()) / (F.max() - F.min())).astype(np.float32)
    levels = int(k["levels"])
    fill_all(cr, rgba(P["00"]))
    # Terraces: one color per elevation band, drawn small and scaled up smoothly.
    b = np.floor(F * levels) / levels
    lowc, highc = np.array(P["00"]), np.array(P["02"])
    mid, top = np.array(mix(P["00"], P["02"], k["fill"])), np.array(mix(P["03"], P["0D"], 0.25))
    low = lowc + (highc - lowc) * (b * 2 * k["fill"])[..., None]
    high = mid + (top - mid) * ((b - 0.5) * 2 * k["fill"] * 0.8)[..., None]
    rgb = np.clip(np.rint(np.where((b < 0.5)[..., None], low, high)), 0, 255).astype(np.uint8)
    px = np.empty((rows, cols, 4), np.uint8)
    px[..., 0], px[..., 1], px[..., 2], px[..., 3] = rgb[..., 2], rgb[..., 1], rgb[..., 0], 255
    cr.save()
    cr.scale(g, g)
    cr.set_source_surface(surface_of(px), 0, 0)
    cr.get_source().set_filter(cairo.FILTER_BILINEAR)
    cr.get_source().set_extend(cairo.EXTEND_PAD)
    cr.rectangle(0, 0, cols, rows)
    cr.fill()
    cr.restore()
    # Contour lines by marching squares, one path per level.
    f = F.tolist()
    for li in range(levels):
        lv = (li + 0.5) / levels
        if lv > 0.86:
            col = P["08"]
        elif lv < 0.5:
            col = mix(P["02"], P["04"], lv * 2)
        else:
            col = mix(P["04"], P["0D"], min(1, (lv - 0.5) * 2.8))
        for j in range(rows - 1):
            r0, r1 = f[j], f[j + 1]
            for i in range(cols - 1):
                a, b_, c, dd = r0[i], r0[i + 1], r1[i + 1], r1[i]
                idx = (a > lv) * 8 | (b_ > lv) * 4 | (c > lv) * 2 | (dd > lv)
                if idx == 0 or idx == 15:
                    continue
                x, y = i * g, j * g
                for e0, e1 in MARCHING[idx]:
                    cr.move_to(*cell_edge(e0, x, y, g, lv, a, b_, c, dd))
                    cr.line_to(*cell_edge(e1, x, y, g, lv, a, b_, c, dd))
        source(cr, rgba(col, 0.9))
        cr.set_line_width((2.4 if li % 5 == 4 else 1.2) * s)
        cr.stroke()
    flake_cutout(cr, W / 2, H / 2, 250 * s, rgba(P["00"]), 70 * s)
    draw_flake(cr, W / 2, H / 2, 250 * s, [rgba(P["0D"]), rgba(P["04"])])
    vignette(L, 0.4)
    grain(L, 0.05)


def windlines(L, W, H, P, k, seed):
    """Thousands of fine streamlines combed along the diagonal, with a few glowing currents."""
    s, r, n, cr = W / 1920, rng(seed), Noise(seed), L.cr
    center_glow_background(L, P)
    curl = k["curl"]

    def field(x, y):
        return ANG + fbm(n, x / W * curl * 2, y / H * curl * 2, 3) * math.pi * 1.6

    def trace(c, x, y, steps, st):
        c.move_to(x, y)
        for _ in range(steps):
            a = field(x, y)
            x += math.cos(a) * st
            y += math.sin(a) * st
            c.line_to(x, y)

    for g in range(7):
        x, y = diag(W, H, -W * 0.65 + r() * W * 0.3, gauss(r) * H * 0.2)
        glow_path(L, lambda c, x=x, y=y: trace(c, x, y, 140, 12 * s),
                  rgba(P["08"] if g % 2 else P["0D"], 0.55 * k["glow"]), 60 * s, 30 * s)
    cr.set_line_width(max(0.6, 1.3 * s))
    cr.set_line_cap(cairo.LINE_CAP_ROUND)
    # Line length and width already scale with s, so the count stays at the board's.
    for _ in range(js_round(1800 * k["density"] * BOARD_S)):
        x = r() * W * 1.2 - W * 0.1
        y = r() * H * 1.2 - H * 0.1
        band = band_of(W, H, x, y, 0.05)
        roll = r()
        if roll < band * 0.7:
            col = P["0D"] if roll < band * 0.35 else P["08"]
        else:
            col = P["03"] if r() < 0.5 else P["04"]
        source(cr, rgba(col, 0.25 + 0.5 * band))
        trace(cr, x, y, 30 + int(r() * 50), 4 * s)
        cr.stroke()
    vignette(L, 0.45)
    grain(L, 0.05)


def flow_engraving(L, W, H, P, k, seed):
    """Evenly spaced engraved strokes that turn gold and teal where they pass through the flake."""
    s, r, n, nw, cr = W / 1920, rng(seed), Noise(seed), Noise(seed + 11), L.cr
    cx, cy, fw = W / 2, H / 2, k["logo"] * s
    sep = k["spacing"] * s
    st = sep / 3
    center_glow_background(L, P)
    # Which lambda (or -1) each half-resolution pixel belongs to.
    mw, mh = math.ceil(W / 2), math.ceil(H / 2)
    owner = np.full((mh, mw), -1, np.int8)
    for i, lam in enumerate(lambdas(mw / 2, mh / 2, fw / 2)):
        mask = cairo.ImageSurface(cairo.FORMAT_A8, mw, mh)
        mc = cairo.Context(mask)
        poly(mc, lam)
        mc.fill()
        mask.flush()
        a = np.ndarray((mh, mw), np.uint8, mask.get_data(), 0, (mask.get_stride(), 1))
        owner[a > 127] = i
    owner = owner.tolist()

    def in_flake(x, y):
        ix, iy = int(x / 2), int(y / 2)
        return owner[iy][ix] if 0 <= ix < mw and 0 <= iy < mh else -1

    curl = k["curl"]

    def field(x, y):
        d = math.hypot(x - cx, y - cy) / (fw * 0.55)
        return ANG + fbm(n, x / W * curl * 2, y / H * curl * 2, 3) * math.pi * 1.6 * (1 - 0.9 * math.exp(-d * d))

    # Evenly spaced streamlines: seeds keep a full sep from other lines, and a line runs on until it comes within sep / 2.
    cell = sep / 2
    gw, gh = math.ceil(W / cell) + 4, math.ceil(H / cell) + 4
    occ = [-1] * (gw * gh)

    def gi(x, y):
        return (math.floor(y / cell) + 2) * gw + math.floor(x / cell) + 2

    def free(x, y, lid, R=2):
        if x < -cell or y < -cell or x > W + cell or y > H + cell:
            return False
        ix, iy = math.floor(x / cell) + 2, math.floor(y / cell) + 2
        for dy in range(-R, R + 1):
            row = (iy + dy) * gw + ix
            for dx in range(-R, R + 1):
                o = occ[row + dx]
                if o >= 0 and o != lid:
                    return False
        return True

    seeds = []
    y = sep / 2
    while y < H:
        x = sep / 2
        while x < W:
            sx = x + (r() - 0.5) * sep
            seeds.append((sx, y + (r() - 0.5) * sep))
            x += sep
        y += sep
    for i in range(len(seeds) - 1, 0, -1):
        j = math.floor(r() * (i + 1))
        seeds[i], seeds[j] = seeds[j], seeds[i]
    lines = []
    for x0, y0 in seeds:
        lid = len(lines)
        if not free(x0, y0, lid):
            continue
        halves = []
        for direction in (1, -1):
            x, y, pts = x0, y0, []
            for _ in range(400):
                a = field(x, y)
                nx, ny = x + direction * math.cos(a) * st, y + direction * math.sin(a) * st
                if not free(nx, ny, lid, 1):
                    break
                x, y = nx, ny
                pts.append((x, y))
                occ[gi(x, y)] = lid
            halves.append(pts)
        occ[gi(x0, y0)] = lid
        pts = halves[1][::-1] + [(x0, y0)] + halves[0]
        if len(pts) > 6:
            lines.append(pts)

    glow = Layer(W, H)
    draw_flake(glow.cr, cx, cy, fw, [(0, 0, 0, 1)])
    shadow(cr, glow, rgba(P["0D"], 0.7 * k["glow"]), 90 * s)
    cr.set_line_cap(cairo.LINE_CAP_ROUND)
    cr.set_line_join(cairo.LINE_JOIN_ROUND)
    for pts in lines:
        band = band_of(W, H, pts[0][0], pts[0][1], 0.06)
        base = mix(P["02"], P["04"], 0.25 + 0.45 * band)
        # Variation only thins: Weight is the maximum, and broad noise patches (plus a little per-line jitter) take strokes down to 15% of it.
        mx0, my0 = pts[len(pts) >> 1]
        thin = min(1, max(0, 0.5 + 1.8 * fbm(nw, mx0 / W * 2.5, my0 / H * 2.5, 2) + 0.3 * (r() - 0.5)))
        vm = 1 - 0.85 * k["vary"] * thin

        def style(c):
            source(cr, rgba(P["04"] if c % 2 else P["0D"], 1) if c >= 0 else rgba(base, 0.8))
            cr.set_line_width(min(sep * 0.85, k["weight"] * s * vm * (2.4 if c >= 0 else 1)))

        cur = in_flake(*pts[0])
        style(cur)
        cr.move_to(*pts[0])
        for p in pts[1:]:
            here = in_flake(*p)
            cr.line_to(*p)
            if here != cur:
                cr.stroke()
                cur = here
                style(cur)
                cr.move_to(*p)
        cr.stroke()
    vignette(L, 0.45)
    grain(L, 0.05)


def prism_shards(L, W, H, P, k, seed):
    """Low-poly facets with patches of the scheme's accents and the flake cut as tinted glass."""
    s, r, n, n2, cr = W / 1920, rng(seed), Noise(seed), Noise(seed + 5), L.cr
    size, cx, cy = k["facet"] * s, W / 2, H / 2
    fw = 380 * s
    acc = [P[c] for c in ["0D", "08", "0E", "0C", "0A"][: int(k["colors"])]]
    ramp = [P["00"], P["01"], P["02"], P["03"]]
    centers = []
    for i in range(14):
        px_ = r() * W
        centers.append((px_, r() * H, acc[i % len(acc)]))
    cols, rows = math.ceil(W / size) + 2, math.ceil(H / size) + 2
    pts, glass = [], []
    for j in range(rows):
        for i in range(cols):
            px_ = (i - 0.5 + (r() - 0.5) * 0.9) * size
            pts.append((px_, (j - 0.5 + (r() - 0.5) * 0.9) * size))

    def tri(a, b, c):
        x, y = (a[0] + b[0] + c[0]) / 3, (a[1] + b[1] + c[1]) / 3
        band = band_of(W, H, x, y, 0.06)
        t = max(0, min(0.999, (fbm(n, x / W * 2.4, y / H * 2.4) + 0.6) / 1.2 * 0.75 + band * 0.3))
        f = t * 3
        i = math.floor(f)
        col = mix(ramp[i], ramp[min(3, i + 1)], f - i)
        near = min(centers, key=lambda p: (p[0] - x) ** 2 + (p[1] - y) ** 2)
        am = max(0, min(1, (band * 1.1 + fbm(n2, x / W * 3, y / H * 3) - (1 - k["accent"]) * 1.2) * 1.6))
        col = shade(mix(col, near[2], am * 0.85), 1 + (r() - 0.5) * k["contrast"] * 0.55)
        poly(cr, [a, b, c])
        source(cr, rgba(col))
        cr.set_line_width(1)
        cr.fill_preserve()
        cr.stroke()
        if math.hypot(x - cx, y - cy) < fw * 0.6:
            glass.append((a, b, c))

    for j in range(rows - 1):
        for i in range(cols - 1):
            a, b, c, d = pts[j * cols + i], pts[j * cols + i + 1], pts[(j + 1) * cols + i + 1], pts[(j + 1) * cols + i]
            if (i + j) % 2:
                tri(a, b, c)
                tri(a, c, d)
            else:
                tri(a, b, d)
                tri(b, c, d)
    # The flake keeps a crisp outline; inside it, the same mesh is recut finer and shaded as tinted glass.
    for li, lam in enumerate(lambdas(cx, cy, fw)):
        tint = mix(P["04"] if li % 2 else P["0D"], P["07"], 0.15)

        def fill_lambda(c, lam=lam, tint=tint):
            poly(c, lam)
            source(c, rgba(tint))
            c.fill()

        with_shadow(L, fill_lambda, (0, 0, 0, 0.5), 24 * s, 0, 8 * s)
        cr.save()
        poly(cr, lam)
        cr.clip()
        for a, b, c in glass:
            mx = ((a[0] + b[0]) / 2, (a[1] + b[1]) / 2)
            my = ((b[0] + c[0]) / 2, (b[1] + c[1]) / 2)
            mz = ((c[0] + a[0]) / 2, (c[1] + a[1]) / 2)
            for p1, p2, p3 in ((a, mx, mz), (mx, b, my), (mz, my, c), (mx, my, mz)):
                tinted = mix(tint, P["07"], r() * 0.3)
                poly(cr, [p1, p2, p3])
                source(cr, rgba(shade(tinted, 0.8 + r() * 0.4)))
                cr.set_line_width(1)
                cr.fill_preserve()
                cr.stroke()
        cr.restore()
        poly(cr, lam)
        source(cr, rgba(P["07"], 0.4))
        cr.set_line_width(1.5 * s)
        cr.stroke()
    vignette(L, 0.45)
    grain(L, 0.05)


def band_order(n):
    """Ribbon draw order: outermost bands first, so inner bands cast shadows onto them."""
    return sorted(range(n), key=lambda i: (min(i, n - 1 - i), i))


def ribbon_band(cr, W, H, P, k, seed, band, bars):
    """One of the waving bands, without shadow. Colors mirror from the edges in
    (base0D, base04, base03, repeat), and the wave's middle is pinned to the screen center."""
    s, r = W / 1920, rng(seed)
    Lh = math.hypot(W, H) / 2 + 200 * s
    ph1, ph2 = r() * 6.28, r() * 6.28
    A, w = k["wave"] * s, k["width"] * s
    gap = w * 0.3

    def wave(u):
        return A * math.sin(u / (560 * s) + ph1) + 0.45 * A * math.sin(u / (1350 * s) + ph2)

    shift = wave(0)
    col = P[["0D", "04", "03"][min(band, bars - 1 - band) % 3]]
    o = (band - (bars - 1) / 2) * (w + gap)
    top, bot = [], []
    u = -Lh
    while u <= Lh:
        fan = 1 + 0.55 * abs(u) / Lh
        c = wave(u) - shift + o * fan
        hw = w / 2 * (0.85 + 0.3 * fan - 0.15)
        top.append((u, c - hw))
        bot.append((u, c + hw))
        u += 6 * s
    cr.save()
    cr.translate(W / 2, H / 2)
    cr.rotate(ANG)
    poly(cr, top + bot[::-1])
    cr.set_source(linear(-Lh, 0, Lh, 0, [(0, rgba(mix(col, P["00"], 0.45))), (0.35, rgba(col)),
                                         (0.5, rgba(mix(col, P["07"], 0.18))), (0.65, rgba(col)),
                                         (1, rgba(mix(col, P["00"], 0.45)))]))
    cr.fill()
    cr.move_to(*top[0])
    for p in top[1:]:
        cr.line_to(*p)
    source(cr, rgba(P["07"], 0.22))
    cr.set_line_width(1.6 * s)
    cr.stroke()
    cr.restore()


def woven_ribbons(L, W, H, P, k, seed):
    """Waving bands that stop short of a raised, shaded flake at the center."""
    s, cr = W / 1920, L.cr
    cx, cy, fw = W / 2, H / 2, k["size"] * s
    bars, depth = int(k["bars"]), k["depth"]
    center_glow_background(L, P)
    # Each band is drawn, the flake's cutout is erased from it, and only then is its shadow cast,
    # so shadows follow the cut ends instead of being sliced off by the gap.
    for band in band_order(bars):
        layer = Layer(W, H)
        ribbon_band(layer.cr, W, H, P, k, seed, band, bars)
        layer.cr.set_operator(cairo.OPERATOR_DEST_OUT)
        flake_cutout(layer.cr, cx, cy, fw, (0, 0, 0, 1), k["cutout"] * s)
        with_shadow(L, lambda c, layer=layer: (c.set_source_surface(layer.surface, 0, 0), c.paint()),
                    (0, 0, 0, 0.6 * depth), 34 * s * depth, 0, 12 * s * depth)
    lams = lambdas(cx, cy, fw)

    def flake_base(c):
        for lam in lams:
            poly(c, lam)
            source(c, rgba(P["00"]))
            c.fill()

    with_shadow(L, flake_base, (0, 0, 0, 0.75 * depth), 44 * s * depth, 0, 18 * s * depth)
    for i, lam in enumerate(lams):
        col = [P["0D"], P["04"]][i % 2]
        poly(cr, lam)
        cr.set_source(linear(cx - fw / 2, cy - fw / 2, cx + fw / 2, cy + fw / 2,
                             [(0, rgba(mix(col, P["07"], 0.3))), (0.5, rgba(col)), (1, rgba(mix(col, P["00"], 0.35)))]))
        cr.fill()
    cr.set_line_join(cairo.LINE_JOIN_ROUND)
    for col, width in ((rgba(P["00"], 0.55), 3 * s), (rgba(P["07"], 0.3), 1.2 * s)):
        for lam in lams:
            poly(cr, lam)
            source(cr, col)
            cr.set_line_width(width)
            cr.stroke()
    vignette(L, 0.4)
    grain(L, 0.06)


def sunburst(L, W, H, P, k, seed):
    """Twisting rays from the flake, with optional softening and bloom."""
    s, cr = W / 1920, L.cr
    cx, cy, R, R0 = W / 2, H / 2, math.hypot(W, H), 150 * s
    N, soft, bloom = int(k["rays"]) * 2, k["soft"], k["bloom"]
    fill_all(cr, rgba(P["00"]))
    rays, acc = Layer(W, H), Layer(W, H)

    def pt(a, rad):
        b = a + k["twist"] * rad / R * 2.4
        return cx + math.cos(b) * rad, cy + math.sin(b) * rad

    for i in range(N):
        if i % 2 and i % 6 != 3:
            continue
        is_acc = i % 6 in (0, 3)
        col = P["0D"] if i % 6 == 0 else P["04"] if i % 6 == 3 else mix(P["01"], P["02"], 0.5)
        a0, a1 = i / N * math.pi * 2, (i + 1) / N * math.pi * 2
        radii = [R0 * 0.4 + (R - R0 * 0.4) * m / 96 for m in range(97)]
        edge = [pt(a0, rad) for rad in radii] + [pt(a1, rad) for rad in reversed(radii)]
        poly(rays.cr, edge)
        source(rays.cr, rgba(col, 0.7 if is_acc else 1))
        rays.cr.fill()
        if is_acc:
            poly(acc.cr, edge)
            source(acc.cr, rgba(col))
            acc.cr.fill()
    cr.set_source_surface(surface_of(blur(rays.pixels(), 4 * s / BOARD_S + 30 * s * soft / 0.6)), 0, 0)
    cr.paint()
    cr.set_source_surface(rays.surface, 0, 0)
    cr.paint_with_alpha(1 - 0.75 * soft)
    if bloom > 0:
        cr.save()
        cr.set_operator(cairo.OPERATOR_SCREEN)
        cr.set_source_surface(surface_of(blur(acc.pixels(), 70 * s)), 0, 0)
        cr.paint_with_alpha(0.9 * bloom)
        fill_all(cr, radial(cx, cy, 0, cx, cy, W * 0.6, [(0, rgba(mix(P["0D"], P["07"], 0.2), 0.5 * bloom)),
                                                         (0.3, rgba(P["0D"], 0.14 * bloom)), (1, rgba(P["0D"], 0))]))
        cr.restore()
    fill_all(cr, radial(cx, cy, W * 0.2, cx, cy, R * 0.55, [(0, rgba(P["00"], 0)), (1, rgba(P["00"], 0.75))]))
    fill_all(cr, radial(cx, cy, 0, cx, cy, R0 * 2.2, [(0, rgba(P["00"], 0.92)), (0.45, rgba(P["00"], 0.75)),
                                                       (1, rgba(P["00"], 0))]))
    with_shadow(L, lambda c: draw_flake(c, cx, cy, 250 * s, [rgba(P["0D"]), rgba(P["04"])]),
                rgba(P["0D"], 0.8 * bloom), 50 * s)
    vignette(L, 0.4)
    grain(L, 0.06)


STYLES = {
    "layered-ridges": layered_ridges,
    "contours": contours,
    "windlines": windlines,
    "flow-engraving": flow_engraving,
    "prism-shards": prism_shards,
    "woven-ribbons": woven_ribbons,
    "sunburst": sunburst,
}

style, out, size, seed, params, *palette = sys.argv[1:]
W, H = map(int, size.split("x"))
P = {key: [float(int(h[i : i + 2], 16)) for i in (0, 2, 4)] for key, h in zip(KEYS, palette)}
L = Layer(W, H)
STYLES[style](L, W, H, P, json.loads(params), int(seed))
L.surface.write_to_png(out)
