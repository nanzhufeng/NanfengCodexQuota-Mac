#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
export MACOSX_DEPLOYMENT_TARGET=13.0
assert_app_stopped() {
  python3 - <<'PY'
from pathlib import Path
import subprocess, sys
expected=str(Path('dist/南枫 Codex 额度.app/Contents/MacOS/NanfengCodexQuota').resolve())
matches=[]
for row in subprocess.check_output(['ps','-axo','pid=,comm='],text=True).splitlines():
    pid, command=row.strip().split(None,1)
    if command==expected: matches.append(pid)
if matches:
    sys.exit('构建目标仍在运行（PID '+','.join(matches)+'）；已阻止替换运行中的程序。')
PY
}
assert_app_stopped
mode=${1:---local}
if [[ "$mode" != "--local" && "$mode" != "--distribute" ]]; then
  echo '用法：build-macos.sh [--local|--distribute]' >&2; exit 2
fi
mkdir -p dist .release
# No artwork edits: each pixel size is sampled directly from the original transparent master.
iconset=.release/AppIcon.iconset
mkdir -p "$iconset"
for size in 16 32 128 256 512; do
  sips -z "$size" "$size" assets/app-icon-master.png --out "$iconset/icon_${size}x${size}.png" >/dev/null
  double=$((size * 2))
  sips -z "$double" "$double" assets/app-icon-master.png --out "$iconset/icon_${size}x${size}@2x.png" >/dev/null
done
iconutil -c icns "$iconset" -o .release/AppIcon.icns
for arch in arm64 x86_64; do
  if [[ "$arch" == arm64 ]]; then target=aarch64-apple-darwin; else target=x86_64-apple-darwin; fi
  cargo build --release --locked --lib --target "$target"
  xcrun swiftc -swift-version 5 -O -target "$arch-apple-macos13.0" \
    -import-objc-header macos/QuotaCore.h macos/*.swift \
    "target/$target/release/libnanfeng_codex_quota.a" \
    -framework AppKit -framework ServiceManagement -o ".release/NanfengCodexQuota-$arch"
done
app='dist/南枫 Codex 额度.app'
mkdir -p "$app/Contents/MacOS" "$app/Contents/Resources"
assert_app_stopped
lipo -create .release/NanfengCodexQuota-arm64 .release/NanfengCodexQuota-x86_64 -output .release/NanfengCodexQuota-universal.new
cp .release/NanfengCodexQuota-universal.new "$app/Contents/MacOS/NanfengCodexQuota.new"
mv "$app/Contents/MacOS/NanfengCodexQuota.new" "$app/Contents/MacOS/NanfengCodexQuota"
cp macos/Info.plist "$app/Contents/Info.plist"
cp .release/AppIcon.icns "$app/Contents/Resources/AppIcon.icns"
cp LICENSE NOTICE "$app/Contents/Resources/"
# Local executable signing is an ad-hoc seal, not a Developer ID distribution claim.
if [[ "$mode" == --local ]]; then
  codesign --force --sign - "$app"
  echo '签名边界：本地 ad-hoc，未进行 Developer ID 签名或 Apple 公证。'
else
  # Complete environment namespace takes precedence. Config stays outside the repository.
  signing_values=$(python3 scripts/macos-signing-config.py)
  eval "$signing_values"
  codesign --force --options runtime --timestamp --sign "$quota_sign_identity" "$app"
  codesign --display --verbose=4 "$app" 2> .release/signature.txt
  if ! /usr/bin/grep -Fq "TeamIdentifier=$quota_sign_team" .release/signature.txt; then echo '签名 Team ID 不匹配' >&2; exit 1; fi
  if ! /usr/bin/grep -Fq 'Authority=Developer ID Application:' .release/signature.txt; then echo '缺少 Developer ID 发行身份' >&2; exit 1; fi
fi
codesign --verify --deep --strict "$app"
plutil -lint "$app/Contents/Info.plist"
staging=.release/dmg-staging
mkdir -p "$staging"
# ditto preserves application symlinks and metadata without changing user's installed apps.
ditto "$app" "$staging/南枫 Codex 额度.app"
if [[ ! -e "$staging/Applications" && ! -L "$staging/Applications" ]]; then ln -s /Applications "$staging/Applications"; fi
dmg='dist/南枫Codex额度-Mac-v0.1.4-universal.dmg'
hdiutil create -quiet -ov -format UDZO -volname '南枫 Codex 额度' -srcfolder "$staging" "$dmg"
if [[ "$mode" == --distribute ]]; then
  codesign --force --timestamp --sign "$quota_sign_identity" "$dmg"
  xcrun notarytool submit "$dmg" --keychain-profile "$quota_notary_profile" --wait
  xcrun stapler staple "$dmg"
  xcrun stapler validate "$dmg"
fi
shasum -a 256 "$dmg" > "$dmg.sha256"
echo "已生成：$app"
echo "已生成：$dmg"
