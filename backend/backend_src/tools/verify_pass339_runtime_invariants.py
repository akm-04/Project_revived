#!/usr/bin/env python3
"""Verify that Pass339 I0 did not alter frozen Pass299 runtime authority."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
MANIFEST = ROOT / "docs/json/PASS339_RUNTIME_INVARIANT_MANIFEST.json"


def included_files() -> list[Path]:
    paths: list[Path] = []
    for relative_root in ("gxb_backend", "data", "local_assets"):
        for path in (ROOT / relative_root).rglob("*"):
            if not path.is_file() or "__pycache__" in path.parts or path.suffix == ".pyc":
                continue
            relative = path.relative_to(ROOT).as_posix()
            if relative.startswith("gxb_backend/foundation/") or relative == "gxb_backend/version.py":
                continue
            paths.append(path)
    paths.extend((ROOT / "server.py", ROOT / "update_controller.py"))
    return sorted(paths, key=lambda path: path.relative_to(ROOT).as_posix())


def root_digest(paths: list[Path]) -> tuple[str, int]:
    digest = hashlib.sha256()
    content_bytes = 0
    for path in paths:
        relative = path.relative_to(ROOT).as_posix().encode("utf-8")
        content = path.read_bytes()
        content_bytes += len(content)
        digest.update(len(relative).to_bytes(4, "big"))
        digest.update(relative)
        digest.update(len(content).to_bytes(8, "big"))
        digest.update(content)
    return digest.hexdigest(), content_bytes


def main() -> None:
    expected = json.loads(MANIFEST.read_text(encoding="utf-8"))
    paths = included_files()
    digest, content_bytes = root_digest(paths)
    observed = {
        "file_count": len(paths),
        "content_bytes": content_bytes,
        "root_sha256": digest,
    }
    wanted = {key: expected[key] for key in observed}
    if observed != wanted:
        raise SystemExit(f"PASS339 RUNTIME INVARIANT: FAIL expected={wanted} observed={observed}")
    print(
        "PASS339 RUNTIME INVARIANT: PASS "
        f"files={len(paths)} bytes={content_bytes} sha256={digest}"
    )


if __name__ == "__main__":
    main()
