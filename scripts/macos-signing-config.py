#!/usr/bin/env python3
"""Emit safely shell-quoted signing settings. Never print credentials or read a key."""
import json
import os
from pathlib import Path
import shlex
import sys
keys = {
    'quota_sign_identity': 'NANFENG_CODEX_QUOTA_MAC_SIGN_IDENTITY',
    'quota_sign_team': 'NANFENG_CODEX_QUOTA_MAC_EXPECTED_TEAM_ID',
    'quota_notary_profile': 'NANFENG_CODEX_QUOTA_MAC_NOTARY_PROFILE',
}
values = {k: os.environ.get(v, '') for k, v in keys.items()}
if not any(values.values()):
    path = Path.home() / '.config/nanfeng-signing/NanfengCodexQuota-Mac.json'
    if path.exists():
        try:
            data = json.loads(path.read_text())
            values = dict(zip(keys, [data.get(k, '') for k in ('identity', 'expectedTeamId', 'notaryProfile')]))
        except (OSError, ValueError):
            sys.exit('签名配置损坏；未读取或更改钥匙串。')
if not all(isinstance(v, str) and v.strip() for v in values.values()):
    sys.exit('正式发行需要完整的 App 专属签名配置；未选择替代身份。')
for key, value in values.items():
    print(f'{key}={shlex.quote(value)}')
