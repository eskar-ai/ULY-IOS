# What is done vs what only you can do

## Already in the repository

| Area | Status |
|------|--------|
| iOS app + keyboard extension source | Done |
| Offline lexicon (~120k ULY words) | Done |
| App icon 1024 + Xcode asset catalog | Done |
| Privacy manifests (app + extension) | Done |
| Host UI: EN · 简体中文 · ئۇيغۇرچە · Uyghurche (ULY) | Done (in-app picker) |
| App Store listing copy (EN + 中文) | [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md) |
| Privacy / support site (4 languages) + Pages workflow | [`site/`](site/), [`.github/workflows/pages.yml`](../.github/workflows/pages.yml) |
| Marketing screenshots 6.7" + resized 6.1"/6.5" | [`marketing/screenshots/`](marketing/screenshots/) |
| TestFlight notes, age rating, export compliance guides | `TESTFLIGHT.md`, `AGE_RATING.md`, `EXPORT_COMPLIANCE.md` |
| Archive helper | [`../ios/ExportOptions.plist`](../ios/ExportOptions.plist) |
| Release validator | [`../tools/validate_release.py`](../tools/validate_release.py) |

## You must do on Apple’s side (cannot be automated here)

1. **Apple Developer Program** enrollment ($99/year)  
2. **Register Bundle IDs** matching `org.uyghurlatin.app` and `org.uyghurlatin.app.keyboard`  
3. **Xcode Signing → Team** on both targets  
4. **Paste HTTPS URLs into App Store Connect** (site is live):  
   - Privacy: `https://eskar-ai.github.io/ULY-IOS/privacy.html`  
   - Support: `https://eskar-ai.github.io/ULY-IOS/support.html`  
   - Contact email on site: `mr.askar@icloud.com`  
5. **Archive & upload** build (Xcode Organizer or Transporter)  
6. **App Store Connect** questionnaire (privacy, age rating, export) — answers in `AGE_RATING.md` / `EXPORT_COMPLIANCE.md`  
7. **Optional but recommended:** replace marketing screenshots with Simulator/device captures before final submit  

## Recommended order

1. `python3 tools/validate_release.py`  
2. `cd ios && xcodegen generate && open UyghurLatin.xcodeproj`  
3. Run on your iPhone → enable keyboard → smoke test  
4. Publish `store/site/` → set Privacy + Support URLs  
5. TestFlight internal → external testers  
6. Submit for review using [`CHECKLIST.md`](CHECKLIST.md)
