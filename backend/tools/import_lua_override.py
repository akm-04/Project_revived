#!/usr/bin/env python3
"""Import sparse Lua/data overrides into backend-local src_32/src_64.

Supports the recovery archive layout used by this project or an extracted
``com.carolgames.gxb`` writable tree. This does not build/enable MID2; it only
stages operator-selected source files under ``local_assets``.
"""
from __future__ import annotations

import argparse
import shutil
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOCAL = ROOT / "local_assets"


def write_pair(rel: str, data: bytes) -> None:
    rel = rel.lstrip("/")
    if rel.startswith("src_32/") or rel.startswith("src_64/"):
        rel = rel.split("/", 1)[1]
    for arch in ("src_32", "src_64"):
        target = LOCAL / arch / rel
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
        print(f"[LUA-IMPORT] {target}")


def from_archive(archive: Path, layer: str, rel: str) -> bytes:
    prefix = {
        "app": "app-assets/output/assets/src_64/",
        "downloaded": "downloaded-assets/output/src_64/",
    }[layer]
    name = prefix + rel.lstrip("/")
    with zipfile.ZipFile(archive) as zf:
        try:
            return zf.read(name)
        except KeyError:
            raise SystemExit(f"Archive does not contain {name}")


def from_tree(tree: Path, rel: str) -> bytes:
    rel = rel.lstrip("/")
    candidates = [tree / "src_64" / rel, tree / rel]
    for path in candidates:
        if path.is_file():
            return path.read_bytes()
    raise SystemExit("Could not find source file; tried: " + ", ".join(str(p) for p in candidates))


def main() -> int:
    ap = argparse.ArgumentParser()
    src = ap.add_mutually_exclusive_group(required=True)
    src.add_argument("--archive", type=Path)
    src.add_argument("--tree", type=Path)
    ap.add_argument("--layer", choices=("app", "downloaded"), default="downloaded")
    ap.add_argument("--path", required=True, help="relative path inside src_64, e.g. app/windows/LoginWindow.lua")
    args = ap.parse_args()

    rel = args.path.lstrip("/")
    data = from_archive(args.archive, args.layer, rel) if args.archive else from_tree(args.tree, rel)
    write_pair(rel, data)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
