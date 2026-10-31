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

# Connexion Supabase : les variables d'environnement Netlify, si elles
# existent, remplacent les valeurs par défaut de lib/core/backend/
# supabase_config.dart. Une variable absente ou vide n'est pas transmise,
# pour ne jamais écraser la valeur par défaut par une chaîne vide.
defines=()
for name in SUPABASE_URL SUPABASE_PUBLISHABLE_KEY; do
  if [ -n "${!name:-}" ]; then
    defines+=("--dart-define=$name=${!name}")
    echo "Supabase : $name fourni par l'environnement"
  fi
done

flutter build web --release --base-href /app/ ${defines[@]+"${defines[@]}"}

rm -rf dist
mkdir -p dist
cp -r landing/. dist/
cp -r build/web dist/app

# Adresses publiques (canonique, partage, sitemap) : celle du site déployé.
# Netlify fournit URL : le domaine principal dès qu'il est branché.
if [ -n "${URL:-}" ]; then
  sed -i "s#https://eventa.ci#${URL%/}#g" dist/index.html dist/robots.txt dist/sitemap.xml
fi
