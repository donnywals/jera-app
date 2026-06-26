#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
PROJECT="$ROOT/JeraOnAir.xcodeproj"
SCHEME="JeraOnAir"
BUNDLE_ID="com.donnywals.jeraonair"
EXPORT_OPTIONS="$ROOT/ExportOptions.plist"
BUILD_DIR="$ROOT/build"
ARCHIVE_PATH="$BUILD_DIR/JeraOnAir.xcarchive"
IPA_PATH="$BUILD_DIR/JeraOnAir.ipa"

cd "$ROOT"

require_auth() {
  if ! asc auth status --verbose 2>/dev/null | python3 -c "
import sys, json
data = json.load(sys.stdin)
if data.get('credentials'):
    raise SystemExit(0)
if data.get('activeProfile'):
    raise SystemExit(0)
raise SystemExit(1)
"; then
    echo "asc is not authenticated. Run asc auth login first."
    exit 1
  fi
}

resolve_app_id() {
  if [[ -n "${ASC_APP_ID:-}" ]]; then
    echo "$ASC_APP_ID"
    return
  fi

  asc apps list --bundle-id "$BUNDLE_ID" --output json | python3 -c "
import sys, json
items = json.load(sys.stdin).get('data') or []
if not items:
    raise SystemExit('App not found in App Store Connect for bundle id $BUNDLE_ID')
print(items[0]['id'])
"
}

require_auth
APP_ID="$(resolve_app_id)"
echo "Using App Store Connect app ID: $APP_ID"

mkdir -p "$BUILD_DIR"

asc publish testflight \
  --app "$APP_ID" \
  --project "$PROJECT" \
  --scheme "$SCHEME" \
  --configuration Release \
  --export-options "$EXPORT_OPTIONS" \
  --archive-path "$ARCHIVE_PATH" \
  --ipa-path "$IPA_PATH" \
  --archive-xcodebuild-flag=-allowProvisioningUpdates \
  --export-xcodebuild-flag=-allowProvisioningUpdates \
  --wait \
  --notify

echo "TestFlight upload complete for app $APP_ID"
