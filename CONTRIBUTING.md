# Contributing to Uyghur ULY keyboard

Thank you for your interest. Contributions of all kinds are welcome — bug reports, translations, lexicon fixes, keyboard UX improvements, and documentation.

## Ways to help

1. **Report issues** — describe the iOS version, steps to reproduce, and expected vs actual behavior.
2. **Improve translations** — host app and site UI languages: English, 简体中文, ئۇيغۇرچە, Uyghurche (ULY).
3. **Lexicon / corrections** — offline dictionary tooling lives under `tools/` and `data/`.
4. **Pull requests** — keep changes focused; explain why the change helps users.

## Platforms

See **[`PLATFORMS.md`](PLATFORMS.md)** for the map.

| Platform | Where to contribute |
|----------|---------------------|
| iOS / web / site | [`ios/CONTRIBUTING.md`](ios/CONTRIBUTING.md) · `web/` · `store/site/` |
| Android | [`android/CONTRIBUTING.md`](android/CONTRIBUTING.md) |
| HarmonyOS NEXT | [`harmonyos/CONTRIBUTING.md`](harmonyos/CONTRIBUTING.md) |

Prefer focused PRs against `main` — one platform or one concern per PR.

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
