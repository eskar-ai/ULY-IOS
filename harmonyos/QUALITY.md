# HarmonyOS quality bar

How this branch should look to reviewers: **professional, clean, responsible**.

## Checklist (PR to this branch)

- [ ] `./scripts/run-unit-tests.sh` passes (Node smoke)
- [ ] Hypium / ohosTest run in DevEco when changing engine or host UI
- [ ] No signing materials / `local.properties` committed
- [ ] No ads, analytics, or keystroke upload
- [ ] `PLATFORM.md` / `TESTING.md` updated if workflows change
- [ ] Diff stays scoped to HarmonyOS (avoid unrelated Android/iOS churn)

## Repository hygiene

| Item | Expectation |
|------|-------------|
| Modules | `uly_engine` (HAR) vs `ime` vs `entry` — clear boundaries |
| Scripts | Release/test entrypoints under `scripts/` |
| CI | `harmonyos-ci.yml` must stay green on this branch |
| Docs | README → PLATFORM → TESTING → QUALITY → CONTRIBUTING |

## Responsible defaults

- Typing stays on-device.
- HAP / AppGallery updates are explicit; no silent telemetry.
- Downloads page never pretends a HAP is “tap-to-install” without channel notes.
