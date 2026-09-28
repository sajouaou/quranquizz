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

echo "==> Installing app dependencies"
if $with_cypress; then npm ci; else CYPRESS_INSTALL_BINARY=0 npm ci; fi

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
