# iOS app (Uyghur ULY keyboard)

## Requirements

- macOS with Xcode 15+
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Generate & run

```bash
# From repo root — refresh lexicon if needed
python3 -m pip install umsc
python3 tools/build_lexicon.py

cd ios
xcodegen generate
open UyghurLatin.xcodeproj
```

1. Select the **UyghurLatin** scheme and your iPhone / Simulator.
2. Set your Team under Signing for both `UyghurLatin` and `UyghurLatinKeyboard`.
3. Run the app, then on device: **Settings → General → Keyboard → Keyboards → Add New Keyboard → Uyghur ULY keyboard**.

The keyboard extension sets `RequestsOpenAccess = false` and runs entirely offline.

## App language (UI only)

The host app can switch **English · 简体中文 · ئۇيغۇرچە · Uyghurche (ULY)** from the language picker. This changes menus, privacy, and credits — not the typing alphabet (always ULY).

## Appearance

- Follows the system Light/Dark appearance by default.
- Tap **◐** on the suggestion bar to override: System → Light → Dark.
- Layout and chrome intentionally mirror the stock iOS keyboard (key colors, QuickType candidate bar, SF Symbols for shift/delete/globe).

## App Store

See [`../store/CHECKLIST.md`](../store/CHECKLIST.md) for signing, privacy, screenshots, and submission steps. Both targets include `PrivacyInfo.xcprivacy`.
