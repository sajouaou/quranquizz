#!/usr/bin/env bash
# Exporte le jeu dans export/.  Usage : tools/export.sh [linux|windows|web|mac|ios|android-apk|android-aab|all]  (mac, ios : voir aussi tools/apple-release.sh)
# Prérequis : les modèles d'export de Godot (Éditeur > Gérer les modèles d'export), et pour Android le SDK
# et une clé de signature (variables GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD, jamais dans git).
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/_godot.sh
require_godot
mkdir -p export

target="${1:-all}"
build() {
  local preset="$1" out="$2"
  echo "== $preset -> $out =="
  "$GODOT_BIN" --headless --path . --export-release "$preset" "$out"
}

case "$target" in
  linux) build "Linux" export/ghafla-linux.x86_64 ;;
  windows) build "Windows" export/ghafla-windows.exe ;;
  mac) tools/apple-release.sh mac ;;
  ios) tools/apple-release.sh ios ;;
  web) mkdir -p export/web && build "Web" export/web/index.html ;;
  android-apk) build "Android APK" export/ghafla.apk ;;
  android-aab) build "Android AAB" export/ghafla.aab ;;
  all)
    build "Linux" export/ghafla-linux.x86_64
    build "Windows" export/ghafla-windows.exe
    ;;
  *) echo "Cible inconnue : $target" >&2; exit 2 ;;
esac
echo "Terminé. Fichiers dans $(pwd)/export"
