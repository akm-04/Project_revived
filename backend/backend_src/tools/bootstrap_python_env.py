#!/usr/bin/env python3
"""Create a reproducible backend-local Python environment."""

from __future__ import annotations

import argparse
import hashlib
import json
import platform
import subprocess
import sys
import venv
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
WHEELHOUSE = ROOT / "vendor" / "wheels" / "linux-x86_64-cp312"
MANIFEST = ROOT / "vendor" / "WHEELHOUSE.json"


def sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b""):
            digest.update(block)
    return digest.hexdigest()


def verify_wheelhouse() -> int:
    payload = json.loads(MANIFEST.read_text(encoding="utf-8"))
    files = payload.get("files", [])
    if not files:
        raise SystemExit("wheelhouse manifest has no files")
    for record in files:
        path = ROOT / record["path"]
        if not path.is_file() or path.stat().st_size != int(record["bytes"]):
            raise SystemExit(f"wheelhouse size/missing failure: {record['path']}")
        if sha256(path) != record["sha256"]:
            raise SystemExit(f"wheelhouse hash failure: {record['path']}")
    return len(files)


def compatible_offline_platform() -> bool:
    return (
        sys.version_info[:2] == (3, 12)
        and sys.platform.startswith("linux")
        and platform.machine().lower() in {"x86_64", "amd64"}
    )


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--venv", default=".venv", help="environment path relative to backend root")
    parser.add_argument("--runtime-only", action="store_true")
    parser.add_argument("--online", action="store_true", help="ignore bundled wheels and use configured index")
    args = parser.parse_args()

    target = (ROOT / args.venv).resolve()
    if ROOT not in target.parents:
        raise SystemExit("--venv must stay under the backend root")
    venv.EnvBuilder(with_pip=True, clear=False).create(target)
    python = target / ("Scripts/python.exe" if sys.platform == "win32" else "bin/python")
    requirements = ROOT / ("requirements.txt" if args.runtime_only else "requirements-dev.txt")

    command = [str(python), "-m", "pip", "install", "--disable-pip-version-check"]
    wheel_count = 0
    if not args.online and compatible_offline_platform():
        wheel_count = verify_wheelhouse()
        command.extend(["--no-index", "--find-links", str(WHEELHOUSE)])
    elif not args.online:
        raise SystemExit("bundled wheels target Linux x86_64 CPython 3.12; use --online elsewhere")
    command.extend(["-r", str(requirements)])
    subprocess.run(command, cwd=ROOT, check=True)
    print(
        json.dumps(
            {
                "status": "PASS",
                "venv": str(target.relative_to(ROOT)),
                "requirements": requirements.name,
                "offline_wheels_verified": wheel_count,
            },
            sort_keys=True,
            separators=(",", ":"),
        )
    )


if __name__ == "__main__":
    main()
