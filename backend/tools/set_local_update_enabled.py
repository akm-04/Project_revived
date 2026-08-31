#!/usr/bin/env python3
"""Retired Pass291 single-manifest toggle.

MID2 scheduling authority is release_registry.json. Published releases are
selected by client app/resource version; a global update_manifest on/off bit can
no longer safely represent that state.
"""
from __future__ import annotations
import argparse


def main() -> int:
    ap=argparse.ArgumentParser()
    ap.add_argument("state", choices=("on","off"))
    args=ap.parse_args()
    raise SystemExit(
        "Pass291 retired the global update_manifest toggle. "
        "Use `python3 update_controller.py status`, build an unpublished candidate, "
        "then `python3 update_controller.py publish` (or `activate`) when ready. "
        "Published release history is not deleted/disabled by this legacy helper."
    )

if __name__ == "__main__":
    raise SystemExit(main())
