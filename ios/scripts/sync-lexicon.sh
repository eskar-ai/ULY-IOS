#!/usr/bin/env bash
# Compile the shared lexicon into the keyboard extension (lexicon.bin only).
# The host app reads lexicon.bin from the embedded extension, so it ships no copy.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/data/generated/lexicon.json"
DST="$ROOT/ios/UyghurLatinKeyboard/Resources/lexicon.bin"
if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC — run: python3 tools/build_lexicon.py" >&2
  exit 1
fi
mkdir -p "$(dirname "$DST")"
python3 "$ROOT/tools/compile_lexicon_bin.py" "$SRC" "$DST"
rm -f "$ROOT/ios/UyghurLatinKeyboard/Resources/lexicon.json" "$ROOT/ios/UyghurLatin/Resources/lexicon.json"
if [[ -f "$ROOT/data/generated/meta.json" ]]; then
  cp "$ROOT/data/generated/meta.json" "$ROOT/ios/UyghurLatinKeyboard/Resources/meta.json"
  cp "$ROOT/data/generated/meta.json" "$ROOT/ios/UyghurLatin/Resources/meta.json"
fi
echo "Synced lexicon.bin → keyboard Resources ($(wc -c < "$DST") bytes)"
