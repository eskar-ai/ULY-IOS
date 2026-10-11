#!/usr/bin/env python3
"""Build offline ULY lexicon, corrections, and bigrams from open MIT sources."""

from __future__ import annotations

import json
import re
import shutil
import sys
from collections import Counter
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
RAW = ROOT / "data" / "raw"
CORPUS_DIR = ROOT / "data" / "corpus"
OUT = ROOT / "data" / "generated"
WEB_PUBLIC = ROOT / "web" / "public" / "data"
IOS_RES = ROOT / "ios" / "UyghurLatinKeyboard" / "Resources"
IOS_HOST = ROOT / "ios" / "UyghurLatin" / "Resources"
ANDROID_ASSETS = ROOT / "android" / "app" / "src" / "main" / "assets"
HARMONY_RAWFILE = ROOT / "harmonyos" / "ime" / "src" / "main" / "resources" / "rawfile"

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
MORPH_STEM_CAP = 3_500
# OCR lemmas need repeats or presence in imla before boosting the lexicon.
OCR_MIN_HITS = 2
MAX_WORD_LEN = 32
MIN_WORD_LEN = 2
SINGLE_LETTER_WORDS = {"u"}

# Real-corpus statistics (data/corpus = curated chat phrases, data/raw/corpus = e.g. ugwiki).
# imla frequencies are nearly flat for common words, so corpus hits re-rank them.
RAW_BOOST_PER_HIT = 3
RAW_BOOST_CAP = 15_000
# New words from raw text need repeated evidence and stay below established words, so a
# misspelling one editor repeats never outranks the standard form.
RAW_MIN_NEW_HITS = 8
RAW_NEW_BASE = 1_000
RAW_NEW_PER_HIT = 15
RAW_NEW_CAP = 8_000
CURATED_BOOST_PER_HIT = 600
CURATED_BOOST_CAP = 15_000
# One curated chat line counts like this many raw-corpus hits.
CURATED_BIGRAM_WEIGHT = 40
RAW_BIGRAM_MIN_HITS = 3
RAW_BIGRAMS_PER_PREV = 12
# Case / possessive endings that ugwiki sometimes writes detached (after digits, foreign names).
DETACHED_SUFFIXES = {
    "ning", "ni", "gha", "ge", "qa", "ke", "da", "de", "ta", "te", "din", "tin",
    "diki", "tiki", "dek", "tek", "li", "lik", "liq", "luq", "lük", "lar", "ler",
    "si", "i", "ma", "me", "chi", "chilar",
}

# Productive clitics / case / aspect endings for offline surface-form expansion.
MORPH_SUFFIXES = [
    # Polite / question clitics
    "mu",
    "musiz",
    "misiz",
    "musen",
    "musiler",
    "siler",
    "siz",
    "sen",
    "chu",
    "ghu",
    "ken",
    # Past / perfect-ish
    "ding",
    "dingiz",
    "dingizmu",
    "digizmu",
    "digiz",
    "gizmu",
    "izmu",
    "dum",
    "duq",
    "di",
    "du",
    # tur- family (adjectival predicative)
    "turding",
    "turdingiz",
    "turdingizmu",
    "turdigizmu",
    "turdigiz",
    "turdi",
    "turdu",
    "turdum",
    "turduq",
    "tur",
    # Progressive / continuous
    "watimen",
    "watisen",
    "watisiz",
    "watidu",
    "watimiz",
    "watidilar",
    "uwatimen",
    "uwatidu",
    "iwatimen",
    "iwatidu",
    # Case / plural (high-value surfaces)
    "lar",
    "ler",
    "ning",
    "ni",
    "gha",
    "qa",
    "da",
    "de",
    "din",
    "tin",
    # Common verb person / optative endings
    "imen",
    "isen",
    "isiz",
    "idu",
    "imiz",
    "idilar",
    "ay",
    "ey",
    "ayli",
    "eyli",
    "ing",
    "ingiz",
    "sun",
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
    "salamueleykum": 9_000,
    "essalamu'eleykum": 12_000,
}

EXTRA_SEEDS_FILE = ROOT / "data" / "extra_uly_seeds.txt"

# Compact fallback if corpus directory is empty.
SEED_CORPUS = """
salam yaxshimusiz
essalamu'eleykum we'eleykum'essalam
men bügün mektepke bardim
u uyghurche sözleydu
bu kitab nahayiti yaxshi
biz öyge qaytimiz
latin yeziqi qulay
uyghur latin yeziqi
""".strip()

