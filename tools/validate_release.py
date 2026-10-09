#!/usr/bin/env python3
"""Pre-release checks for ULY Künupka (run on any OS)."""

from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ERRORS: list[str] = []
WARNINGS: list[str] = []


def need(path: Path, label: str) -> None:
    if not path.exists():
        ERRORS.append(f"Missing {label}: {path.relative_to(ROOT)}")


def warn_if(condition: bool, msg: str) -> None:
    if condition:
        WARNINGS.append(msg)


def main() -> int:
    need(ROOT / "ios/project.yml", "XcodeGen spec")
    need(ROOT / "ios/UyghurLatin/Info.plist", "App Info.plist")
    need(ROOT / "ios/UyghurLatinKeyboard/Info.plist", "Keyboard Info.plist")
    need(ROOT / "ios/UyghurLatin/PrivacyInfo.xcprivacy", "App privacy manifest")
    need(ROOT / "ios/UyghurLatinKeyboard/PrivacyInfo.xcprivacy", "Keyboard privacy manifest")
    icon = ROOT / "ios/UyghurLatin/Assets.xcassets/AppIcon.appiconset/AppIcon-1024.png"
    need(icon, "App icon 1024")
    need(ROOT / "ios/UyghurLatinKeyboard/Resources/lexicon.json", "Keyboard lexicon")
    need(ROOT / "store/APP_STORE_LISTING.md", "Store listing")
    need(ROOT / "store/PRIVACY_POLICY.md", "Privacy draft")
    need(ROOT / "store/site/privacy.html", "Hostable privacy page")

    if icon.exists():
        try:
            from PIL import Image

            im = Image.open(icon)
            if im.size != (1024, 1024):
                ERRORS.append(f"App icon must be 1024×1024, got {im.size}")
        except ImportError:
            WARNINGS.append("Install pillow to verify icon dimensions")

    lex = ROOT / "ios/UyghurLatinKeyboard/Resources/lexicon.json"
    if lex.exists():
        data = json.loads(lex.read_text(encoding="utf-8"))
        wc = data.get("meta", {}).get("wordCount", 0)
        if wc < 50_000:
            WARNINGS.append(f"Lexicon wordCount low: {wc}")

    for p in ROOT.glob("store/**/*.html"):
        text = p.read_text(encoding="utf-8")
        if "CONTACT_EMAIL" in text or "replace-with-your-email" in text:
            WARNINGS.append(f"Replace contact placeholder in {p.relative_to(ROOT)}")

    shots = list((ROOT / "store/marketing/screenshots").glob("*.png"))
    if len(shots) < 3:
        WARNINGS.append("Few marketing screenshots; run tools/make_store_screenshots.py")

    print("=== ULY Künupka release validation ===\n")
    if ERRORS:
        print("ERRORS:")
        for e in ERRORS:
            print("  ✗", e)
    else:
        print("Required files: OK")
    if WARNINGS:
        print("\nWARNINGS (fix before App Store submit):")
        for w in WARNINGS:
            print("  !", w)
    else:
        print("Warnings: none")
    print("\nNext: cd ios && xcodegen generate && archive in Xcode")
    return 1 if ERRORS else 0


if __name__ == "__main__":
    sys.exit(main())
