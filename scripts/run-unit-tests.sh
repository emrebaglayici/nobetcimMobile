#!/bin/sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

DESTINATION="${1:-platform=iOS Simulator,name=iPhone 17,OS=26.5}"

echo "Building app + tests..."
xcodebuild build-for-testing \
  -scheme nobetcim \
  -destination "$DESTINATION" \
  -quiet

echo "Running unit tests..."
xcodebuild test-without-building \
  -scheme nobetcim \
  -destination "$DESTINATION" \
  -only-testing:nobetcimTests \
  -parallel-testing-enabled NO

echo "All tests passed."
