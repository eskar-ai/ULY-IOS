# Contributing — Android

Android work happens on branch **`cursor/android-uly-keyboard-9edd`**. Prefer PRs into that branch (or draft PRs targeting `main` that must not be merged until ready).

## Setup

- Android Studio Ladybug+ / SDK 35 / JDK 17
- Clone the repo and check out this branch
- Open the `android/` folder (or root and sync the Gradle project)

```bash
cd android
./scripts/sync-lexicon.sh
./scripts/run-unit-tests.sh
./scripts/build-debug.sh
```

## What to work on

- Engine accuracy (`uly-engine`) — add unit tests with each behavior change
- IME layout / long-press / theme
- Host enable UX and accessibility
- Lexicon sync / packaging scripts
- Downloads page copy for Android APK links

## Rules

- Keep typing **on-device**; no analytics or ads.
- Do not commit secrets, keystores, or `local.properties`.
- Keep PRs small; include test notes (`./scripts/run-unit-tests.sh` output).

## Related

Root [`CONTRIBUTING.md`](../CONTRIBUTING.md) · [`PLATFORM.md`](PLATFORM.md)
