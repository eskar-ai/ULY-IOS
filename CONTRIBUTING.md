# Contributing to Uyghur ULY keyboard

Thank you for your interest. Contributions of all kinds are welcome — bug reports, translations, lexicon fixes, keyboard UX improvements, and documentation.

## Ways to help

1. **Report issues** — describe the iOS version, steps to reproduce, and expected vs actual behavior.
2. **Improve translations** — host app and site UI languages: English, 简体中文, ئۇيغۇرچە, Uyghurche (ULY).
3. **Lexicon / corrections** — offline dictionary tooling lives under `tools/` and `data/`.
4. **Pull requests** — keep changes focused; explain why the change helps users.

## Platforms

| Platform | Branch | Notes |
|----------|--------|-------|
| iOS / web | `main` | Xcode + Vite demo |
| Android | `cursor/android-uly-keyboard-9edd` | See `android/CONTRIBUTING.md` |
| HarmonyOS NEXT | `cursor/harmonyos-uly-keyboard-9edd` | See `harmonyos/CONTRIBUTING.md` |

Keep platform scaffolds on their branches until release-ready — do not land unfinished Android/HarmonyOS trees on `main`.

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
