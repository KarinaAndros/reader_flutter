#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."

signed=0
skip_build=0
for option in "$@"; do
  case "$option" in
    --signed) signed=1 ;;
    --skip-build) skip_build=1 ;;
    *) echo 'Usage: bash tool/release_ios.sh [--signed] [--skip-build]' >&2; exit 1 ;;
  esac
done
if [[ "$skip_build" == 0 ]]; then
  if [[ "$signed" == 1 ]]; then
    flutter build ios --release
  else
    flutter build ipa --release --no-codesign
  fi
fi
python3 - "$signed" <<'PY'
from pathlib import Path
import datetime
import hashlib
import plistlib
import re
import subprocess
import sys
import tempfile

signed = sys.argv[1] == '1'
archive = Path('build/ios/archive/Runner.xcarchive')
app = Path('build/ios/iphoneos/Runner.app') if signed else archive / 'Products/Applications/Runner.app'
with (app / 'Info.plist').open('rb') as source:
    info = plistlib.load(source)
version = info['CFBundleShortVersionString']
build = str(info['CFBundleVersion'])
expected = next(line.split(':', 1)[1].strip() for line in Path('pubspec.yaml').read_text().splitlines() if line.startswith('version:'))
assert f'{version}+{build}' == expected, 'Archive is stale. Rebuild first.'
identifiers = set(re.findall(r'PRODUCT_BUNDLE_IDENTIFIER = ([^;]+);', Path('ios/Runner.xcodeproj/project.pbxproj').read_text()))
identifiers = {identifier for identifier in identifiers if not identifier.endswith('.RunnerTests')}
assert identifiers == {info['CFBundleIdentifier']}, 'Bundle identifier changed. Rebuild first.'
assert info['CFBundleSupportedPlatforms'] == ['iPhoneOS'], 'Expected a device archive, not a simulator app.'
if signed:
    subprocess.run(['codesign', '--verify', '--deep', '--strict', str(app)], check=True)
    result = subprocess.run(['security', 'cms', '-D', '-i', str(app / 'embedded.mobileprovision')], check=True, capture_output=True)
    profile = plistlib.loads(result.stdout)
    assert profile['ExpirationDate'] > datetime.datetime.now(datetime.timezone.utc).replace(tzinfo=None), 'Provisioning profile expired.'
    assert profile['Entitlements']['application-identifier'].endswith('.' + info['CFBundleIdentifier']), 'Provisioning profile does not match the app.'
    print('Provisioning profile expires:', profile['ExpirationDate'].isoformat() + 'Z')
out = Path(f'build/releases/ios/v{version}')
out.mkdir(parents=True, exist_ok=True)
kind = 'signed' if signed else 'unsigned'
ipa = out / f'MYB-iOS-{version}-{kind}.ipa'
if ipa.exists():
    raise SystemExit(f'Archive already exists: {ipa}')
with tempfile.TemporaryDirectory(prefix='myb-ios-package-') as directory:
    payload = Path(directory) / 'Payload'
    payload.mkdir()
    subprocess.run(['ditto', str(app), str(payload / 'MYB.app')], check=True)
    if signed:
        subprocess.run(['codesign', '--verify', '--deep', '--strict', str(payload / 'MYB.app')], check=True)
    subprocess.run(['ditto', '-c', '-k', '--keepParent', str(payload), str(ipa.resolve())], check=True)
(out / 'SHA256SUMS').write_text(''.join(f'{hashlib.sha256(item.read_bytes()).hexdigest()}  {item.name}\n' for item in sorted(out.glob('*.ipa'))))
print(f'Prepared MYB {version} ({build}): {ipa}')
if signed:
    print('The IPA includes the Apple signature and device provisioning profile.')
else:
    print(f'Xcode archive: {archive}')
    print('This IPA is unsigned and requires Apple signing before installation on an iPhone.')
PY
