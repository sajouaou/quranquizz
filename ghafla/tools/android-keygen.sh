#!/usr/bin/env bash
# Crée la clé de signature Android (« clé d'importation », upload key) pour le Google Play Store.
#
#   tools/android-keygen.sh                       questions à l'écran
#   tools/android-keygen.sh --name "Prénom Nom" --org "Mon studio" --country FR --alias ghafla-upload
#   GHAFLA_KEY_PASSWORD=... tools/android-keygen.sh --yes    sans question (mot de passe via l'environnement)
#
# Options : --dir DOSSIER (défaut ~/.ghafla-keys)  --alias NOM (défaut ghafla-upload)  --years N (défaut 30)
#           --name --org --unit --city --state --country    --yes (ne rien demander si tout est fourni)
#
# Résultat, dans le dossier des clés (JAMAIS dans le dépôt git) :
#   ghafla-upload.jks       la clé privée : à sauvegarder ailleurs, avec son mot de passe
#   keystore.env            les variables que lit tools/android-release.sh (chmod 600)
#   upload_certificate.pem  le certificat public (Google le demande pour enregistrer ou remplacer la clé d'importation)
#   FINGERPRINTS.txt        les empreintes SHA-1 et SHA-256 (à comparer avec la Play Console)
set -euo pipefail

DIR="${GHAFLA_KEYS:-$HOME/.ghafla-keys}"
ALIAS="ghafla-upload"
YEARS=30
NAME="${GHAFLA_KEY_NAME:-}"; ORG="${GHAFLA_KEY_ORG:-}"; UNIT="${GHAFLA_KEY_UNIT:-Jeux}"
CITY="${GHAFLA_KEY_CITY:-}"; STATE="${GHAFLA_KEY_STATE:-}"; COUNTRY="${GHAFLA_KEY_COUNTRY:-}"
YES=0

while [ $# -gt 0 ]; do
  case "$1" in
    --dir) DIR="$2"; shift 2 ;;
    --alias) ALIAS="$2"; shift 2 ;;
    --years) YEARS="$2"; shift 2 ;;
    --name) NAME="$2"; shift 2 ;;
    --org) ORG="$2"; shift 2 ;;
    --unit) UNIT="$2"; shift 2 ;;
    --city) CITY="$2"; shift 2 ;;
    --state) STATE="$2"; shift 2 ;;
    --country) COUNTRY="$2"; shift 2 ;;
    --yes|-y) YES=1; shift ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Option inconnue : $1" >&2; exit 2 ;;
  esac
done

find_keytool() {
  if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/keytool" ]; then echo "$JAVA_HOME/bin/keytool"; return; fi
  command -v keytool 2>/dev/null && return
  for c in "/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin/keytool" "$HOME/android-studio/jbr/bin/keytool" /opt/android-studio/jbr/bin/keytool; do
    [ -x "$c" ] && { echo "$c"; return; }
  done
  return 1
}
KEYTOOL="$(find_keytool)" || { echo "keytool introuvable : installe un JDK 17+ (ou Android Studio, qui en contient un) et/ou définis JAVA_HOME." >&2; exit 1; }
KEYSTORE="$DIR/ghafla-upload.jks"
[ -f "$KEYSTORE" ] && { echo "Il existe déjà une clé : $KEYSTORE. Je ne l'écrase pas (supprime-la toi-même si tu es sûr)." >&2; exit 1; }

ask() {  # ask VAR "Question" "défaut"
  local var="$1" q="$2" def="${3:-}" val=""
  if [ -n "${!var}" ]; then return; fi
  if [ "$YES" -eq 1 ]; then printf -v "$var" '%s' "$def"; return; fi
  read -r -p "$q${def:+ [$def]} : " val
  printf -v "$var" '%s' "${val:-$def}"
}
ask NAME "Ton nom ou celui de ton studio" "Ghafla"
ask ORG "Organisation" "$NAME"
ask CITY "Ville" "Ville"
ask STATE "Région (facultatif)" "Etat"
ask COUNTRY "Pays (2 lettres, ex. FR)" "FR"

PASS="${GHAFLA_KEY_PASSWORD:-}"
if [ -z "$PASS" ]; then
  [ "$YES" -eq 1 ] && { echo "Avec --yes, fournis le mot de passe via GHAFLA_KEY_PASSWORD." >&2; exit 1; }
  read -r -s -p "Mot de passe de la clé (8 caractères minimum) : " PASS; echo
  read -r -s -p "Confirme : " PASS2; echo
  [ "$PASS" = "$PASS2" ] || { echo "Les mots de passe diffèrent." >&2; exit 1; }
fi
[ "${#PASS}" -ge 8 ] || { echo "Mot de passe trop court (8 caractères minimum)." >&2; exit 1; }

# les virgules et signes = casseraient le nom distinctif
clean() { echo "$1" | tr -d ',=+<>#;"\\'; }
DNAME="CN=$(clean "$NAME"), OU=$(clean "$UNIT"), O=$(clean "$ORG"), L=$(clean "$CITY"), ST=$(clean "$STATE"), C=$(clean "$COUNTRY")"

mkdir -p "$DIR"; chmod 700 "$DIR"
"$KEYTOOL" -genkeypair -v -keystore "$KEYSTORE" -alias "$ALIAS" -keyalg RSA -keysize 4096 \
  -validity $((YEARS * 365)) -storepass "$PASS" -keypass "$PASS" -dname "$DNAME"

cat > "$DIR/keystore.env" <<ENV
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$KEYSTORE"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="$ALIAS"
export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD="$PASS"
ENV
chmod 600 "$DIR/keystore.env" "$KEYSTORE"
"$KEYTOOL" -export -rfc -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$PASS" -file "$DIR/upload_certificate.pem" >/dev/null 2>&1
"$KEYTOOL" -list -v -keystore "$KEYSTORE" -alias "$ALIAS" -storepass "$PASS" 2>/dev/null | grep -E "SHA1|SHA256|Owner|Propriétaire|Valid|Valide" > "$DIR/FINGERPRINTS.txt" || true

cat <<MSG

Clé créée dans $DIR
  ghafla-upload.jks       la clé privée (à sauvegarder AILLEURS, avec son mot de passe)
  keystore.env            lu par tools/android-release.sh
  upload_certificate.pem  certificat public, à donner à Google si on te le demande
  FINGERPRINTS.txt        empreintes SHA-1 / SHA-256

$(cat "$DIR/FINGERPRINTS.txt")

Sans ce fichier .jks et son mot de passe, tu ne pourras plus envoyer de mises à jour signées avec cette clé
(Google peut réinitialiser une clé d'importation perdue, mais c'est une démarche manuelle).
Ne la commit jamais : *.jks et *.keystore sont ignorés par git.

Suite : tools/android-release.sh build --bump
MSG
