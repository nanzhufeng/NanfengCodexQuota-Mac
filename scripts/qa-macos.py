#!/usr/bin/env python3
"""Native UI fixture run; no real account, model call, login item or installed app changes."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
root = Path(__file__).resolve().parent.parent
app = root / 'dist/南枫 Codex 额度.app/Contents/MacOS/NanfengCodexQuota'
qa = Path(tempfile.mkdtemp(prefix='nanfeng-quota-mac-qa-'))
fixture = qa / 'codex-fixture'
fixture.write_text(f'''#!{sys.executable}
import json,sys
from pathlib import Path
for line in sys.stdin:
    request=json.loads(line)
    if request['method']=='initialize':
        print(json.dumps({{'id':request['id'],'result':{{}}}}),flush=True)
    elif request['method']=='account/rateLimits/read':
        state=(Path({str(qa)!r})/'fixture-state').read_text() if (Path({str(qa)!r})/'fixture-state').exists() else 'success'
        if state=='failure':
            result={{'error':{{'code':-32000,'message':'network connection unavailable'}}}}
        else:
            limits={{}} if state=='missing' else {{'primary':{{'usedPercent':23,'windowDurationMins':300}},'secondary':{{'usedPercent':66,'windowDurationMins':10080,'resetsAt':1791955200}}}}
            result={{'result':{{'rateLimits':limits}}}}
        print(json.dumps({{'id':request['id'],**result}}),flush=True)
''')
fixture.chmod(0o700)
log = (qa / 'process.log').open('w')
try:
    process = subprocess.Popen([str(app), '--qa-root', str(qa), '--qa-cli', str(fixture), '--qa-run'], stdout=log, stderr=log)
    try:
        code = process.wait(timeout=65)
    except subprocess.TimeoutExpired:
        process.terminate()
        process.wait(timeout=5)
        raise
finally:
    log.close()
report = qa / 'native-qa.json'
results = json.loads(report.read_text()) if report.exists() else {'report_exists': False}
print(json.dumps({'qa_root':str(qa),'exit_code':code,'checks':results}, ensure_ascii=False, indent=2))
(root / 'docs/qa/native-qa-location.txt').write_text(str(qa)+'\n')
if code or not results or not all(results.values()):
    sys.exit(1)
