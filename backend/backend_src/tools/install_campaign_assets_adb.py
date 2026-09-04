#!/usr/bin/env python3
"""Install locally recovered lazy Campaign assets into the original Android client.

This is an operator-run EOL repair helper; the backend itself never invokes ADB.
Authoritative AssetDownload.lua behavior behind the patch:

* catalog paths are named ``res/web/...``;
* UpdateScene checks the writable physical resource as ``res/...`` (the
  intermediate ``web`` component is removed);
* AssetDownload:isFileExist() does not stat the file. It considers a resource
  present when its ``__lazy__res___web___...`` key is absent from the writable
  ``lazyFile.json``.

The helper therefore force-stops the app, copies only exact-MD5 assets already
resolved by the Stage 4A campaign asset audit, backs up lazyFile.json, removes
only those exact lazy keys, and writes the patched lazyFile.json back.
"""

from __future__ import annotations

import argparse
import hashlib
import json
import os
import shlex
import subprocess
import sys
import tempfile
import time
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_SUMMARY = PROJECT_ROOT / "runtime_logs/campaign_asset_summary.json"
DEFAULT_PACKAGE = "com.carolgames.gxb"


def md5_file(path: Path) -> str:
    digest = hashlib.md5()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


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
    def __init__(self, adb: str, package: str, device_root: str) -> None:
        self.adb = adb
        self.package = package
        self.device_root = device_root.rstrip("/")
        self.mode = self._detect_mode()
        self.owner = self._detect_owner() if self.mode == "root" else ""

    def _adb(self, *args: str, **kwargs: Any) -> subprocess.CompletedProcess[bytes]:
        return run([self.adb, *args], **kwargs)

    def _detect_mode(self) -> str:
        self._adb("get-state")
        root_id = self._adb("shell", "id", "-u", check=False)
        if root_id.returncode == 0 and root_id.stdout.strip() == b"0":
            return "root"
        run_as = self._adb("shell", "run-as", self.package, "id", "-u", check=False)
        if run_as.returncode == 0 and run_as.stdout.strip().isdigit():
            return "run-as"
        raise RuntimeError(
            "ADB can see the device, but neither root shell nor `run-as "
            f"{self.package}` is available. This helper intentionally will not guess "
            "a privileged copy method. Use a rooted/debuggable device or copy the "
            "generated files with your existing privileged workflow."
        )

    def _detect_owner(self) -> str:
        probe = f"{self.device_root}/lazyFile.json"
        proc = self._adb("shell", "stat", "-c", "%u:%g", probe, check=False)
        value = proc.stdout.decode("utf-8", "replace").strip()
        return value if proc.returncode == 0 and ":" in value else ""

    def force_stop(self) -> None:
        self._adb("shell", "am", "force-stop", self.package)

    def read(self, remote: str) -> bytes:
        if self.mode == "root":
            proc = self._adb("exec-out", "cat", remote)
        else:
            proc = self._adb("exec-out", "run-as", self.package, "cat", remote)
        return proc.stdout

    def write(self, local: Path, remote: str) -> None:
        remote_dir = str(Path(remote).parent).replace("\\", "/")
        if self.mode == "root":
            self._adb("shell", "mkdir", "-p", remote_dir)
            self._adb("push", str(local), remote)
            self._adb("shell", "chmod", "0644", remote, check=False)
            if self.owner:
                self._adb("shell", "chown", self.owner, remote, check=False)
            return

        # run-as mode: stream bytes through stdin as the app UID. This avoids
        # relying on /data/local/tmp ownership/copy semantics.
        mkdir = self._adb("shell", "run-as", self.package, "mkdir", "-p", remote_dir)
        if mkdir.returncode != 0:
            raise RuntimeError(mkdir.stderr.decode("utf-8", "replace"))
        data = local.read_bytes()
        self._adb(
            "shell", "run-as", self.package, "sh", "-c", f"cat > {shlex.quote(remote)}",
            input_bytes=data,
        )


def lazy_key(catalog_path: str) -> str:
    return "__lazy__" + "___".join(catalog_path.split("/"))


def physical_relative_path(catalog_path: str) -> str:
    """Return the runtime AssetDownload destination relative to update root.

    AssetDownload:downloadFile() writes the original catalog path verbatim
    (for example res/web/skeletons/...), even though UpdateScene's startup
    validator also understands a legacy res/... alias.  The installer should
    emulate the runtime downloader, not the startup alias.
    """
    return catalog_path.replace("\\", "/").lstrip("/")


def load_campaign(summary_path: Path, campaign_id: int) -> dict[str, Any]:
    payload = json.loads(summary_path.read_text(encoding="utf-8"))
    campaigns = payload.get("campaigns") if isinstance(payload, dict) else None
    row = campaigns.get(str(campaign_id)) if isinstance(campaigns, dict) else None
    if not isinstance(row, dict):
        raise RuntimeError(f"campaign {campaign_id} not found in {summary_path}")
    return row


