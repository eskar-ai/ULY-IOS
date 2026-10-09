# Contributing to Uyghur ULY keyboard

Thank you for your interest. Contributions of all kinds are welcome — bug reports, translations, lexicon fixes, keyboard UX improvements, and documentation.

## Ways to help

1. **Report issues** — describe the iOS version, steps to reproduce, and expected vs actual behavior.
2. **Improve translations** — host app and site UI languages: English, 简体中文, ئۇيغۇرچە, Uyghurche (ULY).
3. **Lexicon / corrections** — offline dictionary tooling lives under `tools/` and `data/`.
4. **Pull requests** — keep changes focused; explain why the change helps users.

## Platforms

See **[`PLATFORMS.md`](PLATFORMS.md)** for the canonical branch / PR map.

| Platform | Branch | Where to contribute |
|----------|--------|---------------------|
| iOS / web / site | `main` | This repo default; [`ios/CONTRIBUTING.md`](ios/CONTRIBUTING.md) |
| Android | [`cursor/android-uly-keyboard-9edd`](https://github.com/eskar-ai/ULY-IOS/tree/cursor/android-uly-keyboard-9edd) | `android/CONTRIBUTING.md` **on that branch** ([PR #2](https://github.com/eskar-ai/ULY-IOS/pull/2)) |
| HarmonyOS NEXT | [`cursor/harmonyos-uly-keyboard-9edd`](https://github.com/eskar-ai/ULY-IOS/tree/cursor/harmonyos-uly-keyboard-9edd) | `harmonyos/CONTRIBUTING.md` **on that branch** ([PR #3](https://github.com/eskar-ai/ULY-IOS/pull/3)) |
| iOS performance | [`cursor/ios-ime-performance-9edd`](https://github.com/eskar-ai/ULY-IOS/tree/cursor/ios-ime-performance-9edd) | [PR #5](https://github.com/eskar-ai/ULY-IOS/pull/5) |

Keep Android / HarmonyOS scaffolds on their branches until release-ready — **do not** land unfinished `android/` or `harmonyos/` trees on `main`.

## Development quick start

Public web demo (no local setup): https://eskar-ai.github.io/ULY-IOS/demo/

```bash
# Local web demo (optional) — open the URL printed by Vite
cd web && npm install && npm run dev

# Lexicon rebuild (optional)
python3 -m pip install -r tools/requirements.txt
python3 tools/build_lexicon.py

# iOS (requires macOS + Xcode)
cd ios && brew install xcodegen && xcodegen generate
open UyghurLatin.xcodeproj
```

## Guidelines

- Typing must stay **on-device**; do not add analytics, ads, or Full Access unless there is a clear, documented need.
- Prefer small PRs with a clear summary and test notes.
- Match existing code style and localization patterns (four UI languages).
- Be respectful in issues and reviews.

## License

By contributing, you agree that your contributions are licensed under the project’s MIT License (see `LICENSE`).
