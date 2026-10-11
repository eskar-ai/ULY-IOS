#!/usr/bin/env python3
"""Patch existing lexicon.json with morphology seeds + informal corrections (no umsc).

Prefer `tools/enrich_lexicon.py` for corpus bigrams + expanded morph (v1.3+).
This script remains as a lighter fallback.
"""

from __future__ import annotations

import json
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "generated"
IOS_RES = ROOT / "ios" / "UyghurLatinKeyboard" / "Resources"
IOS_HOST_META = ROOT / "ios" / "UyghurLatin" / "Resources" / "meta.json"
WEB_PUBLIC = ROOT / "web" / "public" / "data"
ANDROID_ASSETS = ROOT / "android" / "app" / "src" / "main" / "assets"
HARMONY_RAWFILE = ROOT / "harmonyos" / "ime" / "src" / "main" / "resources" / "rawfile"

MAX_WORDS = 120_000
MORPH_STEM_CAP = 2_500

MORPH_SUFFIXES = [
    "mu",
    "musiz",
    "misiz",
    "musen",
    "musiler",
    "siz",
    "sen",
    "chu",
    "ghu",
    "ken",
    "ding",
    "dingiz",
    "dingizmu",
    "digizmu",
    "digiz",
    "gizmu",
    "izmu",
    "turding",
    "turdingiz",
    "turdingizmu",
    "turdigizmu",
    "turdigiz",
    "turdi",
    "turdu",
    "turdum",
]

MORPH_SEED_WORDS = {
    "yaxshiturding": 12_000,
    "yaxshiturdigizmu": 11_000,
    "yaxshiturdingizmu": 10_500,
    "yaxshiturdingiz": 10_000,
    "yaxshiturdi": 9_000,
    "yaxshimusiz": 20_000,
    "yaxshimu": 18_000,
    "yaxshimusiler": 8_000,
}

EXTRA_SEEDS_FILE = ROOT / "data" / "extra_uly_seeds.txt"

EXTRA_CORRECTIONS = {
    "yahshi": "yaxshi",
    "yahxi": "yaxshi",
    "yahximu": "yaxshimu",
    "yahximusiz": "yaxshimusiz",
    "yahshimu": "yaxshimu",
    "yahshimusiz": "yaxshimusiz",
    "yahxilik": "yaxshiliq",
    "raxmet": "rehmet",
    "rehmed": "rehmet",
    "teshekkur": "teshekkür",
    "salamu'eleykum": "essalamu'eleykum",
    "essalamu eleykum": "essalamu'eleykum",
    "bugun": "bügün",
    "uygurche": "uyghurche",
}

SKIP_STEMS = {
    "we",
    "bu",
    "u",
    "shu",
    "mu",
    "la",
    "hem",
    "ning",
    "ni",
    "gha",
    "qa",
    "da",
    "de",
    "din",
    "tin",
    "men",
    "sen",
    "siz",
    "biz",
    "ular",
}


def load_extra_seeds() -> dict[str, int]:
    out: dict[str, int] = {}
    if not EXTRA_SEEDS_FILE.exists():
        return out
    for line in EXTRA_SEEDS_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 2:
            continue
        word, freq_s = parts[0].lower(), parts[1]
        if not freq_s.isdigit():
            continue
        out[word] = max(out.get(word, 0), int(freq_s))
    return out


def main() -> None:
    src = OUT / "lexicon.json"
    if not src.exists():
        raise SystemExit(f"Missing {src}")

    payload = json.loads(src.read_text(encoding="utf-8"))
    freqs = {w: int(f) for w, f in payload["words"]}
    corrections = dict(payload.get("corrections") or {})
    bigrams = payload.get("bigrams") or []

    for w, f in MORPH_SEED_WORDS.items():
        freqs[w] = max(freqs.get(w, 0), f)
    extra = load_extra_seeds()
    for w, f in extra.items():
        freqs[w] = max(freqs.get(w, 0), f)
    print(f"  extra seeds: {len(extra)}")

    stems = [w for w, _ in sorted(freqs.items(), key=lambda x: -x[1])[:MORPH_STEM_CAP]]
    added = 0
    for stem in stems:
        if stem in SKIP_STEMS or len(stem) < 3 or len(stem) > 14:
            continue
        base = freqs.get(stem, 1)
        if base < 80:
            continue
        for i, suf in enumerate(MORPH_SUFFIXES):
            form = stem + suf
            freq = max(2, base // (8 + i * 2))
            if form not in freqs:
                added += 1
            freqs[form] = max(freqs.get(form, 0), freq)

    for wrong, right in EXTRA_CORRECTIONS.items():
        corrections.setdefault(wrong, right)

    filtered = sorted(freqs.items(), key=lambda x: (-x[1], x[0]))[:MAX_WORDS]
    words = [[w, f] for w, f in filtered]

    meta = dict(payload.get("meta") or {})
    meta["version"] = "1.2.0"
    meta["wordCount"] = len(words)
    meta["correctionCount"] = len(corrections)
    meta["bigramCount"] = len(bigrams)
    meta["notes"] = (
        "Arabic lemmas converted with umsc UAS→ULS; é→ë; "
        "productive clitic expansion for top stems."
    )

    out_payload = {
        "meta": meta,
        "words": words,
        "corrections": corrections,
        "bigrams": bigrams,
    }

    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "lexicon.json").write_text(
        json.dumps(out_payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    (OUT / "words.json").write_text(
        json.dumps(words, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    (OUT / "corrections.json").write_text(
        json.dumps(corrections, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    (OUT / "bigrams.json").write_text(
        json.dumps(bigrams, ensure_ascii=False, separators=(",", ":")), encoding="utf-8"
    )
    (OUT / "meta.json").write_text(json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8")

    for dest in (WEB_PUBLIC, ANDROID_ASSETS, HARMONY_RAWFILE):
        if dest in (ANDROID_ASSETS, HARMONY_RAWFILE):
            platform = ROOT / ("android" if dest == ANDROID_ASSETS else "harmonyos")
            if not platform.exists():
                continue
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy2(OUT / "lexicon.json", dest / "lexicon.json")
        if dest == WEB_PUBLIC:
            shutil.copy2(OUT / "meta.json", dest / "meta.json")

    # iOS ships only lexicon.bin.
    IOS_RES.mkdir(parents=True, exist_ok=True)
    shutil.copy2(OUT / "meta.json", IOS_RES / "meta.json")
    if IOS_HOST_META.parent.exists():
        shutil.copy2(OUT / "meta.json", IOS_HOST_META)

    from compile_lexicon_bin import compile_lexicon

    (IOS_RES / "lexicon.bin").write_bytes(compile_lexicon(out_payload))

    print(f"Patched lexicon: {len(words)} words (+{added} morph forms), {len(corrections)} corrections")
    for w in ("yaxshiturding", "yaxshiturdigizmu", "yaxshimu", "yaxshimusiz"):
        print(f"  {w}: {w in freqs}")
    print(f"  yahximu → {corrections.get('yahximu')}")


if __name__ == "__main__":
    main()
