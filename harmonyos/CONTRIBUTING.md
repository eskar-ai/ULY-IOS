# Contributing — HarmonyOS NEXT

HarmonyOS work happens on branch **`cursor/harmonyos-uly-keyboard-9edd`**. Prefer PRs into that branch (draft PRs targeting `main` must not merge until ready).

## Setup

- DevEco Studio with HarmonyOS NEXT SDK (API 12+)
- Check out this branch and open the `harmonyos/` folder

```bash
cd harmonyos
chmod +x scripts/*.sh
./scripts/sync-lexicon.sh
./scripts/run-unit-tests.sh
```

## What to work on

- Engine accuracy (`uly_engine`) — keep Hypium cases in sync
- IMEKit insert/delete wiring and keyboard panel UX
- Host enable instructions and accessibility
- Packaging scripts and Downloads page HAP links

## Rules

- Keep typing **on-device**; no analytics or ads.
- Do not commit signing materials or `local.properties`.
- Prefer small PRs with smoke/Hypium notes.

## Related

Root [`CONTRIBUTING.md`](../CONTRIBUTING.md) · [`PLATFORM.md`](PLATFORM.md)
