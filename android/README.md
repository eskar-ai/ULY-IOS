# Uyghur ULY keyboard — Android

Offline Uyghur Latin (ULY) system keyboard for Android. Same lexicon and suggestion pipeline as the iOS / web engines, ported to Kotlin.

[![Android CI](https://github.com/eskar-ai/ULY-IOS/actions/workflows/android-ci.yml/badge.svg?branch=cursor/android-uly-keyboard-9edd)](https://github.com/eskar-ai/ULY-IOS/actions/workflows/android-ci.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](../LICENSE)

> Platform work lives on **`cursor/android-uly-keyboard-9edd`** — not on `main` until release-ready.  
> [`PLATFORM.md`](PLATFORM.md) · [`PERFORMANCE.md`](PERFORMANCE.md) · [`TESTING.md`](TESTING.md) · [`QUALITY.md`](QUALITY.md) · [`CONTRIBUTING.md`](CONTRIBUTING.md)

## Modules

| Path | Role |
|------|------|
| `uly-engine/` | Shared Kotlin engine (trie, spell, n-grams, suggestions) + unit tests |
| `app/` | Host setup activity + `InputMethodService` IME |
| `scripts/` | Lexicon sync, build, test, release-notes helpers |

Bundled lexicon: `app/src/main/assets/lexicon.json` (from `data/generated/lexicon.json`).

## Quick scripts

```bash
cd android
chmod +x scripts/*.sh gradlew
./scripts/sync-lexicon.sh
./scripts/run-unit-tests.sh    # no device needed
./scripts/build-debug.sh       # → app/build/outputs/apk/debug/
./scripts/build-release.sh     # signing via env vars (optional)
./scripts/package-release-notes.sh 0.1.0
```

## Enable on a device

1. Install the debug APK.
2. Open **Uyghur ULY keyboard** → **Open keyboard settings**.
3. Enable **Uyghur ULY keyboard**.
4. Switch to it from the system keyboard picker while typing.

## Testing

| Kind | How |
|------|-----|
| Unit | `./scripts/run-unit-tests.sh` |
| UI (device) | `./gradlew :app:connectedDebugAndroidTest` |
| CI | `.github/workflows/android-ci.yml` on this branch |

## Privacy

- Suggestions and spell check run on device from the bundled lexicon.
- Personal accepted words stay in app SharedPreferences.
- No network permission is declared for typing.

## Contribute

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`PLATFORM.md`](PLATFORM.md).
