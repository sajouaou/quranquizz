# Ghafla — conception

> **Ghafla est une fiction.** Le personnage, son rêve et les lieux sont inventés pour illustrer une idée :
> la négligence (*ghafla*) peut nous gagner sans bruit, et il n'est jamais trop tard pour revenir.
> Ce n'est ni un enseignement religieux ni un avis sur la pratique de qui que ce soit. Le jeu ne juge personne
> et ne se moque de rien.

## 1. Le pitch

Un homme lit le Coran le soir, avec soin, le range et s'endort. Un autre homme voit le Mushaf, hésite, ne l'ouvre pas et
s'endort. Au matin, le second se réveille en sursaut : le soleil est déjà dans sa chambre, il a manqué Fajr. Il prend le
Mushaf, et les pages sont blanches. Il sort de chez lui : le monde qu'il connaît est devenu un rêve. Pour rendre au Mushaf
ses pages, il doit les retrouver, une à une.

Ce n'est pas un jeu de combat ni de score : c'est une balade contemplative avec de petites énigmes, où chaque page
retrouvée fait réagir le personnage, sans le juger ni le moquer.

## 2. Déroulé

| Étape | Ce qui se passe |
|---|---|
| Menu | Ciel du rêve, « Commencer » / « Continuer », réglages, note sur l'histoire. |
| Note | Écran unique avant la première partie : fiction, aucun jugement, pas de texte coranique écrit à la main. |
| Cinématique | Voir [CINEMATIC.md](CINEMATIC.md) : deux hommes sans visage, le réveil manqué, les pages qui blanchissent. |
| Maison | Sortir de la chambre, descendre l'escalier, ouvrir la porte. |
| Rue | Première page devant la porte (Al-Anbya) : le personnage comprend sa ghafla et décide de tout retrouver. |
| Pont de nuages | Des pierres flottantes à franchir en sautant. On ne tombe pas vraiment : le rêve ramène en arrière. |
| Souk | Boutiques, étoffes, pièces d'or qui fuient : Al-Takathur et Al-Humazah, le temps passé à courir après l'argent. |
| Grotte | Al-Kahf entière (12 pages). Pages cachées, corniches, veine de lumière, sceau final. |
| Montée et sommet | Deux pages sur le chemin, puis la porte de l'aube (An-Nas) qui s'ouvre quand toutes les autres sont revenues. |
| Fin | « Le jour se lève. Cette fois, tu es déjà debout. » Puis on peut continuer à explorer. |

## 3. Mécaniques

- **Déplacement** : marcher, courir, sauter (saut plus court si on relâche), interagir. Clavier (QWERTY et AZERTY),
  manette, souris et boutons tactiles.
- **Le Mushaf sur soi** : en haut à gauche, un petit Mushaf se remplit ; touche `M` (ou le bouton « Mushaf ») ouvre le livre :
  - *Livre* : double page ; une page retrouvée porte son texte, **découpé par sourate** avec un bandeau au nom de chaque sourate qui commence sur la page. Une page manquante — ou la partie manquante d'une page — est **blanche**.
  - *Vue d'ensemble* : les 604 pages en 30 rangées de juz', dorées si retrouvées, blanches sinon.
  - *Sourates* : la liste des 114 sourates avec les pages retrouvées.
- **Pages cachées** : elles n'apparaissent qu'après un geste :
  rester immobile près d'un endroit, toucher une veine de lumière, ou attendre qu'un événement se produise.
- **Pages verrouillées** : un coffre (il faut la clé), un sceau qui attend d'autres pages, un sceau final.
  Un message indique toujours ce qui manque (« 7 / 11 »).
- **Réactions** : chaque page fait réagir le personnage (scène courte ou murmure). Certaines affichent d'abord le
  verset de la page dans une traduction publiée (Hamidullah en français, The Clear Quran en anglais), avec sa référence et le nom du traducteur.
- **Sauvegarde** locale, automatique : pages, objets, position, réglages.

## 4. Adab (règles de respect)

Ces règles sont vérifiées, quand c'est possible, par `tests/run_tests.gd`.

