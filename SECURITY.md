# Security policy

## Supported surfaces

| Surface | Location | Notes |
|---------|----------|-------|
| iOS keyboard / host | `ios/` · `Sources/` | No Full Access by default |
| Web demo | `web/` | Offline lexicon in browser |
| Android IME | `android/` | No network permission for typing |
| HarmonyOS IME | `harmonyos/` | On-device suggestions |

## Reporting a vulnerability

Email **mr.askar@icloud.com** with:

1. Affected platform and version / commit
2. Impact (e.g. keystroke exfiltration, malicious update channel)
3. Reproduction steps

Please **do not** open a public issue for exploitable keyboard/privacy flaws until we have a fix or mitigation.

## Hard rules for contributors

- Do not add analytics, ads, or keystroke upload.
- Do not request unnecessary IME “full access” / broad network for prediction.
- Do not commit signing keys, keystores, profiles, or tokens.
