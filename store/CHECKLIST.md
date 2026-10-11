# App Store launch checklist — Uyghur ULY keyboard

See also **[REMAINING.md](REMAINING.md)** (what is already in the repo vs what only you can do).

Run **`python3 tools/validate_release.py`** before archiving.

Work through this before you click **Submit for Review**.

## A. Apple account & identifiers

- [ ] Enrolled in [Apple Developer Program](https://developer.apple.com/programs/) ($99/year)
- [ ] Created App ID in Certificates, Identifiers & Profiles  
  - App: e.g. `org.uyghurlatin.app`  
  - Keyboard extension: e.g. `org.uyghurlatin.app.keyboard` (must be prefixed by the app id)
- [ ] App record created in [App Store Connect](https://appstoreconnect.apple.com)
- [ ] Bundle IDs in Xcode match App Store Connect exactly
- [ ] Team selected for **both** `UyghurLatin` and `UyghurLatinKeyboard` targets

## B. Xcode project readiness

- [ ] `cd ios && xcodegen generate && open UyghurLatin.xcodeproj`
- [ ] Version `MARKETING_VERSION` / build number set (start `1.0.0` / `1`)
- [ ] App Icon 1024×1024 present (`Assets.xcassets/AppIcon.appiconset`)
- [ ] `PrivacyInfo.xcprivacy` present on app + keyboard targets
- [ ] `ITSAppUsesNonExemptEncryption` = false (already in Info.plist)
- [ ] Keyboard `RequestsOpenAccess` = false (already set)
- [ ] Archive on a physical device or “Any iOS Device” succeeds
- [ ] Install TestFlight build on your iPhone and enable the keyboard in Settings

## C. Privacy & legal

- [ ] Enable GitHub Pages (**Settings → Pages → Source: GitHub Actions**) — see [`site/README.md`](site/README.md)
- [x] Contact email set to `mr.askar@icloud.com` in [`site/`](site/)
- [ ] Paste Privacy Policy URL (`https://eskar-ai.github.io/ULY-IOS/privacy.html`) and Support URL (`https://eskar-ai.github.io/ULY-IOS/support.html`) into App Store Connect
- [ ] Complete **App Privacy** questionnaire (recommended: no data collected)
- [ ] Copyright / seller name correct on the store listing

## D. Store listing assets

- [x] App icon 1024×1024 in Xcode + `marketing/app-icon-1024.png`
- [x] Draft screenshots in `marketing/screenshots/` (replace with Simulator captures if desired)
- [ ] Copy from [`APP_STORE_LISTING.md`](APP_STORE_LISTING.md) pasted (name, subtitle, description, keywords)
- [ ] Primary category: Productivity
- [ ] Upload screenshots for required device sizes (see [`SCREENSHOTS.md`](SCREENSHOTS.md))
- [ ] Optional: app preview video
- [x] Host app UI: English · 简体中文 · ئۇيغۇرچە · Uyghurche (ULY); site matches; App Store listing still EN + zh-Hans

## E. Reviewer instructions

- [ ] Paste the “App Review notes” block from `APP_STORE_LISTING.md`
- [ ] Mention that the keyboard must be enabled in iOS Settings after install
- [ ] If review needs a demo account: write **N/A — no account**

## F. Submit

- [ ] Upload build via Xcode Organizer or `Transporter`
- [ ] Select the build in App Store Connect
- [ ] Answer export compliance (encryption: No / uses only exempt encryption)
- [ ] Submit for Review
- [ ] Watch email / Resolution Center for keyboard-related questions

## Common rejection risks (keyboards)

1. **Missing enable steps** in description / review notes → always include Settings path  
2. **Requesting Full Access without clear justification** → keep it off unless you truly need it  
3. **Broken keyboard on launch** → TestFlight smoke test before submit  
4. **Misleading privacy answers** → match the hosted privacy policy  
5. **Empty / placeholder support or privacy URL** → use real HTTPS pages  

## After approval

- [ ] Announce TestFlight → public release phasing if desired  
- [ ] In-app / README note: users must add the keyboard in Settings  
- [ ] Plan 1.0.1 for review feedback or crash fixes
