#!/usr/bin/env python3
"""Renders the Slipstream app icon (default, dark and tinted variants) with Pillow.

Usage: python3 tools/make_icon.py
"""
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

SIZE = 1024
SCALE = 4
S = SIZE * SCALE
OUT = Path(__file__).resolve().parent.parent / "App" / "Assets.xcassets" / "AppIcon.appiconset"


def lerp(a, b, t):
    return a + (b - a) * t


def mix(c1, c2, t):
    return tuple(int(lerp(a, b, t)) for a, b in zip(c1, c2))


def bezier(p0, p1, p2, p3, t):
    u = 1 - t
    return (
        u**3 * p0[0] + 3 * u * u * t * p1[0] + 3 * u * t * t * p2[0] + t**3 * p3[0],
        u**3 * p0[1] + 3 * u * u * t * p1[1] + 3 * u * t * t * p2[1] + t**3 * p3[1],
    )


def background(dark=True):
    img = Image.new("RGB", (S, S))
    px = img.load()
    top = (36, 37, 48) if dark else (36, 37, 48)
    bottom = (8, 9, 13)
    for y in range(0, S, 4):
        for x in range(0, S, 4):
            t = min(1, max(0, (x * 0.35 + y * 0.65) / S))
            c = mix(top, bottom, t)
            for dy in range(4):
                for dx in range(4):
                    px[x + dx, y + dy] = c
    # Red glow in the top-right corner.
    glow = Image.new("RGB", (S, S), (0, 0, 0))
    g = ImageDraw.Draw(glow)
    g.ellipse([S * 0.45, -S * 0.35, S * 1.35, S * 0.55], fill=(150, 10, 0))
    glow = glow.filter(ImageFilter.GaussianBlur(S * 0.12))
    return Image.blend(img, Image.composite(glow, img, glow.convert("L")), 0.55)


def stroke(draw, points, width, color_fn, alpha_fn=None):
    n = len(points)
    for i, (x, y) in enumerate(points):
        t = i / (n - 1)
        r = width(t) / 2
        c = color_fn(t)
        a = 255 if alpha_fn is None else int(255 * alpha_fn(t))
        draw.ellipse([x - r, y - r, x + r, y + r], fill=c + (a,))


def render(variant):
    base = background()
    if variant == "tinted":
        base = Image.new("RGB", (S, S), (0, 0, 0))
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # The racing line: a sweeping S through an apex.
    p0 = (S * 0.14, S * 0.84)
    p1 = (S * 0.62, S * 0.86)
    p2 = (S * 0.30, S * 0.20)
    p3 = (S * 0.88, S * 0.16)
    samples = [bezier(p0, p1, p2, p3, i / 1400) for i in range(1401)]

    def offset(points, dist):
        out = []
        for i in range(len(points)):
            a = points[max(0, i - 1)]
            b = points[min(len(points) - 1, i + 1)]
            dx, dy = b[0] - a[0], b[1] - a[1]
            length = math.hypot(dx, dy) or 1
            nx, ny = -dy / length, dx / length
            out.append((points[i][0] + nx * dist, points[i][1] + ny * dist))
        return out

    white = (255, 255, 255)
    # Slipstream air lines trailing beside the car's path.
    for dist, w, alpha in [(-S * 0.085, S * 0.018, 0.55), (-S * 0.15, S * 0.012, 0.32), (S * 0.085, S * 0.014, 0.4)]:
        pts = offset(samples, dist)
        start = 0.08 if dist < 0 else 0.2
        pts = pts[int(len(pts) * start): int(len(pts) * 0.86)]
        stroke(d, pts, lambda t, w=w: w * (0.35 + 0.65 * math.sin(math.pi * t)), lambda t: white,
               lambda t, a=alpha: a * math.sin(math.pi * t))

    red_a = (255, 64, 32) if variant != "tinted" else (255, 255, 255)
    red_b = (225, 6, 0) if variant != "tinted" else (220, 220, 220)
    stroke(d, samples, lambda t: S * (0.07 + 0.035 * math.sin(math.pi * t)), lambda t: mix(red_b, red_a, t))

    # Apex marker.
    ax, ay = bezier(p0, p1, p2, p3, 0.5)
    r = S * 0.03
    d.ellipse([ax - r, ay - r, ax + r, ay + r], fill=(255, 255, 255, 255))

    shadow = layer.split()[3].filter(ImageFilter.GaussianBlur(S * 0.02))
    shadow_img = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    shadow_img.putalpha(shadow.point(lambda v: int(v * 0.5)))
    out = base.convert("RGBA")
    out.alpha_composite(shadow_img, (0, int(S * 0.012)))
    out.alpha_composite(layer)
    return out.convert("RGB").resize((SIZE, SIZE), Image.LANCZOS)


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    render("default").save(OUT / "AppIcon.png")
    render("default").save(OUT / "AppIcon-Dark.png")
    tinted = render("tinted").convert("L").convert("RGB")
    tinted.save(OUT / "AppIcon-Tinted.png")
    print("icons written to", OUT)


if __name__ == "__main__":
    main()
