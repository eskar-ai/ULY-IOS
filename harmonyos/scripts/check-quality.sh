#!/usr/bin/env bash
# Fast local gate before opening a PR on the HarmonyOS branch.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> sync lexicon + smoke"
./scripts/run-unit-tests.sh

echo "==> quality markers"
test -f PLATFORM.md && test -f TESTING.md && test -f QUALITY.md && test -f CONTRIBUTING.md
test -f uly_engine/src/test/ets/Uly.test.ets
test -f uly_engine/src/test/ets/SpellNGram.test.ets
test -f scripts/run-engine-smoke.mjs

echo "OK — HarmonyOS quality gate passed."
