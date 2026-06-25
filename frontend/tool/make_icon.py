"""Generate the Time app icon: the 24h donut (category colours) with clock
hands in the hollow centre. Produces a full-bleed icon and a transparent
foreground for Android adaptive icons. Run: python tool/make_icon.py"""
import math
import os

import cairosvg

OUT = os.path.join(os.path.dirname(__file__), "..", "assets", "icon")
os.makedirs(OUT, exist_ok=True)

BG = "#F7F5EF"
INK = "#2E2B25"
# A pleasing subset of the category palette, ordered around the ring.
SEGMENTS = [
    ("#A8A29A", 95),   # sleep
    ("#6FB1E0", 35),   # self maintenance
    ("#4F7CAC", 70),   # work
    ("#45B69C", 30),   # leisure
    ("#E3866B", 45),   # relationships
    ("#7FA650", 40),   # growth
    ("#8E6BBF", 45),   # personal projects
]


def arc_path(cx, cy, r, a0, a1):
    x0 = cx + r * math.cos(math.radians(a0))
    y0 = cy + r * math.sin(math.radians(a0))
    x1 = cx + r * math.cos(math.radians(a1))
    y1 = cy + r * math.sin(math.radians(a1))
    large = 1 if (a1 - a0) % 360 > 180 else 0
    return f"M {x0:.2f} {y0:.2f} A {r} {r} 0 {large} 1 {x1:.2f} {y1:.2f}"


def ring(cx, cy, r, width, gap_deg=3.0):
    parts = []
    total = sum(s[1] for s in SEGMENTS)
    angle = -90.0  # start at top
    for color, weight in SEGMENTS:
        sweep = 360.0 * weight / total
        a0 = angle + gap_deg / 2
        a1 = angle + sweep - gap_deg / 2
        parts.append(
            f'<path d="{arc_path(cx, cy, r, a0, a1)}" stroke="{color}" '
            f'stroke-width="{width}" fill="none" stroke-linecap="round"/>'
        )
        angle += sweep
    return "\n".join(parts)


def hands(cx, cy):
    # minute hand to 12, hour hand to ~2 o'clock.
    def hand(angle_deg, length, w):
        x = cx + length * math.cos(math.radians(angle_deg))
        y = cy + length * math.sin(math.radians(angle_deg))
        return (f'<line x1="{cx}" y1="{cy}" x2="{x:.1f}" y2="{y:.1f}" '
                f'stroke="{INK}" stroke-width="{w}" stroke-linecap="round"/>')
    return (
        hand(-90, 150, 34)   # minute
        + hand(35, 110, 34)  # hour
        + f'<circle cx="{cx}" cy="{cy}" r="26" fill="{INK}"/>'
    )


def svg(size, with_bg, scale=1.0):
    cx = cy = size / 2
    r = size * 0.34 * scale
    width = size * 0.12 * scale
    bg = f'<rect width="{size}" height="{size}" rx="{size*0.22}" fill="{BG}"/>' if with_bg else ""
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" width="{size}" height="{size}" '
        f'viewBox="0 0 {size} {size}">{bg}{ring(cx, cy, r, width)}{hands(cx, cy)}</svg>'
    )


def write(name, markup, size):
    path = os.path.join(OUT, name)
    cairosvg.svg2png(bytestring=markup.encode(), write_to=path,
                     output_width=size, output_height=size)
    print("wrote", os.path.relpath(path))


# Full-bleed icon (web favicon / iOS / fallback) and adaptive foreground.
write("icon_full.png", svg(1024, with_bg=True), 1024)
write("icon_foreground.png", svg(1024, with_bg=False, scale=0.78), 1024)
# A standalone logo (transparent) for in-app use if wanted.
write("logo.png", svg(512, with_bg=False), 512)
