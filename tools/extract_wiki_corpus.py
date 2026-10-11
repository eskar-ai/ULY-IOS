#!/usr/bin/env python3
"""Extract running ULY text from a Uyghur Wikipedia dump for lexicon statistics.

Input:  data/raw/wiki/ugwiki-latest-pages-articles.xml.bz2
        (https://dumps.wikimedia.org/ugwiki/latest/, CC BY-SA 4.0)
Output: data/raw/corpus/ugwiki_uly.txt  — one ULY sentence per line (gitignored)

Only derived word / bigram counts reach the shipped lexicon; the text itself stays local.

Usage:
  python3 tools/extract_wiki_corpus.py [dump.xml.bz2] [out.txt]
"""

from __future__ import annotations

import bz2
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))
import build_lexicon as bl  # noqa: E402

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_IN = ROOT / "data/raw/wiki/ugwiki-latest-pages-articles.xml.bz2"
DEFAULT_OUT = ROOT / "data/raw/corpus/ugwiki_uly.txt"

ARABIC_RUN = re.compile(r"[\u0600-\u06FF\uFB50-\uFDFF\uFE70-\uFEFF]+")
SENTENCE_SPLIT = re.compile(r"[.!?؟。\n]+|[،؛:]")
MIN_SENTENCE_TOKENS = 3


def strip_markup(text: str) -> str:
    text = re.sub(r"<!--.*?-->", " ", text, flags=re.S)
    text = re.sub(r"<ref[^>]*/>", " ", text)
    text = re.sub(r"<ref[^>]*>.*?</ref>", " ", text, flags=re.S)
    text = re.sub(r"<(table|gallery|math|code|pre|timeline)[^>]*>.*?</\1>", " ", text, flags=re.S | re.I)
    # Nested templates / tables: peel innermost repeatedly.
    for _ in range(6):
        new = re.sub(r"\{\{[^{}]*\}\}", " ", text)
        new = re.sub(r"\{\|[^{}]*?\|\}", " ", new, flags=re.S)
        if new == text:
            break
        text = new
    # File / category / interwiki links go entirely.
    text = re.sub(r"\[\[(?:[^\]|:]+):[^\]]*\]\]", " ", text)
    # [[target|label]] → label, [[target]] → target
    text = re.sub(r"\[\[([^\]|]*\|)?([^\]]*)\]\]", r"\2", text)
    text = re.sub(r"\[https?://[^\s\]]+\s*([^\]]*)\]", r"\1", text)
    text = re.sub(r"<[^>]+>", " ", text)
    text = re.sub(r"'{2,}", "", text)
    text = re.sub(r"^[=*#:;|!].*$", " ", text, flags=re.M)
    text = text.replace("&nbsp;", " ")
    return text


def iter_articles(path: Path):
    with bz2.open(path, "rb") as f:
        title = None
        ns = None
        for _, elem in ET.iterparse(f, events=("end",)):
            tag = elem.tag.rsplit("}", 1)[-1]
            if tag == "title":
                title = elem.text
            elif tag == "ns":
                ns = elem.text
            elif tag == "text":
                body = elem.text or ""
                if ns == "0" and not body.lstrip().lower().startswith("#redirect") and "#قايتا" not in body[:20]:
                    yield title, body
            elif tag == "page":
                elem.clear()


def main() -> int:
    src = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_IN
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUT
    from umsc import UgMultiScriptConverter

    converter = UgMultiScriptConverter("UAS", "ULS")
    cache: dict[str, str] = {}

    def convert(token: str) -> str:
        hit = cache.get(token)
        if hit is None:
            uly = bl.to_uly(converter, token).lower()
            hit = uly if bl.is_clean_uly(uly) else ""
            cache[token] = hit
        return hit

    out.parent.mkdir(parents=True, exist_ok=True)
    articles = sentences = tokens = 0
    with out.open("w", encoding="utf-8") as w:
        for _title, body in iter_articles(src):
            articles += 1
            for chunk in SENTENCE_SPLIT.split(strip_markup(body)):
                runs = ARABIC_RUN.findall(chunk)
                # Skip mostly non-Uyghur chunks (Latin citations, numbers, tables).
                if len(runs) < MIN_SENTENCE_TOKENS:
                    continue
                words = [convert(t) for t in runs]
                # A failed conversion breaks adjacency; split there instead of gluing words.
                segment: list[str] = []
                for word in words + [""]:
                    if word:
                        segment.append(word)
                        continue
                    if len(segment) >= MIN_SENTENCE_TOKENS:
                        w.write(" ".join(segment) + "\n")
                        sentences += 1
                        tokens += len(segment)
                    segment = []
    print(f"articles={articles} sentences={sentences} tokens={tokens} unique_arabic={len(cache)} → {out}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
