# Relire et traduire les textes

Aucun texte affiché n'est écrit dans le code : tout est dans `locales/<langue>/`. Le français (`fr`) est la langue de référence,
l'anglais (`en`) est fourni comme exemple complet.

```
locales/
  languages.json        langues proposées dans Réglages (code + nom affiché)
  fr/
    ui.json             menus, boutons, HUD, pause, réglages, note « histoire imaginée », carte de fin, Mushaf
    world.json          invites (« Ouvrir la porte »), messages du monde, indices des sceaux
    cinematic.json      sous-titres des deux cinématiques
    dialogue_1.json     scènes et pensées du chapitre 1
    dialogue_2.json     scènes et pensées du chapitre 2
    verses.json         traduction publiée des versets cités : NE PAS modifier à la main (voir plus bas)
    surahs.json         noms des sourates (titres, pas du texte coranique)
  en/ …                 mêmes fichiers, traduits
```

## Relire le français

Ouvrir le fichier voulu dans n'importe quel éditeur : chaque ligne est `"clé": "texte"`. Corriger le texte, jamais la clé.
Les `{repères}` (par exemple `{count}`, `{total}`) sont remplacés par le jeu : les garder tels quels, mais on peut les déplacer dans la phrase.

Les `dialogue_N.json` sont rangés par scène :

- `triggers` : pensées déclenchées en avançant dans le monde (clé = identifiant de la scène) ;
- `reactions` : ce que dit le personnage en prenant une page. `lines` sont ses pensées (le verset cité juste avant vient de `verses.json`), `pool` des murmures tirés à tour de rôle, `objective` la consigne affichée en haut de l'écran.

Où chaque scène se déclenche (position, style) est dans `data/dialogue.json` et `data/dialogue_2.json` : ces fichiers ne contiennent aucun texte à traduire.

## Versets cités

Les versets que le personnage lit en prenant une page ne sont jamais traduits à la main : `tools/fetch_translations.py` copie une traduction
publiée dans `locales/<langue>/verses.json`, et le jeu affiche la sourate, la référence et le nom du traducteur.

| Langue | Traduction | Source utilisée par le script |
|---|---|---|
| français | Muhammad Hamidullah | API de quran.com (traduction n° 31) |
| anglais | The Clear Quran, Dr Mustafa Khattab | github.com/fawazahmed0/quran-api (édition `eng-mustafakhattaba`) |

À savoir : l'édition anglaise de cette source ne garde pas la ponctuation finale de chaque verset, et les signes ˹ ˺ (mots ajoutés par le traducteur)
sont remplacés par des crochets `[ ]`, faute de glyphes dans la police. Quand une référence couvre plusieurs versets, chacun est précédé de son numéro.
**Avant toute publication**, vérifier les droits : The Clear Quran est sous droit d'auteur (demander l'autorisation de l'éditeur), et comparer le texte avec une édition imprimée.

Pour une nouvelle langue : ajouter son édition dans `EDITIONS` du script, puis `python3 tools/fetch_translations.py`. Sans `verses.json`, les versets s'affichent en français.

## Ajouter une langue

1. Copier le dossier `locales/fr/` vers `locales/<code>/` (par exemple `es`, `tr`, `id`).
2. Traduire les valeurs de tous les fichiers (pas les clés, pas les `{repères}`).
3. Ajouter `{"code": "es", "name": "Español", "choose": "Elige tu idioma"}` dans `locales/languages.json` (`choose` est la question posée au premier démarrage).
4. Lancer `tools/test.sh` : le test refuse une langue incomplète (clé manquante, `{repère}` différent, scène avec un nombre de lignes différent).

Une clé absente d'une langue retombe sur le français : on peut donc traduire par étapes. Au tout premier démarrage le jeu demande la langue ;
elle se change ensuite dans les Réglages, depuis le menu principal comme depuis la pause.

## Limites

- **Polices** : Amiri couvre le latin (étendu) et l'arabe. Pour le cyrillique, le grec, le chinois, etc., ajouter une police de repli dans `scripts/core/assets.gd`.
- **Texte du Mushaf** : il vient d'une source en ligne (voir `docs/BUILD.md`), pas de ces fichiers.
- Le titre arabe du jeu, le mot « سورة » et les noms arabes des sourates restent dans le code et les données : le test « adab » refuse tout autre texte arabe.
- L'aide à la lecture de droite à gauche (arabe, hébreu) n'est pas mise en page spécialement : à vérifier si l'on ajoute une telle langue.
