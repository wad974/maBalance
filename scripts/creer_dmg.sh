#!/usr/bin/env bash
# Crée dist/MaBalance.dmg à partir de l'app compilée (macOS uniquement).
# Prérequis : flutter build macos --release
set -euo pipefail
cd "$(dirname "$0")/.."

APP="build/macos/Build/Products/Release/Ma Balance.app"
if [ ! -d "$APP" ]; then
  echo "App introuvable : $APP" >&2
  echo "Lance d'abord : flutter build macos --release" >&2
  exit 1
fi

# Sans compte Apple Developer, l'app est signée « ad hoc » (obligatoire
# pour qu'elle démarre sur les Mac Apple Silicon). Flutter le fait déjà ;
# on re-signe seulement si la signature est absente ou invalide.
if ! codesign --verify --deep --strict "$APP" 2>/dev/null; then
  codesign --force --deep --sign - \
    --entitlements macos/Runner/Release.entitlements "$APP"
fi

rm -rf dist
mkdir -p dist/dmg
cp -R "$APP" dist/dmg/
# Raccourci pour installer par glisser-déposer.
ln -s /Applications dist/dmg/Applications

hdiutil create -volname "Ma Balance" -srcfolder dist/dmg \
  -ov -format UDZO dist/MaBalance.dmg
rm -rf dist/dmg
echo "Créé : dist/MaBalance.dmg"