WORD_RE = re.compile(r"[A-Za-zÖÜËöüëÉé']+")
ARABIC_TOKEN_RE = re.compile(r"[\u0600-\u06FFʼ']+")
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
    "ye",
    "ya",
    "ne",
    "bu",
}


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
    return (
        text.replace("É", "Ë")
        .replace("é", "ë")
        .replace("ʼ", "'")
        .replace("'", "'")
        .replace("‘", "'")
        .replace("’", "'")
    )


def is_clean_uly(word: str) -> bool:
    """Quality gate for converted / curated ULY tokens."""
    if not word:
        return False
    if word in SINGLE_LETTER_WORDS:
        return True
    if len(word) < MIN_WORD_LEN or len(word) > MAX_WORD_LEN:
        return False
    if not WORD_RE.fullmatch(word):
        return False
    # Reject conversion junk: too many apostrophes, leading/trailing marks.
    if word.startswith("'") or word.endswith("'"):
        return False
    if word.count("'") > 2:
        return False
    # Reject all-vowel noise and single digraph leftovers.
    letters = re.sub(r"[^a-zëöü]", "", word.lower())
    if len(letters) < MIN_WORD_LEN:
        return False
    return True


def to_uly(converter, arabic: str) -> str:
    try:
        latin = converter(arabic.strip())
    except Exception:
        return ""
    return normalize_uly(latin)


def load_imla(path: Path, converter) -> dict[str, int]:
    freqs: dict[str, int] = {}
    skipped = 0
    with path.open(encoding="utf-8-sig") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            parts = line.split()
            word_ar = parts[0]
            freq = int(parts[1]) if len(parts) > 1 and parts[1].isdigit() else 1
            uly = to_uly(converter, word_ar)
            key = uly.lower()
            if not is_clean_uly(key):
                skipped += 1
                continue
            freqs[key] = freqs.get(key, 0) + freq
    print(f"  imla skipped (quality): {skipped}")
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
            if is_clean_uly(w) and is_clean_uly(r) and w != r:
                mapping[w] = r
    informal = {
        "bugun": "bügün",
        "uygur": "uyghur",
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
        "uygurche": "uyghurche",
        "dolet": "dölet",
        "kelimen": "këlimen",
        "urumchi": "ürümchi",
        "ulumqi": "ürümchi",
        "kashgar": "qeshqer",
        "kashghar": "qeshqer",
        "hotan": "xoten",
        "khotan": "xoten",
        "kompyuter": "kompüter",
        "komputer": "kompüter",
        "internet": "internet",
        "shinjang": "xinjiang",
        "xinjiang": "xinjiang",
        "beijing": "béyjing",
        "bejing": "béyjing",
        "yaxmux": "yaxshimusiz",
        "yaxmusiz": "yaxshimusiz",
        "salamualeykum": "essalamu'eleykum",
        "assalamu'aleykum": "essalamu'eleykum",
        "rahmet": "rehmet",
        "rakhmet": "rehmet",
        "chushendim": "chüshendim",
        "bilmeyman": "bilmeymen",
        "muellim": "mu'ellim",
        "muellimler": "mu'ellimler",
        "saet": "sa'et",
        "maash": "ma'ash",
        "aksu": "aqsu",
        "unalgu": "ün'alghu",
        "takisi": "taksi",
        "kirek": "kërek",
        "digen": "dëgen",
        "bulup": "bolup",
        "kilip": "këlip",
        "geleymen": "kelimen",
        "barayman": "barimen",
    }
    for w, r in informal.items():
        mapping.setdefault(w, r)
    return mapping


def load_extra_seeds() -> dict[str, int]:
    out: dict[str, int] = {}
    if not EXTRA_SEEDS_FILE.exists():
        return out
    for line in EXTRA_SEEDS_FILE.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        parts = line.split()
        if len(parts) < 2 or not parts[1].isdigit():
            continue
        word = normalize_uly(parts[0]).lower()
        if not is_clean_uly(word):
            continue
        out[word] = max(out.get(word, 0), int(parts[1]))
    return out


