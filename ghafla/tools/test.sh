#!/usr/bin/env bash
# Lance les tests du jeu : syntaxe, tests unitaires + bot qui traverse le monde, parcours de fumée sur la vraie scène principale.
# Code de sortie 0 si tout passe.  Nécessite Godot 4.4+ ; gdtoolkit (pip install gdtoolkit) est facultatif.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/_godot.sh
require_godot

if command -v gdparse >/dev/null 2>&1; then
  echo "== Syntaxe GDScript =="
  find scripts tests -name '*.gd' -print0 | xargs -0 -n1 gdparse >/dev/null
  echo "ok"
else
  echo "(gdtoolkit absent : vérification de syntaxe ignorée)"
fi

LOG="$(mktemp)"
trap 'rm -f "$LOG"' EXIT
status=0

run_scene() {
  local label="$1" scene="$2" tag="$3"
  echo "== $label =="
  # --fixed-fps : la simulation avance aussi vite que possible au lieu du temps réel
  "$GODOT_BIN" --headless --fixed-fps 60 --path . "$scene" >"$LOG" 2>&1 || true
  grep -E "^\[$tag\]" "$LOG" | grep -v ' ok  ' || true
  if grep -qE "SCRIPT ERROR|Parse Error|Compile Error|^ERROR:" "$LOG"; then
    echo "Erreurs de script dans la sortie de Godot :" >&2
    grep -E -A2 "SCRIPT ERROR|Parse Error|Compile Error|^ERROR:" "$LOG" | head -30 >&2
    status=1
  fi
  if grep -q "ECHEC" "$LOG"; then
    status=1
  fi
  if ! grep -qE "^\[$tag\] [0-9]+ réussis" "$LOG"; then
    echo "Le lot « $label » ne s'est pas terminé." >&2
    status=1
  fi
}

run_scene "Tests (données, sauvegarde, verrous, bot)" res://tests/test_runner.tscn test
run_scene "Parcours de fumée (menu, cinématique, jeu, Mushaf, fin)" res://tests/smoke_runner.tscn smoke

if [ "$status" -ne 0 ]; then
  echo "Des tests ont échoué." >&2
  exit 1
fi
echo "Tout est bon."
