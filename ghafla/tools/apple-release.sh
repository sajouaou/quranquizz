#!/usr/bin/env bash
# Construit Ghafla pour macOS et iOS.
#
#   tools/apple-release.sh check           ce qui est prêt, ce qui manque (Xcode, identités de signature, variables)
#   tools/apple-release.sh templates       installe les modèles d'export de Godot
#   tools/apple-release.sh mac             export macOS universel (Intel + Apple Silicon) : export/Ghafla-macos.zip (peut se faire depuis Linux/Windows)
#   tools/apple-release.sh mac-sign        (sur un Mac) signe avec ton « Developer ID », notarise, agrafe, crée export/Ghafla.dmg
#   tools/apple-release.sh ios             export du projet Xcode : export/ios/Ghafla.xcodeproj (peut se faire depuis Linux/Windows)
#   tools/apple-release.sh ios-archive     (sur un Mac) archive + .ipa signé ; avec --upload, envoie à App Store Connect / TestFlight
#   tools/apple-release.sh bump            build + 1 pour macOS et iOS
#
# Variables (à mettre dans ton shell ou dans ~/.ghafla-apple.env, jamais dans git) :
#   APPLE_TEAM_ID         identifiant d'équipe à 10 caractères (developer.apple.com > Compte > Adhésion)
#   APPLE_SIGN_IDENTITY   « Developer ID Application: Ton Nom (TEAMID) » pour mac-sign
#   APPLE_ID              ton identifiant Apple, pour la notarisation
#   APPLE_APP_PASSWORD    mot de passe SPÉCIFIQUE À L'APP (appleid.apple.com > Sécurité), pour la notarisation
#   BUNDLE_ID             défaut : lu dans export_presets.cfg (com.sajouaou.ghafla)
#
# Ce qui a été essayé : les exports « mac » et « ios » (projet Xcode) avec le Godot officiel sous Linux. Les étapes qui exigent un Mac
# (signature, notarisation, xcodebuild) n'ont PAS pu être exécutées dans l'environnement de développement : à essayer chez toi.
set -euo pipefail
cd "$(dirname "$0")/.."
source tools/_godot.sh
[ -f "$HOME/.ghafla-apple.env" ] && source "$HOME/.ghafla-apple.env"

