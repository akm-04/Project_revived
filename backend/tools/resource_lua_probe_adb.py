#!/usr/bin/env python3
"""Install/pull/remove the GXB v0.6 resource-pipeline Lua trace overlay.

This is an operator-run diagnostic helper.  It never runs ADB from server.py.
The overlay is written to the writable src_64 search path used ahead of the
packaged client source, and can be removed/restored after one reproduction.
"""

from __future__ import annotations

import argparse
import json
import os
import shlex
import subprocess
import sys
import time
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parent.parent
PAYLOAD = PROJECT_ROOT / "tools" / "client_probe_payload" / "xinyoudi.lua"
RUNTIME_ROOT = PROJECT_ROOT / "runtime_logs" / "resource_lua_probe"
DEFAULT_PACKAGE = "com.carolgames.gxb"


def run(cmd: list[str], *, input_bytes: bytes | None = None, check: bool = True) -> subprocess.CompletedProcess[bytes]:
    proc = subprocess.run(cmd, input=input_bytes, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    if check and proc.returncode != 0:
        raise RuntimeError(
            f"command failed ({proc.returncode}): {' '.join(shlex.quote(x) for x in cmd)}\n"
            f"stdout: {proc.stdout.decode('utf-8', 'replace')}\n"
            f"stderr: {proc.stderr.decode('utf-8', 'replace')}"
        )
    return proc


class AdbAccess:
    """Small privileged I/O adapter supporting adb-root, su, or run-as."""

    def __init__(self, adb: str, package: str) -> None:
        self.adb = adb
        self.package = package
        run([self.adb, "get-state"])
        self.mode = self._detect_mode()

    def _adb(self, *args: str, input_bytes: bytes | None = None, check: bool = True) -> subprocess.CompletedProcess[bytes]:
        return run([self.adb, *args], input_bytes=input_bytes, check=check)

    def _detect_mode(self) -> str:
        direct = self._adb("shell", "id", "-u", check=False)
        if direct.returncode == 0 and direct.stdout.strip() == b"0":
            return "root"

        su = self._adb("shell", "su", "-c", "id -u", check=False)
        if su.returncode == 0 and su.stdout.strip() == b"0":
            return "su"

        run_as = self._adb("shell", "run-as", self.package, "id", "-u", check=False)
        if run_as.returncode == 0 and run_as.stdout.strip().isdigit():
            return "run-as"

        raise RuntimeError(
            "ADB device is visible, but no supported app-private access is available. "
            "Need adb root, `su -c`, or `run-as <package>`."
        )

    def force_stop(self) -> None:
        self._adb("shell", "am", "force-stop", self.package)

    def _priv(self, command: str, *, input_bytes: bytes | None = None, check: bool = True) -> subprocess.CompletedProcess[bytes]:
        if self.mode == "root":
            return self._adb("shell", "sh", "-c", command, input_bytes=input_bytes, check=check)
        if self.mode == "su":
            return self._adb("shell", "su", "-c", command, input_bytes=input_bytes, check=check)
        return self._adb("shell", "run-as", self.package, "sh", "-c", command, input_bytes=input_bytes, check=check)

    def exists(self, remote: str) -> bool:
        proc = self._priv(f"test -f {shlex.quote(remote)}", check=False)
        return proc.returncode == 0

    def read(self, remote: str, *, required: bool = True) -> bytes:
        proc = self._priv(f"cat {shlex.quote(remote)}", check=False)
        if required and proc.returncode != 0:
            raise RuntimeError(
                f"could not read {remote}: {proc.stderr.decode('utf-8', 'replace')}"
            )
        return proc.stdout if proc.returncode == 0 else b""

    def write_bytes(self, data: bytes, remote: str) -> None:
        parent = str(Path(remote).parent).replace("\\", "/")
        self._priv(f"mkdir -p {shlex.quote(parent)}")
        self._priv(f"cat > {shlex.quote(remote)}", input_bytes=data)
        self._priv(f"chmod 0644 {shlex.quote(remote)}", check=False)

    def remove(self, remote: str) -> None:
        self._priv(f"rm -f {shlex.quote(remote)}")

    def listing(self, remote: str) -> str:
        proc = self._priv(f"ls -laR {shlex.quote(remote)} 2>&1", check=False)
        return proc.stdout.decode("utf-8", "replace")



def device_root(package: str, override: str) -> str:
    return override.rstrip("/") if override.strip() else f"/data/data/{package}/files/{package}"


def manifest_path() -> Path:
    return RUNTIME_ROOT / "active_probe_manifest.json"


def save_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(payload, ensure_ascii=False, indent=2), encoding="utf-8")


