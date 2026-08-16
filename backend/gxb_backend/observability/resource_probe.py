"""Runtime probe for the client's source-backed AssetDownload path.

``AssetDownload:getDownloadInfo_`` constructs each URL as::

    (xyd.resDownloadUrl or "") .. basename .. "." .. expected_md5

When center discovery advertises this backend's ``/res/`` prefix, any resource
that the client believes is missing reaches this probe.  The probe deliberately
never serves placeholder bytes: a wrong body would fail the client's MD5 check
and could be installed only if a future client stopped validating hashes.

Requests are de-duplicated into a compact summary because the native downloader
requeues failures immediately.  This module is diagnostic only and never
changes player/account state.
"""

from __future__ import annotations

import json
import re
import threading
import time
from pathlib import Path
from typing import Any

from flask import Request, make_response

from gxb_backend.config import Settings


_MD5_SUFFIX_RE = re.compile(r"^(?P<name>.+)\.(?P<md5>[0-9a-fA-F]{32})$")


class ResourceProbe:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.root: Path = settings.runtime_log_dir
        self.root.mkdir(parents=True, exist_ok=True)
        self._lock = threading.RLock()
        self._seen: dict[str, dict[str, Any]] = {}

    @staticmethod
    def _split_asset(asset: str) -> tuple[str, str]:
        match = _MD5_SUFFIX_RE.match(asset)
        if not match:
            return asset, ""
        return match.group("name"), match.group("md5").lower()

    def _append_first(self, record: dict[str, Any]) -> None:
        path = self.root / "resource_requests.jsonl"
        with path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(record, ensure_ascii=False, default=str, separators=(",", ":")) + "\n")

    def _write_summary(self) -> None:
        path = self.root / "resource_probe_summary.json"
        tmp = path.with_suffix(path.suffix + ".tmp")
        payload = {
            "generated_at": int(time.time()),
            "resource_base": self.settings.res_download_url,
            "unique_assets": len(self._seen),
            "assets": sorted(self._seen.values(), key=lambda item: (item["first_seen"], item["requested_asset"])),
        }
        tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2, default=str) + "\n", encoding="utf-8")
        tmp.replace(path)

    def capture(self, req: Request, asset: str):
        now = int(time.time())
        requested_asset = asset.lstrip("/")
        basename, expected_md5 = self._split_asset(requested_asset)

        with self._lock:
            existing = self._seen.get(requested_asset)
            if existing is None:
                record = {
                    "ts": now,
                    "kind": "asset_download_probe",
                    "requested_asset": requested_asset,
                    "basename": basename,
                    "expected_md5": expected_md5,
                    "method": req.method,
                    "remote_addr": req.remote_addr or "",
                    "user_agent": req.headers.get("User-Agent", ""),
                    "first_seen": now,
                    "last_seen": now,
                    "count": 1,
                }
                self._seen[requested_asset] = record
                self._append_first(record)
                md5_note = f" expected_md5={expected_md5}" if expected_md5 else ""
                print(f"[RESOURCE PROBE] missing resource requested: {requested_asset}{md5_note}")
            else:
                existing["last_seen"] = now
                existing["count"] = int(existing.get("count", 0)) + 1
                # Avoid flooding stdout while still making a persistent retry loop visible.
                if existing["count"] in {10, 100, 1000}:
                    print(f"[RESOURCE PROBE] retry x{existing['count']}: {requested_asset}")
            self._write_summary()

        # A 404 is intentional.  Serving fabricated bytes would only fail the
        # source-confirmed MD5 validation and could corrupt the update path.
        response = make_response("GXB resource probe: asset not present\n", 404)
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-GXB-Resource-Probe"] = "1"
        return response
