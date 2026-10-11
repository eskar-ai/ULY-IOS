# Platforms & branches

`main` ships **iOS + web + marketing site**, plus the **Android** and **HarmonyOS NEXT** keyboard scaffolds after PRs #2–#5 landed.

| Platform | Primary tree | Notes |
|----------|--------------|-------|
| **iOS / web / kit** | `ios/`, `web/`, `Sources/` | Live on `main`; IME perf via [#5](https://github.com/eskar-ai/ULY-IOS/pull/5) |
| **Downloads / marketing** | `store/site/` | Pages: [downloads](https://eskar-ai.github.io/ULY-IOS/downloads.html) |
| **Android** | `android/` | Scaffold + engine tests + Releases workflow (`android-v*`) — [#2](https://github.com/eskar-ai/ULY-IOS/pull/2) |
| **HarmonyOS NEXT** | `harmonyos/` | Scaffold + smoke CI + AGC notes — [#3](https://github.com/eskar-ai/ULY-IOS/pull/3) |

Feature work still uses `cursor/*-9edd` branches; open PRs against `main` unless a long-lived platform branch is needed.

## What lives where

| Concern | Where to look |
|---------|----------------|
| Shared lexicon | `data/generated/lexicon.json` + `tools/build_lexicon.py` (all platforms) |
| Engine spec (reference) | `Sources/UyghurLatinKit/` (Swift) · `web/src/engine/` (TypeScript) |
| Android engine / IME | `android/` |
| HarmonyOS engine / IME | `harmonyos/` |
| Downloads page (Pages) | `store/site/downloads.html` |
| Per-platform package / display / update / contribute | `android/PLATFORM.md` · `harmonyos/PLATFORM.md` · [`ios/PLATFORM.md`](ios/PLATFORM.md) |

## Checkout cheat sheet

```bash
git checkout main

# Android
cd android && ./scripts/check-quality.sh

# HarmonyOS
cd harmonyos && ./scripts/check-quality.sh
```

## Rules

1. Prefer focused PRs against `main` (one platform or one concern).
2. Do **not** mix Android and HarmonyOS changes in one PR unless coordinating shared site/docs only.
3. APK / HAP binaries ship via Releases or AppGallery — see Downloads on the site when published.
