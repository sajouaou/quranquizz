#!/usr/bin/env bash
# Version web de Ghafla : fonctionne dans Safari, Chrome, Firefox, sur Mac, Windows, Linux, iPhone/iPad et Android, sans rien installer.
#
#   tools/web-release.sh build    export dans export/web/ + archive export/Ghafla-web.zip (à envoyer sur un hébergeur)
#   tools/web-release.sh serve    sert export/web en local sur http://localhost:8060
#   tools/web-release.sh all      build puis serve
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/_godot.sh

cmd_build() {
  require_godot
  mkdir -p export/web
  rm -f export/web/index.*
  echo "== Export web =="
  "$GODOT_BIN" --headless --path . --export-release "Web" export/web/index.html
  [ -f export/web/index.html ] || { echo "Erreur : l'export a échoué (modèles d'export installés ? tools/android-release.sh templates)" >&2; exit 1; }
  rm -f export/Ghafla-web.zip
  (cd export/web && zip -q -r ../Ghafla-web.zip .)
  ls -lh export/Ghafla-web.zip
  echo "Dossier : export/web   Archive : export/Ghafla-web.zip   (voir docs/WEB.md pour l'héberger)"
}

case "${1:-}" in
  build) cmd_build ;;
  serve) exec python3 tools/serve_web.py ;;
  all) cmd_build; exec python3 tools/serve_web.py ;;
  *) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
