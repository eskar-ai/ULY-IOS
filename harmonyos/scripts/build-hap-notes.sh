#!/usr/bin/env bash
# Print DevEco HAP build reminders and a Release body stub.
set -euo pipefail
VERSION="${1:-0.1.0}"
cat <<EOF
## Build HAP (DevEco Studio)

1. Open the \`harmonyos/\` folder in DevEco Studio (HarmonyOS NEXT SDK).
2. File → Sync / ohpm install
3. Configure signing (debug or release profile).
4. Build → Build Hap(s) / App(s)
5. Output typically under \`harmonyos/entry/build/default/outputs/\`

## Release notes stub — Uyghur ULY keyboard for HarmonyOS ${VERSION}

Offline Uyghur Latin (ULY) input method for HarmonyOS NEXT.

### Install
1. Sideload the signed HAP (or install from the store when listed).
2. Enable **Uyghur ULY keyboard** in system keyboard settings.
3. Switch to it while typing.

### Privacy
Typing and suggestions stay on device.

### Source
https://github.com/eskar-ai/ULY-IOS/tree/cursor/harmonyos-uly-keyboard-9edd/harmonyos

### Contribute
See \`harmonyos/CONTRIBUTING.md\` on this branch.
EOF
