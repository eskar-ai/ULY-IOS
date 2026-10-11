#!/usr/bin/env bash
# Print a GitHub Release body stub for Android APKs.
set -euo pipefail
VERSION="${1:-0.1.0}"
cat <<EOF
## Uyghur ULY keyboard for Android ${VERSION}

Offline Uyghur Latin (ULY) system keyboard.

### Install
1. Download the APK for your ABI (or universal).
2. Allow install from this source if prompted.
3. Open the host app → enable the keyboard in system settings.
4. Switch to **Uyghur ULY keyboard** while typing.

### Privacy
Typing, suggestions, and spell check stay on device.

### Source
https://github.com/eskar-ai/ULY-IOS/tree/cursor/android-uly-keyboard-9edd/android

### Contribute
See \`android/CONTRIBUTING.md\` on this branch.
EOF
