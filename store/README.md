# Fiche du Store — Quran Quizz

Tout ce qu'il faut envoyer dans la Play Console (*Présence sur le Play Store > Fiche principale*).

| Fichier | Taille | Où l'envoyer |
|---|---|---|
| `icon-512.png` | 512 × 512 | Icône de l'application |
| `feature-graphic-1024x500.png` | 1024 × 500 | Image de présentation (bannière) |
| `screenshots/01` à `08` | 1080 × 1920 | Captures d'écran de téléphone (8 maximum), dans cet ordre |
| `screenshots/raw/` | 1080 × 1920 | Les mêmes captures sans cadre ni légende |
| `icon-1024.png` | 1024 × 1024 | Icône pour l'App Store |
| `listing-fr.md` | | Titre, descriptions, notes de version, réponses aux questionnaires |

L'icône est le logo de l'application (`resources/logo.svg`) : une étoile à huit branches, celle qui marque les quarts de hizb,
avec le mot « القرآن » en son centre. C'est la même image que l'icône installée sur le téléphone : Google demande que les deux
se ressemblent. Elle est carrée et sans coins arrondis, le Store les arrondit lui-même.

Pour changer le logo : modifier `resources/logo.svg`, puis `./scripts/app-icons.sh` (icônes et écrans de démarrage Android,
iOS et web) et `node scripts/store-assets.cjs --only icon,banner`.

## Régénérer les visuels

À refaire quand l'interface change :

```bash
npm install --no-save playwright && npx playwright install chromium   # une seule fois
node scripts/store-assets.cjs                 # tout
node scripts/store-assets.cjs --only banner   # icon, banner ou shots
```

Le script lance l'application, joue de vraies manches d'Arcade et prend les captures : il faut donc Internet (les récitations
viennent de quran.com). Les records, le pseudo et les récits « écoutés » qu'on voit sur les captures sont des données de
démonstration, définies en haut de `scripts/store-assets.cjs` avec les légendes.

Les captures sont prises dans un navigateur, à la taille d'un téléphone (360 × 640 points). La police est celle de la machine
qui lance le script ; sur un vrai téléphone Android, c'est Roboto.

## Ce qui n'est pas ici

- Les captures pour tablette (facultatives sur le Play Store).
- Les captures pour l'App Store : Apple impose d'autres tailles (1290 × 2796 pour un iPhone 6,9 pouces). Changer `PHONE` dans
  le script en `{ width: 430, height: 932, scale: 3 }` les produit.
- La politique de confidentialité : la Play Console demande une adresse publique.
