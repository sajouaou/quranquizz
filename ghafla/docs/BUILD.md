# Lancer, tester, exporter

Prérequis : **Godot 4.4 ou plus récent** (version « Standard », pas .NET) — https://godotengine.org/download.
Aucune ressource n'a besoin d'être importée : polices et sons sont lus comme des fichiers bruts
(extensions `.font` et `.sfx`), donc le projet démarre tel quel depuis un simple clone.

## Lancer

```bash
tools/run.sh                 # Linux, macOS
.\tools\run.ps1              # Windows (PowerShell)
```

Ou ouvrir le dossier `ghafla/` dans l'éditeur Godot et lancer la scène principale.
Si Godot n'est pas dans le `PATH` : `GODOT=/chemin/vers/Godot tools/run.sh`.

## Commandes

| Action | Clavier | Manette | Tactile |
|---|---|---|---|
| Marcher | Flèches, Q / D, A / D | stick gauche | ◀ ▶ |
| Sauter | Espace, ↑, W, Z | A | ↑ |
| Agir | E, Entrée | X | E |
| Courir | Maj | B | — |
| Mushaf | M, Tab | Y | bouton « Mushaf » |
| Pause | Échap, P | Start | bouton « Pause » |

Les commandes tactiles s'affichent automatiquement sur téléphone ; on peut les forcer ou les cacher dans les Réglages
(utile pour tester à la souris).

## Tests

```bash
tools/test.sh
```

Lance la vérification de syntaxe (si `gdtoolkit` est installé : `pip install gdtoolkit`) puis `tests/run_tests.gd` dans Godot en mode sans fenêtre :
données, références de versets, sauvegarde, sons, garde-fou « aucun texte coranique », verrous et pages cachées, puis **un bot qui atteint chacune
des pages avec la physique du personnage et traverse tout le monde, de la chambre au sommet**.

## Texte des pages (facultatif)

Par défaut le texte de chaque page est téléchargé une fois, à la demande, quand le joueur est en ligne, et gardé en cache local.
Pour une version 100 % hors ligne : `python3 tools/fetch_mushaf_text.py --all`. Le dossier `data/mushaf_text/` est ignoré par git :
vérifie les conditions d'utilisation de la source avant de redistribuer une version qui l'embarque.

## Sons

`python3 tools/gen_sfx.py` régénère les 8 sons (synthèse, aucune dépendance, aucun échantillon externe).

## Exporter

```bash
tools/export.sh linux|windows|web|android-apk|android-aab|all
```

- Installer les modèles d'export : Éditeur > Projet > Gérer les modèles d'export.
- `export_presets.cfg` déclare `include_filter="*.json,*.sfx,*.font"` pour que les données, polices et sons brutes soient
  bien embarquées, et exclut `tests/`, `tools/` et `docs/`.
- **Android** : installer le SDK Android et OpenJDK 17, régler leurs chemins dans les Paramètres de l'éditeur. L'AAB utilise
  la compilation Gradle (Projet > Installer le modèle de compilation Android). La clé de signature se fournit par variables d'environnement :
  `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `GODOT_ANDROID_KEYSTORE_RELEASE_USER`, `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD`. Ne jamais la commiter
  (`*.keystore` et `*.jks` sont ignorés).
- L'autorisation `INTERNET` est déclarée : elle sert uniquement à télécharger le texte des pages depuis quran.com.

## Ce qui a été vérifié, et ce qui ne l'a pas été

Voir le README : la vérification a eu lieu dans un moteur Godot 4.7 compilé en WebAssembly (build non officiel) faute d'accès aux
téléchargements officiels ; le rendu, la logique, les menus et les tests y passent, mais l'export, l'audio réel, le tactile réel et l'affichage arabe
(mise en forme des lettres) doivent être contrôlés sur un vrai Godot et un vrai téléphone.
