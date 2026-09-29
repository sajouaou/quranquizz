# Quran Quizz

Écoute une récitation, retrouve la sourate. Application Ionic React + Capacitor (Android / iOS / web),
avec un mode multijoueur via [quranquizz_server](https://github.com/sajouaou/quranquizz_server).

## Développement

Scripts prêts à l'emploi (Linux/macOS : `.sh`, Windows : `.ps1`) :

```bash
./scripts/setup.sh                # installe les dépendances (ajouter --with-server pour le serveur)
./scripts/run.sh dev              # lance l'app sur http://localhost:5173
./scripts/run.sh dev-local        # app + serveur multijoueur local (../quranquizz_server)
./scripts/run.sh host             # app accessible depuis les téléphones du même Wi-Fi
./scripts/run.sh preview          # build de production (mode hors-ligne)
./scripts/run.sh test             # lint + tests
./scripts/run.sh android          # build + ouvre Android Studio
./scripts/run.sh aab --bump       # bundle signé pour le Play Store
```

Windows : `.\scripts\setup.ps1` puis `.\scripts\run.ps1 dev`.

Ou directement avec npm :

```bash
npm install
npm run dev          # http://localhost:5173
npm run test.unit    # tests Vitest
npm run lint
npm run build        # typecheck + build de production dans dist/
```

Le serveur multijoueur par défaut est `wss://quranquizz-server.onrender.com`.
Pour utiliser un serveur local : `VITE_SERVER_URL=ws://localhost:5000 npm run dev`.

## Fonctionnalités

- Modes Entraînement, Arcade (10 manches), Survie (3 vies) et En ligne (salons, chat).
- **Récits du Coran** : 20 récits (prophètes, figures de foi, sagesse) à écouter en entier avec
  un résumé et une leçon, défi « Situe l'ayah » (étoiles) et quiz « Quel récit ? ».
- **Partie locale sans serveur** : un appareil héberge, les autres s'y connectent en WebRTC en
  scannant un code QR (ou en le collant). Fonctionne sur le même Wi-Fi ou un partage de connexion,
  même sans Internet.
- Version web installable et utilisable hors-ligne (service worker).
- Choix du récitateur (préférence locale à chaque appareil, n'affecte pas les autres joueurs).
- Hors-ligne : les ayat écoutées sont gardées en cache, et on peut télécharger des sourates,
  le Juz' 'Amma ou tout le Coran depuis « Récitateurs & hors-ligne ».
- Records personnels (Arcade, Survie), récapitulatif des manches, vibrations sur mobile.
- En ligne : lien d'invitation (`/online?room=…`), arrivée en cours de partie, reconnexion,
  joueurs éliminés en spectateurs. Le client parle le protocole v2 du serveur (messages
  incrémentaux) et reste compatible avec l'ancien serveur.

Conception, récits et architecture multijoueur : [docs/GAME_DESIGN.md](docs/GAME_DESIGN.md).

## Ghafla (prototype de jeu, dossier `ghafla/`)

Un jeu de rêve en 2D pour PC et Android, fait avec Godot 4, à part de l'application : un homme se réveille après avoir manqué Fajr,
le Mushaf a ses pages blanches, et il doit les retrouver une à une dans un monde de rêve. C'est une **fiction** ; elle ne juge personne.
Cinématique, monde jouable (maison, rue, pont, souk, grotte, sommet), Mushaf en jeu, 23 pages touchées sur 604.
Lancer : `ghafla/tools/run.sh` · tests : `ghafla/tools/test.sh` · détails : [ghafla/README.md](ghafla/README.md).

## Publier sur le Play Store

Un script construit le bundle signé (`.aab`) :

```bash
./scripts/android-release.sh keygen    # une seule fois : crée la clé d'importation + le certificat pour Google
./scripts/android-release.sh --bump    # incrémente versionCode puis produit release/quranquizz-<version>.aab
./scripts/android-release.sh --version-name 1.2.0 --bump
```

Prérequis : JDK 21 (celui d'Android Studio convient : `export JAVA_HOME=~/android-studio/jbr`) et le SDK
Android (installé par Android Studio, ou `ANDROID_HOME`). La clé (`android/upload-keystore.jks`) et
`android/keystore.properties` ne sont jamais commités : **garde-en une sauvegarde**.

### Clé perdue

Si l'application utilise **Play App Signing** (activé par défaut depuis 2021), seule la clé d'importation
est perdue et elle peut être réinitialisée :

1. `./scripts/android-release.sh keygen` crée la nouvelle clé et `release/upload_certificate.pem`.
2. Play Console → l'app → *Test et publication* → *Intégrité de l'application* → *Signature de l'application*
   → **Demander la réinitialisation de la clé d'importation**, et envoyer `upload_certificate.pem`.
   Google valide en général sous quelques jours.
3. Une fois validé : `./scripts/android-release.sh --bump` et envoyer le `.aab`.

Si l'app n'était **pas** inscrite à Play App Signing et que la clé d'origine est perdue, Google ne permet pas
de mettre à jour cette fiche : il faut publier une nouvelle application avec un autre `applicationId`.
