#!/usr/bin/env python3
"""Hash the backend-local Pass339 wheelhouse."""

from __future__ import annotations

import hashlib
import json
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WHEELHOUSE = ROOT / "vendor" / "wheels" / "linux-x86_64-cp312"
OUTPUT = ROOT / "vendor" / "WHEELHOUSE.json"


def digest(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def main() -> None:
    files = []
    for path in sorted(WHEELHOUSE.glob("*.whl"), key=lambda item: item.name.lower()):
        files.append(
            {
                "path": path.relative_to(ROOT).as_posix(),
                "bytes": path.stat().st_size,
                "sha256": digest(path),
            }
        )
    if not files:
        raise SystemExit("wheelhouse is empty")
    payload = {
        "schema_version": 1,
        "pass": "339.0",
        "platform": "Linux x86_64",
        "python": "CPython 3.12",
        "purpose": "offline tested runtime/test dependency bootstrap",
        "files": files,
    }
    OUTPUT.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(f"WHEELHOUSE MANIFEST: PASS files={len(files)}")


if __name__ == "__main__":
    main()
