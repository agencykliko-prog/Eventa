#!/usr/bin/env bash
# Build Netlify : landing à la racine, application Flutter sous /app/.
set -euo pipefail

FLUTTER_VERSION="3.47.8"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -x "$HOME/flutter/bin/flutter" ]; then
    git clone --depth 1 --branch "$FLUTTER_VERSION" https://github.com/flutter/flutter.git "$HOME/flutter"
  fi
  export PATH="$HOME/flutter/bin:$PATH"
fi

flutter config --no-analytics >/dev/null
flutter pub get
flutter build web --release --base-href /app/

rm -rf dist
mkdir -p dist
cp -r landing/. dist/
cp -r build/web dist/app
