#!/usr/bin/env python3
"""Build App Store marketing screenshots (1290×2796) with headline overlays."""

from __future__ import annotations

import json
import math
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageFilter

ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "source"
OUT = ROOT / "output" / "6.7-inch-1284x2778"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1284, 2778
ORANGE = (255, 120, 40)
WHITE = (255, 255, 255)
SUB_GRAY = (180, 185, 195)
BG_TOP = (8, 10, 18)
BG_BOTTOM = (22, 14, 36)

SLIDES = [
    {
        "file": "01-live.png",
        "headline": "Track the ISS live",
        "subhead": "Hybrid map · smooth orbit motion",
    },
    {
        "file": "02-orbit.png",
        "headline": "Orbit at a glance",
        "subhead": "Altitude, speed, day & night",
    },
    {
        "file": "03-cabin.png",
        "headline": "Inside the station",
        "subhead": "Live NASA cabin telemetry",
    },
    {
        "file": "04-passes.png",
        "headline": "Visible passes",
        "subhead": "Flyovers for your city or GPS",
    },
    {
        "file": "05-compass.png",
        "headline": "Know where to look",
        "subhead": "Compass, elevation & timing",
    },
    {
        "file": "06-reminders.png",
        "headline": "Never miss a pass",
        "subhead": "Reminders & Live Activity",
    },
    {
        "file": "07-history.png",
        "headline": "On your device",
        "subhead": "Search history & saved places",
    },
    {
        "file": "08-photos.png",
        "headline": "NASA gallery",
        "subhead": "Browse ISS images",
    },
]

# Map slide index → source filename (place matching PNGs in source/)
SOURCE_MAP = {
    "01-live.png": "live-globe.png",
    "02-orbit.png": "orbit-shadow.png",
    "03-cabin.png": "cabin-dark.png",
    "04-passes.png": "passes-list.png",
    "05-compass.png": "pass-compass.png",
    "06-reminders.png": "pass-alerts.png",
    "07-history.png": "history.png",
    "08-photos.png": "photos.png",
}


def load_font(size: int, bold: bool = False) -> ImageFont.FreeTypeFont | ImageFont.ImageFont:
    candidates = [
        "/System/Library/Fonts/SFNS.ttf",
        "/System/Library/Fonts/Supplemental/SF-Pro-Display-Bold.otf" if bold else "/System/Library/Fonts/Supplemental/SF-Pro-Display-Regular.otf",
        "/System/Library/Fonts/Helvetica.ttc",
        "/Library/Fonts/Arial Bold.ttf" if bold else "/Library/Fonts/Arial.ttf",
    ]
    for path in candidates:
        p = Path(path)
        if p.exists():
            try:
                return ImageFont.truetype(str(p), size=size, index=1 if bold and path.endswith(".ttc") else 0)
            except OSError:
                try:
                    return ImageFont.truetype(str(p), size=size)
                except OSError:
                    continue
    return ImageFont.load_default()


def make_background() -> Image.Image:
    img = Image.new("RGB", (W, H), BG_TOP)
    px = img.load()
    for y in range(H):
        t = y / (H - 1)
        r = int(BG_TOP[0] * (1 - t) + BG_BOTTOM[0] * t)
        g = int(BG_TOP[1] * (1 - t) + BG_BOTTOM[1] * t)
        b = int(BG_TOP[2] * (1 - t) + BG_BOTTOM[2] * t)
        for x in range(W):
            px[x, y] = (r, g, b)
    # soft orange glow behind phone
    glow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    gdraw = ImageDraw.Draw(glow)
    cx, cy = W // 2, H // 2 + 120
    for i in range(8, 0, -1):
        alpha = int(18 * i)
        rad = 420 + i * 55
        gdraw.ellipse((cx - rad, cy - rad, cx + rad, cy + rad), fill=(255, 100, 30, alpha))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img = img.convert("RGBA")
    img = Image.alpha_composite(img, glow)
    return img.convert("RGB")


def draw_text_block(draw: ImageDraw.ImageDraw, headline: str, subhead: str) -> None:
    font_h = load_font(72, bold=True)
    font_s = load_font(38, bold=False)
    y = 120
    # accent bar
    draw.rounded_rectangle((96, y - 8, 104, y + 88), radius=4, fill=ORANGE)
    draw.text((128, y), headline, font=font_h, fill=WHITE)
    bbox = draw.textbbox((128, y), headline, font=font_h)
    draw.text((128, bbox[3] + 20), subhead, font=font_s, fill=SUB_GRAY)


def place_screenshot(base: Image.Image, shot: Image.Image) -> Image.Image:
    """Scale screenshot into phone-style frame."""
    phone_w = 920
    margin_top = 340
    ratio = shot.height / shot.width
    phone_h = int(phone_w * ratio)
    max_h = H - margin_top - 100
    if phone_h > max_h:
        phone_h = max_h
        phone_w = int(phone_h / ratio)

    resized = shot.resize((phone_w, phone_h), Image.Resampling.LANCZOS)
    x = (W - phone_w) // 2
    y = margin_top + (max_h - phone_h) // 2

    frame_pad = 14
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(shadow)
    sx, sy = x - frame_pad, y - frame_pad
    sw, sh = phone_w + frame_pad * 2, phone_h + frame_pad * 2
    sdraw.rounded_rectangle((sx + 8, sy + 12, sx + sw + 8, sy + sh + 12), radius=48, fill=(0, 0, 0, 90))
    shadow = shadow.filter(ImageFilter.GaussianBlur(16))
    base = base.convert("RGBA")
    base = Image.alpha_composite(base, shadow)

    layer = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(layer)
    ldraw.rounded_rectangle(
        (x - frame_pad, y - frame_pad, x + phone_w + frame_pad, y + phone_h + frame_pad),
        radius=44,
        fill=(40, 42, 50, 255),
    )
    base = Image.alpha_composite(base, layer)

    base.paste(resized, (x, y))
    return base.convert("RGB")


def build_slide(meta: dict, source_path: Path) -> None:
    if not source_path.exists():
        print(f"SKIP (missing source): {source_path.name}")
        return
    shot = Image.open(source_path).convert("RGB")
    img = make_background()
    draw = ImageDraw.Draw(img)
    draw_text_block(draw, meta["headline"], meta["subhead"])
    img = place_screenshot(img, shot)
    out_path = OUT / meta["file"]
    img.save(out_path, "PNG", optimize=True)
    print(f"Wrote {out_path}")


def main() -> None:
    manifest = []
    for meta in SLIDES:
        src_name = SOURCE_MAP.get(meta["file"], meta["file"])
        build_slide(meta, SOURCE / src_name)
        manifest.append({**meta, "source": src_name})
    (ROOT / "output" / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"\nDone. Upload PNGs from:\n  {OUT}\n")


if __name__ == "__main__":
    main()
