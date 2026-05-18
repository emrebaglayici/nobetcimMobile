#!/bin/sh
set -euo pipefail

# Fails Release builds when API key is missing (local + CI).
if [ "${CONFIGURATION:-}" != "Release" ]; then
  exit 0
fi

KEY="${NOBETECZA_API_KEY:-}"
KEY="$(printf '%s' "$KEY" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')"

if [ -z "$KEY" ] || [ "$KEY" = "\$(NOBETECZA_API_KEY)" ]; then
  SECRETS_FILE="${SRCROOT:-.}/Config/Secrets.xcconfig"
  if [ -f "$SECRETS_FILE" ]; then
    KEY="$(grep '^NOBETECZA_API_KEY' "$SECRETS_FILE" | head -1 | sed 's/^[^=]*=[[:space:]]*//;s/[[:space:]]*$//')"
  fi
fi

if [ -z "$KEY" ] || [ "$KEY" = "your_nobetecza_api_key_here" ] || [ "$KEY" = "YOUR_API_KEY_HERE" ]; then
  echo "error: NOBETECZA_API_KEY is not configured for Release."
  echo "  Local: run ./scripts/setup-secrets.sh and set Config/Secrets.xcconfig"
  echo "  Xcode Cloud: add workflow secret NOBETECZA_API_KEY"
  exit 1
fi
