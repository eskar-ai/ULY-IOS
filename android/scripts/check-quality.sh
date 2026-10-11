#!/usr/bin/env bash
# Fast local gate before opening a PR on the Android branch.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

echo "==> sync lexicon"
./scripts/sync-lexicon.sh

echo "==> unit tests"
./scripts/run-unit-tests.sh

echo "==> assemble debug"
./gradlew :app:assembleDebug --stacktrace -q

echo "==> quality markers"
test -f PLATFORM.md && test -f TESTING.md && test -f QUALITY.md && test -f CONTRIBUTING.md
test -f src/../uly-engine/src/test/java/org/uyghurlatin/engine/SuggestionEngineTest.kt

echo "OK — Android quality gate passed."
