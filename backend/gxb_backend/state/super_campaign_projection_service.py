"""Source-ordered Super Campaign projection/frontier owner."""
from __future__ import annotations

from typing import Any

from gxb_backend.content.super_campaign_catalog import SuperCampaignCatalog

from .player_state import PlayerState
from .unit_of_work import UnitOfWork


class SuperCampaignProjectionService:
    """Materialize source Super rows and derive server-issued Super cursors."""

    def __init__(
        self,
        player: PlayerState,
        catalog: SuperCampaignCatalog,
        uow: UnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.catalog = catalog
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _mark(self) -> None:
        if self.uow is not None and self.uow.active:
            self.uow.mark_changed("campaign_super_projection")

    def _world(self) -> dict[str, Any]:
        if not isinstance(self.player.world_map, dict):
            self.player.world_map = {}
        return self.player.world_map

    def _rows(self) -> list[dict[str, Any]]:
        world = self._world()
        rows = world.get("super")
        if not isinstance(rows, list):
            rows = []
            world["super"] = rows
        return rows

    def find_row(self, campaign_id: Any) -> dict[str, Any] | None:
        cid = self._int(campaign_id, 0)
        for row in self._rows():
            if isinstance(row, dict) and self._int(row.get("campaign_id"), 0) == cid:
                return row
        return None

    def _source_row(self, campaign_id: int) -> dict[str, int]:
        return {
            "campaign_id": int(campaign_id),
            "star": 0,
            "daily_limit": self.catalog.daily_limit(campaign_id),
            "reset_count": 0,
            "is_partner_drop": 0,
        }

    def ensure_first_frontier(self) -> tuple[dict[str, Any], bool]:
        existing = self.find_row(self.catalog.first_id)
        if existing is not None:
            return existing, False
        row = self._source_row(self.catalog.first_id)
        self._rows().append(row)
        self._mark()
        return row, True

    def materialize_next(self, cleared_campaign_id: Any) -> tuple[dict[str, Any] | None, bool]:
        next_id = self.catalog.next_id(cleared_campaign_id)
        if next_id <= 0:
            return None, False
        existing = self.find_row(next_id)
        if existing is not None:
            return existing, False
        row = self._source_row(next_id)
        self._rows().append(row)
        self._mark()
        return row, True

    def frontier_id(self) -> int:
        present = {
            self._int(row.get("campaign_id"), 0)
            for row in self._rows()
            if isinstance(row, dict)
        }
        frontier = 0
        for cid in self.catalog.ids():
            if cid in present:
                frontier = cid
        return frontier

    def _chapter_star_sum(self, chapter: int) -> int:
        if chapter <= 0:
            return 0
        total = 0
        for row in self._rows():
            if not isinstance(row, dict):
                continue
            cid = self._int(row.get("campaign_id"), 0)
            if self.catalog.chapter(cid) == chapter:
                total += max(0, min(3, self._int(row.get("star"), 0)))
        return total

    def recompute_cursors(self, *, function_open: bool) -> bool:
        world = self._world()
        chapter = world.get("chapter_info")
        if not isinstance(chapter, dict):
            chapter = {}
            world["chapter_info"] = chapter
        frontier = self.frontier_id() if function_open else 0
        frontier_chapter = self.catalog.chapter(frontier) if frontier else 0
        updates = {
            "super_chapter_id": frontier_chapter,
            "super_campaign_id": frontier,
            "super_stars": self._chapter_star_sum(frontier_chapter) if frontier_chapter else 0,
            "super_bonus_id": max(0, self._int(chapter.get("super_bonus_id"), 0)),
        }
        changed = False
        for key, value in updates.items():
            # Pass128.2 wire-contract hotfix: stock SelfPlayer.worldMapEvent_()
            # assigns these chapter_info fields directly and MapWindow performs
            # numeric comparisons without nil guards. A missing key is therefore
            # observably different from numeric zero on MID112, even when both
            # normalize to the same Python integer. Projection ownership includes
            # materializing every mandatory Super cursor key.
            if key not in chapter or self._int(chapter.get(key), 0) != value:
                chapter[key] = value
                changed = True
        if changed:
            self._mark()
        return changed

    def reconcile(self, *, function_open: bool, ensure_first: bool = True) -> bool:
        changed = False
        if function_open and ensure_first:
            _row, added = self.ensure_first_frontier()
            changed = changed or added
        if self.recompute_cursors(function_open=function_open):
            changed = True
        return changed
