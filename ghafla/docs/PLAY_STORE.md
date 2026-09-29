# Publier Ghafla sur le Google Play Store

Ce guide va de zéro jusqu'à la version en ligne. Le script `tools/android-release.sh` automatise la partie technique ;
le reste se fait dans la Play Console (https://play.google.com/console).

> Le script a été écrit et essayé pour `check`, `templates`, `setup`, `keygen` (et la validité du preset d'export AAB), mais **pas la compilation Gradle finale** : le SDK Android
> n'était pas téléchargeable dans l'environnement de développement. La première compilation est à faire chez toi ; en cas d'erreur, copie-la telle quelle.

## 1. Prérequis sur ta machine

| Outil | Version | Où |
|---|---|---|
| Godot | 4.4 ou plus (testé : 4.7.2) | https://godotengine.org/download |
| Modèles d'export Godot | la même version | `tools/android-release.sh templates` |
| JDK | 17 ou plus récent | Android Studio l'inclut (JBR), ou OpenJDK |
| SDK Android | build-tools 35.0.1, plateforme android-35, NDK 28.1.13356709 | Android Studio > SDK Manager, ou `tools/android-release.sh sdk` |

Si Android Studio est déjà installé (c'est le cas si tu as publié l'application Quran Quizz), il suffit de pointer vers son SDK :

```bash
export ANDROID_HOME="$HOME/Android/Sdk"          # macOS : ~/Library/Android/sdk
export JAVA_HOME="/chemin/vers/le/jdk"           # facultatif : keytool du PATH suffit
tools/android-release.sh check                   # dit ce qui manque
tools/android-release.sh sdk                     # installe NDK, build-tools et plateforme manquants
tools/android-release.sh templates               # modèles d'export de Godot
tools/android-release.sh setup                   # modèle Gradle dans android/ + réglages de Godot (JDK, SDK)
```

## 2. Identité de l'application

Dans `export_presets.cfg` (preset « Android AAB », et « Android APK » pour rester cohérent) :

- `package/unique_name="com.sajouaou.ghafla"` : l'identifiant définitif de l'application. **Il ne pourra plus changer** une fois publiée. Change-le maintenant si tu veux un autre nom de domaine inversé (dans les deux presets).
- `version/name="0.1.0"` : ce que voit le joueur. `version/code=1` : entier qui doit **augmenter à chaque envoi** (`build --bump` s'en charge).
- `gradle_build/target_sdk=""` : vide = valeur par défaut de Godot. Vérifie dans la Play Console (« Politique > Exigences de niveau d'API cible ») que le niveau exigé est atteint ; sinon mets-le ici.
- `permissions/internet=true` : nécessaire uniquement pour télécharger le texte des pages depuis quran.com. Si tu embarques le texte (voir `tools/fetch_mushaf_text.py`), tu peux le retirer et écrire « aucune donnée » dans la déclaration de sécurité.

## 3. La clé de signature

Google Play utilise la **signature d'application par Google** (Play App Signing) : tu signes ton bundle avec une **clé d'importation** (upload key), et Google le re-signe avec la clé finale qu'il garde.

```bash
tools/android-release.sh keygen
```

Crée dans `~/.ghafla-keys/` (jamais dans le dépôt) :

- `ghafla-upload.jks` : la clé d'importation → **sauvegarde-la ailleurs**, avec son mot de passe ;
- `keystore.env` : les variables lues par le script (chmod 600) ;
- `upload_certificate.pem` : le certificat public.

Si la Play Console te demande un certificat (au moment d'enregistrer la clé d'importation, ou si tu l'as perdue et veux la remplacer), c'est ce `.pem` qu'il faut donner. Les fichiers `certificates.zip` et `upload_cert.der` de la console ne sont **pas** à importer dans l'application : ils sont les certificats publics de Google/de ta clé, utiles seulement pour enregistrer une clé.

Si tu as déjà une clé d'importation (celle de Quran Quizz par exemple), tu peux la réutiliser : mets ses trois variables dans `~/.ghafla-keys/keystore.env`
(`GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD`).
Une application Play = une identité : une nouvelle application Ghafla aura sa propre signature Google, quelle que soit la clé d'importation utilisée.

## 4. Construire le bundle

```bash
tools/android-release.sh build --bump      # tests, puis export/ghafla.aab signé, version/code + 1
tools/android-release.sh verify            # affiche la signature du bundle
tools/android-release.sh apk               # facultatif : un .apk à installer avec adb pour essayer sur ton téléphone
```

Avant d'envoyer, **essaie l'application sur un vrai téléphone** (`apk` puis `adb install -r export/ghafla.apk`) : contrôles tactiles, son, affichage des lettres arabes,
sauvegarde, bouton retour.

## 5. Créer l'application dans la Play Console

1. **Créer une application** : nom « Ghafla », langue par défaut français, type *Jeu*, *Gratuit*.
2. **Configuration de l'application** (tableau de bord) :
   - *Accès à l'application* : toutes les fonctionnalités sont accessibles sans compte.
   - *Annonces* : **aucune**.
   - *Classification du contenu* : questionnaire IARC. Réponses attendues : pas de violence, pas de sexualité, pas de jeu d'argent, pas d'achats, pas de communication entre joueurs. Contenu à caractère religieux : le questionnaire n'a pas de case dédiée ; mentionne-le dans la description.
   - *Public cible* : 13 ans et plus est le plus simple. Si tu cibles aussi des enfants de moins de 13 ans, la politique « Familles » impose des règles supplémentaires (à lire avant).
   - *Application d'actualités / de santé / financière / gouvernementale* : non.
   - *Sécurité des données* : voir la section 7.
   - *Politique de confidentialité* : URL publique obligatoire (section 6).
3. **Fiche du Store** (textes prêts dans `store/listing-fr.md`) :
   - icône 512×512 : `store/icon-512.png` ;
   - image de présentation 1024×500 : `store/feature-graphic-1024x500.png` ;
   - **captures d'écran de téléphone** (2 à 8) : à prendre sur un téléphone, en **paysage** (le jeu est en paysage) ; évite l'écran-titre si tes lettres arabes s'affichent mal ;
   - catégorie : *Jeux > Aventure* (ou *Jeux > Éducatif* si tu insistes sur l'apprentissage) ; coordonnées de contact : une adresse e-mail publique.
4. **Test** (obligatoire pour les comptes personnels créés après novembre 2023) : publie d'abord en **test fermé** avec au moins 12 testeurs
   qui restent inscrits 14 jours d'affilée, puis demande l'accès à la production (*Tableau de bord > Accéder à la production*). Un compte d'organisation n'a pas cette obligation. Le **test interne** (jusqu'à 100 personnes, sans délai) permet de vérifier le bundle tout de suite.
5. **Version** : *Test > Test interne (ou Production) > Créer une version* → **Play App Signing** : accepte l'inscription au premier envoi → importe `export/ghafla.aab` → notes de version (`store/listing-fr.md`) → *Examiner* → *Déployer*.
6. L'examen par Google prend de quelques heures à quelques jours.

## 6. Politique de confidentialité

Le modèle `docs/privacy-policy.md` est prêt : héberge-le à une adresse publique (GitHub Pages, ton site) et colle l'URL dans la Play Console. Relis-le : c'est toi l'éditeur, et il doit rester vrai si l'application change (par exemple si tu ajoutes des statistiques ou de la publicité).

## 7. Déclaration de sécurité des données

Ce que fait réellement l'application :

- aucun compte, aucune publicité, aucune statistique, aucun service tiers de suivi ;
- progression et réglages : stockés **sur l'appareil** uniquement ;
- texte des pages du Mushaf : téléchargé depuis `api.quran.com` (le serveur voit l'adresse IP et le numéro de page demandé, comme n'importe quel site). Si tu embarques le texte et retires `INTERNET`, l'application ne se connecte plus à rien.

Réponses : *L'application collecte-t-elle ou partage-t-elle des données utilisateur ?* Le plus prudent : **oui, non partagées, chiffrées en transit (HTTPS), sans lien avec l'identité**, catégorie « Informations sur l'application et performances > Autre » **ou** « Non » si tu embarques le texte. En cas de doute, lis la définition de « collecte » de Google : les demandes réseau de l'application vers un serveur que tu ne contrôles pas y sont assimilées quand elles envoient des identifiants ; ici il n'y en a pas d'autre que l'adresse IP côté serveur.

## 8. Avant chaque mise à jour

```bash
git pull
tools/android-release.sh build --bump
```

Puis Play Console > Créer une version > importer le nouveau `.aab`. Le `version/code` du dépôt doit toujours être **supérieur** à celui du dernier envoi (le script l'incrémente, pense à valider `export_presets.cfg`).

## 9. Notes de respect à garder dans la fiche

- Écris clairement que l'histoire est **fictive** et ne remplace pas l'enseignement ; ne présente jamais le jeu comme un moyen de « valider » une pratique.
- N'utilise pas d'images de personnes ni de captures montrant des lettres arabes mal formées.
- Fais relire les textes « sens approximatif » (`data/dialogue.json`) par une personne compétente avant la mise en ligne.
- Le texte coranique vient de quran.com : cite la source dans la description si tu l'embarques, et lis leurs conditions d'utilisation.
