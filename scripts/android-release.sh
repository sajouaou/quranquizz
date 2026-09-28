#!/usr/bin/env bash
# Builds a signed Android App Bundle (.aab) for the Play Store.
#
#   ./scripts/android-release.sh keygen            create a new upload key (once) + certificate for Google
#   ./scripts/android-release.sh                   build release/quranquizz-<version>.aab
#   ./scripts/android-release.sh --bump            same, after incrementing versionCode (required for each upload)
#   ./scripts/android-release.sh --version-name 1.2.0 --bump
#
# Needs: Node 22+, JDK 21, Android SDK (ANDROID_HOME, or Android Studio installed once).
set -euo pipefail
cd "$(dirname "$0")/.."

GRADLE_FILE=android/app/build.gradle
KEYSTORE=android/upload-keystore.jks
PROPS=android/keystore.properties
OUT=release

die() { echo "Error: $*" >&2; exit 1; }

check_java() {
  command -v java >/dev/null 2>&1 || die "JDK 21 is required (e.g. sudo apt install openjdk-21-jdk, or use the JDK bundled with Android Studio: export JAVA_HOME=~/android-studio/jbr)."
  local major
  major=$(java -version 2>&1 | awk -F'"' '/version/ {split($2, v, "."); print (v[1] == "1" ? v[2] : v[1])}')
  [ "${major:-0}" -ge 21 ] || die "JDK 21+ is required (found Java $major). Set JAVA_HOME to a JDK 21, e.g. export JAVA_HOME=~/android-studio/jbr"
}

keygen() {
  command -v keytool >/dev/null 2>&1 || die "keytool not found: install JDK 21 first."
  [ ! -f "$KEYSTORE" ] || die "$KEYSTORE already exists. Delete it only if you really want a new key."
  read -rp "Key password (6+ characters): " -s pass; echo
  [ ${#pass} -ge 6 ] || die "The password must be at least 6 characters."
  read -rp "Confirm password: " -s pass2; echo
  [ "$pass" = "$pass2" ] || die "Passwords don't match."
  read -rp "Your name or organisation (for the certificate): " cn
  keytool -genkeypair -keystore "$KEYSTORE" -alias upload -keyalg RSA -keysize 2048 -validity 10000 \
    -storepass "$pass" -keypass "$pass" -dname "CN=${cn:-Quran Quizz}"
  cat > "$PROPS" <<PROPS
storeFile=../upload-keystore.jks
storePassword=$pass
keyAlias=upload
keyPassword=$pass
PROPS
  chmod 600 "$PROPS" "$KEYSTORE" 2>/dev/null || true
  mkdir -p "$OUT"
  keytool -export -rfc -keystore "$KEYSTORE" -alias upload -storepass "$pass" -file "$OUT/upload_certificate.pem"
  echo
  echo "Key created: $KEYSTORE (keep a backup somewhere safe, it is not committed)."
  echo "Certificate for Google: $OUT/upload_certificate.pem"
  echo "Play Console > your app > Test and release > App integrity > App signing >"
  echo "  'Request upload key reset', and upload that .pem file."
}

build() {
  local bump=false version_name=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --bump) bump=true ;;
      --version-name) version_name="${2:?missing value}"; shift ;;
      *) die "Unknown option: $1" ;;
    esac
    shift
  done

  check_java
  if [ -z "${ANDROID_HOME:-${ANDROID_SDK_ROOT:-}}" ] && ! grep -qs '^sdk.dir' android/local.properties; then
    if [ -d "$HOME/Android/Sdk" ]; then export ANDROID_HOME="$HOME/Android/Sdk"
    else die "Android SDK not found. Install Android Studio (it downloads the SDK) or set ANDROID_HOME."; fi
  fi
  [ -f "$PROPS" ] || die "No signing key configured. Run: ./scripts/android-release.sh keygen (or create $PROPS, see README)."

  if $bump; then
    local code
    code=$(awk '/versionCode/ {print $2; exit}' "$GRADLE_FILE")
    sed -i.bak "s/versionCode $code/versionCode $((code + 1))/" "$GRADLE_FILE" && rm -f "$GRADLE_FILE.bak"
  fi
  if [ -n "$version_name" ]; then
    sed -i.bak "s/versionName \"[^\"]*\"/versionName \"$version_name\"/" "$GRADLE_FILE" && rm -f "$GRADLE_FILE.bak"
  fi
  local code name
  code=$(awk '/versionCode/ {print $2; exit}' "$GRADLE_FILE")
  name=$(awk -F'"' '/versionName/ {print $2; exit}' "$GRADLE_FILE")
  echo "==> Building version $name (code $code)"

  [ -d node_modules ] || ./scripts/setup.sh
  npm run build
  npx cap sync android
  chmod +x android/gradlew
  (cd android && ./gradlew --no-daemon clean bundleRelease)

  mkdir -p "$OUT"
  local aab="$OUT/quranquizz-$name-$code.aab"
  cp android/app/build/outputs/bundle/release/app-release.aab "$aab"
  echo
  echo "Signed bundle: $aab"
  keytool -printcert -jarfile "$aab" 2>/dev/null | grep -E "Owner|SHA1" || true
  echo "Upload it in Play Console > Test and release > Production (or Internal testing) > Create new release."
  $bump && echo "versionCode was changed in $GRADLE_FILE: commit it."
  return 0
}

case "${1:-}" in
  keygen) keygen ;;
  -h|--help) sed -n '2,10p' "$0" ;;
  *) build "$@" ;;
esac
