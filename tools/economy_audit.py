"""Run the actual Lua economies and 200 seeded greedy games, without dependencies."""
import json
import os
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[1]
save_dir = ROOT / 'build/economy-audit-home'
save_dir.mkdir(parents=True, exist_ok=True)
result = subprocess.run([str(ROOT / 'build/test/engine'), '--script', 'tools/economy_audit.lua'],
                        cwd=ROOT, env={**os.environ, 'SPRITE_SAVE_DIR': str(save_dir)},
                        text=True, capture_output=True, check=True)
report = None
for line in result.stdout.splitlines():
    if line.startswith('ECONOMY_JSON '):
        report = json.loads(line.removeprefix('ECONOMY_JSON '))
    else:
        print(line)
assert report is not None
path = ROOT / 'docs/economy-audit.json'
path.write_text(json.dumps(report, indent=2) + '\n')
print(f'Wrote {path.relative_to(ROOT)}')
