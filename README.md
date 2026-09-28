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

## Publier sur le Play Store avec une nouvelle clé

Si l'application utilise **Play App Signing** (activé par défaut pour les apps créées depuis 2021),
Google détient la clé de signature de l'app : seule la **clé d'importation (upload key)** est perdue,
et elle peut être réinitialisée.

1. Générer une nouvelle clé d'importation (à garder précieusement, hors du dépôt) :
   ```bash
   keytool -genkeypair -v -keystore android/upload-keystore.jks -alias upload \
     -keyalg RSA -keysize 2048 -validity 10000
   keytool -export -rfc -keystore android/upload-keystore.jks -alias upload -file upload_certificate.pem
   ```
2. Play Console → l'app → *Test et publication* → *Intégrité de l'application* → *Signature de l'application*
   → **Demander la réinitialisation de la clé d'importation**, et envoyer `upload_certificate.pem`.
   Google valide en général sous quelques jours.
3. Créer `android/keystore.properties` (ignoré par git) :
   ```properties
   storeFile=../upload-keystore.jks
   storePassword=...
   keyAlias=upload
   keyPassword=...
   ```
4. Construire le bundle signé (augmenter `versionCode` dans `android/app/build.gradle` à chaque envoi) :
   ```bash
   npm run build && npx cap sync android
   cd android && ./gradlew bundleRelease   # -> app/build/outputs/bundle/release/app-release.aab
   ```

Si l'app n'était **pas** inscrite à Play App Signing et que la clé de signature d'origine est perdue,
Google ne permet pas de mettre à jour cette fiche : il faut publier une nouvelle application avec un autre
`applicationId` (par ex. `com.quranquizz.app`).
