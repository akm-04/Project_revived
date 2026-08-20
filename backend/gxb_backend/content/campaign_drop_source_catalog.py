"""Immutable source-derived Campaign drop catalog.

Pass40.1 separates effective-source facts from executable compatibility policy.
This catalog preserves ordered init/repeat dropbox rows and raw ``increase_rate``
values without assigning probability semantics to them.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from .game_data_catalog import CatalogNamespace, ContentRef


@dataclass(frozen=True)
class CampaignDropSourceRow:
    row_id: int
    dropbox_id: int
    item: ContentRef
    increase_rate: int
    pool_ordinal: int
    source_file_ordinal: int


@dataclass(frozen=True)
class CampaignDropSourceEntry:
    campaign_id: int
    campaign_row_ordinal: int
    source_campaign_type: int
    source_mode: str
    chapter: int
    init_dropbox_id: int
    repeat_dropbox_id: int
    init_rows: tuple[CampaignDropSourceRow, ...]
    repeat_rows: tuple[CampaignDropSourceRow, ...]


class CampaignDropSourceCatalog:
    """Read-only lookup over generated effective-source Campaign drop facts."""

    def __init__(self, data_dir: Path) -> None:
        self.data_dir = Path(data_dir)
        self.path = self.data_dir / "campaign_drop_source_catalog.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        campaigns = raw.get("campaigns") or {}
        if not isinstance(campaigns, dict):
            raise ValueError("campaign drop source catalog campaigns must be an object")
        self.schema_version = int(raw.get("schema_version") or 0)
        self.sources = raw.get("sources") if isinstance(raw.get("sources"), dict) else {}
        self._campaigns: dict[int, CampaignDropSourceEntry] = {}
        for key, value in campaigns.items():
            if not isinstance(value, dict):
                continue
            campaign_id = self._int(value.get("campaign_id"), self._int(key, 0))
            if campaign_id <= 0:
                continue
            self._campaigns[campaign_id] = CampaignDropSourceEntry(
                campaign_id=campaign_id,
                campaign_row_ordinal=self._int(value.get("campaign_row_ordinal"), 0),
                source_campaign_type=self._int(value.get("source_campaign_type"), 0),
                source_mode=str(value.get("source_mode") or "other"),
                chapter=self._int(value.get("chapter"), 0),
                init_dropbox_id=self._int(value.get("init_dropbox_id"), 0),
                repeat_dropbox_id=self._int(value.get("repeat_dropbox_id"), 0),
                init_rows=self._rows(value.get("init_dropbox_rows")),
                repeat_rows=self._rows(value.get("repeat_dropbox_rows")),
            )

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _rows(self, raw: Any) -> tuple[CampaignDropSourceRow, ...]:
        if not isinstance(raw, list):
            return ()
        rows: list[CampaignDropSourceRow] = []
        for value in raw:
            if not isinstance(value, dict):
                continue
            row_id = self._int(value.get("row_id"), 0)
            dropbox_id = self._int(value.get("dropbox_id"), 0)
            item_id = self._int(value.get("item_id"), 0)
            if row_id <= 0 or dropbox_id <= 0 or item_id <= 0:
                continue
            rows.append(
                CampaignDropSourceRow(
                    row_id=row_id,
                    dropbox_id=dropbox_id,
                    item=ContentRef(CatalogNamespace.ITEM, item_id),
                    increase_rate=self._int(value.get("increase_rate"), 0),
                    pool_ordinal=self._int(value.get("pool_ordinal"), len(rows) + 1),
                    source_file_ordinal=self._int(value.get("source_file_ordinal"), 0),
                )
            )
        return tuple(rows)

    def campaign(self, campaign_id: Any) -> CampaignDropSourceEntry | None:
        return self._campaigns.get(self._int(campaign_id, -1))

    def pool_for(self, campaign_id: Any, channel: str) -> tuple[int, tuple[CampaignDropSourceRow, ...]]:
        entry = self.campaign(campaign_id)
        if entry is None:
            return 0, ()
        if channel == "first_clear":
            return entry.init_dropbox_id, entry.init_rows
        if channel == "repeat":
            return entry.repeat_dropbox_id, entry.repeat_rows
        raise ValueError(f"unsupported Campaign drop channel: {channel}")
