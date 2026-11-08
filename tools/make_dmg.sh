#!/bin/zsh
# Builds Kite release, stages it, and creates macOS DMG and ZIP installers.
set -euo pipefail

here=${0:A:h}
root=${here:h}
name="Kite"
app="$HOME/Applications/$name.app"
version="${1:-1.3.0}"

if [[ ! -d "$app" ]]; then
    echo "App not found at $app. Running build.sh first..."
    "$root/build.sh"
fi

dist="$root/dist"
mkdir -p "$dist"

dmg_name="$name-$version-macOS.dmg"
dmg_path="$dist/$dmg_name"
zip_name="$name-$version-macOS.zip"
zip_path="$dist/$zip_name"
tmp_dmg="$dist/tmp.dmg"
stage_dir=$(mktemp -d /tmp/kite_dmg_stage.XXXXXX)

trap 'rm -rf "$stage_dir" "$tmp_dmg"' EXIT

echo "1. Staging $name.app for DMG creation..."
cp -R "$app" "$stage_dir/"
ln -s /Applications "$stage_dir/Applications"

echo "2. Building DMG installer..."
rm -f "$dmg_path" "$tmp_dmg" "$zip_path"

hdiutil create -volname "$name" -srcfolder "$stage_dir" -ov -format UDRW "$tmp_dmg" -quiet
hdiutil convert "$tmp_dmg" -format UDZO -imagekey zlib-level=9 -o "$dmg_path" -quiet
rm -f "$tmp_dmg"

echo "3. Creating ZIP release archive..."
ditto -c -k --keepParent "$app" "$zip_path"

echo "4. Generating SHA256 checksums..."
cd "$dist"
shasum -a 256 "$dmg_name" "$zip_name" > checksums.txt

echo "Build complete! Artifacts in $dist:"
ls -lh "$dist"
echo ""
echo "Checksums:"
cat checksums.txt
