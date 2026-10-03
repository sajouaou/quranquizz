#!/usr/bin/env python3
"""Récupère la traduction des versets cités par le jeu et l'écrit dans locales/<langue>/verses.json.

Le jeu ne cite que quelques versets (ceux de data/dialogue*.json, champ meaning.ref). Leur traduction n'est jamais
écrite à la main : elle est copiée telle quelle depuis une édition publiée, puis citée avec le nom du traducteur.
  - français : Muhammad Hamidullah (texte diffusé par tanzil.net)
  - anglais  : The Clear Quran, Dr Mustafa Khattab

Sources :
  - français : API publique de quran.com (traduction n° 31, ponctuation d'origine) ;
  - anglais  : https://github.com/fawazahmed0/quran-api (édition eng-mustafakhattaba ; quran.com ne diffuse plus cette traduction).
    Cette édition ne garde pas la ponctuation finale de chaque verset : le texte est repris tel qu'elle le fournit.
Quand la référence couvre plusieurs versets, chacun est précédé de son numéro entre parenthèses.
À VÉRIFIER AVANT PUBLICATION : les conditions d'utilisation de chaque traduction (The Clear Quran est une œuvre
sous droit d'auteur : demander l'autorisation de l'éditeur pour une diffusion publique).

Usage : python3 tools/fetch_translations.py
"""
import json
import os
import re
import urllib.request

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
API = "https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions/%s/%d.json"
QURAN_COM = "https://api.quran.com/api/v4/quran/translations/%d?chapter_number=%d"
EDITIONS = {
    "fr": {"quran_com": 31, "translator": "Muhammad Hamidullah", "title": "Le Saint Coran, traduction de Muhammad Hamidullah"},
    "en": {"edition": "eng-mustafakhattaba", "translator": "Dr. Mustafa Khattab", "title": "The Clear Quran, Dr. Mustafa Khattab"},
}
# ˹ ˺ encadrent les mots ajoutés par le traducteur ; la police du jeu n'a pas ces signes : ils deviennent des crochets [ ].
BRACKETS = {"\u02f9": "[", "\u02fa": "]"}


def refs():
    out = []
    for name in ("dialogue.json", "dialogue_2.json"):
        with open(os.path.join(ROOT, "data", name), encoding="utf-8") as f:
            for r in json.load(f)["reactions"].values():
                if "meaning" in r and r["meaning"]["ref"] not in out:
                    out.append(r["meaning"]["ref"])
    return out


_cache = {}


def _get(url):
    req = urllib.request.Request(url, headers={"User-Agent": "ghafla-tools/1.0"})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return json.load(resp)


def chapter(ed, sid):
    key = (ed["translator"], sid)
    if key not in _cache:
        if "quran_com" in ed:
            rows = _get(QURAN_COM % (ed["quran_com"], sid))["translations"]  # dans l'ordre des versets
            _cache[key] = {i + 1: re.sub(r"<sup[^>]*>.*?</sup>|<[^>]+>", "", r["text"]) for i, r in enumerate(rows)}
        else:
            _cache[key] = {int(v["verse"]): v["text"] for v in _get(API % (ed["edition"], sid))["chapter"]}
    return _cache[key]


def text_of(ed, ref):
    sid, span = ref.split(":")
    a, _, b = span.partition("-")
    verses = chapter(ed, int(sid))
    nums = list(range(int(a), int(b or a) + 1))
    parts = [verses[v].strip() if len(nums) == 1 else "(%d) %s" % (v, verses[v].strip()) for v in nums]
    text = " ".join(parts)
    for ch, rep in BRACKETS.items():
        text = text.replace(ch, rep)
    return " ".join(text.split())


def main():
    for lang, ed in EDITIONS.items():
        doc = {
            "_comment": "Traduction des versets cités, copiée telle quelle (tools/fetch_translations.py). Ne pas modifier à la main.",
            "translator": ed["translator"],
            "title": ed["title"],
            "verses": {ref: text_of(ed, ref) for ref in refs()},
        }
        path = os.path.join(ROOT, "locales", lang, "verses.json")
        with open(path, "w", encoding="utf-8") as f:
            json.dump(doc, f, ensure_ascii=False, indent=1)
        print("%s : %d versets -> %s" % (lang, len(doc["verses"]), os.path.normpath(path)))


if __name__ == "__main__":
    main()
