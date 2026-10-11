#!/usr/bin/env python3
"""Enrich existing lexicon.json without umsc: seeds, morph, corpus bigrams."""

from __future__ import annotations

import importlib.util
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "data" / "generated"

# Reuse helpers from build_lexicon.py
spec = importlib.util.spec_from_file_location("build_lexicon", ROOT / "tools" / "build_lexicon.py")
assert spec and spec.loader
bl = importlib.util.module_from_spec(spec)
sys.modules["build_lexicon"] = bl
spec.loader.exec_module(bl)


def main() -> None:
    src = OUT / "lexicon.json"
    if not src.exists():
        raise SystemExit(f"Missing {src}; run build_lexicon.py first")

    payload = json.loads(src.read_text(encoding="utf-8"))
    freqs = {w: int(f) for w, f in payload["words"]}
    corrections = dict(payload.get("corrections") or {})

    before = len(freqs)
    freqs = bl.expand_morphology(freqs)
    print(f"morph+seeds: {before} → {len(freqs)}")

    for wrong, right in {
        "yahshi": "yaxshi",
        "yahxi": "yaxshi",
        "yahximu": "yaxshimu",
        "yahximusiz": "yaxshimusiz",
        "raxmet": "rehmet",
        "rehmed": "rehmet",
        "teshekkur": "teshekkür",
        "bugun": "bügün",
        "uygurche": "uyghurche",
        "urumchi": "ürümchi",
        "ulumqi": "ürümchi",
        "kashgar": "qeshqer",
        "kashghar": "qeshqer",
        "hotan": "xoten",
        "khotan": "xoten",
        "kompyuter": "kompüter",
        "komputer": "kompüter",
        "yaxmux": "yaxshimusiz",
        "yaxmusiz": "yaxshimusiz",
        "salamualeykum": "essalamu'eleykum",
        "rahmet": "rehmet",
        "chushendim": "chüshendim",
        "bilmeyman": "bilmeymen",
    }.items():
        corrections.setdefault(wrong, right)

    filtered = sorted(
        ((w, f) for w, f in freqs.items() if f >= bl.MIN_FREQ and bl.is_clean_uly(w)),
        key=lambda x: (-x[1], x[0]),
    )[: bl.MAX_WORDS]
    words = [[w, f] for w, f in filtered]

    # Corpus unigram re-ranking is left to build_lexicon.py; repeating it here would
    # compound boosts on every run.
    bigrams = bl.build_bigrams({w for w, _ in words}, bl.load_corpus_stats(converter=None))
    print(f"bigrams: {len(bigrams)}")

    meta = dict(payload.get("meta") or {})
    meta.update(
        {
            "version": "1.4.0",
            "script": "ULY-2008",
            "wordCount": len(words),
            "correctionCount": len(corrections),
            "bigramCount": len(bigrams),
            "notes": (
                "Enriched offline: domain seeds, morph expansion, curated corpus bigrams; "
                "quality-filtered ULY tokens."
            ),
        }
    )
    sources = list(meta.get("sources") or [])
    corpus_src = "data/corpus/uly_phrases.txt (project MIT curated ULY phrases)"
    if corpus_src not in sources:
        sources.append(corpus_src)
    meta["sources"] = sources

    bl.write_outputs(words, corrections, bigrams, meta)
    print(f"Wrote {OUT / 'lexicon.json'} ({(OUT / 'lexicon.json').stat().st_size / 1e6:.2f} MB)")


if __name__ == "__main__":
    main()
