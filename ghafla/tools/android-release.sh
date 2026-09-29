#!/usr/bin/env bash
# Prépare et construit le bundle Android signé (.aab) de Ghafla pour le Google Play Store.
#
#   tools/android-release.sh check            vérifie les prérequis (Godot, modèles, JDK, SDK Android, clé)
#   tools/android-release.sh templates        télécharge et installe les modèles d'export de Godot
#   tools/android-release.sh sdk              installe les composants du SDK Android (si sdkmanager est présent)
#   tools/android-release.sh setup            installe le modèle de compilation Android dans le projet et règle Godot
#   tools/android-release.sh keygen           crée la clé d'importation (upload key) + son certificat, hors du dépôt
#   tools/android-release.sh build [--bump]   construit export/ghafla.aab (--bump : version/code + 1)
#   tools/android-release.sh apk              construit export/ghafla.apk (test sur téléphone, sans le Play Store)
#   tools/android-release.sh verify           affiche la signature du .aab
#
# Variables utiles (toutes facultatives) :
#   GODOT          chemin du binaire Godot            ANDROID_HOME   dossier du SDK Android
#   JAVA_HOME      JDK 17 ou plus récent              GHAFLA_KEYS    dossier des clés (défaut : ~/.ghafla-keys)
#   GHAFLA_KEY_PASSWORD  mot de passe de la clé (sinon il est demandé à `keygen`)
#
# La clé de signature n'est JAMAIS dans le dépôt : elle vit dans $GHAFLA_KEYS, avec un fichier keystore.env en chmod 600.
# Ce script n'a pas pu être exécuté de bout en bout dans l'environnement de développement (le SDK Android n'y était pas téléchargeable) :
# les étapes check, templates, setup, keygen et la lecture des réglages ont été essayées ; la compilation Gradle est à essayer chez toi.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/_godot.sh

KEYS_DIR="${GHAFLA_KEYS:-$HOME/.ghafla-keys}"
KEYSTORE="$KEYS_DIR/ghafla-upload.jks"
KEY_ALIAS="ghafla-upload"
ENV_FILE="$KEYS_DIR/keystore.env"
PRESETS="export_presets.cfg"
NDK_VERSION="28.1.13356709"
BUILD_TOOLS="35.0.1"
PLATFORM="android-35"

die() { echo "Erreur : $*" >&2; exit 1; }
say() { echo "== $* =="; }

godot_version() {  # ex. 4.7.2.stable
  "$GODOT_BIN" --version 2>/dev/null | head -1 | sed -E 's/^([0-9]+\.[0-9]+(\.[0-9]+)?\.[a-z0-9]+).*/\1/'
}

templates_dir() {
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Godot/export_templates/$(godot_version)" ;;
    *) echo "${XDG_DATA_HOME:-$HOME/.local/share}/godot/export_templates/$(godot_version)" ;;
  esac
}

settings_file() {
  local v major_minor
  v="$(godot_version)"; major_minor="$(echo "$v" | cut -d. -f1,2)"
  case "$(uname -s)" in
    Darwin) echo "$HOME/Library/Application Support/Godot/editor_settings-$major_minor.tres" ;;
    *) echo "${XDG_CONFIG_HOME:-$HOME/.config}/godot/editor_settings-$major_minor.tres" ;;
  esac
}

java_home() {
  if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/keytool" ]; then echo "$JAVA_HOME"; return; fi
  if command -v keytool >/dev/null 2>&1; then
    dirname "$(dirname "$(readlink -f "$(command -v keytool)")")"; return
  fi
  return 1
}

sdk_home() {
  for c in "${ANDROID_HOME:-}" "${ANDROID_SDK_ROOT:-}" "$HOME/Android/Sdk" "$HOME/Library/Android/sdk"; do
    if [ -n "$c" ] && [ -d "$c" ]; then echo "$c"; return; fi
  done
  return 1
}

# Écrit (ou remplace) une clé dans les paramètres de l'éditeur Godot.
set_editor_setting() {
  local key="$1" value="$2" f
  f="$(settings_file)"
  if [ ! -f "$f" ]; then
    mkdir -p "$(dirname "$f")"
    printf '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n' > "$f"
  fi
  if grep -q "^$key = " "$f"; then
    local tmp; tmp="$(mktemp)"
    awk -v k="$key" -v v="$value" 'index($0, k " = ")==1 { print k " = \"" v "\""; next } { print }' "$f" > "$tmp" && mv "$tmp" "$f"
  else
    echo "$key = \"$value\"" >> "$f"
  fi
}

