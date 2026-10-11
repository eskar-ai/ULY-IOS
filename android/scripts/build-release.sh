#!/usr/bin/env bash
# Assemble a release APK. Set ANDROID_RELEASE_STORE_FILE / STORE_PASSWORD /
# KEY_ALIAS / KEY_PASSWORD to sign; otherwise produces an unsigned release.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
"$ROOT/scripts/sync-lexicon.sh"
cd "$ROOT"
./gradlew :app:assembleRelease --stacktrace
echo "Look under $ROOT/app/build/outputs/apk/release/"
