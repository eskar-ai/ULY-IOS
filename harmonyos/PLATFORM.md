# HarmonyOS NEXT platform plan

Work for HarmonyOS stays on **`cursor/harmonyos-uly-keyboard-9edd`**. Do not merge to `main` until the platform is release-ready.

## Goals

| Area | Approach |
|------|----------|
| **Package** | Signed HAP via DevEco; GitHub Releases for sideload; AppGallery later |
| **Display** | Host entry ability + IME panel; Downloads page links HAP when published |
| **Update** | `versionCode` / `versionName` in `AppScope/app.json5`; release-notes script; optional Releases check later (no telemetry) |
| **Contribute** | `harmonyos/CONTRIBUTING.md`; PRs against this branch |
| **Scripts** | `harmonyos/scripts/*` for lexicon sync, smoke tests, HAP notes |
| **Deps** | IMEKit / AbilityKit / ArkUI; Hypium for on-device tests; ohpm packages pinned in `oh-package.json5` |

## Scripts

```bash
./scripts/sync-lexicon.sh
./scripts/run-unit-tests.sh       # Node lexicon/engine smoke (+ Hypium reminder)
./scripts/build-hap-notes.sh 0.1.0
```

## Testing

| Layer | Location | How |
|-------|----------|-----|
| Smoke (CI) | `scripts/run-engine-smoke.mjs` | `./scripts/run-unit-tests.sh` |
| Unit (Hypium) | `uly_engine/src/test/ets` | DevEco → Run Tests |
| UI / Ability | `entry/src/ohosTest` | DevEco → ohosTest on device |

## Release checklist

1. Sync lexicon; bump version in `AppScope/app.json5`.
2. Run smoke + Hypium tests; smoke-test IME on a HarmonyOS NEXT device.
3. Sign HAP; attach to GitHub Release.
4. Update `store/site/downloads.html` on this branch.
5. Keep the draft PR open — merge to `main` only when ready.

## Parallel platforms

- iOS / web: `main`
- Android: `cursor/android-uly-keyboard-9edd`
