# iOS app (ULY Künupka)

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
3. Run the app, then on device: **Settings → General → Keyboard → Keyboards → Add New Keyboard → ULY Künupka**.

The keyboard extension sets `RequestsOpenAccess = false` and runs entirely offline.
