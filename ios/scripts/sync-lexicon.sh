#!/usr/bin/env bash
# Copy shared lexicon into the keyboard extension Resources.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/data/generated/lexicon.json"
DST="$ROOT/ios/UyghurLatinKeyboard/Resources/lexicon.json"
if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC — run: python3 tools/build_lexicon.py" >&2
  exit 1
fi
mkdir -p "$(dirname "$DST")"
cp "$SRC" "$DST"
# meta.json is optional for the extension
if [[ -f "$ROOT/data/generated/meta.json" ]]; then
  cp "$ROOT/data/generated/meta.json" "$ROOT/ios/UyghurLatinKeyboard/Resources/meta.json"
fi
echo "Synced lexicon → ios/UyghurLatinKeyboard/Resources/ ($(wc -c < "$DST") bytes)"
