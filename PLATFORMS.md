# Platforms & branches

`main` ships **iOS + web + marketing site**. Android and HarmonyOS NEXT are developed on **separate branches** and must **not** be merged into `main` until each platform is release-ready.

| Platform | Branch | Directory (on that branch) | Draft PR | Status |
|----------|--------|----------------------------|----------|--------|
| **iOS / web** | [`main`](https://github.com/eskar-ai/ULY-IOS/tree/main) | `ios/`, `web/`, `Sources/` | — | Live on `main` |
| **iOS docs + Downloads hub** | [`cursor/ios-platform-and-downloads-9edd`](https://github.com/eskar-ai/ULY-IOS/tree/cursor/ios-platform-and-downloads-9edd) | `ios/PLATFORM.md`, `store/site/downloads.html` | [#4](https://github.com/eskar-ai/ULY-IOS/pull/4) | Ready for `main` |
| **iOS IME performance** | [`cursor/ios-ime-performance-9edd`](https://github.com/eskar-ai/ULY-IOS/tree/cursor/ios-ime-performance-9edd) | `Sources/`, `ios/PERFORMANCE.md` | [#5](https://github.com/eskar-ai/ULY-IOS/pull/5) | Review / merge after #4 |
| **Android** | [`cursor/android-uly-keyboard-9edd`](https://github.com/eskar-ai/ULY-IOS/tree/cursor/android-uly-keyboard-9edd) | `android/` | [#2](https://github.com/eskar-ai/ULY-IOS/pull/2) | Scaffold + perf; **keep off `main`** |
| **HarmonyOS NEXT** | [`cursor/harmonyos-uly-keyboard-9edd`](https://github.com/eskar-ai/ULY-IOS/tree/cursor/harmonyos-uly-keyboard-9edd) | `harmonyos/` | [#3](https://github.com/eskar-ai/ULY-IOS/pull/3) | Scaffold + perf; **keep off `main`** |

## What lives where

| Concern | Where to look |
|---------|----------------|
| Shared lexicon | `data/generated/lexicon.json` + `tools/build_lexicon.py` (all platforms) |
| Engine spec (reference) | `Sources/UyghurLatinKit/` (Swift) · `web/src/engine/` (TypeScript) |
| Android engine / IME | `android/` on Android branch only |
| HarmonyOS engine / IME | `harmonyos/` on HarmonyOS branch only |
| Downloads page (Pages) | `store/site/downloads.html` → https://eskar-ai.github.io/ULY-IOS/downloads.html |
| Per-platform package / display / update / contribute | `*/PLATFORM.md` on each platform branch · [`ios/PLATFORM.md`](ios/PLATFORM.md) on this tree |

## Checkout cheat sheet

```bash
# iOS / web (default)
git checkout main

# Android only
git checkout cursor/android-uly-keyboard-9edd
cd android && ./scripts/check-quality.sh

# HarmonyOS only
git checkout cursor/harmonyos-uly-keyboard-9edd
cd harmonyos && ./scripts/check-quality.sh

# iOS performance work
git checkout cursor/ios-ime-performance-9edd
```

## Rules

1. Open PRs against the **matching platform branch** (or `main` for iOS/web/site only).
2. Do **not** land unfinished `android/` or `harmonyos/` trees on `main`.
3. Do **not** mix Android and HarmonyOS changes in one PR.
4. APK / HAP binaries ship via Releases or AppGallery — see Downloads on the site when published.
