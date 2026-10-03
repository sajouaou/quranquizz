#!/usr/bin/env python3
"""Sert la version web de Ghafla en local : python3 tools/serve_web.py [dossier] [port]

Un export web ne s'ouvre PAS en double-cliquant sur index.html (le navigateur bloque le chargement du .wasm depuis file://) :
il faut un petit serveur. Aucune dépendance. Ouvre ensuite http://localhost:8060 dans Safari, Chrome ou Firefox.
"""
import http.server
import os
import socketserver
import sys
import webbrowser

root = sys.argv[1] if len(sys.argv) > 1 else os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "export", "web")
port = int(sys.argv[2]) if len(sys.argv) > 2 else 8060
if not os.path.exists(os.path.join(root, "index.html")):
    sys.exit("Pas de index.html dans %s : lance d'abord  tools/web-release.sh build" % os.path.normpath(root))


class Handler(http.server.SimpleHTTPRequestHandler):
    extensions_map = {**http.server.SimpleHTTPRequestHandler.extensions_map, ".wasm": "application/wasm", ".pck": "application/octet-stream", ".js": "text/javascript"}

    def end_headers(self):
        self.send_header("Cache-Control", "no-cache")
        super().end_headers()

    def log_message(self, *args):
        pass


os.chdir(root)
socketserver.TCPServer.allow_reuse_address = True
with socketserver.TCPServer(("", port), Handler) as srv:
    url = "http://localhost:%d" % port
    print("Ghafla (web) : %s   (Ctrl+C pour arrêter)" % url)
    try:
        webbrowser.open(url)
    except Exception:
        pass
    try:
        srv.serve_forever()
    except KeyboardInterrupt:
        pass
