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


def is_master(path: Path) -> bool:
    """Only NN-slug.png masters — skip already-resized *-iphone-*.png."""
    stem = path.stem
    return "-iphone-" not in stem


def main() -> None:
    masters = sorted(p for p in SRC.glob("[0-9][0-9]-*.png") if is_master(p))
    if not masters:
        print("No masters in", SRC)
        return
    for path in masters:
        im = Image.open(path).convert("RGB")
        base = path.stem
        for tag, size in SIZES.items():
            dest = OUT / f"{base}-{tag}.png"
            if im.size == size:
                im.save(dest, "PNG")
            else:
                fitted = im.resize(size, Image.Resampling.LANCZOS)
                fitted.save(dest, "PNG")
            print("wrote", dest.name, size)
    print("done")


if __name__ == "__main__":
    main()
