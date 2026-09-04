#!/usr/bin/env python3
"""Compatibility wrapper for the Pass291 version-aware update controller.

The old single-manifest builder used to delete every prior gxb-local volume.
That is unsafe once published MID2 releases are immutable history. Use
``update_controller.py`` directly for normal operation; this wrapper remains so
old operator notes/scripts do not destroy the release chain.
"""
from __future__ import annotations
import argparse
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
import update_controller as uc


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--version", required=True)
    ap.add_argument("--silent", action="store_true")
    ap.add_argument("--disable", action="store_true", help="accepted for compatibility; Pass291 builds are always unpublished until explicit publish")
    ap.add_argument("--probe-only", action="store_true")
    args = ap.parse_args()
    if args.probe_only:
        raise SystemExit("--probe-only is retired under the immutable release registry; use a normal unpublished CODE_ONLY candidate or a dedicated test tree")
    print("[LOCAL-UPDATE][PASS291] delegating to update_controller.py CODE_ONLY candidate builder")
    print("[LOCAL-UPDATE][PASS291] build is unpublished by design; --disable is therefore redundant")
    uc.build_release(uc.CODE_ONLY, version=args.version, silent=bool(args.silent))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
