#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
BUNDLE_ID="com.donnywals.jeraonair"
APP_NAME="Jera On Air"
SKU="jeraonair-timetable-2026"
PRIMARY_LOCALE="en-US"

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

bundle_id_resource_id() {
  asc bundle-ids list --output json | python3 -c "
import sys, json
target = '$BUNDLE_ID'
for item in json.load(sys.stdin).get('data', []):
    if item.get('attributes', {}).get('identifier') == target:
        print(item['id'])
        raise SystemExit(0)
raise SystemExit(1)
"
}

create_bundle_id_if_needed() {
  if bundle_id_resource_id >/dev/null 2>&1; then
    echo "Bundle ID already registered: $BUNDLE_ID"
    return
  fi

  echo "Creating bundle ID $BUNDLE_ID"
  asc bundle-ids create --identifier "$BUNDLE_ID" --name "$APP_NAME" --platform IOS
}

create_app_if_needed() {
  if asc apps list --bundle-id "$BUNDLE_ID" --output json | python3 -c "import sys,json; raise SystemExit(0 if json.load(sys.stdin).get('data') else 1)"; then
    echo "App Store Connect app already exists for $BUNDLE_ID"
    asc apps list --bundle-id "$BUNDLE_ID" --output table
    return
  fi

  local bundle_resource_id
  bundle_resource_id="$(bundle_id_resource_id)"
  local token
  token="$(asc auth token)"

  echo "Creating App Store Connect app record for $BUNDLE_ID"
  curl -sfS -X POST "https://api.appstoreconnect.apple.com/v1/apps" \
    -H "Authorization: Bearer ${token}" \
    -H "Content-Type: application/json" \
    -d "$(python3 -c "
import json
print(json.dumps({
  'data': {
    'type': 'apps',
    'attributes': {
      'name': '$APP_NAME',
      'sku': '$SKU',
      'primaryLocale': '$PRIMARY_LOCALE'
    },
    'relationships': {
      'bundleId': {
        'data': {
          'type': 'bundleIds',
          'id': '$bundle_resource_id'
        }
      }
    }
  }
}))
")" >/dev/null

  asc apps list --bundle-id "$BUNDLE_ID" --output table
}

require_auth
create_bundle_id_if_needed
create_app_if_needed
