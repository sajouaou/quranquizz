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
  - *Livre* : double page ; une page retrouvée porte son texte, une page manquante est **blanche**.
  - *Vue d'ensemble* : les 604 pages en 30 rangées de juz', dorées si retrouvées, blanches sinon.
  - *Sourates* : la liste des 114 sourates avec les pages retrouvées.
- **Pages cachées** : elles n'apparaissent qu'après un geste :
  rester immobile près d'un endroit, toucher une veine de lumière, ou attendre qu'un événement se produise.
- **Pages verrouillées** : un coffre (il faut la clé), un sceau qui attend d'autres pages, un sceau final.
  Un message indique toujours ce qui manque (« 7 / 11 »).
- **Réactions** : chaque page fait réagir le personnage (scène courte ou murmure). Certaines affichent d'abord un
  « sens approximatif » du passage, marqué comme tel, avec sa référence.
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

Contenu : cinématique complète, une maison, une rue, un pont, un souk, une grotte, une montée avec sommet, **19 pages placées**,
9 déclencheurs d'histoire, 10 réactions, le Mushaf en jeu, sauvegarde, menus, contrôles tactiles, 8 sons, tests et bot.

Volontairement absent : les 585 autres pages, plusieurs modes de récupération à inventer, d'autres lieux (montagne enneigée, mer, désert de
nuit, jardins…), plus de dialogues, une traduction en arabe ou en anglais, des succès.

## 7. Pistes pour la suite

- **Nouveaux lieux liés aux sourates** : une mer calme pour Yunus et Musa, un jardin pour Ar-Rahman, un puits pour Yusuf, une montagne
  pour Al-Tur, une nuit étoilée pour Al-Najm, sans jamais figurer un prophète ni une personne.
- **Nouvelles façons de récupérer une page** : un puzzle de lumière à orienter, un chemin qui n'existe que si on marche en silence,
  une porte qui s'ouvre après avoir retrouvé des pages précises, un mot de passe donné par un indice de sens, un lieu que l'on ne voit qu'à l'aube.
- **Option « faux réveil »** : à la fin, le personnage se réveille pour de bon avant Fajr : un dernier plan calme, une prière commencée.
- **Difficulté douce** : un mode contemplatif (indices plus visibles) et un mode exploration (aucune aide).
- **Textes** : relecture par un imam ou un enseignant ; version anglaise et arabe.
- **Accessibilité** : options de contraste, taille de police, sous-titres des sons, mode à une main sur téléphone.
