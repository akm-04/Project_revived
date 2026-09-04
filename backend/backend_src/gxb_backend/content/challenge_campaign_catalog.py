"""Source-derived Challenge Campaign topology and deterministic first-clear catalog."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Any

CHALLENGE_CAMPAIGN_TYPE = 24
EXPECTED_ROWS = 144
EXPECTED_EDGES = 137
EXPECTED_ROOTS = (24111, 24211, 24311, 24411, 24511, 24611, 24711)
EXPECTED_FANOUT = 22


class ChallengeCampaignCatalog:
    """Read-only raw Challenge graph authority generated from effective ``src_64``."""

    def __init__(self, data_dir: Path) -> None:
        self.path = Path(data_dir) / "challenge_campaign_catalog.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        meta = raw.get("_meta") if isinstance(raw, dict) else None
        rows = raw.get("campaigns") if isinstance(raw, dict) else None
        ordered = raw.get("ordered_campaign_ids") if isinstance(raw, dict) else None
        roots = raw.get("roots") if isinstance(raw, dict) else None
        if not isinstance(meta, dict) or not isinstance(rows, dict) or not isinstance(ordered, list):
            raise ValueError("invalid ChallengeCampaignCatalog shape")
        if str(meta.get("source_resolution") or "") != "effective_merged":
            raise ValueError("ChallengeCampaignCatalog is not effective_merged")
        self._rows: dict[int, dict[str, Any]] = {}
        for key, value in rows.items():
            if not isinstance(value, dict):
                raise ValueError(f"invalid Challenge row {key}")
            cid = int(key)
            row = dict(value)
            if int(row.get("campaign_id", 0)) != cid:
                raise ValueError(f"Challenge row key/id mismatch {key}")
            row["parents"] = tuple(int(v) for v in row.get("parents", []))
            row["children"] = tuple(int(v) for v in row.get("children", []))
            awards = []
            for award in row.get("deterministic_init_awards", []):
                if not isinstance(award, dict):
                    raise ValueError(f"invalid Challenge award for {cid}")
                rate = int(award.get("increase_rate", 0))
                if rate <= 0 or rate % 10000 != 0:
                    raise ValueError(f"non-deterministic Challenge init rate for {cid}: {rate}")
                quantity = rate // 10000
                # ``item_num`` is retained as a source-derived audit assertion;
                # settlement uses the frozen Pass120 formula from increase_rate.
                if int(award.get("item_num", quantity)) != quantity:
                    raise ValueError(f"Challenge quantity mismatch for {cid}")
                awards.append({
                    "item_id": int(award.get("item_id", 0)),
                    "increase_rate": rate,
                    "item_num": quantity,
                })
            row["deterministic_init_awards"] = tuple(awards)
            self._rows[cid] = row
        self._ordered = tuple(int(v) for v in ordered)
        self._roots = tuple(int(v) for v in (roots or []))
        self._validate(meta)

    def _validate(self, meta: dict[str, Any]) -> None:
        if len(self._rows) != EXPECTED_ROWS or len(self._ordered) != EXPECTED_ROWS:
            raise ValueError("Challenge row count mismatch")
        if set(self._ordered) != set(self._rows):
            raise ValueError("Challenge ordered id set mismatch")
        edges = 0
        fanout = 0
        for cid, row in self._rows.items():
            children = tuple(row["children"])
            edges += len(children)
            fanout += int(len(children) > 1)
            if int(row.get("daily_limit", 0)) != 0 or int(row.get("dropbox_id", 0)) != 0 or int(row.get("sweep_reward", 0)) != 0:
                raise ValueError(f"Challenge row unexpectedly exposes sweep/repeat plane: {cid}")
            for child in children:
                child_row = self._rows.get(child)
                if child_row is None or cid not in child_row["parents"]:
                    raise ValueError(f"Challenge edge backlink mismatch {cid}->{child}")
        if edges != EXPECTED_EDGES or fanout != EXPECTED_FANOUT:
            raise ValueError("Challenge edge/fanout count mismatch")
        if self._roots != EXPECTED_ROOTS:
            raise ValueError(f"Challenge roots mismatch: {self._roots}")
        for cid in self._roots:
            if self._rows[cid]["parents"]:
                raise ValueError(f"Challenge root has parent: {cid}")
        if int(meta.get("row_count", -1)) != EXPECTED_ROWS or int(meta.get("edge_count", -1)) != EXPECTED_EDGES:
            raise ValueError("Challenge metadata count mismatch")

    def contains(self, campaign_id: Any) -> bool:
        try:
            return int(campaign_id) in self._rows
        except (TypeError, ValueError):
            return False

    def row(self, campaign_id: Any) -> dict[str, Any] | None:
        try:
            row = self._rows.get(int(campaign_id))
        except (TypeError, ValueError):
            return None
        return dict(row) if row is not None else None

    def children(self, campaign_id: Any) -> tuple[int, ...]:
        row = self.row(campaign_id)
        return tuple(row.get("children", ())) if row else ()

    def awards(self, campaign_id: Any) -> list[dict[str, int]]:
        row = self.row(campaign_id)
        if not row:
            return []
        return [dict(v) for v in row.get("deterministic_init_awards", ())]

    @property
    def roots(self) -> tuple[int, ...]:
        return self._roots

    @property
    def ordered_ids(self) -> tuple[int, ...]:
        return self._ordered
