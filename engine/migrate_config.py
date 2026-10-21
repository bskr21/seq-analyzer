"""Clean settings saved by v0.1-0.2, which wrote every default into config.json."""
import json, os, sys

p = sys.argv[1]
if os.path.exists(p):
    c = json.load(open(p))
    if c.get("configVersion", 0) < 3:
        old_defaults = {"tempoMode": "record", "leadBars": 2, "counts": True, "recordTempo": True,
                        "structure": "auto", "vocalThreshold": 0.12}
        for k, v in old_defaults.items():
            if c.get(k) == v:
                c.pop(k)
        for k in ("python", "engine"):   # install paths: always the defaults
            c.pop(k, None)
        c["configVersion"] = 3
        json.dump(c, open(p, "w"), indent=1)
