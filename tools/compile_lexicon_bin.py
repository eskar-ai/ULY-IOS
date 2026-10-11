#!/usr/bin/env python3
"""Compile lexicon.json into the memory-mappable lexicon.bin used by the iOS keyboard.

Layout must match Sources/UyghurLatinKit/LexiconBinary.swift (format version 2):

  header   b"ULYB", formatVersion, metaLength, wordCount W, stringCount S, nodeCount N,
           correctionCount C, bigramCount B, stringBlobLength, reserved   (10 x u32 LE)
  meta     JSON bytes, zero-padded to 4
  u32[S+1] string offsets (ids < W: lexicon words, frequency desc; ids >= W: extra strings)
  u32[W]   word frequencies
  u32[N]   node first-child index (BFS; root = 0)
  u32[N]   node label (low 16 bits: unicode scalar) | child count << 16
  u32[N]   node word id (0xFFFFFFFF = none)
  u32[2C]  corrections (wrongId, rightId) sorted by wrong UTF-8 bytes
  u32[3B]  bigrams (prevId, nextId, count) sorted by prev bytes, then count desc
  bytes    UTF-8 string blob

Children are sorted by best frequency in their subtree (desc), so a node's subtree best is
max(own word freq, best of first child) and is not stored.

The keyboard extension ships only lexicon.bin; lexicon.json stays in data/generated.

Usage:
  python3 tools/compile_lexicon_bin.py [lexicon.json] [lexicon.bin]
"""

from __future__ import annotations

import json
import struct
import sys
import unicodedata
from collections import deque
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_IN = ROOT / "data/generated/lexicon.json"
DEFAULT_OUT = ROOT / "ios/UyghurLatinKeyboard/Resources/lexicon.bin"

FORMAT_VERSION = 2
NO_WORD = 0xFFFFFFFF
U32_MAX = 0xFFFFFFFF


def lookup_key(s: str) -> str:
    s = s.replace("É", "Ë").replace("é", "ë").replace("ʼ", "'").replace("\u2019", "'")
    return unicodedata.normalize("NFC", s.lower())


def clamp(v: int) -> int:
    return max(0, min(int(v), U32_MAX))


def compile_lexicon(src: dict) -> bytes:
    freq_by_key: dict[str, int] = {}
    for row in src["words"]:
        if len(row) < 2 or not isinstance(row[0], str) or not isinstance(row[1], int):
            continue
        key = lookup_key(row[0])
        if not key or any(ord(c) > 0xFFFF for c in key):
            continue
        freq_by_key[key] = max(freq_by_key.get(key, 0), row[1])

    words = sorted(freq_by_key.items(), key=lambda kv: (-kv[1], kv[0].encode("utf-8")))
    strings = [w for w, _ in words]
    id_of = {s: i for i, s in enumerate(strings)}

    def intern(s: str) -> int:
        if s in id_of:
            return id_of[s]
        id_of[s] = len(strings)
        strings.append(s)
        return len(strings) - 1

    corrections = []
    for wrong, right in src.get("corrections", {}).items():
        w, r = lookup_key(wrong), lookup_key(right)
        if w and r:
            corrections.append((intern(w), intern(r)))
    bigrams = []
    for row in src.get("bigrams", []):
        if len(row) < 3:
            continue
        a, b = lookup_key(str(row[0])), lookup_key(str(row[1]))
        if a and b:
            bigrams.append((intern(a), intern(b), int(row[2])))

    encoded = [s.encode("utf-8") for s in strings]
    corrections.sort(key=lambda p: encoded[p[0]])
    deduped = []
    for p in corrections:
        if not deduped or encoded[deduped[-1][0]] != encoded[p[0]]:
            deduped.append(p)
    bigrams.sort(key=lambda t: (encoded[t[0]], -t[2], encoded[t[1]]))

    # Temporary trie.
    children: list[dict[int, int]] = [{}]
    node_word = [NO_WORD]
    node_best = [0]
    for wid, (key, freq) in enumerate(words):
        node = 0
        node_best[0] = max(node_best[0], freq)
        for ch in key:
            s = ord(ch)
            nxt = children[node].get(s)
            if nxt is None:
                children.append({})
                node_word.append(NO_WORD)
                node_best.append(0)
                nxt = len(children) - 1
                children[node][s] = nxt
            node = nxt
            node_best[node] = max(node_best[node], freq)
        node_word[node] = wid

    # BFS layout.
    n = len(children)
    order = [0]
    label_of = [0] * n
    first_child = [0] * n
    head = 0
    while head < len(order):
        old = order[head]
        head += 1
        kids = sorted(children[old].items(), key=lambda kv: (-node_best[kv[1]], kv[0]))
        first_child[old] = len(order)
        for label, child in kids:
            label_of[child] = label
            order.append(child)

    meta = json.dumps(src["meta"], ensure_ascii=False, separators=(",", ":")).encode("utf-8")
    blob = bytearray()
    offsets = [0]
    for b in encoded:
        blob.extend(b)
        offsets.append(len(blob))

    out = bytearray()
    out += b"ULYB"
    out += struct.pack(
        "<9I",
        FORMAT_VERSION, len(meta), len(words), len(strings), n,
        len(deduped), len(bigrams), len(blob), 0,
    )
    out += meta
    while len(out) % 4:
        out.append(0)

    def put_all(values):
        out.extend(struct.pack(f"<{len(values)}I", *values))

    put_all(offsets)
    put_all([clamp(f) for _, f in words])
    put_all([first_child[o] for o in order])
    put_all([label_of[o] | (len(children[o]) << 16) for o in order])
    put_all([node_word[o] for o in order])
    put_all([v for p in deduped for v in p])
    put_all([clamp(v) for t in bigrams for v in t])
    out += blob
    return bytes(out)


def main() -> int:
    src_path = Path(sys.argv[1]) if len(sys.argv) > 1 else DEFAULT_IN
    out_path = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUT
    src = json.loads(src_path.read_text(encoding="utf-8"))
    data = compile_lexicon(src)
    out_path.write_bytes(data)
    print(f"wrote {out_path} ({len(data) / 1024 / 1024:.2f} MB) from {src_path.name}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