- **Aucun texte coranique écrit à la main** dans le code ni dans les données. Le texte des pages vient d'une source
  reconnue (API de quran.com, téléchargée à la demande et gardée en cache, ou préparée avec `tools/fetch_mushaf_text.py`).
  Sans texte disponible, la page affiche seulement des traits abstraits. Un test refuse toute lettre arabe hors du titre du jeu et du mot « sourate ».
- **« Sens approximatif »** : les citations en français sont des résumés courts, marquées comme tels avec leur référence. Ils doivent être
  relus par une personne compétente avant toute publication.
- **Ni visage, ni figure, ni statue** : les personnages sont des silhouettes sans traits ; le monde contient des maisons, une
  mosquée fermée au loin, des montagnes, une grotte, un souk, mais aucune statue, aucune idole, aucune image d'être vivant en dehors du personnage.
- **Aucune moquerie** : le personnage se reprend lui-même avec douceur ; personne d'autre n'est visé. Les erreurs ne sont pas punies (le rêve ramène en arrière).
- **Pas de musique** : seulement des bruits du quotidien (pas, papier, porte, vent, gouttes d'eau).
- **Pas de mécanique de hasard, pas de pub, pas de compte.**

## 5. 604 ou 605 pages ?

Le Mushaf de Médine compte **604 pages**. La demande initiale parlait de 605 ; le jeu utilise 604 (nombre réel), et l'interface
l'affiche partout (« 12 / 604 »). Si l'on veut une page de plus (par exemple une page de couverture ou de fin), c'est un changement de données
(`data/surahs.json` : `total_pages`), pas de code.

## 6. Ce que le prototype contient, et ce qu'il ne contient pas

Contenu : cinématique complète, une maison, une rue, un pont, un souk, une grotte, une montée avec sommet, **23 objets à prendre : 22 pages complètes, 24 touchées** (dont deux pages à plusieurs sourates prises sourate par sourate),
9 déclencheurs d'histoire, 10 réactions, le Mushaf en jeu, sauvegarde, menus, contrôles tactiles, 8 sons, tests et bot.

Volontairement absent : les 585 autres pages, plusieurs modes de récupération à inventer, d'autres lieux (montagne enneigée, mer, désert de
nuit, jardins…), plus de dialogues, une traduction en arabe ou en anglais, des succès.

## 6 bis. Chapitre 2 : les leçons oubliées

