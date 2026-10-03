#!/usr/bin/env bash
# Trouve le binaire Godot 4 : $GODOT, sinon godot4 / godot dans le PATH, sinon les emplacements usuels.
find_godot() {
  if [ -n "${GODOT:-}" ] && [ -x "$GODOT" ]; then echo "$GODOT"; return 0; fi
  for c in godot4 godot Godot; do
    if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return 0; fi
  done
  for c in "/Applications/Godot.app/Contents/MacOS/Godot" "$HOME/Applications/Godot.app/Contents/MacOS/Godot" \
           "$HOME/.local/bin/godot" /opt/godot/godot /snap/bin/godot-4; do
    if [ -x "$c" ]; then echo "$c"; return 0; fi
  done
  return 1
}

require_godot() {
  GODOT_BIN="$(find_godot)" || {
    echo "Godot 4.4 ou plus récent est introuvable." >&2
    echo "  1. Télécharge-le sur https://godotengine.org/download (version « Standard », pas .NET)" >&2
    echo "  2. Mets-le dans ton PATH, ou lance :  GODOT=/chemin/vers/Godot  $0" >&2
    exit 1
  }
}
