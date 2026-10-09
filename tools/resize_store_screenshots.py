#!/usr/bin/env python3
"""Create additional App Store screenshot sizes from 6.7\" masters."""

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "store/marketing/screenshots"
OUT = SRC

SIZES = {
    "iphone-67": (1290, 2796),
    "iphone-65": (1284, 2778),
    "iphone-61": (1179, 2556),
}


def main() -> None:
    masters = sorted(SRC.glob("[0-9][0-9]-*.png"))
    if not masters:
        print("No masters in", SRC)
        return
    for path in masters:
        im = Image.open(path).convert("RGB")
        base = path.stem
        for tag, size in SIZES.items():
            if im.size == size:
                dest = OUT / f"{base}-{tag}.png"
                im.save(dest, "PNG")
                continue
            fitted = im.resize(size, Image.Resampling.LANCZOS)
            dest = OUT / f"{base}-{tag}.png"
            fitted.save(dest, "PNG")
            print("wrote", dest.name, size)
    print("done")


if __name__ == "__main__":
    main()
