"""Deterministic projection/self-heal for the raw Challenge Campaign graph."""
from __future__ import annotations

from typing import Any

from gxb_backend.content.challenge_campaign_catalog import ChallengeCampaignCatalog


class ChallengeProjectionService:
    def __init__(self, catalog: ChallengeCampaignCatalog) -> None:
        self.catalog = catalog
        self._order = {cid: idx for idx, cid in enumerate(catalog.ordered_ids)}

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def wire_row(campaign_id: int, star: int = 0) -> dict[str, int]:
        return {
            "campaign_id": int(campaign_id),
            "star": max(0, min(3, int(star))),
            "daily_limit": 0,
            "reset_count": 0,
        }

    def project(self, raw: Any, *, gate_open: bool) -> tuple[list[dict[str, int]], list[int], bool]:
        """Return canonical Challenge rows, newly materialized IDs and changed flag.

        Projection is a fixpoint over *cleared* source-known nodes only. A star=0
        child never recursively opens its children. When the source-bounded gate
        is open all seven graph roots are seeded for compatibility.
        """
        original = raw
        if isinstance(raw, dict):
            raw = [value for value in raw.values() if isinstance(value, dict)]
        if not isinstance(raw, list):
            raw = []

        stars: dict[int, int] = {}
        for row in raw:
            if not isinstance(row, dict):
                continue
            cid = self._int(row.get("campaign_id"), 0)
            if not self.catalog.contains(cid):
                continue
            stars[cid] = max(stars.get(cid, 0), max(0, min(3, self._int(row.get("star"), 0))))

        before_ids = set(stars)
        if gate_open:
            for cid in self.catalog.roots:
                stars.setdefault(cid, 0)

        # The graph is acyclic/source-ordered, but use an explicit fixpoint so
        # self-heal remains correct for legacy state containing non-root clears.
        while True:
            added = False
            for cid, star in list(stars.items()):
                if star <= 0:
                    continue
                for child in self.catalog.children(cid):
                    if child not in stars:
                        stars[child] = 0
                        added = True
            if not added:
                break

        rows = [self.wire_row(cid, stars[cid]) for cid in sorted(stars, key=lambda v: self._order[v])]
        added_ids = [row["campaign_id"] for row in rows if row["campaign_id"] not in before_ids]
        changed = original != rows
        return rows, added_ids, changed
