# Security policy

## Supported surfaces

| Surface | Branch | Notes |
|---------|--------|-------|
| iOS keyboard / host | `main` | No Full Access by default |
| Web demo | `main` (`web/`) | Offline lexicon in browser |
| Android IME | `cursor/android-uly-keyboard-9edd` | No network permission for typing |
| HarmonyOS IME | `cursor/harmonyos-uly-keyboard-9edd` | On-device suggestions |

## Reporting a vulnerability

Email **mr.askar@icloud.com** with:

1. Affected platform and version / commit
2. Impact (e.g. keystroke exfiltration, malicious update channel)
3. Reproduction steps

Please **do not** open a public issue for exploitable keyboard/privacy flaws until we have a fix or mitigation.

## Hard rules for contributors

- Do not add analytics, ads, or keystroke upload.
<<<<<<< HEAD
- Do not request unnecessary broad network for prediction.
- Do not commit signing keys, profiles, or tokens.
=======
- Do not request unnecessary IME “full access” / broad network for prediction.
- Do not commit signing keys, keystores, or tokens.
>>>>>>> e871523 (Android: expand engine tests and professional quality ecosystem)
