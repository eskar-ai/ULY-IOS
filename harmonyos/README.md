# Uyghur ULY keyboard — HarmonyOS NEXT

Offline Uyghur Latin (ULY) input method for **HarmonyOS NEXT** (ArkTS). Same lexicon and suggestion pipeline as iOS / web / Android, implemented as an `InputMethodExtensionAbility`.

> Platform work lives on **`cursor/harmonyos-uly-keyboard-9edd`** — not on `main` until release-ready. See [`PLATFORM.md`](PLATFORM.md).

## Modules

| Path | Role |
|------|------|
| `uly_engine/` | Shared ArkTS HAR — trie, spell, n-grams, suggestions + Hypium tests |
| `entry/` | Host setup ability + ohosTest smoke |
| `ime/` | Input Method Extension + keyboard panel UI |
| `scripts/` | Lexicon sync, CI smoke, HAP release notes |

Bundled lexicon: `ime/src/main/resources/rawfile/lexicon.json`.

## Quick scripts

```bash
cd harmonyos
chmod +x scripts/*.sh
./scripts/sync-lexicon.sh
./scripts/run-unit-tests.sh      # Node smoke (no DevEco required)
./scripts/build-hap-notes.sh 0.1.0
```

Open `harmonyos/` in **DevEco Studio** to build HAP and run Hypium / ohosTest.

## Testing

| Kind | How |
|------|-----|
| Smoke (CI) | `./scripts/run-unit-tests.sh` |
| Unit (Hypium) | DevEco → `uly_engine` tests |
| UI / Ability | DevEco → `entry` ohosTest |
| CI | `.github/workflows/harmonyos-ci.yml` on this branch |

## Privacy

- Suggestions and spell check run on device from the bundled lexicon.
- No network permission is required for typing.

## Contribute

See [`CONTRIBUTING.md`](CONTRIBUTING.md) and [`PLATFORM.md`](PLATFORM.md).