Un second rêve (menu « Chapitres », où les deux chapitres sont réunis, ou à la fin du chapitre 1). Même mécanique, autre monde :
cinématique de l'enfance (Luqman), ville en fête (Al-Isra, An-Nur), avenue d'or et cortège englouti (fin d'Al-Qasas), rue de l'ivresse en trois étapes (2:219, 4:43, 5:91),
tombes (Al-Hijr, Al-Muddaththir, Al-Qiyamah, An-Naba'). Détails : [PAGES.md](PAGES.md) et [CINEMATIC.md](CINEMATIC.md).

Règles de respect propres à ce chapitre :
- **Des sujets délicats, traités sans moquerie ni jugement** : le personnage se regarde lui-même ; on ne montre aucune scène intime, aucune personne dans la ville des amoureux (seulement des décors vides), aucun buveur (seulement des verres et des bouteilles).
- **Silhouettes sans visage** seulement quand l'histoire l'exige : la famille dans la cinématique, l'homme riche sur son char. Aucune statue, aucune idole, aucune image d'un prophète.
- **Les tombes** sont de simples tertres et de petites dalles nues : sans ornement, sans inscription.
- Les versets cités viennent de traductions publiées (Hamidullah, The Clear Quran) ; les pensées du personnage (`locales/*/dialogue_2.json`) doivent être relues par une personne compétente avant publication.

## 6 ter. Profondeur « 2.5D »

Le jeu reste en 2D (rendu dessiné en code, aucune image), mais la scène est empilée en plans qui défilent à des vitesses différentes :

| Plan | Fichier | Vitesse (1 = le monde) |
|---|---|---|
| ciel, horloges, collines lointaines | `world/backdrop.gd` | 0,01 à 0,12 |
| ville lointaine, puis ville proche (deuxième rangée) | `backdrop.gd` | 0,28 puis 0,4 |
| collines proches, collines intermédiaires (sommet, chapitre 2) | `backdrop.gd` | 0,5 puis 0,7 |
| décor, sol, pages, personnage | `world.gd`, `prop.gd`, `ground_art.gd` | 1 |
| joints du sol en perspective (ils fuient vers le centre de l'écran) | `world/ground_depth.gd` | 1 à 1,6 |
| rayons de lumière, bokeh | `world/foreground.gd` | 0,9 et 1,8 |
| avant-plan (herbes, roches, stalagmites, fanions, stalactites) | `foreground.gd` | 1,45 |

Les bâtiments sont dessinés en volume : on voit leur mur de côté, plus ou moins large selon l'endroit d'où on les regarde (`prop.gd`, `_side_wall`) ;
les pièces de la maison ont un plancher en perspective et des angles dans l'ombre.

S'y ajoutent : une ombre portée sous le personnage et sous les objets posés, la teinte du ciel sur le personnage, un sol qui a de l'épaisseur
(filets de profondeur et arête claire), une vignette, et une caméra qui recule en courant et s'approche doucement à l'arrêt.

Son : bus `World` (réverbération différente par zone : la grotte résonne, la chambre est étouffée) et `Wind` (le vent d'extérieur est filtré
tant que la porte de la maison est fermée) ; sources positionnelles très discrètes (flammes des lampes, linge, frémissement des pages tout près d'elles). La grotte est volontairement calme : gouttes rares et graves, peu de réverbération ;
pas différents selon le sol (plancher, pierre, herbe). Toujours sans musique. Les sons sont synthétisés par `tools/gen_sfx.py`.

`tests/dev/world_shots.tscn` enregistre des captures du menu et de chaque zone, `tests/dev/cinematic_shots.tscn` des deux cinématiques (voir l'en-tête des scripts).

### Qualité graphique et fluidité

Réglages > « Qualité graphique » (`scripts/core/gfx.gd`) : automatique (moyenne sur téléphone et navigateur, haute sur ordinateur), basse, moyenne ou haute. Le changement s'applique tout de suite.

| Niveau | Ce qui est retiré |
|---|---|
| haute | rien |
| moyenne | lueurs floues et rayons de lumière ; moins d'étoiles et de poussières |
| basse | en plus : avant-plan, murs de côté des bâtiments, joints du sol, rangée de bâtiments intermédiaire, vignette ; fond redessiné 30 fois par seconde |

À tous les niveaux, rien n'est redessiné hors de l'écran (décors animés, pages, lueurs), le fond n'est refait que si la caméra bouge, et les calculs répétés
(pages d'une sourate, fenêtres allumées de la ville) sont faits une seule fois. `tests/dev/bench.tscn` mesure le temps d'une image dans chaque zone, personnage en marche
(`godot --path ghafla res://tests/dev/bench.tscn -- low|medium|high`).

Pages cachées : leur signe ne ressemble à aucune autre particule (étoiles nettes à quatre branches, vert d'eau, en spirale au-dessus d'un anneau au sol),
alors que les poussières d'ambiance sont des points ronds, flous et dorés. Il se voit de loin, même dans la grotte.

## 7. Pistes pour la suite

- **Nouveaux lieux liés aux sourates** : une mer calme pour Yunus et Musa, un jardin pour Ar-Rahman, un puits pour Yusuf, une montagne
  pour Al-Tur, une nuit étoilée pour Al-Najm, sans jamais figurer un prophète ni une personne.
- **Nouvelles façons de récupérer une page** : un puzzle de lumière à orienter, un chemin qui n'existe que si on marche en silence,
  une porte qui s'ouvre après avoir retrouvé des pages précises, un mot de passe donné par un indice de sens, un lieu que l'on ne voit qu'à l'aube.
- **Option « faux réveil »** : à la fin, le personnage se réveille pour de bon avant Fajr : un dernier plan calme, une prière commencée.
- **Difficulté douce** : un mode contemplatif (indices plus visibles) et un mode exploration (aucune aide).
- **Textes** : relecture par un imam ou un enseignant ; version anglaise fournie, arabe à faire (voir `docs/TRANSLATING.md`).
- **Accessibilité** : options de contraste, taille de police, sous-titres des sons, mode à une main sur téléphone.
