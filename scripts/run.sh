#!/usr/bin/env bash
# Runs Quran Quizz. Usage: ./scripts/run.sh <command>
#   dev        app on http://localhost:5173 (online mode uses the public server)
#   dev-local  app + local multiplayer server (../quranquizz_server) on port 5000
#   host       app reachable from other devices on the network (phones on the same Wi-Fi)
#   build      production build in dist/
#   preview    build then serve dist/ (offline mode / service worker)
#   test       lint + unit tests
#   android    build, sync and open Android Studio
set -euo pipefail
cd "$(dirname "$0")/.."
[ -d node_modules ] || ./scripts/setup.sh

case "${1:-dev}" in
  dev) npm run dev ;;
  host) npm run dev -- --host ;;
  dev-local)
    server="../quranquizz_server"
    [ -d "$server/node_modules" ] || ./scripts/setup.sh --with-server
    (cd "$server" && PORT=5000 node index.js) &
    server_pid=$!
    trap 'kill $server_pid 2>/dev/null' EXIT INT TERM
    VITE_SERVER_URL=ws://localhost:5000 npm run dev
    ;;
  build) npm run build ;;
  preview) npm run build && npx vite preview --host ;;
  test) npm run lint && npm run test.unit ;;
  android) npm run android ;;
  *) sed -n '2,11p' "$0"; exit 1 ;;
esac
