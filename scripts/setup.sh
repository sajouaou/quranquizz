#!/usr/bin/env bash
# Installs everything needed to run Quran Quizz. Usage: ./scripts/setup.sh [--with-server] [--with-cypress]
set -euo pipefail
cd "$(dirname "$0")/.."

need_node=22
if ! command -v node >/dev/null 2>&1; then
  echo "Node.js $need_node+ is required: https://nodejs.org (or: nvm install $need_node)" >&2; exit 1
fi
major=$(node -p 'process.versions.node.split(".")[0]')
if [ "$major" -lt "$need_node" ]; then
  echo "Node.js $need_node+ is required (found $(node -v)). Try: nvm install $need_node" >&2; exit 1
fi

with_server=false; with_cypress=false
for arg in "$@"; do
  case "$arg" in
    --with-server) with_server=true ;;
    --with-cypress) with_cypress=true ;;
    *) echo "Unknown option: $arg" >&2; exit 1 ;;
  esac
done

# NTFS/exFAT/FAT partitions (e.g. /mnt/disk) can't hold symlinks, which npm uses for node_modules/.bin.
supports_symlinks() {
  local probe=".symlink-probe-$$"
  if ln -s package.json "$probe" 2>/dev/null; then rm -f "$probe"; return 0; fi
  rm -f "$probe" 2>/dev/null; return 1
}
npm_flags=()
if ! supports_symlinks; then
  echo "!! This folder's filesystem doesn't support symbolic links ($(df -T . 2>/dev/null | awk 'NR==2 {print $2}'))."
  echo "   Installing without them. For best results, move the project to a Linux (ext4) partition, e.g. ~/IdeaProjects."
  npm_flags+=(--no-bin-links)
fi

echo "==> Installing app dependencies"
if $with_cypress; then npm ci "${npm_flags[@]}"; else CYPRESS_INSTALL_BINARY=0 npm ci "${npm_flags[@]}"; fi
if [ ${#npm_flags[@]} -gt 0 ]; then node scripts/make-bin-shims.cjs; fi

if $with_server; then
  server="../quranquizz_server"
  if [ ! -d "$server" ]; then
    echo "==> Cloning the server next to the app"
    git clone https://github.com/sajouaou/quranquizz_server.git "$server"
  fi
  echo "==> Installing server dependencies"
  (cd "$server" && npm install --no-audit --no-fund)
fi

echo "Done. Start the app with: ./scripts/run.sh dev"
