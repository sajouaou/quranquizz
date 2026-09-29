#!/usr/bin/env bash
# Lance les tests du jeu (données, sauvegarde, verrous, bot qui traverse le monde).
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

echo "== Tests dans le moteur =="
# --fixed-fps : la simulation avance aussi vite que possible au lieu du temps réel
"$GODOT_BIN" --headless --fixed-fps 60 --path . res://tests/test_runner.tscn 2>&1 | tee /tmp/ghafla_tests.log | grep -E '^\[test\]' | grep -v ' ok  ' || true
if grep -q 'ECHEC' /tmp/ghafla_tests.log; then
  echo "Des tests ont échoué." >&2
  exit 1
fi
grep -E '^\[test\] [0-9]+ réussis' /tmp/ghafla_tests.log || { echo "Les tests ne se sont pas terminés." >&2; exit 1; }
