#!/usr/bin/env bash
# Copy the shared generated lexicon into the Android app assets.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SRC="$ROOT/data/generated/lexicon.json"
DST="$ROOT/android/app/src/main/assets/lexicon.json"
if [[ ! -f "$SRC" ]]; then
  echo "Missing $SRC — run: python3 tools/build_lexicon.py" >&2
  exit 1
fi
mkdir -p "$(dirname "$DST")"
cp "$SRC" "$DST"
echo "Synced lexicon → android/app/src/main/assets/lexicon.json ($(wc -c < "$DST") bytes)"
