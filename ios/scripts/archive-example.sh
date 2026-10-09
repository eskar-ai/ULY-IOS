#!/usr/bin/env bash
# Example: archive and upload after XcodeGen + signing are configured.
set -euo pipefail
cd "$(dirname "$0")/.."
xcodegen generate
SCHEME=UyghurLatin
ARCHIVE="./build/UyghurLatin.xcarchive"
xcodebuild -scheme "$SCHEME" -configuration Release -archivePath "$ARCHIVE" archive
xcodebuild -exportArchive -archivePath "$ARCHIVE" -exportOptionsPlist ExportOptions.plist -exportPath ./build/export
echo "Upload build/export/*.ipa via Transporter or Xcode Organizer."
