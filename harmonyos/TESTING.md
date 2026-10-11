# HarmonyOS NEXT testing

Professional quality bar for `cursor/harmonyos-uly-keyboard-9edd`.

## Layers

| Layer | Location | Command | Device / DevEco? |
|-------|----------|---------|------------------|
| Smoke (CI) | `scripts/run-engine-smoke.mjs` | `./scripts/run-unit-tests.sh` | No |
| Unit (Hypium) | `uly_engine/src/test/ets` | DevEco → Run Tests | Yes |
| UI / Ability | `entry/src/ohosTest` | DevEco → ohosTest | Yes |
| CI | `.github/workflows/harmonyos-ci.yml` | push to this branch | No |

## Hypium coverage (engine)

- `Uly.test.ets` — lookupKey, trie, SuggestionEngine modes
- `SpellNGram.test.ets` — SpellChecker, NGramPredictor, PersonalDictionary

## Ability smoke

- `HostAbility.test.ets` — ability delegator available

## Adding a test

1. Prefer Hypium cases next to engine modules for logic.
2. Keep CI smoke (`run-engine-smoke.mjs`) green — it gates PRs without DevEco.
3. Document manual IME checks in `PLATFORM.md` when UI cannot be automated.

## CI artifacts

Actions logs show Node smoke JSON (`ok: true`, wordCount, sample prefixes).
