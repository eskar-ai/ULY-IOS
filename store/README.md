# App Store materials

Everything you need before submitting **ULY Künupka**.

## Contents

| Path | What |
|------|------|
| [CHECKLIST.md](CHECKLIST.md) | End-to-end submit checklist |
| [APP_STORE_LISTING.md](APP_STORE_LISTING.md) | EN + 中文 listing copy, keywords, review notes |
| [PRIVACY_POLICY.md](PRIVACY_POLICY.md) | Privacy policy draft (host on HTTPS) |
| [SUPPORT.md](SUPPORT.md) | Support page draft |
| [SCREENSHOTS.md](SCREENSHOTS.md) | Shot list & pixel sizes |
| [marketing/app-icon-1024.png](marketing/app-icon-1024.png) | App icon master (also wired in Xcode) |
| [marketing/screenshots/](marketing/screenshots/) | 6.7" / 6.5" / 6.1" frames |
| [site/](site/) | Multilingual static site + [one-click GitHub Pages](site/README.md) |
| [REMAINING.md](REMAINING.md) | Done vs your action items |
| [AGE_RATING.md](AGE_RATING.md) | Age rating answers |
| [EXPORT_COMPLIANCE.md](EXPORT_COMPLIANCE.md) | Encryption questionnaire |
| [TESTFLIGHT.md](TESTFLIGHT.md) | Beta test instructions |
| [app-store-connect/](app-store-connect/) | Metadata JSON (EN + zh-Hans) |

## Regenerate marketing screenshots

Requires captures under `/opt/cursor/artifacts/screenshots/` (or edit the script paths):

```bash
python3 -m pip install pillow
python3 tools/make_store_screenshots.py
```

Prefer replacing those frames with **real Simulator / device** screenshots before submit (see `SCREENSHOTS.md`).

## Still replace before submit

1. Email placeholders in privacy + support pages  
2. Public HTTPS URLs for Privacy Policy & Support  
3. Bundle ID / Team in Xcode Signing  
4. Real device screenshots if you want photoreal status bars  