cmd_check() {
  local bad=0
  require_godot
  echo "Godot     : $GODOT_BIN ($(godot_version))"
  [ -d "$(templates_dir)" ] && [ -f "$(templates_dir)/android_source.zip" ] && echo "Modèles   : ok ($(templates_dir))" || { echo "Modèles   : MANQUANTS -> tools/android-release.sh templates"; bad=1; }
  if jh="$(java_home)"; then echo "JDK       : $jh ($("$jh/bin/java" -version 2>&1 | grep -m1 version | tr -d "\r"))"; else echo "JDK       : MANQUANT (installe OpenJDK 17+)"; bad=1; fi
  if sh="$(sdk_home)"; then
    echo "SDK       : $sh"
    [ -d "$sh/ndk/$NDK_VERSION" ] || { echo "            NDK $NDK_VERSION absent -> tools/android-release.sh sdk"; bad=1; }
    [ -d "$sh/build-tools/$BUILD_TOOLS" ] || { echo "            build-tools $BUILD_TOOLS absent -> tools/android-release.sh sdk"; bad=1; }
    [ -d "$sh/platforms/$PLATFORM" ] || { echo "            plateforme $PLATFORM absente -> tools/android-release.sh sdk"; bad=1; }
  else echo "SDK       : MANQUANT (définis ANDROID_HOME ; voir docs/PLAY_STORE.md)"; bad=1; fi
  [ -f android/build/build.gradle ] && echo "Gradle    : modèle de compilation installé" || { echo "Gradle    : modèle absent -> tools/android-release.sh setup"; bad=1; }
  [ -f "$KEYSTORE" ] && echo "Clé       : $KEYSTORE" || { echo "Clé       : ABSENTE -> tools/android-release.sh keygen"; bad=1; }
  echo "Version   : $(grep -m1 '^version/name' "$PRESETS" | cut -d= -f2) (code $(grep -m1 '^version/code' "$PRESETS" | cut -d= -f2))"
  echo "Package   : $(grep -m1 '^package/unique_name' "$PRESETS" | cut -d= -f2)"
  return $bad
}

cmd_templates() {
  require_godot
  local v dir url tpz
  v="$(godot_version)"; dir="$(templates_dir)"
  if [ -f "$dir/android_source.zip" ]; then echo "Modèles déjà installés dans $dir"; return; fi
  url="https://github.com/godotengine/godot-builds/releases/download/${v%.*}-${v##*.}/Godot_v${v%.*}-${v##*.}_export_templates.tpz"
  say "Téléchargement des modèles d'export ($url)"
  tpz="$(mktemp -d)/templates.tpz"
  curl -fL --retry 3 -o "$tpz" "$url" || die "téléchargement impossible : installe-les depuis l'éditeur (Éditeur > Gérer les modèles d'export)"
  mkdir -p "$dir"
  unzip -o -q "$tpz" 'templates/*' -d "$(dirname "$tpz")"
  cp -R "$(dirname "$tpz")"/templates/* "$dir/"
  echo "Installés dans $dir"
}

cmd_sdk() {
  local sh sm
  sh="$(sdk_home)" || die "définis ANDROID_HOME (dossier du SDK Android, avec cmdline-tools). Voir docs/PLAY_STORE.md"
  sm="$(ls "$sh"/cmdline-tools/*/bin/sdkmanager "$sh"/tools/bin/sdkmanager 2>/dev/null | head -1 || true)"
  [ -n "$sm" ] || die "sdkmanager introuvable : installe « Android SDK Command-line Tools » (Android Studio > SDK Manager)"
  say "Licences"
  yes | "$sm" --sdk_root="$sh" --licenses >/dev/null || true
  say "Installation des composants"
  "$sm" --sdk_root="$sh" "platform-tools" "build-tools;$BUILD_TOOLS" "platforms;$PLATFORM" "cmdline-tools;latest" "ndk;$NDK_VERSION"
}

cmd_setup() {
  require_godot
  local jh sh dir
  jh="$(java_home)" || die "JDK introuvable"
  sh="$(sdk_home)" || die "SDK Android introuvable (définis ANDROID_HOME)"
  dir="$(templates_dir)"
  [ -f "$dir/android_source.zip" ] || die "modèles absents : tools/android-release.sh templates"
  say "Modèle de compilation Android dans android/"
  mkdir -p android/build
  unzip -o -q "$dir/android_source.zip" -d android/build
  godot_version > android/.build_version
  touch android/build/.gdignore
  say "Réglages de Godot (JDK et SDK)"
  set_editor_setting "export/android/java_sdk_path" "$jh"
  set_editor_setting "export/android/android_sdk_path" "$sh"
  echo "Réglages écrits dans $(settings_file)"
}

