#!/usr/bin/env python3
"""Build backend-local local_assets/res from extracted community captures.

The current client catalog names resources as res/web/..., while older captures
may store the same payload as res/... . This tool discovers extracted directories
named exactly 'res', checks only exact catalog candidates, verifies MD5, then
places matching files into the normalized target res/web/... layout.

It does not blindly merge same-name old files. By default it hard-links matching
files when possible and falls back to copy across filesystems.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shutil
from collections import deque
from pathlib import Path, PurePosixPath

PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_CATALOG = PROJECT_ROOT / "data/resource_catalog/resource_catalog.json"
DEFAULT_TARGET = PROJECT_ROOT / "local_assets/res"


def md5_file(path: Path) -> str:
    h = hashlib.md5()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def discover_res_dirs(roots: list[Path], max_depth: int) -> list[Path]:
    out: list[Path] = []
    seen: set[str] = set()
    for raw_root in roots:
        root = raw_root.expanduser().resolve()
        if not root.exists() or not root.is_dir():
            print(f"[STATIC-ASSET][WARN] source missing/not-dir: {root}")
            continue
        q = deque([(root, 0)])
        while q:
            current, depth = q.popleft()
            key = str(current)
            if key in seen:
                continue
            seen.add(key)
            if current.name.lower() == "res":
                out.append(current)
                continue
            if depth >= max_depth:
                continue
            try:
                children = [p for p in current.iterdir() if p.is_dir()]
            except OSError:
                continue
            for child in children:
                q.append((child, depth + 1))
    return out


def source_candidates(res_root: Path, catalog_path: str) -> list[Path]:
    parts = PurePosixPath(catalog_path).parts
    if not parts or parts[0] != "res":
        return []
    rel = parts[1:]
    candidates = [res_root.joinpath(*rel)]
    if len(parts) >= 2 and parts[:2] == ("res", "web"):
        candidates.append(res_root.joinpath(*parts[2:]))
    # De-duplicate while preserving source priority.
    unique: list[Path] = []
    for path in candidates:
        if path not in unique:
            unique.append(path)
    return unique


def place_file(source: Path, target: Path, mode: str) -> str:
    target.parent.mkdir(parents=True, exist_ok=True)
    if target.exists() or target.is_symlink():
        target.unlink()
    if mode == "copy":
        shutil.copy2(source, target)
        return "copied"
    if mode == "symlink":
        target.symlink_to(source.resolve())
        return "symlinked"
    try:
        os.link(source, target)
        return "hardlinked"
    except OSError:
        shutil.copy2(source, target)
        return "copied-fallback"


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("sources", nargs="+", help="Archive parent(s) or extracted trees to search")
    ap.add_argument("--catalog", default=str(DEFAULT_CATALOG))
    ap.add_argument("--target", default=str(DEFAULT_TARGET))
    ap.add_argument("--max-depth", type=int, default=12)
    ap.add_argument("--mode", choices=("hardlink", "copy", "symlink"), default="hardlink")
    args = ap.parse_args()

    catalog_path = Path(args.catalog).expanduser().resolve()
    target_root = Path(args.target).expanduser().resolve()
    source_roots = [Path(value) for value in args.sources]
    res_dirs = discover_res_dirs(source_roots, max(0, args.max_depth))
    print(f"[STATIC-ASSET] discovered res roots={len(res_dirs)}")
    for path in res_dirs:
        print(f"  - {path}")
    if not res_dirs:
        return 2

    payload = json.loads(catalog_path.read_text(encoding="utf-8"))
    rows = payload.get("entries", []) if isinstance(payload, dict) else []
    matched = 0
    already = 0
    missing = 0
    mismatches = 0
    actions: dict[str, int] = {}
    missing_rows: list[dict] = []

    for row in rows:
        catalog_path_value = str(row.get("path", ""))
        expected = str(row.get("md5", "")).lower()
        if not catalog_path_value.startswith("res/") or len(expected) != 32:
            continue
        target = target_root.joinpath(*PurePosixPath(catalog_path_value).parts[1:])
        if target.exists():
            try:
                if md5_file(target) == expected:
                    already += 1
                    continue
            except OSError:
                pass

        found = None
        saw_wrong = False
        for res_root in res_dirs:
            for candidate in source_candidates(res_root, catalog_path_value):
                if not candidate.is_file():
                    continue
                try:
                    actual = md5_file(candidate)
                except OSError:
                    continue
                if actual == expected:
                    found = candidate
                    break
                saw_wrong = True
            if found:
                break

        if found:
            action = place_file(found, target, args.mode)
            actions[action] = actions.get(action, 0) + 1
            matched += 1
        else:
            missing += 1
            if saw_wrong:
                mismatches += 1
            if len(missing_rows) < 500:
                missing_rows.append({"path": catalog_path_value, "md5": expected, "saw_wrong_version": saw_wrong})

    target_root.mkdir(parents=True, exist_ok=True)
    summary = {
        "catalog": str(catalog_path),
        "target": str(target_root),
        "res_roots": [str(p) for p in res_dirs],
        "catalog_entries": len(rows),
        "new_matches": matched,
        "already_present": already,
        "missing": missing,
        "paths_with_wrong_version_seen": mismatches,
        "actions": actions,
        "missing_sample": missing_rows,
    }
    (target_root.parent / "static_asset_build_summary.json").write_text(
        json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8"
    )
    print(json.dumps({k: v for k, v in summary.items() if k != "missing_sample"}, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
