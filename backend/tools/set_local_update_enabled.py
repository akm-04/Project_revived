#!/usr/bin/env python3
"""Enable or disable the already-built backend-local MID2 update manifest."""
from __future__ import annotations

import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "local_assets" / "update_manifest.json"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("state", choices=("on", "off"))
    args = ap.parse_args()
    if not MANIFEST.is_file():
        raise SystemExit(f"No manifest: {MANIFEST}")
    raw = json.loads(MANIFEST.read_text(encoding="utf-8"))
    raw["enabled"] = args.state == "on"
    MANIFEST.write_text(json.dumps(raw, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"[LOCAL-UPDATE] enabled={raw['enabled']} manifest={MANIFEST}")
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
