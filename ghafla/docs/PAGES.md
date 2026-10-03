# Carte des pages

Le prototype place **23 objets à prendre**, qui complètent **22 pages sur 604** et en touchent 24 (Al-Mulk et As-Sajdah sont offertes en entier, d'un seul geste). Chaque page est liée à un lieu par son thème, et le personnage réagit
à sa manière (les textes sont dans `data/dialogue.json`, les positions dans `data/world_pages.json`).

| Page | Ce qu'on prend | Zone | Type | Comment l'obtenir | Réaction |
|---:|---|---|---|---|---|
| 322 | Al-Anbya | rue | visible | visible | `anbiya` |
| 1 | Al-Fatihah | rue | hidden | reste immobile 2.4 s près de l'endroit : elle apparaît | `fatiha` |
| 600 | Al-'Adiyat en entier (pages 599 à 600) | souk | visible | visible | `adiyat` |
| 600 | Al-Qari'ah (partie de la page) | souk | visible | visible | `qariah` |
| 601 | Al-'Asr (partie de la page) | souk | visible | visible | `asr` |
| 601 | Al-Humazah (partie de la page) | souk | locked | coffre : la clé est cachée dans les étoffes du souk | `humazah` |
| 601 | Al-Fil (partie de la page) | souk | visible | visible | `fil` |
| 600 | At-Takathur (partie de la page) | souk | hidden | attends que les pièces du souk se dissolvent | `takathur` |
| 293 | Al-Isra · Al-Kahf | grotte | visible | visible | `kahf_first` |
| 294 | Al-Kahf | grotte | visible | visible | `kahf_mid` |
| 295 | Al-Kahf | grotte | hidden | reste immobile 2.2 s près de l'endroit : elle apparaît | `kahf_mid` |
| 296 | Al-Kahf | grotte | visible | visible, sur une corniche de 70 px (marches de pierre) | `kahf_mid` |
| 297 | Al-Kahf | grotte | visible | visible | `kahf_mid` |
| 298 | Al-Kahf | grotte | hidden | reste immobile 2.2 s près de l'endroit : elle apparaît | `kahf_mid` |
| 299 | Al-Kahf | grotte | visible | visible, sur une corniche de 140 px (marches de pierre) | `kahf_mid` |
| 300 | Al-Kahf | grotte | hidden | touche la veine de lumière de la grotte | `kahf_mid` |
| 301 | Al-Kahf | grotte | visible | visible | `kahf_mid` |
| 302 | Al-Kahf | grotte | hidden | reste immobile 2.2 s près de l'endroit : elle apparaît | `kahf_mid` |
| 303 | Al-Kahf | grotte | visible | visible | `kahf_mid` |
| 304 | Al-Kahf | grotte | locked | sceau : il faut d'abord retrouver les pages 293 à 303 | `kahf_last` |
| 415 | As-Sajdah en entier (pages 415 à 417) | sommet | hidden | reste immobile 2.4 s près de l'endroit : elle apparaît | `sajdah` |
| 562 | Al-Mulk en entier (pages 562 à 564) | sommet | visible | visible | `mulk` |
| 604 | Al-Ikhlas · Al-Falaq · An-Nas | sommet | locked | sceau de l'aube : tout le reste doit être revenu | `final` |

## Liens entre les pages et les lieux

- **Al-Anbya (322)**, devant la porte : la première page. Son début parle des gens qui approchent de leur
  reddition de comptes « et qui demeurent pourtant dans l'insouciance » : c'est le mot qui donne son nom au jeu, *ghafla*.
- **Al-Fatiha (1)**, dans la rue : cachée près d'un banc, on la voit si l'on sait attendre.
- **Al-Kahf (293 à 304)**, la grotte : la sourate entière est dans une caverne, en écho aux gens de la Caverne.
  Le personnage se souvient qu'il la lisait le vendredi, et qu'il a fini par laisser cette habitude.
  La dernière page est scellée tant que les onze précédentes ne sont pas revenues.
- **Pages à plusieurs sourates (600, 601)** : une page du Mushaf peut porter la fin d'une sourate, une sourate entière et le début de la suivante
  (la page 600 : Al-'Adiyat, Al-Qari'ah, At-Takathur ; la page 601 : Al-'Asr, Al-Humazah, Al-Fil). Chaque sourate se retrouve **séparément** : dans le livre, la page est
  complète quand toutes ses parties sont là, et une partie manquante reste blanche.
- **Al-Mulk (562 à 564) et As-Sajdah (415 à 417)** : une seule page trouvée offre la sourate entière (Al-Mulk s'étend sur 2,5 pages : la page 564 porte aussi le début d'Al-Qalam, qui reste à retrouver).
- **At-Takathur et Al-Humazah (600, 601)**, le souk : un lieu de boutiques, d'étoffes et de pièces, où le temps est arrêté à midi.
  Le personnage regrette le temps passé à courir après l'argent. La page 600 attend que les pièces s'effacent ;
  la page 601 est dans un coffre dont la clé est cachée dans un présentoir de vêtements.
- **As-Sajdah (415) et Al-Mulk (562)**, la montée : deux pages sur le chemin de la montagne.
- **An-Nas (604)**, la porte de l'aube, au sommet : elle ne s'ouvre que lorsque toutes les autres pages sont revenues.

## Ajouter une page

1. Ajouter une entrée dans `data/world_pages.json` :
   ```json
   {"page": 50, "x": 13900, "lift": 70, "kind": "visible", "reaction": "identifiant_de_reaction"}
   ```
   - `part` : numéro de sourate, pour ne prendre que **sa part** de la page (`{"page": 600, "part": 102, ...}`) ;
   - `grant_surah` : offre la sourate entière sur toutes ses pages (`{"page": 562, "grant_surah": 67, ...}`).
   - Le découpage des pages en sourates vient de `data/page_parts.json` (numéros seulement, aucun texte).
   - `kind` : `visible`, `hidden` (avec `reveal`) ou `locked` (avec `lock`).
   - `reveal` : `{"type": "wait", "seconds": 2.4, "radius": 120}`, `{"type": "event", "event": "coins_gone"}` ou `{"type": "vein"}`.
   - `lock` : `{"type": "key", "item": "key_chest", "visual": "chest"}`, `{"type": "pages", "pages": [...], "visual": "seal"}`
     ou `{"type": "others", "visual": "seal"}` (réservé à la page finale).
   - `ledge` : hauteur d'une corniche à atteindre par des marches de pierre (70 px au plus entre deux marches).
2. Ajouter (ou réutiliser) une réaction dans `data/dialogue.json` : `lines` (pensées), `meaning` facultatif
   (`ref` sourate:verset ; le texte vient de la traduction publiée de `locales/<langue>/verses.json`), ou `style: "whisper"` avec un `pool`.
3. Lancer `tools/test.sh` : les données sont validées (références de versets, pages dans la bonne sourate, verrous)
   et un bot vérifie que la page est atteignable avec les sauts du personnage.

Aucun texte coranique n'est écrit dans ces fichiers ; un test le vérifie.

# Chapitre 2 : les leçons oubliées

Un second rêve, dans le même monde d'images : la maison, une ville de fête, l'avenue d'un homme riche, la rue de l'ivresse, les tombes.
Il compte **11 objets à prendre** (`data/world_pages_2.json`, textes dans `data/dialogue_2.json`) qui complètent 32 pages et en touchent 39, la plupart par sourate entière
(`grant_surah`) puisque ces sourates sont courtes ou se lisent d'un trait.

| Page(s) | Ce qu'on prend | Zone | Type | Comment l'obtenir | Réaction |
|---|---|---|---|---|---|
| 411–414 | Luqman en entier | ville en fête | visible | visible | `luqman` |
| 282–293 | Al-Isra en entier | ville en fête | visible | visible | `isra` |
| 350–359 | An-Nur en entier | ville en fête | hidden | reste immobile 2.4 s : elle apparaît | `nur` |
| 394–396 | Al-Qasas (partie des pages) | avenue d'or | hidden | regarde le cortège : elle apparaît quand la terre l'a englouti | `qarun` |
| 34 | Al-Baqarah | rue de l'ivresse | visible | visible | `khamr1` |
| 85 | An-Nisa | rue de l'ivresse | locked | sceau : il faut d'abord lire la ou les paroles précédentes | `khamr2` |
| 123 | Al-Ma'idah | rue de l'ivresse | locked | sceau : il faut d'abord lire la ou les paroles précédentes | `khamr3` |
| 267 | Al-Hijr (partie des pages) | chemin des tombes | visible | visible | `hijr` |
| 575–577 | Al-Muddaththir en entier | chemin des tombes | hidden | reste immobile 2.4 s : elle apparaît | `muddathir` |
| 577–578 | Al-Qiyamah en entier | chemin des tombes | visible | visible | `qiyamah` |
| 582–583 | An-Naba en entier | chemin des tombes | locked | sceau de l'aube : tout le reste doit être revenu | `naba` |

## Les lieux et leur lien avec les pages

- **La chambre d'enfance (cinématique)** : l'homme se voit petit, absorbé par ses jeux, tandis que ses parents l'appellent, à la prière puis pour un petit service ; il continue à jouer. À la fin, la page de **Luqman** apparaît : il avait entendu ces conseils sans les suivre.
- **La ville en fête (Al-Isra 17:32, An-Nur)** : guirlandes de cœurs, roses, tables pour deux, bougies allumées, **et personne** : le rêve montre le décor de l'amour sans lendemain. Les paroles sur « ne vous approchez pas de la fornication » (Al-Isra) et sur le regard baissé et la chasteté (An-Nur) sont présentées avec douceur, en insistant sur ce qui protège avant la chute, sans jugement sur qui que ce soit.
- **L'avenue d'or (fin d'Al-Qasas, pages 394 à 396)** : un cortège somptueux (bannières, chariots de coffres, un char doré où se tient une silhouette sans visage) avance, puis la terre s'ouvre et l'engloutit (Al-Qasas 28:76-82). La page se révèle alors. Le joueur est immobilisé quelques secondes pour regarder.
- **La rue de l'ivresse (2:219, 4:43, 5:91)** : trois tables, trois étapes, **dans l'ordre de la révélation**. Chaque page scellée s'ouvre quand la précédente est lue. Décor : bouteilles et néons, aucune personne.
- **Le chemin qui longe les tombes (Al-Hijr 15:99, Al-Muddaththir, Al-Qiyamah, An-Naba')** : une route de nuit bordée d'un muret ; le cimetière ne se voit que de loin, sur la colline (tertres et dalles nues, sans inscription ni ornement). Les pages sont sur le chemin, jamais parmi les tombes. Regret, certitude de la mort, résurrection comme réalité ; la dernière page (An-Naba') est scellée jusqu'à ce que tout le reste soit revenu, et le chapitre se termine sur « tant que je respire, il est encore temps ».
