#!/usr/bin/env bash
# Lance le jeu depuis les sources.  Usage : tools/run.sh [--fullscreen]
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/_godot.sh
require_godot
exec "$GODOT_BIN" --path . "$@"
