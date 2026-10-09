# Uyghur ULY keyboard — HarmonyOS NEXT

Offline Uyghur Latin (ULY) input method for **HarmonyOS NEXT** (ArkTS). Same lexicon and suggestion pipeline as iOS / web / Android, implemented as an `InputMethodExtensionAbility`.

> This branch scaffolds the HarmonyOS project. Builds require **DevEco Studio** and the HarmonyOS NEXT SDK. HAP downloads will be linked from the site Downloads page when published.

## Modules

| Path | Role |
|------|------|
| `uly_engine/` | Shared ArkTS HAR — trie, spell, n-grams, suggestions |
| `entry/` | Host setup ability (enable instructions + try field) |
| `ime/` | Input Method Extension + keyboard panel UI |

Bundled lexicon: `ime/src/main/resources/rawfile/lexicon.json` (from `data/generated/lexicon.json`).

## Open in DevEco Studio

1. Install DevEco Studio with HarmonyOS NEXT SDK (API 12+).
2. **Open** the `harmonyos/` folder as a project.
3. Let ohpm / hvigor sync dependencies.
4. Sign with your debug profile, then Run on a HarmonyOS NEXT device/emulator.
5. Enable **Uyghur ULY keyboard** under system keyboard settings and switch to it while typing.

## Privacy

- Suggestions and spell check run on device from the bundled lexicon.
- No network permission is required for typing.
- Source stays open under MIT (see repo root).

## Status

Early scaffold — engine port, IME extension stub, host page, and keyboard panel UI. Full IMEKit insert/delete wiring and signed HAP release come next on this branch (not on `main`).

## Related branches

- iOS / web: `main` (do not merge platform scaffolds into `main` until ready)
- Android: `cursor/android-uly-keyboard-9edd`
