"""Read and expose an optional backend-local MID2 resource update package.

This is intentionally separate from the runtime lazy resource gateway.  GXB's
UpdateScene consumes MID2 ``res`` descriptors, downloads ``resource.001`` etc,
assembles a ZIP, verifies its MD5, unzips into ``xyd.versionUpdatePath``, stores
the descriptor version, and restarts.  Writable ``src_32`` / ``src_64`` then
win through Lua's package.path search order.
"""
from __future__ import annotations

import json
import re
from pathlib import Path
from typing import Any

from gxb_backend.config import Settings


_RESOURCE_VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")


def parse_resource_version(value: object) -> tuple[int, int, int] | None:
    """Parse the three-component numeric grammar used by UpdateScene.compareVersion."""
    text = str(value or "").strip()
    match = _RESOURCE_VERSION_RE.fullmatch(text)
    if not match:
        return None
    return tuple(int(part) for part in match.groups())


def load_manifest(settings: Settings) -> dict[str, Any] | None:
    path = settings.local_update_manifest_path
    try:
        raw = json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        return None
    except Exception as exc:
        print(f"[UPDATE] invalid manifest {path}: {exc}")
        return None

    if not isinstance(raw, dict) or not bool(raw.get("enabled", False)):
        return None

    version = str(raw.get("version") or "").strip()
    package = str(raw.get("package") or "").strip()
    try:
        volume = int(raw.get("volume") or 0)
        size = int(raw.get("size") or 0)
    except (TypeError, ValueError):
        return None
    md5 = str(raw.get("md5") or "").strip().lower()
    if not version or not package or volume <= 0 or size <= 0 or len(md5) != 32:
        print(f"[UPDATE] enabled manifest is incomplete: {path}")
        return None
    if parse_resource_version(version) is None:
        print(
            f"[UPDATE] refusing unsafe resource version {version!r}: "
            "UpdateScene requires exactly N.N.N and crashes on suffixes"
        )
        return None
    if Path(package).name != package or "/" in package or "\\" in package:
        print(f"[UPDATE] refusing unsafe package base: {package!r}")
        return None

    # Each descriptor volume is fetched as <resource>.<NNN>. Verify the files
    # exist before telling a client an update is available.
    for idx in range(1, volume + 1):
        candidate = settings.local_update_dir / f"{package}.{idx:03d}"
        if not candidate.is_file():
            print(f"[UPDATE] missing volume {candidate}; update not advertised")
            return None

    return {
        "enabled": True,
        "version": version,
        "package": package,
        "volume": volume,
        "size": size,
        "md5": md5,
        "silent": bool(raw.get("silent", False)),
        "note": str(raw.get("note") or ""),
    }


def log_update_event(settings: Settings, event: str, **fields: Any) -> None:
    row = {"event": event, **fields}
    try:
        import time
        row["ts"] = int(time.time())
        settings.runtime_log_dir.mkdir(parents=True, exist_ok=True)
        path = settings.runtime_log_dir / "local_update_events.jsonl"
        with path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n")
    except Exception as exc:
        print(f"[UPDATE] log failed: {exc}")


def version_check_payload(settings: Settings, request: dict[str, Any]) -> dict[str, Any]:
    manifest = load_manifest(settings)
    base = {
        "is_appstore": 0,
        "is_inapp": 0,
        "is_review": 0,
        "need_restart": 0,
    }
    if manifest is None:
        return base

    current = str(request.get("v") or "").strip()
    target = str(manifest["version"])
    target_key = parse_resource_version(target)
    current_key = parse_resource_version(current)

    # Empty ``v`` is the source-observed clean-install state and should receive
    # the update.  For a valid numeric installed version, never advertise a
    # downgrade or re-advertise the same package.
    if current_key is not None and target_key is not None and current_key >= target_key:
        log_update_event(
            settings, "version_current_or_newer", current=current, target=target
        )
        return base

    resource = f"{settings.engine_base_url}/updates/{manifest['package']}"
    print(
        f"[UPDATE] advertise current={current!r} target={target!r} "
        f"volumes={manifest['volume']} resource={resource}"
    )
    log_update_event(
        settings, "advertise", current=current, target=target,
        volumes=int(manifest["volume"]), size=int(manifest["size"]),
        md5=str(manifest["md5"]), resource=resource, silent=bool(manifest["silent"]),
    )
    return {
        **base,
        "is_inapp": 1,
        # UpdateScene uses is_review to skip its confirmation dialog and enter
        # update_ immediately. This is operator-controlled and defaults false.
        "is_review": 1 if manifest["silent"] else 0,
        "res": [
            {
                "version": target,
                "volume": int(manifest["volume"]),
                "size": int(manifest["size"]),
                "md5": str(manifest["md5"]),
                "resource": resource,
            }
        ],
    }


def resolve_volume(settings: Settings, asset: str) -> Path | None:
    """Resolve one /updates route without allowing path traversal."""
    name = str(asset or "").strip()
    if not name or Path(name).name != name or "/" in name or "\\" in name:
        return None
    path = (settings.local_update_dir / name).resolve()
    root = settings.local_update_dir.resolve()
    try:
        path.relative_to(root)
    except ValueError:
        return None
    return path if path.is_file() else None
