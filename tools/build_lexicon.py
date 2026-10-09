#!/usr/bin/env python3
"""Build offline ULY lexicon, corrections, and bigrams from open MIT sources."""

from __future__ import annotations

import json
import re
import shutil
import sys
from collections import Counter, defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
OUT = ROOT / "data" / "generated"
WEB_PUBLIC = ROOT / "web" / "public" / "data"
IOS_RES = ROOT / "ios" / "UyghurLatinKeyboard" / "Resources"

# Prefer local clones under /tmp from agent setup; fall back to data/raw.
SOURCE_CANDIDATES = [
    Path("/tmp/UyghurEditPP"),
    RAW / "UyghurEditPP",
]
IMLA_LUGHET_CANDIDATES = [
    Path("/tmp/imlalughet"),
    RAW / "imlalughet",
]

MAX_WORDS = 120_000
MIN_FREQ = 2
MAX_BIGRAMS = 40_000

# Seed ULY sentences for next-word prediction (public/common phrases).
SEED_CORPUS = """
salam yaxshimusiz
men bügün mektepke bardim
u uyghurche sözleydu
bu kitab nahayiti yaxshi
biz öyge qaytimiz
siz qeyerge barisiz
ular tamaq yéwatidu
men su ichimen
bu kün hawa yaxshi
uyghur tili chirayliq
dölet we millet
ata ana we balilar
men uni kördum
u manga kitab berdi
biz bilen keling
shu yerde turup
bu ish nahayiti muhim
men oquymen
u yazidu we oquydu
yaxshi künler bolsun
rehmen qiling
kechürüng
qandaq ehwallar
men uyghur
u qeshqerde tughulghan
ürümchi chong sheher
bügün hawa issiq
ete yaghmur yaghishi mumkin
men tamaq yédim
u chay ichidu
biz kinogha barimiz
bu mesile muhim
men bilimen
u bilmeydu
siz nime qiliwatisiz
men xizmet qiliwatimen
bu söz toghrimu
imla tekshürüsh muhim
latin yeziqi qulay
uyghur latin yeziqi
hemme adem erkin
izzet hörmet we hoquq
bir birige qërindashliq
""".strip()

WORD_RE = re.compile(r"[A-Za-zÖÜËöüëÉé']+")


def ensure_cloned(repo: str, dest: Path) -> None:
    if dest.exists():
        return
    import subprocess

    dest.parent.mkdir(parents=True, exist_ok=True)
    print(f"Cloning {repo} → {dest}")
    subprocess.check_call(["git", "clone", "--depth", "1", repo, str(dest)])


def find_source() -> Path:
    for p in SOURCE_CANDIDATES:
        if (p / "uyghur_imla.txt").exists():
            return p
    ensure_cloned("https://github.com/gheyret/UyghurEditPP.git", RAW / "UyghurEditPP")
    for p in SOURCE_CANDIDATES:
        if (p / "uyghur_imla.txt").exists():
            return p
    raise SystemExit(
        "Cannot find UyghurEditPP/uyghur_imla.txt. "
        "Clone https://github.com/gheyret/UyghurEditPP into data/raw/"
    )


def normalize_uly(text: str) -> str:
    """Normalize to 2008 ULY: é→ë, keep ö/ü, lowercase for lookup keys."""
    return (
        text.replace("É", "Ë")
        .replace("é", "ë")
        .replace("ʼ", "'")
        .replace("'", "'")
    )


def to_uly(converter, arabic: str) -> str:
    try:
        latin = converter(arabic.strip())
    except Exception:
        return ""
    return normalize_uly(latin)


def load_imla(path: Path, converter) -> dict[str, int]:
    freqs: dict[str, int] = {}
    with path.open(encoding="utf-8-sig") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            word_ar = parts[0]
            freq = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 1
            uly = to_uly(converter, word_ar)
            if not uly or len(uly) < 1:
                continue
            # Skip pure punctuation / digits leftovers
            if not WORD_RE.fullmatch(uly):
                continue
            key = uly.lower()
            freqs[key] = freqs.get(key, 0) + freq
    return freqs


def load_corrections(path: Path, converter) -> dict[str, str]:
    mapping: dict[str, str] = {}
    with path.open(encoding="utf-8-sig") as f:
        for line in f:
            line = line.strip()
            if not line or "=" not in line:
                continue
            wrong, right = line.split("=", 1)
            w = to_uly(converter, wrong).lower()
            r = to_uly(converter, right).lower()
            if w and r and w != r:
                mapping[w] = r
    # Common Latin typos for ULY diacritics
    mapping.setdefault("bugun", "bügün")
    mapping.setdefault("uygur", "uyghur")
    mapping.setdefault("yahshi", "yaxshi")
    mapping.setdefault("dolet", "dölet")
    mapping.setdefault("kelimen", "këlimen")
    return mapping


def extract_lemma_freqs_from_imlalughet(converter) -> dict[str, int]:
    freqs: Counter[str] = Counter()
    root = None
    for p in IMLA_LUGHET_CANDIDATES:
        if p.exists():
            root = p
            break
    if root is None:
        try:
            ensure_cloned("https://github.com/gheyret/imlalughet.git", RAW / "imlalughet")
            root = RAW / "imlalughet"
        except Exception as exc:
            print(f"  skip imlalughet: {exc}")
            return {}
    for txt in sorted(root.glob("imla_ocr_*.txt")):
        text = txt.read_text(encoding="utf-8-sig", errors="ignore")
        for m in re.finditer(r"^([\u0600-\u06FFʼ']+)", text, re.M):
            uly = to_uly(converter, m.group(1)).lower()
            if uly and WORD_RE.fullmatch(uly):
                freqs[uly] += 1
    return dict(freqs)


