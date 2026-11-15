#!/bin/bash
set -euo pipefail

# The signing key stays in the login Keychain; never export it into this repo.
cd "$(dirname "$0")/.."
if [[ "${1:-}" == "--skip-build" ]]; then
  shift
else
  flutter build macos --release
fi

app="build/macos/Build/Products/Release/MYB.app"
plist="$app/Contents/Info.plist"
version=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$plist")
build=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' "$plist")
expected=$(awk '/^version: / {print $2}' pubspec.yaml)
if [[ "$version+$build" != "$expected" ]]; then
  echo "Built version $version+$build differs from pubspec $expected. Rebuild first." >&2
  exit 1
fi
notes="${1:-releases/macos-$version.md}"
[[ -f "$notes" ]] || { echo "Missing release notes: $notes" >&2; exit 1; }
sparkle="build/macos/SourcePackages/artifacts/sparkle/Sparkle/bin"
account="com.example.flutterApp.sparkle"
public_key=$(/usr/libexec/PlistBuddy -c 'Print SUPublicEDKey' "$plist")
if [[ "$("$sparkle/generate_keys" --account "$account" -p)" != "$public_key" ]]; then
  echo 'The Keychain signing key does not match the installed app public key.' >&2
  exit 1
fi
codesign --verify --deep --strict "$app"
out="build/releases/v$version"
archive="MYB-macOS-$version.zip"
[[ ! -e "$out/$archive" ]] || { echo "Release archive already exists: $out/$archive" >&2; exit 1; }
mkdir -p "$out"
ditto -c -k --sequesterRsrc --keepParent "$app" "$out/$archive"
cp "$notes" "$out/MYB-macOS-$version.md"
echo 'Signing the release. macOS may request Keychain access for generate_appcast.'
"$sparkle/generate_appcast" --account "$account" \
  --download-url-prefix "https://github.com/KarinaAndros/reader_flutter/releases/download/v$version/" \
  --embed-release-notes --maximum-deltas 0 --maximum-versions 1 "$out"
echo 'Verifying signatures using the app public key.'
xcrun swift tool/verify_macos_release.swift "$plist" "$out/appcast.xml" "$out/$archive"
(cd "$out" && shasum -a 256 "$archive" appcast.xml > SHA256SUMS)
echo "Verified release $version ($build): $out"
echo "Publish $archive, appcast.xml and SHA256SUMS as assets of GitHub Release v$version."
