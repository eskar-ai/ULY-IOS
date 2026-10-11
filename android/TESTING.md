# Android testing

Professional quality bar for `cursor/android-uly-keyboard-9edd`.

## Layers

| Layer | Location | Command | Device? |
|-------|----------|---------|---------|
| Unit | `uly-engine/src/test` | `./scripts/run-unit-tests.sh` | No |
| UI (instrumented) | `app/src/androidTest` | `./gradlew :app:connectedDebugAndroidTest` | Yes |
| Build smoke | APK assemble | `./scripts/build-debug.sh` | No |
| CI | `.github/workflows/android-ci.yml` | push to this branch | No |

## Unit coverage (engine)

Must stay green before merging into this branch:

- `UlyNormalizerTest` — case / apostrophe folding
- `PrefixTrieTest` — insert / completions ranking
- `SpellCheckerTest` — corrections map + known words
- `NGramPredictorTest` — bigram vs unigram fallback
- `PersonalDictionaryTest` — learn / clear (no SharedPreferences in JVM)
- `SuggestionEngineTest` — completion / next-word / correction modes

## UI coverage (host)

- `HostMainActivityTest` — try field + settings button visible

IME system UI is hard to Espresso fully; prefer manual checklist in `PLATFORM.md` plus engine unit tests for prediction logic.

## Adding a test

1. Prefer pure JVM unit tests in `uly-engine` for logic.
2. Name `*Test.kt`; one behavior per `@Test`.
3. Run `./scripts/run-unit-tests.sh` and paste result in the PR.
4. Do not skip failing tests — fix or quarantine with a linked issue.

## CI artifacts

On failure, download the Gradle test report from the Actions run (`uly-engine/build/reports/tests/`).
