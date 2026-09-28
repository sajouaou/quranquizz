# Quran Quizz

Écoute une récitation, retrouve la sourate. Application Ionic React + Capacitor (Android / iOS / web),
avec un mode multijoueur via [quranquizz_server](https://github.com/sajouaou/quranquizz_server).

## Développement

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
- Choix du récitateur (préférence locale à chaque appareil, n'affecte pas les autres joueurs).
- Hors-ligne : les ayat écoutées sont gardées en cache, et on peut télécharger des sourates,
  le Juz' 'Amma ou tout le Coran depuis « Récitateurs & hors-ligne ».

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