def install(args: argparse.Namespace) -> int:
    if not PAYLOAD.is_file():
        raise RuntimeError(f"probe payload missing: {PAYLOAD}")

    adb = AdbAccess(args.adb, args.package)
    root = device_root(args.package, args.device_root)
    remote_probe = f"{root}/src_64/app/xinyoudi.lua"
    remote_trace = f"{root}/resource_pipeline_trace.log"
    remote_lazy = f"{root}/lazyFile.json"
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup_dir = RUNTIME_ROOT / "backups" / stamp
    backup_dir.mkdir(parents=True, exist_ok=True)

    adb.force_stop()
    had_override = adb.exists(remote_probe)
    override_backup = ""
    previous_override = b""
    if had_override:
        previous_override = adb.read(remote_probe)
        local_backup = backup_dir / "xinyoudi.before.lua"
        local_backup.write_bytes(previous_override)
        override_backup = str(local_backup)

    lazy_backup = ""
    if adb.exists(remote_lazy):
        local_lazy = backup_dir / "lazyFile.before.json"
        local_lazy.write_bytes(adb.read(remote_lazy))
        lazy_backup = str(local_lazy)

    payload_bytes = PAYLOAD.read_bytes()
    strategy = "full_bundled_overlay"
    if had_override:
        marker = b"-- GXB EOL resource-pipeline diagnostic overlay (v0.6.0)."
        idx = payload_bytes.find(marker)
        if idx < 0:
            raise RuntimeError("probe marker missing from bundled payload")
        # Preserve a runtime/hot-update xinyoudi.lua if one already exists and
        # append only the diagnostic wrapper block to that exact version.
        payload_bytes = previous_override.rstrip() + b"\n\n" + payload_bytes[idx:]
        strategy = "append_to_existing_hot_override"

    adb.write_bytes(payload_bytes, remote_probe)
    adb.remove(remote_trace)

    manifest = {
        "installed_at": int(time.time()),
        "package": args.package,
        "device_root": root,
        "access_mode": adb.mode,
        "remote_probe": remote_probe,
        "remote_trace": remote_trace,
        "had_previous_override": had_override,
        "previous_override_backup": override_backup,
        "lazy_backup": lazy_backup,
        "payload": str(PAYLOAD),
        "install_strategy": strategy,
    }
    save_json(manifest_path(), manifest)

    print(f"[RESOURCE-LUA-PROBE] access={adb.mode}")
    print(f"[RESOURCE-LUA-PROBE] installed -> {remote_probe} ({strategy})")
    if had_override:
        print(f"[RESOURCE-LUA-PROBE] previous override backed up -> {override_backup}")
    print("[RESOURCE-LUA-PROBE] trace cleared; app remains stopped.")
    print("Launch GXB, reproduce campaign 200002 once, then run this tool with `pull`.")
    return 0


