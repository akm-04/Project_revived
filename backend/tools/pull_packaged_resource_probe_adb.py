#!/usr/bin/env python3
"""Pull the v0.6.1 packaged-Lua resource trace without stopping the game.

The primary trace path is the backend's runtime_logs/resource_client_probe.jsonl.
This helper is a fallback for the synchronous on-device file written by the Lua
probe. Unlike the old v0.6.0 helper, it does NOT force-stop the app by default.
"""

from __future__ import annotations

import argparse
import shlex
import subprocess
import time
from pathlib import Path


DEFAULT_PACKAGE = "com.carolgames.gxb"
PROJECT_ROOT = Path(__file__).resolve().parent.parent


def run(cmd: list[str], *, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    proc = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and proc.returncode != 0:
        raise RuntimeError(
            f"command failed ({proc.returncode}): {' '.join(shlex.quote(x) for x in cmd)}\n"
            f"stdout: {proc.stdout.decode('utf-8', 'replace')}\n"
            f"stderr: {proc.stderr.decode('utf-8', 'replace')}"
        )
    return proc


def detect_mode(adb: str, package: str) -> str:
    direct = run([adb, "shell", "id", "-u"], check=False)
    if direct.returncode == 0 and direct.stdout.strip() == b"0":
        return "root"
    su = run([adb, "shell", "su", "-c", "id -u"], check=False)
    if su.returncode == 0 and su.stdout.strip() == b"0":
        return "su"
    run_as = run([adb, "shell", "run-as", package, "id", "-u"], check=False)
    if run_as.returncode == 0 and run_as.stdout.strip().isdigit():
        return "run-as"
    raise RuntimeError("need adb root, `su -c`, or `run-as <package>` to read the app-private trace")


def read_remote(adb: str, package: str, mode: str, remote: str) -> bytes:
    quoted = shlex.quote(remote)
    if mode == "root":
        proc = run([adb, "shell", "sh", "-c", f"cat {quoted}"], check=False)
    elif mode == "su":
        proc = run([adb, "shell", "su", "-c", f"cat {quoted}"], check=False)
    else:
        proc = run([adb, "shell", "run-as", package, "sh", "-c", f"cat {quoted}"], check=False)
    if proc.returncode != 0:
        raise RuntimeError(f"could not read {remote}: {proc.stderr.decode('utf-8', 'replace')}")
    return proc.stdout


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--adb", default="adb")
    parser.add_argument("--package", default=DEFAULT_PACKAGE)
    parser.add_argument("--device-root", default="")
    parser.add_argument("--force-stop", action="store_true", help="stop the app before reading; off by default")
    args = parser.parse_args()

    run([args.adb, "get-state"])
    mode = detect_mode(args.adb, args.package)
    root = args.device_root.rstrip("/") if args.device_root else f"/data/data/{args.package}/files/{args.package}"
    remote = f"{root}/resource_pipeline_trace.log"

    if args.force_stop:
        run([args.adb, "shell", "am", "force-stop", args.package])

    data = read_remote(args.adb, args.package, mode, remote)
    out_dir = PROJECT_ROOT / "runtime_logs" / "resource_packaged_probe"
    out_dir.mkdir(parents=True, exist_ok=True)
    out = out_dir / f"resource_pipeline_trace-{time.strftime('%Y%m%d-%H%M%S')}.log"
    out.write_bytes(data)
    print(f"[RESOURCE-PROBE] access={mode} bytes={len(data)}")
    print(f"[RESOURCE-PROBE] saved -> {out}")
    if not args.force_stop:
        print("[RESOURCE-PROBE] app was not stopped.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
