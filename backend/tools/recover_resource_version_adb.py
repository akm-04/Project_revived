#!/usr/bin/env python3
"""Repair a malformed GXB Cocos UserDefault resource version on a rooted device.

v0.6.4's first MID2 probe allowed a label such as ``1.631.0-local1``.  The
client's UpdateScene.compareVersion() accepts only three numeric dot-separated
components and can crash before MID2 on the next launch.  This tool edits only
the Cocos shared-preference entry named ``__version__`` while preserving the
preference file's owner/group/mode.

The game is force-stopped before the edit and is left stopped afterward.
"""
from __future__ import annotations

import argparse
import re
import subprocess
import tempfile
import xml.etree.ElementTree as ET
from pathlib import Path

VERSION_RE = re.compile(r"^\d+\.\d+\.\d+$")
DEFAULT_PACKAGE = "com.carolgames.gxb"
DEFAULT_VERSION = "1.631.0"


def run(cmd: list[str], *, check: bool = True, text: bool = True) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, check=check, text=text, capture_output=True)


def adb_shell(serial: str | None, command: str, *, check: bool = True) -> subprocess.CompletedProcess:
    cmd = ["adb"]
    if serial:
        cmd += ["-s", serial]
    cmd += ["shell", command]
    return run(cmd, check=check)


def root_shell(serial: str | None, command: str, *, check: bool = True) -> subprocess.CompletedProcess:
    # The user's restoration workflow already uses su.  Keep this helper narrow
    # instead of guessing other privilege mechanisms.
    quoted = command.replace("'", "'\\''")
    return adb_shell(serial, f"su -c '{quoted}'", check=check)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--package", default=DEFAULT_PACKAGE)
    ap.add_argument("--version", default=DEFAULT_VERSION, help="safe numeric resource version (N.N.N)")
    ap.add_argument("--serial", help="optional adb device serial")
    args = ap.parse_args()

    if not VERSION_RE.fullmatch(args.version):
        raise SystemExit("--version must be exactly N.N.N, for example 1.631.0")

    package = args.package
    roots = [f"/data/data/{package}", f"/data/user/0/{package}"]
    root_shell(args.serial, f"am force-stop {package}")

    pref_path = ""
    for root in roots:
        result = root_shell(
            args.serial,
            f"grep -rl -- '__version__' {root}/shared_prefs 2>/dev/null | head -n 1",
            check=False,
        )
        candidate = result.stdout.strip()
        if candidate:
            pref_path = candidate
            break
    if not pref_path:
        raise SystemExit("Could not find a shared_prefs XML containing __version__; no change made")

    backup_path = pref_path + ".gxb_v064_bad_version_backup"
    root_shell(
        args.serial,
        f"test -f {backup_path} || cp {pref_path} {backup_path}",
    )
    old_xml = root_shell(args.serial, f"cat {pref_path}").stdout
    try:
        tree = ET.ElementTree(ET.fromstring(old_xml))
    except ET.ParseError as exc:
        raise SystemExit(f"Preference XML parse failed: {exc}") from exc

    changed = False
    old_value = None
    for node in tree.getroot():
        if node.attrib.get("name") == "__version__":
            old_value = node.text or ""
            node.text = args.version
            changed = True
            break
    if not changed:
        raise SystemExit(f"Found {pref_path}, but it has no __version__ entry")

    meta = root_shell(args.serial, f"stat -c '%u:%g %a' {pref_path}").stdout.strip().split()
    owner = meta[0] if meta else ""
    mode = meta[1] if len(meta) > 1 else "600"

    with tempfile.TemporaryDirectory(prefix="gxb-version-repair-") as td:
        local = Path(td) / "prefs.xml"
        tree.write(local, encoding="utf-8", xml_declaration=True)
        remote_tmp = "/sdcard/Download/gxb-cocos-prefs-repair.xml"
        adb = ["adb"]
        if args.serial:
            adb += ["-s", args.serial]
        run(adb + ["push", str(local), remote_tmp])
        root_shell(args.serial, f"cp {remote_tmp} {pref_path}")
        if owner:
            root_shell(args.serial, f"chown {owner} {pref_path}")
        root_shell(args.serial, f"chmod {mode} {pref_path}")
        adb_shell(args.serial, f"rm -f {remote_tmp}", check=False)

    verify = root_shell(args.serial, f"grep -n -- '__version__' {pref_path}").stdout.strip()
    print(f"[RECOVER] file={pref_path}")
    print(f"[RECOVER] backup={backup_path}")
    print(f"[RECOVER] __version__: {old_value!r} -> {args.version!r}")
    print(f"[RECOVER] verify: {verify}")
    print("[RECOVER] game remains force-stopped; start it normally when the server is ready")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
