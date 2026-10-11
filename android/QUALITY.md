# Android quality bar

How this branch should look to reviewers: **professional, clean, responsible**.

## Checklist (PR to this branch)

- [ ] `./scripts/run-unit-tests.sh` passes
- [ ] `./scripts/sync-lexicon.sh` if lexicon changed
- [ ] No secrets / keystores / `local.properties` committed
- [ ] No ads, analytics, or new network permissions for typing
- [ ] Public strings stay clear; prefer four UI languages when adding host copy
- [ ] `PLATFORM.md` / `TESTING.md` updated if workflows change
- [ ] Diff stays scoped to Android (avoid unrelated `ios/` / `web/` churn)

## Repository hygiene

| Item | Expectation |
|------|-------------|
| Modules | `uly-engine` (logic) vs `app` (IME/UI) — keep boundaries |
| Scripts | All release/test entrypoints under `scripts/` |
| CI | `android-ci.yml` must stay green on this branch |
| Docs | README → PLATFORM → TESTING → CONTRIBUTING |

## Responsible defaults

- Typing stays on-device.
- Personal dictionary is local-only.
- Releases are explicit (version bump + notes script); no silent auto-update spyware.
