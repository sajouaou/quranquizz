# Ghafla sur macOS et iOS

Godot exporte le jeu pour **macOS** (application universelle Intel + Apple Silicon) et pour **iOS** (un projet Xcode que l'on compile ensuite).
`tools/apple-release.sh` automatise les étapes. Les **exports** (`mac`, `ios`) marchent depuis Linux, Windows ou macOS (essayés avec Godot 4.7.2 sous Linux) ;
la **signature, la notarisation, l'archive et l'envoi** exigent un **Mac avec Xcode** (non essayés dans l'environnement de développement : à essayer chez toi).

## Ce qu'il faut

| Pour | Il faut |
|---|---|
| Tester l'app macOS sur ton Mac | rien (l'export est signé « ad hoc » : clic droit > Ouvrir au premier lancement) |
| Distribuer l'app macOS hors du Mac App Store | compte **Apple Developer Program** (99 $/an), certificat **Developer ID Application** |
| iOS (TestFlight, App Store) | même compte, un Mac avec **Xcode**, un identifiant d'app (App ID) et une fiche dans **App Store Connect** |
| Tout | modèles d'export de Godot : `tools/apple-release.sh templates` |

## Les variables

À mettre dans ton shell, ou dans `~/.ghafla-apple.env` (lu automatiquement, jamais dans git) :

```bash
export APPLE_TEAM_ID="ABCDE12345"                                   # developer.apple.com > Compte > Adhésion
export APPLE_SIGN_IDENTITY="Developer ID Application: Ton Nom (ABCDE12345)"   # macOS seulement
export APPLE_ID="toi@exemple.com"                                   # notarisation
export APPLE_APP_PASSWORD="abcd-efgh-ijkl-mnop"                     # mot de passe SPÉCIFIQUE À L'APP : appleid.apple.com > Connexion et sécurité
```

`tools/apple-release.sh check` dit ce qui est en place. Pour lister tes identités de signature : `security find-identity -v -p codesigning`.

## macOS

```bash
tools/apple-release.sh templates
tools/apple-release.sh mac          # export/Ghafla-macos.zip (universel, ad hoc)
tools/apple-release.sh mac-sign     # sur un Mac : signature + notarisation + export/Ghafla.dmg
```

- `mac-sign` signe avec le « hardened runtime » et `tools/macos.entitlements` (Godot a besoin de `allow-jit` et `allow-unsigned-executable-memory` ; `network.client` sert au téléchargement du texte des pages).
- Sans `APPLE_ID` / `APPLE_APP_PASSWORD`, la signature est faite mais **pas la notarisation** : macOS affichera un avertissement au premier lancement chez les autres.
- **Mac App Store** : c'est une autre filière (certificats « Apple Distribution » et « Mac Installer Distribution », bac à sable activé, `.pkg`). Dans le preset `macOS`, choisis *Export > Distribution type* et renseigne les identités, puis envoie avec Transporter. Non automatisé ici.
- Identifiant : `application/bundle_identifier="com.sajouaou.ghafla"` dans `export_presets.cfg`. Il doit être **identique** à l'App ID enregistré chez Apple ; il ne pourra plus changer après publication.

## iOS

```bash
tools/apple-release.sh ios                  # projet Xcode : export/ios/Ghafla.xcodeproj
tools/apple-release.sh ios-archive          # sur un Mac : archive + export/ios/ipa/Ghafla.ipa
tools/apple-release.sh ios-archive --upload # idem, et envoi à App Store Connect (TestFlight)
tools/apple-release.sh bump                 # build + 1 (à faire avant chaque nouvel envoi)
```

Étapes chez Apple, une seule fois :
1. **developer.apple.com > Identifiers** : crée l'App ID `com.sajouaou.ghafla` (Explicit).
2. **App Store Connect > Apps > + Nouvelle app** : plateforme iOS, nom « Ghafla », langue principale français, même bundle ID, SKU au choix.
3. Xcode gère les certificats et profils (`-allowProvisioningUpdates`) : connecte ton compte dans *Xcode > Réglages > Comptes* au moins une fois.

Réglages déjà faits dans le preset iOS : paysage seulement, arm64, fond sombre au lancement, projet Xcode exporté sans compilation (`export_project_only`).
Il te manque probablement les **icônes** : Godot utilise `icon.svg`, mais l'App Store exige une icône 1024×1024 sans transparence
(ajoute-la dans le projet Xcode : `Assets.xcassets`, ou fournis `store/icon-512.png` agrandie).

## App Store Connect : la fiche

Reprends `store/listing-fr.md` et `docs/privacy-policy.md` (politique de confidentialité à héberger sur une URL publique).

- **Confidentialité de l'app** : aucune donnée collectée liée à l'utilisateur ; la seule connexion réseau est le téléchargement du texte des pages depuis api.quran.com (si tu l'embarques avec `tools/fetch_mushaf_text.py`, l'app ne se connecte plus à rien).
- **Classification d'âge** : questionnaire ; pas de violence ni de contenu sensible autre que le thème religieux (les chapitres évoquent la mort, l'alcool et la fornication sans image ni scène : à indiquer avec honnêteté dans le questionnaire).
- **Captures** : iPhone 6,9" et 6,5" en **paysage**, iPad si tu gardes iPad activé. Prends-les sur un simulateur Xcode ou un appareil.
- **Notes pour l'examen** : précise que l'histoire est fictive, sans compte, sans achat, sans publicité.
- **Cohérence avec le jeu** : n'utilise pas de captures montrant des lettres arabes mal formées (vérifie l'affichage sur un vrai appareil avant).

## Avant chaque mise à jour

```bash
git pull
tools/apple-release.sh bump
tools/apple-release.sh ios-archive --upload     # iOS
tools/apple-release.sh mac-sign                 # macOS
```
