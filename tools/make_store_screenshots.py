#!/usr/bin/env python3
"""Compose App Store–sized marketing screenshots from capture + caption."""

from __future__ import annotations

import json
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "store" / "marketing" / "screenshots"
CAPTIONS = ROOT / "store" / "marketing" / "screenshot_captions.json"

# iPhone 6.7" portrait
TARGET = (1290, 2796)


def font(size: int, bold: bool = False) -> ImageFont.ImageFont:
    candidates = [
        "/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
        "/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf"
        if bold
        else "/usr/share/fonts/truetype/liberation/LiberationSans-Regular.ttf",
    ]
    for p in candidates:
        if Path(p).exists():
            return ImageFont.truetype(p, size)
    return ImageFont.load_default()


def fit_cover(img: Image.Image, size: tuple[int, int]) -> Image.Image:
    tw, th = size
    scale = max(tw / img.width, th / img.height)
    nw, nh = int(img.width * scale), int(img.height * scale)
    resized = img.resize((nw, nh), Image.Resampling.LANCZOS)
    left = (nw - tw) // 2
    top = (nh - th) // 2
    return resized.crop((left, top, left + tw, top + th))


def compose(bg_color: tuple[int, int, int], capture: Path, title: str, subtitle: str, out: Path) -> None:
    canvas = Image.new("RGB", TARGET, bg_color)
    draw = ImageDraw.Draw(canvas)

    # header text
    title_font = font(64, bold=True)
    sub_font = font(36)
    draw.text((80, 120), title, fill=(28, 28, 30) if sum(bg_color) > 400 else (245, 245, 247), font=title_font)
    draw.text(
        (80, 210),
        subtitle,
        fill=(90, 90, 95) if sum(bg_color) > 400 else (180, 180, 185),
        font=sub_font,
    )

    # phone content frame
    if capture.exists():
        shot = Image.open(capture).convert("RGB")
        # Prefer cropping to the phone column if wide desktop capture
        if shot.width > shot.height:
            # center crop to phone-ish aspect before fit
            aspect = 9 / 19.5
            nh = shot.height
            nw = int(nh * aspect)
            if nw < shot.width:
                left = (shot.width - nw) // 2
                shot = shot.crop((left, 0, left + nw, nh))
        frame = fit_cover(shot, (1090, 2220))
        # rounded device frame
        device = Image.new("RGBA", (1130, 2260), (0, 0, 0, 0))
        d = ImageDraw.Draw(device)
        d.rounded_rectangle([0, 0, 1129, 2259], radius=70, fill=(20, 20, 22, 255))
        device.paste(frame, (20, 20))
        x = (TARGET[0] - device.width) // 2
        y = 320
        canvas.paste(device.convert("RGB"), (x, y), device.split()[-1])

    # footer brand
    brand = font(28, bold=True)
    draw.text((80, TARGET[1] - 120), "Uyghur ULY keyboard", fill=(120, 120, 125), font=brand)

    out.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(out, "PNG")
    print("wrote", out)


def main() -> None:
    shots_dir = Path("/opt/cursor/artifacts/screenshots")
    # Prefer latest theme captures; fall back to any available
    mapping = [
        (
            "01-setup.png",
            (242, 242, 247),
            shots_dir / "uly-theme-system.webp",
            "Enable in a minute",
            "Settings → Keyboard → Add Uyghur ULY keyboard",
        ),
        (
            "02-keyboard-light.png",
            (242, 242, 247),
            shots_dir / "uly-theme-light.webp",
            "Feels like the system keyboard",
            "Light appearance · offline ULY Latin",
        ),
        (
            "03-suggestions.png",
            (242, 242, 247),
            shots_dir / "uly-theme-dark-suggestions.webp",
            "Suggestions as you type",
            "uygh → uyghur, uyghurche, …",
        ),
        (
            "04-spellcheck.png",
            (242, 242, 247),
            shots_dir / "uly-corrected-bugun.webp",
            "Spell check on device",
            "bugun → bügün",
        ),
        (
            "05-keyboard-dark.png",
            (0, 0, 0),
            shots_dir / "uly-theme-dark.webp",
            "Follows system Dark Mode",
            "Or lock Light / Dark from the keyboard",
        ),
    ]

    captions = []
    for name, color, src, title, subtitle in mapping:
        # dark canvas text handled in compose; for dark shot use dark bg
        if "dark" in name and "suggestions" not in name:
            color = (0, 0, 0)
        dest = OUT / name
        # fallback chain
        if not src.exists():
            alts = sorted(shots_dir.glob("uly-*.webp"))
            src = alts[0] if alts else src
        compose(color, src, title, subtitle, dest)
        captions.append({"file": name, "title": title, "subtitle": subtitle, "source": str(src)})

    CAPTIONS.write_text(json.dumps(captions, indent=2), encoding="utf-8")
    print("captions →", CAPTIONS)


if __name__ == "__main__":
    main()
