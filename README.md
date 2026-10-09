# Uyghur ULY keyboard — Offline Uyghur Latin (ULY) Keyboard for iPhone

System keyboard for **Uyghur Latin Yëziqi (2008)** with offline **prefix suggestions**, **next-word prediction**, and **spell-check / corrections**. Built from public MIT lexicons (UyghurEdit++ imla + imlalughet), converted with `umsc`.

## What’s included

| Path | Description |
|------|-------------|
| `ios/` | Host app + **Custom Keyboard Extension** (XcodeGen) — see [`ios/PLATFORM.md`](ios/PLATFORM.md) |
| `Sources/UyghurLatinKit/` | Shared Swift engine (Trie, spell, n-grams) |
| `web/` | Offline browser playground (same engine in TypeScript) |
| `tools/build_lexicon.py` | Rebuilds `data/generated/lexicon.json` from open sources |
| `data/generated/` | Bundled 120k-word ULY lexicon + corrections + bigrams |
| `store/site/` | Marketing + **Downloads** (GitHub Pages) |

### Platforms (separate branches)

| Platform | Branch | Notes |
|----------|--------|-------|
| iOS / web | `main` | This tree |
| Android | `cursor/android-uly-keyboard-9edd` | Do not merge until release-ready |
| HarmonyOS NEXT | `cursor/harmonyos-uly-keyboard-9edd` | Do not merge until release-ready |

Contributions welcome — see [`CONTRIBUTING.md`](CONTRIBUTING.md).

## Quick demo (web)

**Fixed public demo (always works):**  
https://eskar-ai.github.io/ULY-IOS/demo/

**Downloads hub:**  
https://eskar-ai.github.io/ULY-IOS/downloads.html

Try typing `uygh` or `bugun`. No local server required.

Optional local run (for development only — use the URL Vite prints; do not assume a fixed port):

```bash
cd web
npm install
npm run dev
```

## Install on iPhone (requires Mac + Xcode)

```bash
python3 -m pip install -r tools/requirements.txt
python3 tools/build_lexicon.py   # optional refresh

cd ios
brew install xcodegen            # once
./scripts/generate.sh
open UyghurLatin.xcodeproj
```

1. Select your **Team** for targets `UyghurLatin` and `UyghurLatinKeyboard`.
2. Run on your iPhone.
3. **Settings → General → Keyboard → Keyboards → Add New Keyboard… → Uyghur ULY keyboard**.

The extension sets `RequestsOpenAccess = false`. All prediction and spell-check stay on device.

### Appearance

- **Default: follow system** Light/Dark (same as the stock keyboard).
- On the suggestion bar, tap **◐** to cycle **System → Light → Dark** (stored in the keyboard sandbox).
- Visual style matches the system keyboard: gray chassis, white/dark keycaps, QuickType-style candidates.

> This Cloud Agent environment is Linux and cannot run the iOS Simulator. Use Xcode Simulator / a device on a Mac for native install testing; use the public web demo (`/demo/`) for theme and layout checks.

### Typing tips

- Long-press **e / o / u** → `ë ö ü`
- Long-press **c / s / z / g / n** → `ch sh zh gh ng`
- Tap **ëöü** for digraphs and apostrophe
- Tap the suggestion bar to complete, predict the next word, or apply a correction

## Rebuild lexicon

```bash
pip install -r tools/requirements.txt
python3 tools/build_lexicon.py
```

Copies outputs into `web/public/data/` and `ios/UyghurLatinKeyboard/Resources/`.

## App Store launch pack

Pre-submit materials live in [`store/`](store/):

| File | Purpose |
|------|---------|
| [store/CHECKLIST.md](store/CHECKLIST.md) | Step-by-step launch checklist |
| [store/APP_STORE_LISTING.md](store/APP_STORE_LISTING.md) | EN/ZH listing copy + review notes |
| [store/PRIVACY_POLICY.md](store/PRIVACY_POLICY.md) | Privacy policy draft to host on HTTPS |
| [store/SUPPORT.md](store/SUPPORT.md) | Support URL page draft |
| [store/SCREENSHOTS.md](store/SCREENSHOTS.md) | Screenshot shot list & sizes |
| [store/marketing/app-icon-1024.png](store/marketing/app-icon-1024.png) | App icon master |
| [store/marketing/screenshots/](store/marketing/screenshots/) | 6.7" marketing frames |

Host app UI languages: **English · 简体中文 · ئۇيغۇرچە · Uyghurche (ULY)** (in-app picker; software chrome only — typing stays ULY). Launch background, accent color, and privacy manifests included.

GitHub Pages one-click deploy for marketing/privacy/support: see [`store/site/README.md`](store/site/README.md) (workflow [`.github/workflows/pages.yml`](.github/workflows/pages.yml)).

Run `python3 tools/validate_release.py` before archiving.

**Still on you:** Apple Developer account, signing, upload build. Hosted pages use `mr.askar@icloud.com` ([`store/site/`](store/site/)). See [`store/REMAINING.md`](store/REMAINING.md).

## License & data

App code in this repository is provided for you to use and modify. Lexicon sources remain under their upstream licenses — see [THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md).