def expand_morphology(freqs: dict[str, int]) -> dict[str, int]:
    out = dict(freqs)
    for w, f in MORPH_SEED_WORDS.items():
        out[w] = max(out.get(w, 0), f)
    for w, f in load_extra_seeds().items():
        out[w] = max(out.get(w, 0), f)

    stems = [w for w, _ in sorted(freqs.items(), key=lambda x: -x[1])[:MORPH_STEM_CAP]]
    for stem in stems:
        if stem in SKIP_STEMS or len(stem) < 3 or len(stem) > 16:
            continue
        base = freqs.get(stem, 1)
        if base < 60:
            continue
        for i, suf in enumerate(MORPH_SUFFIXES):
            form = stem + suf
            if not is_clean_uly(form) or len(form) > MAX_WORD_LEN:
                continue
            freq = max(2, base // (6 + i * 2))
            out[form] = max(out.get(form, 0), freq)
    return out


def extract_lemma_freqs_from_imlalughet(converter, imla_keys: set[str]) -> dict[str, int]:
    """Selective OCR merge: keep lemmas seen often or already in imla."""
    raw_hits: Counter[str] = Counter()
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
        # Drop dictionary annotations: "(تۇرغۇن)" part of speech, "<قەدىمكى>" register, "-(پېئىل)".
        text = re.sub(r"\([^)\n]*\)|<[^>\n]*>", " ", text)
        for m in ARABIC_TOKEN_RE.finditer(text):
            uly = to_uly(converter, m.group(0)).lower()
            if is_clean_uly(uly):
                raw_hits[uly] += 1

    kept: dict[str, int] = {}
    dropped = 0
    for w, c in raw_hits.items():
        if c >= OCR_MIN_HITS or w in imla_keys:
            kept[w] = c
        else:
            dropped += 1
    print(f"  imlalughet kept={len(kept)} dropped_sparse={dropped}")
    return kept


class CorpusStats:
    """Unigram / bigram counts, kept apart for curated (chat-register) and raw (encyclopedic) text."""

    def __init__(self) -> None:
        self.curated_uni: Counter[str] = Counter()
        self.curated_bi: Counter[tuple[str, str]] = Counter()
        self.raw_uni: Counter[str] = Counter()
        self.raw_bi: Counter[tuple[str, str]] = Counter()
        self.raw_tokens = 0


def iter_corpus_files() -> list[tuple[str, bool]]:
    """(text, curated) pairs: project-curated phrases, then optional dumps in data/raw/corpus/."""
    items: list[tuple[str, bool]] = [(SEED_CORPUS, True)]
    if CORPUS_DIR.exists():
        for path in sorted(CORPUS_DIR.glob("*.txt")):
            items.append((path.read_text(encoding="utf-8", errors="ignore"), True))
    raw_corpus = RAW / "corpus"
    if raw_corpus.exists():
        for path in sorted(raw_corpus.rglob("*.txt")):
            items.append((path.read_text(encoding="utf-8", errors="ignore"), False))
    return items


def load_corpus_stats(converter=None) -> CorpusStats:
    """Count words and adjacent pairs per line (lines are sentences / phrases)."""
    stats = CorpusStats()
    for text, curated in iter_corpus_files():
        if converter is not None:
            text = convert_arabic_corpus_chunks(converter, text)
        uni = stats.curated_uni if curated else stats.raw_uni
        bi = stats.curated_bi if curated else stats.raw_bi
        for line in text.splitlines():
            line = line.strip()
            if not line or line.startswith("#"):
                continue
            tokens = [normalize_uly(t).lower() for t in WORD_RE.findall(line)]
            tokens = [t for t in tokens if is_clean_uly(t)]
            uni.update(tokens)
            bi.update(zip(tokens, tokens[1:]))
            if not curated:
                stats.raw_tokens += len(tokens)
    return stats


def fold_variant(word: str) -> str:
    """Collapse common non-standard ULY spellings (kirek/kërek, bulup/bolup, jaylaxkan/jaylashqan,
    kitap/kitab, video/widio)."""
    w = word.lower().replace("'", "")
    w = w.replace("gh", "g").replace("sh", "x").replace("ë", "i").replace("é", "i")
    w = w.replace("o", "u").replace("ö", "ü").replace("q", "k").replace("v", "w")
    if w.endswith("b"):
        w = w[:-1] + "p"
    return w


def merge_corpus_unigrams(
    freqs: dict[str, int],
    stats: CorpusStats,
    wrong_spellings: set[str],
) -> tuple[int, int]:
    """Re-rank known words by real usage and swap in well-attested new words.

    New raw-corpus words must be frequent, not a known misspelling, not a detached suffix and
    not a spelling variant of a word we already have. Everything competes for MAX_WORDS
    afterwards, so additions displace the weakest imla / morphology entries.
    """
    folded = {fold_variant(w) for w in freqs}
    boosted = added = 0
    for word, n in stats.raw_uni.most_common():
        if word in freqs:
            freqs[word] += min(RAW_BOOST_CAP, RAW_BOOST_PER_HIT * n)
            boosted += 1
            continue
        if n < RAW_MIN_NEW_HITS:
            continue
        if word in DETACHED_SUFFIXES or word in wrong_spellings:
            continue
        key = fold_variant(word)
        if key in folded:
            continue
        folded.add(key)
        freqs[word] = min(RAW_NEW_CAP, RAW_NEW_BASE + RAW_NEW_PER_HIT * n)
        added += 1
    for word, n in stats.curated_uni.items():
        freqs[word] = freqs.get(word, 0) + min(CURATED_BOOST_CAP, CURATED_BOOST_PER_HIT * n)
    return boosted, added


def convert_arabic_corpus_chunks(converter, text: str) -> str:
    """If a line is mostly Arabic, convert tokens to ULY; else keep as-is."""
    out_lines: list[str] = []
    for line in text.splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        arabic_chars = len(ARABIC_TOKEN_RE.findall(line))
        latin_chars = len(WORD_RE.findall(line))
        if arabic_chars > latin_chars and arabic_chars > 0:
            parts: list[str] = []
            pos = 0
            for m in ARABIC_TOKEN_RE.finditer(line):
                parts.append(line[pos : m.start()])
                uly = to_uly(converter, m.group(0)).lower()
                parts.append(uly if is_clean_uly(uly) else "")
                pos = m.end()
            parts.append(line[pos:])
            out_lines.append("".join(parts))
        else:
            out_lines.append(line)
    return "\n".join(out_lines)


def build_bigrams(word_set: set[str], stats: CorpusStats) -> list[list]:
    """Real next-word pairs only: every curated pair, then raw-corpus pairs by count.

    Curated counts are scaled so chat phrasing outranks encyclopedic continuations of the
    same word. Raw pairs are capped per previous word so frequent words like `we` cannot
    use up the MAX_BIGRAMS budget that rarer contexts need.
    """
    out: list[list] = []
    seen: set[tuple[str, str]] = set()
    per_prev: Counter[str] = Counter()
    for (a, b), n in stats.curated_bi.most_common():
        if b not in word_set:
            continue
        out.append([a, b, CURATED_BIGRAM_WEIGHT * n + stats.raw_bi.get((a, b), 0)])
        seen.add((a, b))
    for (a, b), n in stats.raw_bi.most_common():
        if len(out) >= MAX_BIGRAMS or n < RAW_BIGRAM_MIN_HITS:
            break
        if (a, b) in seen or a == b or a not in word_set or b not in word_set:
            continue
        if b in DETACHED_SUFFIXES or per_prev[a] >= RAW_BIGRAMS_PER_PREV:
            continue
        out.append([a, b, n])
        seen.add((a, b))
        per_prev[a] += 1
    out.sort(key=lambda r: (-r[2], r[0], r[1]))
    return out[:MAX_BIGRAMS]


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
    (OUT / "lexicon.json").write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")),
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
    (OUT / "meta.json").write_text(
        json.dumps(meta, ensure_ascii=False, indent=2), encoding="utf-8"
    )

    for dest in (WEB_PUBLIC, ANDROID_ASSETS, HARMONY_RAWFILE):
        if dest in (ANDROID_ASSETS, HARMONY_RAWFILE):
            platform = ROOT / ("android" if dest == ANDROID_ASSETS else "harmonyos")
            if not platform.exists():
                continue
        dest.mkdir(parents=True, exist_ok=True)
        shutil.copy2(OUT / "lexicon.json", dest / "lexicon.json")
        if dest == WEB_PUBLIC:
            shutil.copy2(OUT / "meta.json", dest / "meta.json")

    # iOS ships only the compiled lexicon.bin (inside the keyboard extension; the host
    # app reads it from there), never lexicon.json.
    from compile_lexicon_bin import compile_lexicon

    IOS_RES.mkdir(parents=True, exist_ok=True)
    shutil.copy2(OUT / "meta.json", IOS_RES / "meta.json")
    (IOS_RES / "lexicon.bin").write_bytes(
        compile_lexicon(json.loads((OUT / "lexicon.json").read_text(encoding="utf-8")))
    )
    if IOS_HOST.exists():
        shutil.copy2(OUT / "meta.json", IOS_HOST / "meta.json")


def main() -> None:
    try:
        from umsc import UgMultiScriptConverter
    except ImportError:
        print("Install umsc: pip install umsc", file=sys.stderr)
        raise SystemExit(1)

    converter = UgMultiScriptConverter("UAS", "ULS")
    src = find_source()
    print(f"Using source: {src}")

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

    lemma = extract_lemma_freqs_from_imlalughet(converter, set(freqs))
    for w, c in lemma.items():
        freqs[w] = freqs.get(w, 0) + c * 3
    print(f"  after selective imlalughet: {len(freqs)}")

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
        ("ürümchi", 18_000),
        ("qeshqer", 16_000),
        ("xoten", 14_000),
        ("kompüter", 12_000),
        ("internet", 11_000),
        ("mashina", 10_000),
        ("doxtur", 9_000),
        ("banka", 9_000),
        ("hayit", 8_500),
        ("jüme", 9_000),
        ("hazir", 11_000),
        ("chünki", 9_500),
        ("shunga", 9_000),
        ("béyjing", 8_000),
        ("korla", 9_000),
        ("yeken", 8_000),
    ):
        freqs[w] = max(freqs.get(w, 0), f)

    print("Expanding productive morphology for top stems…")
    before = len(freqs)
    freqs = expand_morphology(freqs)
    print(f"  stems+clitics: {before} → {len(freqs)}")

    print("Converting corrections…")
    corrections_raw = load_corrections(src / "imla_xatatoghra.txt", converter)
    corrections = {w: r for w, r in corrections_raw.items() if is_clean_uly(w) and is_clean_uly(r)}
    print(f"  corrections: {len(corrections)}")

    print("Reading corpus (curated + data/raw/corpus)…")
    stats = load_corpus_stats(converter)
    print(
        f"  curated tokens={sum(stats.curated_uni.values())} "
        f"raw tokens={stats.raw_tokens} raw unique={len(stats.raw_uni)}"
    )
    boosted, added = merge_corpus_unigrams(freqs, stats, set(corrections))
    print(f"  corpus re-ranked {boosted} known words, swapped in {added} attested new words")

    filtered = [(w, f) for w, f in freqs.items() if f >= MIN_FREQ and is_clean_uly(w)]
    filtered.sort(key=lambda x: (-x[1], x[0]))
    filtered = filtered[:MAX_WORDS]
    words = [[w, f] for w, f in filtered]
    word_set = {w for w, _ in words}

    print("Building bigrams from real corpus pairs…")
    bigrams = build_bigrams(word_set, stats)
    print(f"  bigrams: {len(bigrams)}")

    sources = [
        "https://github.com/gheyret/UyghurEditPP (MIT)",
        "https://github.com/gheyret/imlalughet (MIT)",
        "https://github.com/neouyghur/Uyghur-Multi-Script-Converter / umsc (Apache-2.0)",
        "data/corpus/*.txt (project MIT curated ULY phrases)",
    ]
    if stats.raw_tokens:
        sources.append(
            "Uyghur Wikipedia dump (CC BY-SA 4.0) — word / bigram counts only, via tools/extract_wiki_corpus.py"
        )

    meta = {
        "version": "1.4.0",
        "script": "ULY-2008",
        "wordCount": len(words),
        "correctionCount": len(corrections),
        "bigramCount": len(bigrams),
        "sources": sources,
        "notes": (
            "Arabic lemmas converted with umsc UAS→ULS; quality-filtered; selective OCR merge; "
            "productive morph expansion; corpus-ranked frequencies with attested-word swap-in "
            "under the word cap; real corpus bigrams (curated chat pairs first)."
        ),
    }
    write_outputs(words, corrections, bigrams, meta)
    size = (OUT / "lexicon.json").stat().st_size
    print(f"Wrote {OUT / 'lexicon.json'} ({size / 1e6:.2f} MB)")
    print("Done.")


if __name__ == "__main__":
    main()