def build_bigrams(word_freqs: dict[str, int]) -> list[list]:
    bigram_counts: Counter[tuple[str, str]] = Counter()

    def add_text(text: str, weight: int = 5) -> None:
        tokens = [normalize_uly(t).lower() for t in WORD_RE.findall(text)]
        for a, b in zip(tokens, tokens[1:]):
            bigram_counts[(a, b)] += weight

    add_text(SEED_CORPUS, weight=20)

    # Pair frequent content words with common function words.
    function = [
        "we",
        "bilen",
        "üchün",
        "dep",
        "mu",
        "la",
        "hem",
        "emma",
        "lekin",
        "shu",
        "bu",
        "u",
        "men",
        "sen",
        "siz",
        "biz",
        "ular",
        "ning",
        "ni",
        "gha",
        "qa",
        "da",
        "de",
        "din",
        "tin",
    ]
    top = [w for w, _ in sorted(word_freqs.items(), key=lambda x: -x[1])[:3000]]
    for fw in function:
        if fw not in word_freqs:
            continue
        for w in top[:400]:
            if w == fw:
                continue
            # Mild synthetic prior so next-word is never empty after common words.
            bigram_counts[(fw, w)] += max(1, word_freqs[w] // 5000)
            bigram_counts[(w, fw)] += max(1, word_freqs[w] // 8000)

    ranked = bigram_counts.most_common(MAX_BIGRAMS)
    return [[a, b, c] for (a, b), c in ranked]


def write_outputs(
    words: list[list],
    corrections: dict[str, str],
    bigrams: list[list],
    meta: dict,
) -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    payload = {
        "meta": meta,
        "words": words,
        "corrections": corrections,
        "bigrams": bigrams,
    }
    # Full bundle for tooling
    (OUT / "lexicon.json").write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    # Compact split files for clients that prefer smaller chunks
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
    (OUT / "meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    for dest in (WEB_PUBLIC, IOS_RES):
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy2(OUT / "lexicon.json", dest / "lexicon.json")
        shutil.copy2(OUT / "meta.json", dest / "meta.json")


def main() -> None:
    try:
        from umsc import UgMultiScriptConverter
    except ImportError:
        print("Install umsc: pip install umsc", file=sys.stderr)
        raise SystemExit(1)

    converter = UgMultiScriptConverter("UAS", "ULS")
    src = find_source()
    print(f"Using source: {src}")

    # Cache raw copies for reproducibility notes
    RAW.mkdir(parents=True, exist_ok=True)
    for name in ("uyghur_imla.txt", "imla_xatatoghra.txt"):
        src_file = src / name
        if src_file.exists():
            dest = RAW / name
            if not dest.exists():
                shutil.copy2(src_file, dest)

    print("Converting imla dictionary to ULY…")
    freqs = load_imla(src / "uyghur_imla.txt", converter)
    print(f"  unique ULY words from imla: {len(freqs)}")

    lemma = extract_lemma_freqs_from_imlalughet(converter)
    for w, c in lemma.items():
        freqs[w] = freqs.get(w, 0) + c * 3
    print(f"  after imlalughet lemmas: {len(freqs)}")

    # Ensure core demo words exist
    for w, f in (
        ("uyghur", 50_000),
        ("bügün", 40_000),
        ("yaxshi", 35_000),
        ("salam", 30_000),
        ("men", 60_000),
        ("bu", 55_000),
        ("dölet", 25_000),
        ("til", 20_000),
        ("latin", 15_000),
        ("yeziq", 15_000),
        ("imla", 12_000),
    ):
        freqs[w] = max(freqs.get(w, 0), f)

    filtered = [(w, f) for w, f in freqs.items() if f >= MIN_FREQ]
    filtered.sort(key=lambda x: (-x[1], x[0]))
    filtered = filtered[:MAX_WORDS]
    words = [[w, f] for w, f in filtered]
    word_set = {w for w, _ in words}

    print("Converting corrections…")
    corrections_raw = load_corrections(src / "imla_xatatoghra.txt", converter)
    corrections = {
        w: r for w, r in corrections_raw.items() if r in word_set or True
    }
    # Keep corrections even if target rare — spell UX still useful
    print(f"  corrections: {len(corrections)}")

    word_freqs = {w: f for w, f in words}
    bigrams = build_bigrams(word_freqs)
    print(f"  bigrams: {len(bigrams)}")

    meta = {
        "version": "1.0.0",
        "script": "ULY-2008",
        "wordCount": len(words),
        "correctionCount": len(corrections),
        "bigramCount": len(bigrams),
        "sources": [
            "https://github.com/gheyret/UyghurEditPP (MIT)",
            "https://github.com/gheyret/imlalughet (MIT)",
            "https://github.com/neouyghur/Uyghur-Multi-Script-Converter / umsc (Apache-2.0)",
        ],
        "notes": "Arabic lemmas converted with umsc UAS→ULS; é normalized to ë (2008 ULY).",
    }
    write_outputs(words, corrections, bigrams, meta)
    size = (OUT / "lexicon.json").stat().st_size
    print(f"Wrote {OUT / 'lexicon.json'} ({size / 1e6:.2f} MB)")
    print("Done.")


if __name__ == "__main__":
    main()
