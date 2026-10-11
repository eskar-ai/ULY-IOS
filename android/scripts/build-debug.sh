#!/usr/bin/env bash
# Assemble a debug APK (unsigned / debug-signed).
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/sync-lexicon.sh"
cd "$ROOT"
./gradlew :app:assembleDebug --stacktrace
echo "APK: $ROOT/app/build/outputs/apk/debug/app-debug.apk"
