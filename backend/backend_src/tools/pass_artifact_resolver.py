#!/usr/bin/env python3
"""Resolve historical PASS artifacts after root-clean packaging.

Canonical pass evidence keeps its original recorded relative paths. Portable
packaging moves top-level PASS JSON to docs/json and top-level PASS reports to
docs/pass-reports. This resolver preserves validator compatibility without
rewriting historical manifests or their recorded hashes.
"""
from __future__ import annotations
from pathlib import Path


def resolve_pass_artifact(root: Path, relative: str | Path) -> Path:
    root = Path(root)
    rel = Path(relative)
    direct = root / rel
    if direct.exists() or len(rel.parts) != 1 or not rel.name.startswith("PASS"):
        return direct
    if rel.suffix == ".json":
        moved = root / "docs" / "json" / rel.name
    elif rel.suffix in {".md", ".txt"}:
        moved = root / "docs" / "pass-reports" / rel.name
    else:
        return direct
    return moved if moved.exists() else direct
