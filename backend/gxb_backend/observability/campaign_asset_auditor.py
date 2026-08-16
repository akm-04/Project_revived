"""Server-side Campaign asset dependency audit for EOL recovery.

The native FileDownloader can stall before issuing an HTTP GET.  This auditor
uses source-derived Campaign/Battle/Model metadata at MID113 time to report the
exact resource catalog paths and whether each exists in configured archives.
"""

from __future__ import annotations

import json
import threading
import time
from pathlib import Path
from typing import Any

from gxb_backend.config import Settings
from gxb_backend.observability.resource_gateway import ResourceGateway


class CampaignAssetAuditor:
    def __init__(self, settings: Settings, gateway: ResourceGateway | None) -> None:
        self.settings = settings
        self.gateway = gateway
        self._lock = threading.RLock()
        self._requirements = self._load()
        self._latest: dict[str, dict[str, Any]] = {}

    def _load(self) -> dict[str, dict[str, Any]]:
        path = self.settings.campaign_asset_requirements_path
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
            rows = payload.get("campaigns") or {}
            return rows if isinstance(rows, dict) else {}
        except Exception as exc:
            print(f"[CAMPAIGN ASSET] could not load {path}: {exc}")
            return {}

    def audit(self, campaign_id: Any) -> dict[str, Any]:
        try:
            cid = int(campaign_id)
        except (TypeError, ValueError):
            cid = 0
        row = self._requirements.get(str(cid)) or {}
        paths = row.get("paths") or []
        checks: list[dict[str, Any]] = []
        if self.gateway is not None:
            checks = [self.gateway.inspect_catalog_path(path) for path in paths if isinstance(path, str)]

        counts: dict[str, int] = {}
        for check in checks:
            status = str(check.get("status") or "unknown")
            counts[status] = counts.get(status, 0) + 1

        lazy_paths = [
            check["path"] for check in checks
            if check.get("lazy_missing_snapshot")
        ]
        # Only the snapshot's lazy-managed rows are candidates for the jellyfish
        # downloader. Catalog-miss/non-lazy rows may be force-packed/local and
        # are kept informational rather than labeled blocking.
        unresolved = [
            check for check in checks
            if check.get("lazy_missing_snapshot") and check.get("status") != "present"
        ]
        informational_missing = [
            check for check in checks
            if not check.get("lazy_missing_snapshot") and check.get("status") != "present"
        ]
        record = {
            "ts": int(time.time()),
            "campaign_id": cid,
            "fight_id": int(row.get("fight_id") or 0),
            "enemy_model_ids": row.get("enemy_model_ids") or [],
            "required_count": len(paths),
            "status_counts": counts,
            "lazy_snapshot_paths": lazy_paths,
            "unresolved_lazy": unresolved,
            "informational_missing": informational_missing,
            "checks": checks,
        }
        self._record(record)
        if paths:
            print(
                f"[CAMPAIGN ASSET] campaign={cid} fight={record['fight_id']} "
                f"required={len(paths)} present={counts.get('present', 0)} "
                f"lazy_snapshot={len(lazy_paths)} unresolved_lazy={len(unresolved)}"
            )
            for check in unresolved[:12]:
                print(f"[CAMPAIGN ASSET]   {check.get('status')}: {check.get('path')}")
        return record

    def _record(self, record: dict[str, Any]) -> None:
        root = self.settings.runtime_log_dir
        root.mkdir(parents=True, exist_ok=True)
        with self._lock:
            path = root / "campaign_asset_requirements.jsonl"
            with path.open("a", encoding="utf-8") as fh:
                fh.write(json.dumps(record, ensure_ascii=False, separators=(",", ":"), default=str) + "\n")
            self._latest[str(record["campaign_id"])] = record
            summary = root / "campaign_asset_summary.json"
            tmp = summary.with_suffix(summary.suffix + ".tmp")
            tmp.write_text(json.dumps({
                "generated_at": int(time.time()),
                "campaigns": self._latest,
            }, ensure_ascii=False, indent=2, default=str) + "\n", encoding="utf-8")
            tmp.replace(summary)
