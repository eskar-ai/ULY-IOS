# Android platform plan

Work for Android stays on **`cursor/android-uly-keyboard-9edd`**. Do not merge to `main` until the platform is release-ready.

## Goals

| Area | Approach |
|------|----------|
| **Package** | Debug/release APK via Gradle; GitHub Releases for sideload; Play Store later |
| **Display** | Host setup activity + IME chrome; Downloads page on site links APK when published |
| **Update** | VersionCode / versionName in `app/build.gradle.kts`; Release notes script; optional in-app “check GitHub Releases” later (no forced telemetry) |
| **Contribute** | `android/CONTRIBUTING.md` + root guidelines; focused PRs against this branch |
| **Scripts** | `android/scripts/*` for lexicon sync, build, unit tests, release notes |
| **Deps** | AndroidX / Material; engine uses `org.json`; pin versions in Gradle |

## Scripts

```bash
./scripts/sync-lexicon.sh      # data/generated → app assets
./scripts/run-unit-tests.sh    # JVM unit tests (uly-engine)
./scripts/build-debug.sh       # debug APK
./scripts/build-release.sh     # release APK
./scripts/package-release-notes.sh 0.1.0
```

## Testing

| Layer | Location | Command |
|-------|----------|---------|
| Unit | `uly-engine/src/test` | `./scripts/run-unit-tests.sh` |
| UI (instrumented) | `app/src/androidTest` | `./gradlew :app:connectedDebugAndroidTest` (device/emulator) |

## Release checklist

1. Sync lexicon; bump `versionCode` / `versionName`.
2. Run unit tests; smoke-test IME on a device.
3. Sign release APK; attach to GitHub Release.
4. Update `store/site/downloads.html` download URL + status strings on this branch.
5. Open/update the Android draft PR (still not merge to `main` until ready).

## Parallel platforms

- iOS / web: `main`
- HarmonyOS NEXT: `cursor/harmonyos-uly-keyboard-9edd`
