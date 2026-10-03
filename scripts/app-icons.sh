#!/usr/bin/env bash
# Regenerates every app icon and splash screen (Android, iOS, web) from resources/logo.svg.
# Usage: ./scripts/app-icons.sh
# Needs: rsvg-convert (librsvg) and magick (ImageMagick 7).
set -euo pipefail
cd "$(dirname "$0")/.."

SVG=resources/logo.svg
RES=android/app/src/main/res
IOS=ios/App/App/Assets.xcassets
command -v rsvg-convert >/dev/null 2>&1 || { echo "Error: rsvg-convert not found (package librsvg)." >&2; exit 1; }
command -v magick >/dev/null 2>&1 || { echo "Error: magick not found (package imagemagick)." >&2; exit 1; }

tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
echo '#mark { display: none }' > "$tmp/background.css"
echo '#background { display: none }' > "$tmp/mark.css"

# Masters, 1024 px: the whole icon, its two layers, and the shapes of the pre-Android 8 icons.
rsvg-convert -w 1024 "$SVG" -o "$tmp/icon.png"
rsvg-convert -w 1024 --stylesheet "$tmp/background.css" "$SVG" -o "$tmp/background.png"
rsvg-convert -w 1024 --stylesheet "$tmp/mark.css" "$SVG" -o "$tmp/foreground.png"
mask() { # mask <draw command> <output>
  magick "$tmp/icon.png" \( -size 1024x1024 xc:black -fill white -draw "$1" \) -alpha off -compose CopyOpacity -composite "$2"
}
mask 'roundrectangle 0,0 1023,1023 225,225' "$tmp/legacy.png"
mask 'circle 511.5,511.5 511.5,0' "$tmp/round.png"

# Splash screens: the mark in the middle of a square that every screen ratio crops.
rsvg-convert -w 2732 --stylesheet "$tmp/background.css" "$SVG" -o "$tmp/splash-background.png"
rsvg-convert -w 900 --stylesheet "$tmp/mark.css" "$SVG" -o "$tmp/mark.png"
magick "$tmp/splash-background.png" "$tmp/mark.png" -gravity center -composite resources/splash.png
magick -size 2732x2732 xc:'#0e1513' "$tmp/mark.png" -gravity center -composite resources/splash-dark.png
magick "$tmp/icon.png" -resize 512x512 resources/icon.png

# Android launcher icons. The adaptive layers are 108 dp wide; mipmap-anydpi-v26 insets them so
# that the image fills the visible part, which keeps the star inside the safe zone.
while read -r density legacy adaptive; do
  dir="$RES/mipmap-$density"
  magick "$tmp/legacy.png" -resize "${legacy}x${legacy}" "$dir/ic_launcher.png"
  magick "$tmp/round.png" -resize "${legacy}x${legacy}" "$dir/ic_launcher_round.png"
  magick "$tmp/foreground.png" -resize "${adaptive}x${adaptive}" "$dir/ic_launcher_foreground.png"
  magick "$tmp/background.png" -resize "${adaptive}x${adaptive}" "$dir/ic_launcher_background.png"
done <<'SIZES'
ldpi 36 81
mdpi 48 108
hdpi 72 162
xhdpi 96 216
xxhdpi 144 324
xxxhdpi 192 432
SIZES

# Android splash screens: same sizes as the files in place, dark variant in the -night folders.
for file in "$RES"/drawable*/splash.png; do
  size=$(magick identify -format '%wx%h' "$file")
  case "$file" in *night*) source=resources/splash-dark.png ;; *) source=resources/splash.png ;; esac
  magick "$source" -resize "$size^" -gravity center -extent "$size" "$file"
done

# iOS: the icon must not have an alpha channel.
magick "$tmp/icon.png" -alpha off "$IOS/AppIcon.appiconset/AppIcon-512@2x.png"
for scale in 1x 2x 3x; do
  cp resources/splash.png "$IOS/Splash.imageset/Default@$scale~universal~anyany.png"
  cp resources/splash-dark.png "$IOS/Splash.imageset/Default@$scale~universal~anyany-dark.png"
done

# Web app (manifest and favicon).
magick "$tmp/icon.png" -resize 512x512 public/icon-512.png
magick "$tmp/legacy.png" -resize 64x64 public/favicon.png

echo "Done. Rebuild the apps to ship the new icon (./scripts/run.sh aab --bump, npx cap sync ios)."
