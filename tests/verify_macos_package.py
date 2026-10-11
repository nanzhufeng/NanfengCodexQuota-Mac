#!/usr/bin/env python3
"""Verify the exact frozen DMG, its app bytes and a real read-only query in isolated settings."""
from pathlib import Path
import hashlib
import json
import plistlib
import subprocess
import tempfile
import time
root=Path(__file__).resolve().parent.parent
app=root/'dist/南枫 Codex 额度.app'
with (app/'Contents/Info.plist').open('rb') as stream: app_info=plistlib.load(stream)
dmg=root/f"dist/南枫Codex额度-Mac-v{app_info['CFBundleShortVersionString']}-universal.dmg"
mount=Path(tempfile.mkdtemp(prefix='nanfeng-quota-dmg-'))
probe=Path(tempfile.mkdtemp(prefix='nanfeng-quota-live-'))
attached=False
try:
    subprocess.run(['hdiutil','attach','-quiet','-readonly','-nobrowse','-mountpoint',str(mount),str(dmg)],check=True)
    attached=True
    mounted=mount/app.name
    binary=Path('Contents/MacOS/NanfengCodexQuota')
    def digest(path): return hashlib.sha256(path.read_bytes()).hexdigest()
    assert digest(app/binary)==digest(mounted/binary), 'DMG executable differs from frozen bundle'
    subprocess.run(['codesign','--verify','--deep','--strict',str(mounted)],check=True)
    with (mounted/'Contents/Info.plist').open('rb') as stream: info=plistlib.load(stream)
    assert info['CFBundleIdentifier']=='studio.nanzhufeng.codexquota.mac'
    assert info.get('LSUIElement') is not True, 'Bundle is incorrectly hidden as an agent app'
    assert info.get('LSApplicationCategoryType')=='public.app-category.utilities'
    arches=subprocess.check_output(['lipo','-archs',str(mounted/binary)],text=True).strip()
    assert set(arches.split())=={'arm64','x86_64'}
    with (probe/'process.log').open('w') as log:
        process=subprocess.Popen([str(mounted/binary),'--qa-root',str(probe),'--verify-live'],stdout=log,stderr=log)
        try: code=process.wait(timeout=60)
        except subprocess.TimeoutExpired:
            process.terminate(); process.wait(timeout=5); raise
    assert code==0
    checks=json.loads((probe/'native-qa.json').read_text())
    assert all(checks.values())
    live=json.loads((probe/'live-summary.json').read_text())
    baseline=json.loads((root/'.release/source-manifest.json').read_text())
    assert live['commit']==baseline['commit'] and live['dirty'] is False
    assert all(digest(root/p)==expected for p,expected in baseline['files'].items()), 'Production source changed after freezing'
    report={'commit':live['commit'],'version':info['CFBundleShortVersionString'],'bundle_id':info['CFBundleIdentifier'],'architectures':arches,'minimum_macos':info['LSMinimumSystemVersion'],'dmg_bytes':dmg.stat().st_size,'dmg_sha256':digest(dmg),'executable_sha256':digest(app/binary),'live_probe':str(probe),'real_service':live,'checks':checks,'signature':'ad-hoc; not Developer ID signed or notarized'}
    (root/'docs/qa/package-verification.json').write_text(json.dumps(report,ensure_ascii=False,indent=2)+'\n')
    print(json.dumps(report,ensure_ascii=False,indent=2))
finally:
    if attached:
        # macOS can briefly retain a just-read mount after the probe exits.
        for attempt in range(3):
            result=subprocess.run(['hdiutil','detach','-quiet',str(mount)])
            if result.returncode==0: break
            if attempt==2: result.check_returncode()
            time.sleep(0.5)
    mount.rmdir()
