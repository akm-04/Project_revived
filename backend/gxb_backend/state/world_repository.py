"""Canonical normal-Campaign progression and commit helpers.

The supplied client simulates normal Campaign combat locally.  The backend owns
persistent map state around that simulation: the unlocked campaign rows, best
stars, chapter cursor, the pending MID113 -> MID114 session, and the conservative
source-derived first-clear item subset committed into canonical Backpack state.  Source-derived
campaign links are packaged in ``data/campaign_meta.json``; no next campaign ID
is guessed in handler code.
"""
from __future__ import annotations

import json
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .inventory_repository import InventoryRepository
from .player_state import PlayerState


class WorldRepository:
    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        inventory: InventoryRepository | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.inventory = inventory
        self._campaigns = self._load_campaign_meta()
        self._campaign_rewards = self._load_campaign_reward_meta()
        self._story_drop_campaigns, self._story_drop_partners = self._load_story_drop_meta()

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _load_campaign_meta(self) -> dict[str, dict[str, int]]:
        path = self.data_dir / "campaign_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            rows = data.get("campaigns") or {}
            return rows if isinstance(rows, dict) else {}
        except Exception as exc:
            print(f"[WORLD] could not load campaign metadata {path}: {exc}")
            return {}

    def _load_campaign_reward_meta(self) -> dict[str, dict[str, Any]]:
        path = self.data_dir / "campaign_reward_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            rows = data.get("campaigns") or {}
            return rows if isinstance(rows, dict) else {}
        except Exception as exc:
            print(f"[WORLD] could not load campaign reward metadata {path}: {exc}")
            return {}

    def _load_story_drop_meta(
        self,
    ) -> tuple[dict[str, dict[str, Any]], dict[str, dict[str, Any]]]:
        path = self.data_dir / "campaign_story_drop_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            campaigns = data.get("campaigns") or {}
            partners = data.get("partners") or {}
            if not isinstance(campaigns, dict) or not isinstance(partners, dict):
                raise ValueError("campaigns/partners must be objects")
            return campaigns, partners
        except Exception as exc:
            print(f"[WORLD] could not load story-drop metadata {path}: {exc}")
            return {}, {}

    def meta(self, campaign_id: Any) -> dict[str, int] | None:
        return self._campaigns.get(str(self._int(campaign_id, -1)))

    def story_drop_options(self, campaign_id: Any) -> list[int]:
        meta = self._story_drop_campaigns.get(str(self._int(campaign_id, -1))) or {}
        raw = meta.get("story_drop_partner") or []
        if not isinstance(raw, list):
            return []
        return [self._int(value) for value in raw if self._int(value) > 0]

    def story_drop_initial_star(self, table_id: Any) -> int:
        meta = self._story_drop_partners.get(str(self._int(table_id, -1))) or {}
        return max(0, self._int(meta.get("ini_star"), 0))

    def prepare_story_drop_claim(
        self, campaign_id: Any, table_id: Any, campaign_type: Any
    ) -> dict[str, Any]:
        """Validate MID2064 against source options and the pending MID113 session.

        BattleSpecialStory runs before MID114.  The current MID113 session is
        therefore the strongest source-compatible guard we have against an
        arbitrary story reward request.  A previously recorded claim in the
        same pending session is returned for idempotent same-choice retries.
        """
        self.normalize()
        cid = self._int(campaign_id, 0)
        selected = self._int(table_id, 0)
        ctype = self._int(campaign_type, 1)
        options = self.story_drop_options(cid)
        if selected <= 0 or selected not in options:
            return {"status": "invalid"}

        current = self._find_row(cid)
        if current is None:
            return {"status": "invalid"}

        pending = (
            self.player.active_campaign_battle
            if isinstance(self.player.active_campaign_battle, dict)
            else {}
        )
        if self._int(pending.get("campaign_id"), 0) != cid:
            return {"status": "invalid"}
        if self._int(pending.get("campaign_type"), 1) != ctype:
            return {"status": "invalid"}

        existing = pending.get("story_drop_claim")
        if isinstance(existing, dict):
            # Recovery-idempotency: the first successful MID2064 claim is the
            # authoritative choice for this pending battle. If the client-side
            # reward callback crashes and the user taps either choice again,
            # return the already-owned reward so BattleSpecialStory can finish
            # rather than wedging on an empty story_drop_awards response.
            existing_table = self._int(existing.get("table_id"), 0)
            existing_partner = self._int(existing.get("partner_id"), 0)
            if existing_table in options and existing_partner > 0:
                return {
                    "status": "existing",
                    "table_id": existing_table,
                    "partner_id": existing_partner,
                }
            return {"status": "already_claimed"}

        if self._int(current.get("is_partner_drop"), 0) == 1:
            return {"status": "already_claimed"}

        star = self.story_drop_initial_star(selected)
        if star <= 0:
            return {"status": "invalid"}
        return {"status": "new", "table_id": selected, "star": star}

    def record_story_drop_claim(
        self, campaign_id: Any, table_id: Any, partner_id: Any, *, persist: bool = True
    ) -> bool:
        """Persist the source-consumed partner-drop marker and pending claim."""
        self.normalize()
        cid = self._int(campaign_id, 0)
        selected = self._int(table_id, 0)
        owned_partner_id = self._int(partner_id, 0)
        current = self._find_row(cid)
        pending = (
            self.player.active_campaign_battle
            if isinstance(self.player.active_campaign_battle, dict)
            else {}
        )
        if (
            current is None
            or selected <= 0
            or owned_partner_id <= 0
            or selected not in self.story_drop_options(cid)
            or self._int(pending.get("campaign_id"), 0) != cid
        ):
            return False
        current["is_partner_drop"] = 1
        pending["story_drop_claim"] = {
            "table_id": selected,
            "partner_id": owned_partner_id,
        }
        self.player.active_campaign_battle = pending
        if persist:
            self._save()
        return True

    def _guaranteed_first_awards(self, campaign_id: int) -> list[dict[str, int]]:
        """Return the conservative source-derived first-clear award subset.

        campaign_dropbox.lua has no quantity column. A selected drop row maps to
        one item in MID114. Stage 4A.5 only enables rows whose increase_rate is
        exactly 10000; lower-rate rows are retained in metadata but are not
        rolled until their RNG semantics are verified.
        """
        meta = self._campaign_rewards.get(str(campaign_id)) or {}
        rows = meta.get("init_dropbox_rows") or []
        awards: list[dict[str, int]] = []
        for row in rows:
            if not isinstance(row, dict) or self._int(row.get("increase_rate"), 0) != 10000:
                continue
            item_id = self._int(row.get("item_id"), 0)
            if item_id > 0:
                awards.append({"item_id": item_id, "item_num": 1})
        return awards

    @staticmethod
    def _campaign_row(campaign_id: int, star: int) -> dict[str, int]:
        return {
            "campaign_id": int(campaign_id),
            "star": max(0, min(3, int(star))),
            "daily_limit": 0,
            "reset_count": 0,
            "is_partner_drop": 0,
        }

    def normalize(self) -> bool:
        """Migrate old hard-coded map defaults into explicit JSON state."""
        changed = False
        if not isinstance(self.player.world_map, dict):
            self.player.world_map = {}
            changed = True
        wm = self.player.world_map
        normal = wm.get("normal")
        if not isinstance(normal, list) or not normal:
            # Accessible but unbeaten.  Stage 3 incorrectly seeded star=3,
            # which exposed Raid before the first real clear.
            normal = [self._campaign_row(100001, 0)]
            wm["normal"] = normal
            changed = True
        else:
            cleaned = []
            for row in normal:
                if not isinstance(row, dict):
                    continue
                cid = self._int(row.get("campaign_id"), 0)
                if cid <= 0:
                    continue
                cleaned.append({
                    "campaign_id": cid,
                    "star": max(0, min(3, self._int(row.get("star"), 0))),
                    "daily_limit": self._int(row.get("daily_limit"), 0),
                    "reset_count": self._int(row.get("reset_count"), 0),
                    "is_partner_drop": self._int(row.get("is_partner_drop"), 0),
                })
            if cleaned != normal:
                wm["normal"] = cleaned
                normal = cleaned
                changed = True
        for key, default in (("super", {}), ("challenge", {}), ("chapter_events", {})):
            if not isinstance(wm.get(key), type(default)):
                wm[key] = default
                changed = True
        chapter = wm.get("chapter_info")
        if not isinstance(chapter, dict):
            chapter = {}
            wm["chapter_info"] = chapter
            changed = True
        highest = self._frontier_campaign(normal) or 100001
        meta = self.meta(highest) or {}
        chapter_id = self._int(meta.get("chapter"), 1) or 1
        normalized_chapter = {
            **chapter,
            "normal_chapter_id": chapter_id,
            "normal_campaign_id": highest,
            "normal_stars": self._chapter_star_sum(normal, chapter_id),
            "normal_bonus_id": self._int(chapter.get("normal_bonus_id"), 0),
            "super_chapter_id": self._int(chapter.get("super_chapter_id"), 0),
            "super_campaign_id": self._int(chapter.get("super_campaign_id"), 0),
            "super_stars": self._int(chapter.get("super_stars"), 0),
            "super_bonus_id": self._int(chapter.get("super_bonus_id"), 0),
        }
        if normalized_chapter != chapter:
            wm["chapter_info"] = normalized_chapter
            changed = True
        if not isinstance(self.player.active_campaign_battle, dict):
            self.player.active_campaign_battle = {}
            changed = True
        return changed

    def _normal_rows(self) -> list[dict[str, Any]]:
        self.normalize()
        return self.player.world_map["normal"]

    def _find_row(self, campaign_id: int) -> dict[str, Any] | None:
        for row in self._normal_rows():
            if self._int(row.get("campaign_id"), 0) == campaign_id:
                return row
        return None

    def _highest_unlocked(self, rows: list[dict[str, Any]]) -> int:
        return max((self._int(row.get("campaign_id"), 0) for row in rows if isinstance(row, dict)), default=0)

    def _frontier_campaign(self, rows: list[dict[str, Any]]) -> int:
        """Return the source-chain frontier among currently unlocked rows.

        Campaign IDs are not contiguous (the opening chain is
        100001 -> 100002 -> 100004), so progression must never use ``id + 1``.
        Prefer the persisted chapter cursor when it still names an unlocked
        row; otherwise find the row whose source-derived next campaign has not
        been unlocked yet.  The numeric fallback exists only for malformed
        legacy/hand-edited data with multiple disconnected frontiers.
        """
        ids = {
            self._int(row.get("campaign_id"), 0)
            for row in rows
            if isinstance(row, dict) and self._int(row.get("campaign_id"), 0) > 0
        }
        chapter = self.player.world_map.get("chapter_info") if isinstance(self.player.world_map, dict) else {}
        persisted = self._int((chapter or {}).get("normal_campaign_id"), 0)
        if persisted in ids:
            persisted_row = next(
                (row for row in rows if self._int(row.get("campaign_id"), 0) == persisted),
                None,
            )
            persisted_meta = self.meta(persisted) or {}
            persisted_next = self._int(persisted_meta.get("next_campaign_id"), 0)
            # A star-0 cursor is the currently playable unbeaten node. A
            # cleared terminal/no-next cursor is also valid. If its source next
            # node is already in the unlocked set, however, the cursor is stale
            # and we intentionally fall through to locate the real frontier.
            if (
                self._int((persisted_row or {}).get("star"), 0) == 0
                or persisted_next <= 0
                or persisted_next not in ids
            ):
                return persisted

        frontiers: list[int] = []
        for cid in ids:
            meta = self.meta(cid) or {}
            next_id = self._int(meta.get("next_campaign_id"), 0)
            if next_id <= 0 or next_id not in ids:
                frontiers.append(cid)
        if len(frontiers) == 1:
            return frontiers[0]
        return self._highest_unlocked(rows)

    def _chapter_star_sum(self, rows: list[dict[str, Any]], chapter: int) -> int:
        total = 0
        for row in rows:
            cid = self._int(row.get("campaign_id"), 0)
            meta = self.meta(cid) or {}
            if self._int(meta.get("chapter"), 0) == chapter:
                total += max(0, min(3, self._int(row.get("star"), 0)))
        return total

    def payload(self) -> dict[str, Any]:
        self.normalize()
        return self.player.world_map

    def begin_fight(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()
        campaign_id = self._int(req.get("campaign_id"), 0)
        current = self._find_row(campaign_id)
        first_clear_candidate = current is not None and self._int(current.get("star"), 0) <= 0
        staged_items = self._guaranteed_first_awards(campaign_id) if first_clear_candidate else []
        self.player.active_campaign_battle = {
            "campaign_id": campaign_id,
            "campaign_type": self._int(req.get("campaign_type"), 1),
            "formation": str(req.get("formation") or ""),
            "started_at": self.player.now(),
            "items": staged_items,
        }
        self._save()
        # SelectTeamWindow consumes ``items`` before building the local battle;
        # the same staged rows are committed to Backpack only after MID114 wins.
        return {"battle_id": 1, "report": {}, "seed": 1, "enemy_info": {}, "items": staged_items}

    def commit_fight_result(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()
        cid = self._int(req.get("campaign_id"), 0)
        star = max(0, min(3, self._int(req.get("star"), 0)))
        current = self._find_row(cid)
        was_cleared = current is not None and self._int(current.get("star"), 0) > 0
        pending = self.player.active_campaign_battle if isinstance(self.player.active_campaign_battle, dict) else {}
        staged_items = pending.get("items") if self._int(pending.get("campaign_id"), 0) == cid else None
        if current is None:
            if self.meta(cid) is None:
                self.player.active_campaign_battle = {}
                self._save()
                return {"is_win": 1 if star > 0 else 0, "result": 1 if star > 0 else 0, "items": []}
            current = self._campaign_row(cid, 0)
            self._normal_rows().append(current)
        if star > 0:
            current["star"] = max(self._int(current.get("star"), 0), star)

        touched = [current]
        meta = self.meta(cid) or {}
        next_id = self._int(meta.get("next_campaign_id"), 0)
        if star > 0 and next_id > 0 and self.meta(next_id) is not None:
            nxt = self._find_row(next_id)
            if nxt is None:
                nxt = self._campaign_row(next_id, 0)
                self._normal_rows().append(nxt)
                # BattleCreate treats a *different* returned campaign with
                # star=0 as a newly opened node. Only return that row when it
                # was actually unlocked by this result; replaying an older
                # stage must not repeatedly trigger the unlock animation.
                touched.append(nxt)

        highest = self._frontier_campaign(self._normal_rows()) or cid
        highest_meta = self.meta(highest) or meta
        chapter_id = self._int(highest_meta.get("chapter"), 1) or 1
        chapter_info = dict(self.player.world_map.get("chapter_info") or {})
        chapter_info.update({
            "normal_chapter_id": chapter_id,
            "normal_campaign_id": highest,
            "normal_stars": self._chapter_star_sum(self._normal_rows(), chapter_id),
            "normal_bonus_id": self._int(chapter_info.get("normal_bonus_id"), 0),
            "super_chapter_id": self._int(chapter_info.get("super_chapter_id"), 0),
            "super_campaign_id": self._int(chapter_info.get("super_campaign_id"), 0),
            "super_stars": self._int(chapter_info.get("super_stars"), 0),
            "super_bonus_id": self._int(chapter_info.get("super_bonus_id"), 0),
        })
        self.player.world_map["chapter_info"] = chapter_info

        awarded_items: list[dict[str, int]] = []
        if star > 0 and not was_cleared:
            candidate_awards = staged_items if isinstance(staged_items, list) else self._guaranteed_first_awards(cid)
            if self.inventory is not None:
                awarded_items = self.inventory.add_items(candidate_awards, persist=False)

        self.player.active_campaign_battle = {}
        self._save()
        return {
            "is_win": 1 if star > 0 else 0,
            "result": 1 if star > 0 else 0,
            "chapter_info": chapter_info,
            "campaigns": touched,
            "items": awarded_items,
        }

    def sweep(self, req: dict[str, Any]) -> dict[str, Any]:
        self.normalize()
        cid = self._int(req.get("campaign_id"), 0)
        count = max(1, min(100, self._int(req.get("sweep_num"), 1)))
        row = self._find_row(cid) or self._campaign_row(cid, 0)
        reward_meta = self._campaign_rewards.get(str(cid)) or {}
        source_sweep = reward_meta.get("sweep_rewards") or []

        # campaign.lua explicitly pairs sweep_reward + sweep_reward_num. Only
        # those rows are granted here; normal/first-clear dropbox RNG remains a
        # separate contract. SweepWindow consumes one list of item_id/item_num
        # rows per sweep and adds them to its local Backpack.
        per_sweep: list[dict[str, int]] = []
        if self._int(row.get("star"), 0) > 0:
            for award in source_sweep:
                if not isinstance(award, dict):
                    continue
                item_id = self._int(award.get("item_id"), 0)
                item_num = self._int(award.get("item_num"), 0)
                if item_id > 0 and item_num > 0:
                    per_sweep.append({"item_id": item_id, "item_num": item_num})

        item_rows = [[dict(award) for award in per_sweep] for _ in range(count)]
        if per_sweep and self.inventory is not None:
            aggregate = [
                {"item_id": award["item_id"], "item_num": award["item_num"] * count}
                for award in per_sweep
            ]
            self.inventory.add_items(aggregate, persist=False)
            self._save()

        return {
            "items": item_rows,
            # SweepWindow defaults a missing economy.exp to 12 client-side.
            # Explicit zeroes prevent us from fabricating player EXP/mana until
            # those economy mutation semantics are reconstructed and persisted.
            "economys": [{"exp": 0, "mana": 0} for _ in range(count)],
            "additional": [],
            "campaign": row,
        }

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