PRESETS="export_presets.cfg"
die() { echo "Erreur : $*" >&2; exit 1; }
say() { echo "== $* =="; }
need_mac() { [ "$(uname -s)" = "Darwin" ] || die "cette étape exige un Mac (Xcode)."; }
bundle_id() { echo "${BUNDLE_ID:-$(grep -m1 '^application/bundle_identifier' "$PRESETS" | cut -d'"' -f2)}"; }

# Écrit temporairement l'identifiant d'équipe dans les presets (Godot refuse l'export iOS sans lui), puis restaure.
with_team_id() {
  : "${APPLE_TEAM_ID:?définis APPLE_TEAM_ID (Team ID Apple, 10 caractères)}"
  cp "$PRESETS" "$PRESETS.orig"
  trap 'mv -f "$PRESETS.orig" "$PRESETS"' EXIT
  sed -i.bak -E "s/^application\/app_store_team_id=\"[^\"]*\"/application\/app_store_team_id=\"$APPLE_TEAM_ID\"/; s/^codesign\/apple_team_id=\"[^\"]*\"/codesign\/apple_team_id=\"$APPLE_TEAM_ID\"/" "$PRESETS"
  rm -f "$PRESETS.bak"
  "$@"
}

cmd_check() {
  require_godot
  echo "Godot        : $GODOT_BIN"
  echo "Système      : $(uname -s)"
  if [ "$(uname -s)" = "Darwin" ]; then
    xcodebuild -version 2>/dev/null | head -1 || echo "Xcode        : MANQUANT (installe Xcode depuis l'App Store)"
    xcrun --find notarytool >/dev/null 2>&1 && echo "notarytool   : ok" || echo "notarytool   : MANQUANT (Xcode 13+)"
    echo "Identités de signature :"; security find-identity -v -p codesigning 2>/dev/null | sed 's/^/   /' || true
  else
    echo "(pas un Mac : seuls les exports « mac » et « ios » sont possibles ici ; la signature et xcodebuild exigent un Mac)"
  fi
  echo "Bundle ID    : $(bundle_id)"
  for v in APPLE_TEAM_ID APPLE_SIGN_IDENTITY APPLE_ID APPLE_APP_PASSWORD; do
    if [ -n "${!v:-}" ]; then echo "$v : défini"; else echo "$v : non défini"; fi
  done
}

cmd_templates() { tools/android-release.sh templates; }

cmd_mac() {
  require_godot
  mkdir -p export
  say "Export macOS (universel)"
  "$GODOT_BIN" --headless --path . --export-release "macOS" export/Ghafla-macos.zip
  ls -lh export/Ghafla-macos.zip
  echo "Signé « ad hoc » seulement : pour distribuer hors de ton Mac, lance  tools/apple-release.sh mac-sign  sur un Mac."
}

cmd_mac_sign() {
  need_mac
  : "${APPLE_SIGN_IDENTITY:?définis APPLE_SIGN_IDENTITY (ex. « Developer ID Application: Ton Nom (ABCDE12345) »)}"
  [ -f export/Ghafla-macos.zip ] || cmd_mac
  rm -rf export/mac && mkdir -p export/mac
  ditto -x -k export/Ghafla-macos.zip export/mac
  local app="export/mac/Ghafla.app"
  [ -d "$app" ] || die "Ghafla.app introuvable dans le zip"
  say "Signature (hardened runtime)"
  codesign --force --deep --options runtime --timestamp --entitlements tools/macos.entitlements --sign "$APPLE_SIGN_IDENTITY" "$app"
  codesign --verify --deep --strict --verbose=2 "$app"
  if [ -n "${APPLE_ID:-}" ] && [ -n "${APPLE_APP_PASSWORD:-}" ] && [ -n "${APPLE_TEAM_ID:-}" ]; then
    say "Notarisation (quelques minutes)"
    ditto -c -k --keepParent "$app" export/mac/notarize.zip
    xcrun notarytool submit export/mac/notarize.zip --apple-id "$APPLE_ID" --team-id "$APPLE_TEAM_ID" --password "$APPLE_APP_PASSWORD" --wait
    xcrun stapler staple "$app"
    rm -f export/mac/notarize.zip
  else
    echo "APPLE_ID / APPLE_APP_PASSWORD / APPLE_TEAM_ID non définis : signature faite, notarisation SAUTÉE (macOS affichera un avertissement au premier lancement)."
  fi
  say "Image disque"
  rm -f export/Ghafla.dmg
  hdiutil create -volname "Ghafla" -srcfolder "$app" -ov -format UDZO export/Ghafla.dmg
  codesign --force --sign "$APPLE_SIGN_IDENTITY" --timestamp export/Ghafla.dmg
  ls -lh export/Ghafla.dmg
}

cmd_ios() {
  require_godot
  mkdir -p export/ios
  say "Export du projet Xcode"
  with_team_id "$GODOT_BIN" --headless --path . --export-release "iOS" export/ios/Ghafla.ipa
  echo "Projet Xcode : export/ios/Ghafla.xcodeproj"
  echo "Suite (sur un Mac) : tools/apple-release.sh ios-archive [--upload]   ou ouvre le projet dans Xcode."
}

cmd_ios_archive() {
  need_mac
  : "${APPLE_TEAM_ID:?définis APPLE_TEAM_ID}"
  local upload=0; [ "${1:-}" = "--upload" ] && upload=1
  [ -d export/ios/Ghafla.xcodeproj ] || cmd_ios
  say "Archive"
  rm -rf export/ios/Ghafla.xcarchive export/ios/ipa
  xcodebuild -project export/ios/Ghafla.xcodeproj -scheme Ghafla -configuration Release \
    -destination "generic/platform=iOS" -archivePath export/ios/Ghafla.xcarchive \
    -allowProvisioningUpdates DEVELOPMENT_TEAM="$APPLE_TEAM_ID" CODE_SIGN_STYLE=Automatic archive
  cat > export/ios/ExportOptions.plist <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
  <key>method</key><string>app-store-connect</string>
  <key>teamID</key><string>$APPLE_TEAM_ID</string>
  <key>signingStyle</key><string>automatic</string>
  <key>destination</key><string>$([ "$upload" -eq 1 ] && echo upload || echo export)</string>
  <key>uploadSymbols</key><true/>
</dict></plist>
PLIST
  say "$([ "$upload" -eq 1 ] && echo "Export et envoi à App Store Connect" || echo "Export du .ipa")"
  xcodebuild -exportArchive -archivePath export/ios/Ghafla.xcarchive -exportPath export/ios/ipa \
    -exportOptionsPlist export/ios/ExportOptions.plist -allowProvisioningUpdates
  [ "$upload" -eq 1 ] && echo "Envoyé : la version apparaît dans App Store Connect > TestFlight après traitement (quelques minutes)." || ls -lh export/ios/ipa
}

cmd_bump() {
  local cur next
  cur="$(grep -m1 '^application/version=' "$PRESETS" | cut -d'"' -f2)"
  next=$((cur + 1))
  sed -i.bak -E "s/^application\/version=\"[0-9]+\"/application\/version=\"$next\"/" "$PRESETS" && rm -f "$PRESETS.bak"
  echo "application/version (build) : $cur -> $next"
}

case "${1:-}" in
  check) cmd_check ;;
  templates) cmd_templates ;;
  mac) cmd_mac ;;
  mac-sign) cmd_mac_sign ;;
  ios) cmd_ios ;;
  ios-archive) shift; cmd_ios_archive "${1:-}" ;;
  bump) cmd_bump ;;
  *) sed -n '2,24p' "$0" | sed 's/^# \{0,1\}//'; exit 2 ;;
esac
