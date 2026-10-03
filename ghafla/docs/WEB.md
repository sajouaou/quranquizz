# Ghafla sur le web (Mac, Windows, Linux, iPhone, iPad, Android)

Une version web tourne dans le navigateur, **sans rien installer** : Safari (Mac, iPhone, iPad), Chrome, Edge, Firefox. C'est la solution si l'application macOS
signée « ad hoc » refuse de s'ouvrir. Elle a été exportée avec le Godot officiel 4.7.2 (préréglage « Web », sans threads, donc sans réglage spécial du serveur)
et chargée dans Chromium : le menu s'affiche, avec les lettres arabes correctement mises en forme.

## L'essayer chez soi

```bash
tools/web-release.sh build    # export/web/ + export/Ghafla-web.zip
tools/web-release.sh serve    # http://localhost:8060
```

(ou `python3 tools/serve_web.py` si tu as déjà exporté). **Ne double-clique pas sur `index.html`** : un navigateur ne charge pas le `.wasm` depuis `file://`.

## La publier (au choix, gratuit)

| Hébergeur | Comment |
|---|---|
| **itch.io** | Nouveau projet > *Kind of project : HTML* > envoie `export/Ghafla-web.zip` > coche « This file will be played in the browser » > taille 1280×720. Le plus simple. |
| **GitHub Pages (automatique)** | Le dépôt contient `.github/workflows/ghafla-web.yml` : *Settings > Pages > Source : GitHub Actions*, puis *Actions > Ghafla web > Run workflow*. Il lance les tests, exporte et publie ; l'adresse s'affiche à la fin. (Workflow non essayé ici.) |
| **GitHub Pages (à la main)** | Copie le contenu de `export/web/` dans une branche `gh-pages` (ou un dossier `docs/` d'un dépôt dédié) puis active Pages. |
| **Netlify / Cloudflare Pages** | Glisse le dossier `export/web/` dans l'interface. |
| Ton serveur | Copie `export/web/` ; sers `.wasm` en `application/wasm` et active la compression gzip/brotli (le `.wasm` fait ~40 Mo, ~10 Mo compressé). HTTPS conseillé. |

## À savoir

- **Sauvegarde** : la progression est gardée dans le stockage du navigateur (IndexedDB) ; elle est perdue si tu vides les données du site, et elle n'est pas partagée entre appareils ni entre navigateurs.
  En navigation privée, elle disparaît à la fermeture.
- **Son** : les navigateurs n'autorisent le son qu'après un clic ; le menu principal en demande un, donc c'est automatique.
- **Texte du Mushaf** : il est téléchargé depuis api.quran.com par le navigateur. Cela exige que ce service autorise les requêtes depuis ton site (CORS) : si le texte n'apparaît pas, embarque-le
  (`python3 tools/fetch_mushaf_text.py --all`, puis refais l'export ; vérifie leurs conditions d'utilisation avant de redistribuer).
- **Téléphone** : les boutons tactiles s'affichent seuls ; mets le téléphone en paysage. Sur iPhone, ajoute la page à l'écran d'accueil pour jouer en plein écran.
- **Clavier** : clique une fois dans la page pour lui donner le focus.
- **Plein écran** : F11 (ou Ctrl+Cmd+F sur Mac).
- **Performances** : le rendu utilise WebGL 2 (compatibilité) ; une machine récente n'a aucun souci.

## Ce qui n'a pas été vérifié

Chargement complet dans Chromium sans carte graphique (menu OK). Pas essayé dans Safari, Firefox ni sur téléphone, ni le son ni l'hébergement réel : à contrôler chez toi.
