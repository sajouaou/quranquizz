#!/usr/bin/env python3
"""Télécharge le texte des pages du Mushaf pour l'embarquer dans le jeu (facultatif).

Par défaut le jeu n'embarque AUCUN texte coranique : il le télécharge une fois par page, à la demande,
quand le joueur est en ligne (core/quran_text.gd), et le garde en cache. Ce script sert à préparer une
version qui fonctionne entièrement hors ligne : il écrit data/mushaf_text/page_XXX.json à partir de
l'API publique de quran.com (texte ʿuthmānī, Médine, 604 pages).

Le texte est copié tel quel, sans modification. Il est ignoré par git (voir .gitignore) : à toi de
vérifier les conditions d'utilisation de la source avant de redistribuer une version qui l'embarque
(https://quran.com, https://tanzil.net/docs/text_license) et de la citer dans le jeu.

Usage :
    python3 tools/fetch_mushaf_text.py               # les pages placées dans le prototype
    python3 tools/fetch_mushaf_text.py --all         # les 604 pages
    python3 tools/fetch_mushaf_text.py --pages 1 322 # des pages précises
"""
import argparse
import json
import os
import sys
import time
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
OUT = os.path.join(ROOT, "data", "mushaf_text")
API = "https://api.quran.com/api/v4/quran/verses/uthmani?page_number=%d"


def placed_pages():
    with open(os.path.join(ROOT, "data", "world_pages.json"), encoding="utf-8") as f:
        return sorted(int(p["page"]) for p in json.load(f)["pages"])


def fetch(page):
    req = urllib.request.Request(API % page, headers={"User-Agent": "ghafla-tools/1.0"})
    with urllib.request.urlopen(req, timeout=20) as resp:
        data = json.load(resp)
    verses = [{"key": v["verse_key"], "text": v["text_uthmani"]} for v in data["verses"]]
    if not verses:
        raise ValueError("page vide")
    return {"page": page, "verses": verses}


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--all", action="store_true", help="télécharger les 604 pages")
    ap.add_argument("--pages", type=int, nargs="+", help="numéros de pages")
    ap.add_argument("--force", action="store_true", help="retélécharger même si le fichier existe")
    args = ap.parse_args()
    pages = list(range(1, 605)) if args.all else (args.pages or placed_pages())
    os.makedirs(OUT, exist_ok=True)
    failed = []
    for p in pages:
        path = os.path.join(OUT, "page_%03d.json" % p)
        if os.path.exists(path) and not args.force:
            continue
        for attempt in range(3):
            try:
                doc = fetch(p)
                with open(path, "w", encoding="utf-8") as f:
                    json.dump(doc, f, ensure_ascii=False)
                print("page %3d : %d versets" % (p, len(doc["verses"])))
                break
            except Exception as e:  # réseau, quota, page inattendue
                if attempt == 2:
                    print("page %3d : échec (%s)" % (p, e), file=sys.stderr)
                    failed.append(p)
                else:
                    time.sleep(1.5 * (attempt + 1))
        time.sleep(0.15)
    if failed:
        print("Pages en échec :", failed, file=sys.stderr)
        return 1
    print("Terminé : %s" % os.path.normpath(OUT))
    return 0


if __name__ == "__main__":
    sys.exit(main())
