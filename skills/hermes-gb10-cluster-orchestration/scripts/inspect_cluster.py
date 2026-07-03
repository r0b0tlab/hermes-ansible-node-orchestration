#!/usr/bin/env python3
import json
import subprocess
import sys

inventory = sys.argv[1] if len(sys.argv) > 1 else "inventories/examples/three-node-gb10.yml"
cmd = ["ansible-inventory", "-i", inventory, "--list"]
result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, check=False)
if result.returncode != 0:
    print(result.stderr, file=sys.stderr)
    sys.exit(result.returncode)
data = json.loads(result.stdout)
print(json.dumps({"inventory": inventory, "groups": sorted(k for k in data if not k.startswith("_"))}, indent=2))
