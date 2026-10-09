# Uyghur ULY keyboard — Android

Offline Uyghur Latin (ULY) system keyboard for Android. Same lexicon and suggestion pipeline as the iOS / web engines, ported to Kotlin.

> This branch scaffolds the Android app. Builds require Android Studio / SDK. APK downloads will be published via GitHub Releases and linked from the site `downloads` page when ready.

## Modules

| Path | Role |
|------|------|
| `uly-engine/` | Shared Kotlin engine (trie, spell, n-grams, suggestions) |
| `app/` | Host setup activity + `InputMethodService` IME |

Bundled lexicon: `app/src/main/assets/lexicon.json` (copied from `data/generated/lexicon.json`).

## Build

```bash
cd android
# Generate wrapper once if missing:
# gradle wrapper --gradle-version 8.9
./gradlew :app:assembleDebug
```

Install the debug APK, then:

1. Open **Uyghur ULY keyboard** host app → **Open keyboard settings**
2. Enable **Uyghur ULY keyboard**
3. Switch to it from the system keyboard picker while typing

## Privacy

- Suggestions and spell check run on device from the bundled lexicon.
- Personal accepted words stay in app SharedPreferences.
- No network permission is declared for typing.

## Status

Early scaffold — keyboard layout, offline suggestions, and host enable flow. Play Store packaging and signed release APKs come later.