def pull(args: argparse.Namespace) -> int:
    adb = AdbAccess(args.adb, args.package)
    root = device_root(args.package, args.device_root)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    out = RUNTIME_ROOT / f"capture-{stamp}"
    out.mkdir(parents=True, exist_ok=True)

    # Stop first so append-only trace and lazy map are stable on disk.
    adb.force_stop()

    targets = {
        "resource_pipeline_trace.log": f"{root}/resource_pipeline_trace.log",
        "lazyFile.json": f"{root}/lazyFile.json",
        "version.json": f"{root}/version.json",
    }
    pulled: dict[str, Any] = {}
    for name, remote in targets.items():
        exists = adb.exists(remote)
        pulled[name] = {"remote": remote, "present": exists}
        if exists:
            data = adb.read(remote)
            (out / name).write_bytes(data)
            pulled[name]["bytes"] = len(data)

    # Capture both physical locations because boot searches writable res/web
    # before writable res, while historical updater validation aliases /web/.
    for rel, name in [
        ("res/web/skeletons/npc/zhuankuai", "res_web_zhuankuai_ls.txt"),
        ("res/skeletons/npc/zhuankuai", "res_legacy_zhuankuai_ls.txt"),
    ]:
        remote = f"{root}/{rel}"
        text = adb.listing(remote)
        (out / name).write_text(text, encoding="utf-8")

    # Pull Lua error DB when readable; host can inspect it later with sqlite3.
    app_base = f"/data/data/{args.package}"
    log_db = f"{app_base}/files/log.db"
    if adb.exists(log_db):
        data = adb.read(log_db)
        (out / "log.db").write_bytes(data)
        pulled["log.db"] = {"remote": log_db, "present": True, "bytes": len(data)}

    save_json(out / "capture_manifest.json", {
        "captured_at": int(time.time()),
        "package": args.package,
        "device_root": root,
        "access_mode": adb.mode,
        "files": pulled,
    })

    print(f"[RESOURCE-LUA-PROBE] capture -> {out}")
    trace = out / "resource_pipeline_trace.log"
    if trace.exists():
        print(f"[RESOURCE-LUA-PROBE] trace -> {trace}")
    else:
        print("[RESOURCE-LUA-PROBE] WARNING: trace file was not created; overlay may not have loaded.")
    print("[RESOURCE-LUA-PROBE] app remains stopped. Run `remove` before normal play.")
    return 0


def remove(args: argparse.Namespace) -> int:
    adb = AdbAccess(args.adb, args.package)
    path = manifest_path()
    if path.is_file():
        manifest = json.loads(path.read_text(encoding="utf-8"))
        root = str(manifest.get("device_root") or device_root(args.package, args.device_root)).rstrip("/")
        remote_probe = str(manifest.get("remote_probe") or f"{root}/src_64/app/xinyoudi.lua")
        had_previous = bool(manifest.get("had_previous_override"))
        backup = str(manifest.get("previous_override_backup") or "")
    else:
        root = device_root(args.package, args.device_root)
        remote_probe = f"{root}/src_64/app/xinyoudi.lua"
        had_previous = False
        backup = ""

    adb.force_stop()
    if had_previous:
        local_backup = Path(backup)
        if not local_backup.is_file():
            raise RuntimeError(f"cannot restore prior override; backup is missing: {local_backup}")
        adb.write_bytes(local_backup.read_bytes(), remote_probe)
        action = f"restored previous override from {local_backup}"
    else:
        adb.remove(remote_probe)
        action = "removed diagnostic override"

    if path.exists():
        archived = RUNTIME_ROOT / f"probe_manifest.removed-{time.strftime('%Y%m%d-%H%M%S')}.json"
        path.replace(archived)

    print(f"[RESOURCE-LUA-PROBE] {action}")
    print("[RESOURCE-LUA-PROBE] app remains stopped; launch normally when ready.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("install", "pull", "remove"))
    parser.add_argument("--adb", default=os.environ.get("ADB", "adb"))
    parser.add_argument("--package", default=DEFAULT_PACKAGE)
    parser.add_argument("--device-root", default="", help="override writable update root")
    args = parser.parse_args()

    if args.action == "install":
        return install(args)
    if args.action == "pull":
        return pull(args)
    return remove(args)


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"[RESOURCE-LUA-PROBE][ERROR] {type(exc).__name__}: {exc}", file=sys.stderr)
        raise SystemExit(1)
