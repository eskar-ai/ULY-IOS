#!/usr/bin/env bash
# Hypium tests require DevEco. CI uses the Node smoke test as a gate.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/sync-lexicon.sh"
node "$ROOT/scripts/run-engine-smoke.mjs"
echo "Hypium (DevEco): open harmonyos/ → Run Tests (uly_engine + entry ohosTest)"