cmd_keygen() {
  local jh
  jh="$(java_home)" || die "JDK introuvable (keytool)"
  [ -f "$KEYSTORE" ] && die "$KEYSTORE existe déjà : je ne l'écrase pas"
  mkdir -p "$KEYS_DIR"; chmod 700 "$KEYS_DIR"
  local pass="${GHAFLA_KEY_PASSWORD:-}"
  if [ -z "$pass" ]; then
    read -r -s -p "Mot de passe de la clé (8 caractères minimum) : " pass; echo
    read -r -s -p "Confirme : " pass2; echo
    [ "$pass" = "$pass2" ] || die "les mots de passe diffèrent"
  fi
  [ "${#pass}" -ge 8 ] || die "mot de passe trop court"
  local dname="${GHAFLA_DNAME:-CN=Ghafla, OU=Jeux, O=Ghafla, L=Ville, C=FR}"
  "$jh/bin/keytool" -genkeypair -v -keystore "$KEYSTORE" -alias "$KEY_ALIAS" -keyalg RSA -keysize 4096 -validity 10000 \
    -storepass "$pass" -keypass "$pass" -dname "$dname"
  cat > "$ENV_FILE" <<ENV
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$KEY_ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$pass"
ENV
  chmod 600 "$ENV_FILE" "$KEYSTORE"
  "$jh/bin/keytool" -export -rfc -keystore "$KEYSTORE" -alias "$KEY_ALIAS" -storepass "$pass" -file "$KEYS_DIR/upload_certificate.pem"
  cat <<MSG

Clé créée dans $KEYS_DIR :
  ghafla-upload.jks        la clé d'importation (à sauvegarder AILLEURS, et à ne jamais publier)
  keystore.env             les variables lues par ce script
  upload_certificate.pem   le certificat public (à donner à Google si on te le demande)

Sauvegarde le .jks et le mot de passe dans un gestionnaire de mots de passe : sans eux, plus de mise à jour possible avec cette clé.
MSG
}

load_key() {
  if [ -f "$ENV_FILE" ]; then source "$ENV_FILE"; fi
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_PATH:?clé absente : tools/android-release.sh keygen (ou exporte GODOT_ANDROID_KEYSTORE_RELEASE_PATH / _USER / _PASSWORD)}"
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_USER:?variable manquante}"
  : "${GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD:?variable manquante}"
  [ -f "$GODOT_ANDROID_KEYSTORE_RELEASE_PATH" ] || die "keystore introuvable : $GODOT_ANDROID_KEYSTORE_RELEASE_PATH"
}

bump_version() {
  local cur next
  cur="$(grep -m1 '^version/code=' "$PRESETS" | cut -d= -f2)"
  next=$((cur + 1))
  sed -i.bak -E "s/^version\/code=[0-9]+/version\/code=$next/" "$PRESETS" && rm -f "$PRESETS.bak"
  echo "version/code : $cur -> $next"
}

preflight() {
  require_godot
  [ -d "$(templates_dir)" ] || die "modèles d'export absents : tools/android-release.sh templates"
  sh="$(sdk_home)" || die "SDK Android introuvable (définis ANDROID_HOME)"
  # « Le modèle de compilation Android n'est pas installé dans le projet » : on l'installe nous-mêmes
  if [ ! -f android/build/build.gradle ] || [ "$(cat android/.build_version 2>/dev/null)" != "$(godot_version)" ]; then
    say "Modèle de compilation Android absent ou d'une autre version : installation"
    cmd_setup
  fi
  export ANDROID_HOME="$sh" ANDROID_SDK_ROOT="$sh"
  export JAVA_HOME="$(java_home)"
}

cmd_build() {
  local bump=0
  [ "${1:-}" = "--bump" ] && bump=1
  preflight
  load_key
  [ "$bump" -eq 1 ] && bump_version
  mkdir -p export
  say "Tests avant de construire"
  tools/test.sh
  say "Export du bundle signé"
  "$GODOT_BIN" --headless --path . --export-release "Android AAB" export/ghafla.aab
  [ -f export/ghafla.aab ] || die "le bundle n'a pas été produit"
  echo
  ls -lh export/ghafla.aab
  cmd_verify
  echo
  echo "Prochaine étape : Play Console > Production (ou Test interne) > Créer une version > importer export/ghafla.aab"
}

cmd_apk() {
  preflight
  load_key
  mkdir -p export
  "$GODOT_BIN" --headless --path . --export-release "Android APK" export/ghafla.apk
  ls -lh export/ghafla.apk
  echo "Installation sur un téléphone en mode développeur :  adb install -r export/ghafla.apk"
}

cmd_verify() {
  local jh; jh="$(java_home)" || die "JDK introuvable"
  [ -f export/ghafla.aab ] || die "export/ghafla.aab absent"
  "$jh/bin/jarsigner" -verify export/ghafla.aab | tail -3
  echo "Certificat de signature du bundle :"
  "$jh/bin/keytool" -printcert -jarfile export/ghafla.aab | grep -E "Propriétaire|Owner|SHA1|SHA256|Valide|Valid" | head -6
}

case "${1:-}" in
  check) cmd_check ;;
  templates) cmd_templates ;;
  sdk) cmd_sdk ;;
  setup) cmd_setup ;;
  keygen) cmd_keygen ;;
  build) shift; cmd_build "${1:-}" ;;
  apk) cmd_apk ;;
  verify) cmd_verify ;;
  *) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
