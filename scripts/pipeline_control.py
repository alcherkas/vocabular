#!/usr/bin/env python3
"""
pipeline_control.py — Manage the vocab pipeline control file.

Usage:
    python3 scripts/pipeline_control.py status        # show current command
    python3 scripts/pipeline_control.py run           # resume pipeline
    python3 scripts/pipeline_control.py pause         # pause after current cycle
    python3 scripts/pipeline_control.py stop          # stop immediately
    python3 scripts/pipeline_control.py after N       # stop after cycle N
"""
import json, sys
from pathlib import Path

CONTROL_FILE = Path("data/pipeline_control.json")
DEFAULT = {"command": "run", "after_cycle": None}

def load():
    if CONTROL_FILE.exists():
        return json.loads(CONTROL_FILE.read_text())
    return dict(DEFAULT)

def save(data):
    CONTROL_FILE.write_text(json.dumps(data, indent=2) + "\n")

def main():
    args = sys.argv[1:]
    if not args or args[0] == "status":
        d = load()
        print(f"command: {d.get('command', 'run')}")
        if d.get('after_cycle'):
            print(f"after_cycle: {d['after_cycle']}")
        return
    if args[0] == "run":
        save({"command": "run", "after_cycle": None})
        print("Pipeline set to: run")
    elif args[0] == "pause":
        d = load(); d["command"] = "pause"
        save(d); print("Pipeline set to: pause (will stop after current cycle)")
    elif args[0] == "stop":
        d = load(); d["command"] = "stop"
        save(d); print("Pipeline set to: stop (will stop after current batch)")
    elif args[0] == "after" and len(args) > 1:
        d = load(); d["after_cycle"] = int(args[1])
        save(d); print(f"Pipeline will stop after cycle {args[1]}")
    else:
        print(__doc__); sys.exit(1)

if __name__ == "__main__":
    main()
