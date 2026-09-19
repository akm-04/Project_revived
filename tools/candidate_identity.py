#!/usr/bin/env python3
"""Canonical backend candidate identity helper.

The product-tree identity is external metadata: it is computed from the final
candidate tree and may be recorded in PassMap/handoff material.  It is not
embedded back into the tree, avoiding a self-referential digest.
"""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ALGORITHM_ID = "gxb-candidate-tree-v1:path-nul-bytes-sorted-excluding-vcs-python-cache"
SNAPSHOT_MANIFEST = "SNAPSHOT_MANIFEST.sha256"


def _files(root: Path, *, include_snapshot_manifest: bool = True) -> list[Path]:
    root = root.resolve()
    out: list[Path] = []
    for p in root.rglob("*"):
        if not p.is_file() or ".git" in p.parts or "__pycache__" in p.parts or p.suffix in {".pyc", ".pyo"}:
            continue
        rel = p.relative_to(root).as_posix()
        if not include_snapshot_manifest and rel == SNAPSHOT_MANIFEST:
            continue
        out.append(p)
    return sorted(out, key=lambda p: p.relative_to(root).as_posix())


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def tree_identity(root: Path = ROOT) -> dict[str, object]:
    root = root.resolve()
    files = _files(root, include_snapshot_manifest=True)
    h = hashlib.sha256()
    for p in files:
        rel = p.relative_to(root).as_posix().encode("utf-8")
        h.update(rel)
        h.update(b"\0")
        h.update(p.read_bytes())
    return {
        "algorithm": ALGORITHM_ID,
        "product_tree_digest_sha256": h.hexdigest(),
        "file_count_excluding_git": len(files),
    }


def render_snapshot_manifest(root: Path = ROOT) -> str:
    root = root.resolve()
    rows = []
    for p in _files(root, include_snapshot_manifest=False):
        rel = p.relative_to(root).as_posix()
        rows.append(f"{sha256_file(p)}  {rel}")
    return "\n".join(rows) + "\n"


def verify_snapshot_manifest(root: Path = ROOT) -> dict[str, object]:
    root = root.resolve()
    manifest = root / SNAPSHOT_MANIFEST
    if not manifest.is_file():
        raise RuntimeError(f"missing {SNAPSHOT_MANIFEST}")
    expected = render_snapshot_manifest(root)
    actual = manifest.read_text()
    if actual != expected:
        exp_lines = expected.splitlines()
        got_lines = actual.splitlines()
        first = None
        for i, (a, b) in enumerate(zip(exp_lines, got_lines), 1):
            if a != b:
                first = f"line {i}: expected {a!r}, got {b!r}"
                break
        if first is None and len(exp_lines) != len(got_lines):
            first = f"line-count expected {len(exp_lines)}, got {len(got_lines)}"
        raise RuntimeError(f"{SNAPSHOT_MANIFEST} drift: {first or 'content mismatch'}")
    return {
        "snapshot_manifest_sha256": sha256_file(manifest),
        "snapshot_entry_count": len(expected.splitlines()),
    }


def main() -> None:
    ap = argparse.ArgumentParser()
    ap.add_argument("--root", type=Path, default=ROOT)
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--verify-snapshot", action="store_true")
    ap.add_argument("--write-snapshot", action="store_true")
    args = ap.parse_args()
    root = args.root.resolve()
    if args.write_snapshot:
        (root / SNAPSHOT_MANIFEST).write_text(render_snapshot_manifest(root))
    result = tree_identity(root)
    if args.verify_snapshot:
        result.update(verify_snapshot_manifest(root))
    if args.json:
        print(json.dumps(result, sort_keys=True))
    else:
        for k, v in result.items():
            print(f"{k} {v}")


if __name__ == "__main__":
    main()
