#!/usr/bin/env bash
# Archive + export IPA with manual provisioning profiles (bypasses Distribute App auto-provisioning API).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ARCHIVE_PATH="$ROOT/build/nobetcim.xcarchive"
EXPORT_PATH="$ROOT/build/export"
EXPORT_PLIST="$ROOT/Config/ExportOptions.plist"

echo "Installing provisioning profiles from Downloads (if present)…"
for profile in "$HOME/Downloads"/Nobetcim*.mobileprovision; do
  [[ -f "$profile" ]] || continue
  open "$profile"
done
sleep 2

echo "Archiving (Release)…"
xcodebuild \
  -project "$ROOT/nobetcim.xcodeproj" \
  -scheme nobetcim \
  -configuration Release \
  -archivePath "$ARCHIVE_PATH" \
  -destination "generic/platform=iOS" \
  DEVELOPMENT_TEAM=8XZ69YB7U5 \
  -allowProvisioningUpdates \
  archive

echo "Exporting for App Store Connect…"
rm -rf "$EXPORT_PATH"
xcodebuild \
  -exportArchive \
  -archivePath "$ARCHIVE_PATH" \
  -exportPath "$EXPORT_PATH" \
  -exportOptionsPlist "$EXPORT_PLIST" \
  -allowProvisioningUpdates

IPA="$(find "$EXPORT_PATH" -name '*.ipa' | head -1)"
echo ""
echo "IPA ready: $IPA"
echo ""
echo "Upload with Transporter app (Mac App Store) or run:"
echo "  xcrun altool --upload-app -f \"$IPA\" -t ios -u YOUR_APPLE_ID -p APP_SPECIFIC_PASSWORD"
echo "Or drag the IPA into Transporter."