def select_assets(campaign: dict[str, Any]) -> list[dict[str, Any]]:
    lazy_paths = set(str(x) for x in campaign.get("lazy_snapshot_paths") or [])
    selected: list[dict[str, Any]] = []
    for check in campaign.get("checks") or []:
        if not isinstance(check, dict):
            continue
        path = str(check.get("path") or "")
        if path not in lazy_paths:
            continue
        if check.get("status") != "present":
            continue
        resolved = str(check.get("resolved_path") or "")
        if not resolved or resolved.startswith("zip://"):
            # Normal Stage 4A.8 static store resolves to a real file. ZIP URIs
            # are intentionally not unpacked by this ADB helper.
            continue
        selected.append(check)
    return selected


def append_log(record: dict[str, Any]) -> None:
    log = PROJECT_ROOT / "runtime_logs" / "adb_asset_installs.jsonl"
    log.parent.mkdir(parents=True, exist_ok=True)
    with log.open("a", encoding="utf-8") as fh:
        fh.write(json.dumps(record, ensure_ascii=False, separators=(",", ":")) + "\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--campaign", type=int, required=True, help="campaign id already present in campaign_asset_summary.json")
    parser.add_argument("--summary", type=Path, default=DEFAULT_SUMMARY)
    parser.add_argument("--adb", default=os.environ.get("ADB", "adb"))
    parser.add_argument("--package", default=DEFAULT_PACKAGE)
    parser.add_argument("--device-root", default="", help="override writable update root")
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()

    summary_path = args.summary.expanduser().resolve()
    campaign = load_campaign(summary_path, args.campaign)
    assets = select_assets(campaign)
    if not assets:
        print(f"[ADB-ASSET] no locally-present lazy assets selected for campaign {args.campaign}")
        return 2

    device_root = args.device_root.strip() or f"/data/data/{args.package}/files/{args.package}"
    print(f"[ADB-ASSET] campaign={args.campaign} selected={len(assets)}")
    print(f"[ADB-ASSET] device_root={device_root}")

    verified: list[tuple[dict[str, Any], Path]] = []
    for check in assets:
        src = Path(str(check["resolved_path"])).expanduser()
        if not src.is_file():
            raise RuntimeError(f"resolved local file disappeared: {src}")
        expected = str(check.get("expected_md5") or "").lower()
        actual = md5_file(src)
        if expected and actual != expected:
            raise RuntimeError(f"MD5 changed for {src}: expected {expected}, got {actual}")
        verified.append((check, src))
        print(f"  OK {check['path']} <- {src}")

    if args.dry_run:
        print("[ADB-ASSET] dry-run: no device changes made")
        return 0

    adb = AdbAccess(args.adb, args.package, device_root)
    owner_note = f" owner={adb.owner}" if adb.owner else ""
    print(f"[ADB-ASSET] access mode={adb.mode}{owner_note}")
    adb.force_stop()

    remote_lazy = f"{device_root}/lazyFile.json"
    lazy_bytes = adb.read(remote_lazy)
    try:
        lazy = json.loads(lazy_bytes.decode("utf-8"))
    except Exception as exc:
        raise RuntimeError(f"could not parse remote {remote_lazy}: {exc}") from exc
    if not isinstance(lazy, dict):
        raise RuntimeError(f"remote {remote_lazy} is not a JSON object")

    backup_dir = PROJECT_ROOT / "runtime_logs" / "adb_backups"
    backup_dir.mkdir(parents=True, exist_ok=True)
    stamp = time.strftime("%Y%m%d-%H%M%S")
    backup = backup_dir / f"lazyFile.before-{args.campaign}-{stamp}.json"
    backup.write_bytes(lazy_bytes)
    print(f"[ADB-ASSET] backed up lazyFile -> {backup}")

    removed: list[str] = []
    installed: list[dict[str, Any]] = []
    for check, src in verified:
        catalog_path = str(check["path"])
        remote_rel = physical_relative_path(catalog_path)
        remote = f"{device_root}/{remote_rel}"
        adb.write(src, remote)
        key = lazy_key(catalog_path)
        if key in lazy:
            lazy.pop(key, None)
            removed.append(key)
        installed.append({
            "catalog_path": catalog_path,
            "source": str(src),
            "remote": remote,
            "md5": str(check.get("expected_md5") or ""),
            "lazy_key_removed": key in removed,
        })
        print(f"[ADB-ASSET] installed {catalog_path} -> {remote}")

    with tempfile.TemporaryDirectory(prefix="gxb_lazy_") as td:
        patched = Path(td) / "lazyFile.json"
        patched.write_text(json.dumps(lazy, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
        adb.write(patched, remote_lazy)

    record = {
        "ts": int(time.time()),
        "campaign_id": args.campaign,
        "summary": str(summary_path),
        "device_root": device_root,
        "access_mode": adb.mode,
        "lazy_backup": str(backup),
        "lazy_keys_removed": removed,
        "installed": installed,
    }
    append_log(record)
    print(f"[ADB-ASSET] patched {remote_lazy}; removed lazy keys={len(removed)}")
    print("[ADB-ASSET] app remains force-stopped. Launch it normally and retry the campaign.")
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except Exception as exc:
        print(f"[ADB-ASSET][ERROR] {type(exc).__name__}: {exc}", file=sys.stderr)
        raise SystemExit(1)
