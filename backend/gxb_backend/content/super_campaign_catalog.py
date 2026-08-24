"""Source-derived Normal<->Super Campaign relationship catalog.

Pass128 promotes the Pass75 effective-source ownership census into a dedicated
runtime read model.  The canonical relation is ``campaign.lua.relate_campaign_id``;
no arithmetic campaign-id transform is permitted.
"""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any


SUPER_CAMPAIGN_TYPE = 2
SUPER_FUNCTION_ID = 31
SUPER_FUNCTION_LEVEL = 11


class SuperCampaignCatalogError(RuntimeError):
    """The packaged source-derived Super Campaign metadata is inconsistent."""


class SuperCampaignCatalog:
    EXPECTED_ROWS = 155
    EXPECTED_FIRST_ID = 100019
    EXPECTED_TERMINAL_ID = 2300024

    def __init__(self, data_dir: Path) -> None:
        self.data_dir = Path(data_dir)
        self.path = self.data_dir / "pass75_campaign_ownership_meta.json"
        self._payload = self._load()
        campaigns = self._payload.get("campaigns")
        ids = self._payload.get("super_campaign_ids")
        if not isinstance(campaigns, dict) or not isinstance(ids, list):
            raise SuperCampaignCatalogError("Super Campaign ownership metadata shape invalid")
        self._ids = tuple(self._int(value) for value in ids if self._int(value) > 0)
        self._rows = {
            cid: dict(campaigns.get(str(cid)) or {})
            for cid in self._ids
        }
        self._order = {cid: index for index, cid in enumerate(self._ids)}
        self._validate(campaigns)

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _load(self) -> dict[str, Any]:
        try:
            payload = json.loads(self.path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise SuperCampaignCatalogError(f"could not load {self.path}: {exc}") from exc
        if not isinstance(payload, dict):
            raise SuperCampaignCatalogError("Super Campaign ownership metadata root must be object")
        meta = payload.get("_meta") if isinstance(payload.get("_meta"), dict) else {}
        if str(meta.get("source_resolution") or "") != "effective_merged":
            raise SuperCampaignCatalogError("Super Campaign ownership metadata is not effective_merged")
        return payload

    def _validate(self, campaigns: dict[str, Any]) -> None:
        if len(self._ids) != self.EXPECTED_ROWS or len(set(self._ids)) != self.EXPECTED_ROWS:
            raise SuperCampaignCatalogError(
                f"expected {self.EXPECTED_ROWS} unique Super rows, got {len(self._ids)}"
            )
        if not self._ids or self._ids[0] != self.EXPECTED_FIRST_ID:
            raise SuperCampaignCatalogError("unexpected first Super Campaign id")
        if self._ids[-1] != self.EXPECTED_TERMINAL_ID:
            raise SuperCampaignCatalogError("unexpected terminal Super Campaign id")

        normal_anchors: set[int] = set()
        for index, cid in enumerate(self._ids):
            row = self._rows[cid]
            if self._int(row.get("campaign_id"), 0) != cid:
                raise SuperCampaignCatalogError(f"Super row id mismatch for {cid}")
            if self._int(row.get("node_type"), 0) != 3:
                raise SuperCampaignCatalogError(f"Super row {cid} is not source node_type=3")
            anchor = self._int(row.get("relate_campaign_id"), 0)
            if anchor <= 0 or anchor in normal_anchors:
                raise SuperCampaignCatalogError(f"invalid/duplicate Normal anchor for Super {cid}")
            normal_anchors.add(anchor)
            normal = campaigns.get(str(anchor))
            if not isinstance(normal, dict):
                raise SuperCampaignCatalogError(f"missing Normal anchor {anchor} for Super {cid}")
            if self._int(normal.get("node_type"), 0) != 2:
                raise SuperCampaignCatalogError(f"Normal anchor {anchor} is not source node_type=2")
            if self._int(normal.get("relate_campaign_id"), 0) != cid:
                raise SuperCampaignCatalogError(f"relation is not bidirectional for Super {cid}")

            expected_last = self._ids[index - 1] if index > 0 else 0
            expected_next = self._ids[index + 1] if index + 1 < len(self._ids) else 0
            if self._int(row.get("last_campaign_id"), 0) != expected_last:
                raise SuperCampaignCatalogError(f"Super last_campaign_id chain mismatch at {cid}")
            if self._int(row.get("next_campaign_id"), 0) != expected_next:
                raise SuperCampaignCatalogError(f"Super next_campaign_id chain mismatch at {cid}")

    @property
    def first_id(self) -> int:
        return self._ids[0]

    @property
    def terminal_id(self) -> int:
        return self._ids[-1]

    def ids(self) -> tuple[int, ...]:
        return self._ids

    def contains(self, campaign_id: Any) -> bool:
        return self._int(campaign_id, 0) in self._rows

    def row(self, campaign_id: Any) -> dict[str, Any] | None:
        row = self._rows.get(self._int(campaign_id, 0))
        return dict(row) if isinstance(row, dict) else None

    def related_normal_id(self, campaign_id: Any) -> int:
        row = self._rows.get(self._int(campaign_id, 0)) or {}
        return self._int(row.get("relate_campaign_id"), 0)

    def next_id(self, campaign_id: Any) -> int:
        row = self._rows.get(self._int(campaign_id, 0)) or {}
        return self._int(row.get("next_campaign_id"), 0)

    def last_id(self, campaign_id: Any) -> int:
        row = self._rows.get(self._int(campaign_id, 0)) or {}
        return self._int(row.get("last_campaign_id"), 0)

    def chapter(self, campaign_id: Any) -> int:
        row = self._rows.get(self._int(campaign_id, 0)) or {}
        return self._int(row.get("chapter"), 0)

    def daily_limit(self, campaign_id: Any) -> int:
        row = self._rows.get(self._int(campaign_id, 0)) or {}
        return max(0, self._int(row.get("daily_limit"), 0))

    def order_index(self, campaign_id: Any) -> int:
        return self._order.get(self._int(campaign_id, 0), -1)
