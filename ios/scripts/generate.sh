#!/usr/bin/env bash
# Generate the Xcode project with XcodeGen.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"
if ! command -v xcodegen >/dev/null 2>&1; then
  echo "Install XcodeGen: brew install xcodegen" >&2
  exit 1
fi
./scripts/sync-lexicon.sh
xcodegen generate
echo "Open: $ROOT/UyghurLatin.xcodeproj"
