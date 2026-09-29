# Ghafla — غفلة

Prototype d'un jeu de rêve, en 2D, pour **PC (surtout) et Android**, fait avec **Godot 4**.

> **Ghafla est une fiction.** Le personnage, son rêve et les lieux sont inventés pour illustrer une idée : la négligence
> peut nous gagner sans bruit, et il n'est jamais trop tard pour revenir. Ce n'est ni un enseignement religieux, ni un
> avis sur la pratique de qui que ce soit. Le jeu ne juge personne et ne se moque de rien.

## L'histoire

Un homme lit le Coran et s'endort. Un autre homme, dont on ne voit pas le visage, voit le Mushaf, ne l'ouvre pas et s'endort.
Il se réveille en sursaut, le soleil est dans sa chambre : il a manqué Fajr. Il prend le Mushaf : **les pages sont blanches**.
Dehors, le monde est devenu un rêve. Il faut retrouver les pages du Mushaf, une à une. La première est devant la porte : Al-Anbya.
Il comprend sa négligence et décide de tout retrouver.

- Le Mushaf est toujours sur soi : les pages retrouvées sont dorées, les pages manquantes sont blanches.
- Des pages sont **cachées** (rester immobile, toucher une veine de lumière, attendre un événement) ou **verrouillées** (coffre, sceaux).
- Chaque page est liée à son lieu : Al-Kahf entière dans une grotte, At-Takathur et Al-Humazah dans un souk, et le personnage réagit
  à chacune (par exemple le regret d'avoir délaissé Al-Kahf le vendredi).

Détails : [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md) · [docs/PAGES.md](docs/PAGES.md) · [docs/CINEMATIC.md](docs/CINEMATIC.md) · [docs/BUILD.md](docs/BUILD.md)

## Lancer

Installer **Godot 4.4+** (https://godotengine.org/download), puis :

```bash
tools/run.sh          # Linux, macOS
.\tools\run.ps1       # Windows
```

(ou ouvrir ce dossier dans l'éditeur Godot). Rien à importer : le projet démarre tel quel.

Touches : flèches ou Q/D pour marcher, Espace pour sauter, E pour agir, M pour le Mushaf, Échap pour la pause. Manette et tactile pris en charge.

## Tester et exporter

```bash
tools/test.sh                 # données, sauvegarde, verrous, bot qui traverse le monde
tools/export.sh linux         # ou windows, web, android-apk, android-aab
```

## État du prototype

| | |
|---|---|
| Cinématique | complète (~2 min, passable) |
| Monde | maison avec escalier, rue, pont de nuages, souk, grotte, montée et sommet |
| Pages | **19 sur 604** placées ; le reste est à construire |
| Mushaf en jeu | livre, vue d'ensemble (604 cases), liste des sourates |
| Sauvegarde | locale, automatique |
| Sons | 8 bruits du quotidien, **pas de musique** |
| Tests | 64 contrôles, un bot qui atteint les 19 pages et traverse le monde, 21 étapes de parcours |

Nombre de pages : le Mushaf de Médine en compte **604**, pas 605 ; le jeu affiche « n / 604 ».

## Respect

- Aucun texte coranique n'est écrit dans le code ni dans les données ; le texte des pages vient d'une source reconnue, téléchargé à la
  demande (ou préparé avec `tools/fetch_mushaf_text.py`). Un test le vérifie.
- Les citations en français sont marquées « sens approximatif » ; elles doivent être relues par une personne compétente avant publication.
- Pas de visage, pas de statue ni d'image de personne, pas de musique, pas de hasard payant, pas de compte.

## Ce qui a été vérifié

- **Godot 4.7.2 officiel (Linux, sans fenêtre)** : `tools/test.sh` passe — 64 contrôles (données, sauvegarde, entrées, sons, verrous, garde-fou
  « aucun texte coranique », compilation de tous les scripts), un bot qui atteint les 19 pages et traverse le monde de la chambre au sommet, et un
  parcours de fumée sur la vraie scène principale (menu → note → cinématique → jeu → page → Mushaf → pause → retour → fin) en 21 étapes, sans aucune erreur de script.
- **Rendu** : les captures (cinématique, monde, HUD, dialogues, Mushaf, menus, tactile) ont été prises dans un moteur Godot compilé en WebAssembly
  (build non officiel, sans carte graphique). Ce moteur affiche les lettres arabes séparées ; le vrai moteur les met en forme.

- **Export Linux** : construit avec les modèles officiels 4.7.2 (`tools/export.sh linux`), et l'exécutable démarre sans erreur ni fichier manquant.

**Non vérifié** (à contrôler sur ta machine et sur un téléphone) : l'export Windows, Web et Android, le son réel, les touches du clavier
(les correspondances touche → action sont testées, pas la frappe physique), le tactile réel, et l'affichage arabe dans le vrai moteur.
Les collisions sont écrites à la main (`scripts/world/collision.gd`) plutôt que via le moteur physique, ce qui rend le comportement prévisible et testable.

## Organisation

```
ghafla/
  project.godot, export_presets.cfg
  data/        pages placées, dialogues, sourates (aucun texte coranique)
  assets/      polices Amiri (licence OFL), sons générés
  scripts/
    main.gd    machine d'états : menu → note → cinématique → jeu
    core/      palette, sauvegarde, Mushaf (604 pages), entrées, sons, texte des pages
    cinematic/ la cinématique et le personnage sans visage
    world/     monde, joueur, collisions, pages, zones (maison, rue, souk, grotte, sommet)
    ui/        HUD, dialogues, livre du Mushaf, menus, note, fin, tactile
  tests/       run_tests.gd (+ scène test_runner.tscn), aperçus de développement
  tools/       run, test, export, génération des sons, texte des pages
  docs/        conception, pages, cinématique, build
```

La police Amiri (SIL Open Font License) est incluse : voir `assets/fonts/OFL-Amiri.txt`.
