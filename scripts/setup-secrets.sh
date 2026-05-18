#!/bin/sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SECRETS="$ROOT/Config/Secrets.xcconfig"
EXAMPLE="$ROOT/Config/Secrets.xcconfig.example"
PLIST_EXAMPLE="$ROOT/nobetcim/NobetcimConfig.example.plist"
PLIST="$ROOT/nobetcim/NobetcimConfig.plist"

if [ ! -f "$SECRETS" ]; then
  cp "$EXAMPLE" "$SECRETS"
  echo "Created $SECRETS — set NOBETECZA_API_KEY before building."
else
  echo "Secrets file already exists: $SECRETS"
fi

if [ ! -f "$PLIST" ] && [ -f "$PLIST_EXAMPLE" ]; then
  cp "$PLIST_EXAMPLE" "$PLIST"
  echo "Created $PLIST from example — optional fallback if xcconfig is not used."
fi
