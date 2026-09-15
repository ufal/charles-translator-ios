#!/bin/bash
# Archive, export and (optionally) upload CharlesTranslator to TestFlight.
#
#   Scripts/testflight.sh [build-number]
#
# With no argument the build number in the project is reused as-is. App Store
# Connect rejects a build number it has already seen for the same marketing
# version, so pass the next integer for every upload after the first.
#
# Uploading needs an App Store Connect API key (Users and Access > Integrations):
#   export ASC_KEY_ID=XXXXXXXXXX
#   export ASC_ISSUER_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee
#   # and AuthKey_$ASC_KEY_ID.p8 in ~/.appstoreconnect/private_keys/
# Without those the script stops after writing the .ipa, which can be uploaded
# by hand from Xcode's Organizer.

set -euo pipefail

cd "$(dirname "$0")/.."

PROJECT=CharlesTranslator.xcodeproj
SCHEME=CharlesTranslator
BUILD_DIR=build
ARCHIVE="$BUILD_DIR/CharlesTranslator.xcarchive"
EXPORT_DIR="$BUILD_DIR/export"

BUILD_NUMBER_ARG=()
if [[ $# -ge 1 ]]; then
  BUILD_NUMBER_ARG=("CURRENT_PROJECT_VERSION=$1")
  echo "==> Building as build number $1"
fi

echo "==> Archiving"
rm -rf "$ARCHIVE" "$EXPORT_DIR"
xcodebuild archive \
  -project "$PROJECT" \
  -scheme "$SCHEME" \
  -configuration Release \
  -destination 'generic/platform=iOS' \
  -archivePath "$ARCHIVE" \
  -allowProvisioningUpdates \
  "${BUILD_NUMBER_ARG[@]}"

echo "==> Exporting .ipa"
xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportOptionsPlist ExportOptions.plist \
  -exportPath "$EXPORT_DIR" \
  -allowProvisioningUpdates

IPA=$(find "$EXPORT_DIR" -name '*.ipa' -maxdepth 1 | head -1)
echo "==> Exported $IPA"

if [[ -z "${ASC_KEY_ID:-}" || -z "${ASC_ISSUER_ID:-}" ]]; then
  cat <<MSG

ASC_KEY_ID / ASC_ISSUER_ID are not set, so nothing was uploaded.
Upload $IPA from Xcode > Window > Organizer, or set the two variables and
re-run to have this script do it.
MSG
  exit 0
fi

echo "==> Validating"
xcrun altool --validate-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "==> Uploading to App Store Connect"
xcrun altool --upload-app -f "$IPA" -t ios \
  --apiKey "$ASC_KEY_ID" --apiIssuer "$ASC_ISSUER_ID"

echo "==> Done. The build appears in TestFlight once Apple finishes processing it."
