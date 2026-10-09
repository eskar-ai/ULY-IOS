# Contributing — iOS

iOS / web work targets **`main`**. Keep unfinished `android/` and `harmonyos/` trees on their platform branches.

## Setup

- macOS + Xcode 15+
- XcodeGen: `brew install xcodegen`

```bash
cd ios
./scripts/sync-lexicon.sh
./scripts/generate.sh
open UyghurLatin.xcodeproj
```

## What to work on

- Keyboard UX (candidates, long-press, theme)
- Host enable / privacy / four UI languages
- Shared Swift engine in `Sources/UyghurLatinKit`
- Site pages under `store/site/` (including Downloads)
- Web demo under `web/`

## Rules

- Typing stays **on-device**; do not add analytics, ads, or Full Access without a documented need.
- Prefer small PRs with test notes (Simulator steps).
- See [`PLATFORM.md`](PLATFORM.md) for package / display / update / scripts / deps.

## Related

Root [`CONTRIBUTING.md`](../CONTRIBUTING.md) · [`../store/CHECKLIST.md`](../store/CHECKLIST.md)
