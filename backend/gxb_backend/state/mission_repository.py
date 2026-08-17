"""Canonical Story Mission foundation for the early Campaign tutorial.

Pass 30 intentionally implements only Story Mission 80001. The repository owns
progress/claim persistence and delegates currency/items to EconomyRepository and
InventoryRepository. Source reward columns are generated from the effective
writable-over-APK mission/function/asset view.
"""
from __future__ import annotations

import copy
import json
from collections.abc import Callable
from pathlib import Path
from typing import Any

from .economy_repository import EconomyRepository
from .inventory_repository import InventoryRepository
from .player_state import PlayerState


class MissionRepository:
    STORY_TYPE = 4
    FIRST_STORY_MISSION = 80001

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        save_callback: Callable[[], None] | None = None,
        *,
        economy: EconomyRepository | None = None,
        inventory: InventoryRepository | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self._save_callback = save_callback
        self.economy = economy or EconomyRepository(player, self.data_dir)
        self.inventory = inventory or InventoryRepository(player)
        self.meta = self._load_meta()
        self.story_missions = self.meta.get("story_missions") or {}

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _load_meta(self) -> dict[str, Any]:
        path = self.data_dir / "story_mission_meta.json"
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
            meta = data.get("_meta") or {}
            if not isinstance(data, dict) or meta.get("source_resolution") != "effective_merged":
                raise ValueError("story mission metadata is not effective_merged")
            return data
        except Exception as exc:
            raise RuntimeError(f"[MISSION] invalid source metadata {path}: {exc}") from exc

    def _state_root(self) -> dict[str, Any]:
        if not isinstance(self.player.mission_state, dict):
            self.player.mission_state = {}
        story = self.player.mission_state.get("story")
        if not isinstance(story, dict):
            story = {}
            self.player.mission_state["story"] = story
        if not isinstance(story.get("missions"), dict):
            story["missions"] = {}
        if not isinstance(story.get("claimed"), list):
            story["claimed"] = []
        if not isinstance(story.get("claim_receipts"), dict):
            story["claim_receipts"] = {}
        return story

    def _meta_row(self, table_id: Any) -> dict[str, Any]:
        row = self.story_missions.get(str(self._int(table_id))) if isinstance(self.story_missions, dict) else None
        return row if isinstance(row, dict) else {}

    def _campaign_star(self, campaign_id: int) -> int:
        world = self.player.world_map if isinstance(self.player.world_map, dict) else {}
        rows = world.get("normal") if isinstance(world.get("normal"), list) else []
        for row in rows:
            if isinstance(row, dict) and self._int(row.get("campaign_id")) == campaign_id:
                return max(0, self._int(row.get("star")))
        return 0

    def _mission_row(self, table_id: int, *, count: int, is_complete: int, is_reward: int = 0) -> dict[str, int]:
        return {
            "table_id": int(table_id),
            "count": max(0, int(count)),
            "is_complete": 1 if is_complete else 0,
            "is_reward": 1 if is_reward else 0,
        }

    def normalize_story_80001(self) -> bool:
        """Seed/recover the chain root from canonical Campaign state."""
        meta = self._meta_row(self.FIRST_STORY_MISSION)
        if not meta:
            return False
        story = self._state_root()
        claimed = {self._int(value) for value in story.get("claimed", [])}
        missions = story["missions"]
        key = str(self.FIRST_STORY_MISSION)
        changed = False

        if self.FIRST_STORY_MISSION in claimed:
            if key in missions:
                missions.pop(key, None)
                changed = True
            return changed

        target_campaign = 0
        task_raw = str(meta.get("task_num_raw") or "")
        parts = [self._int(part) for part in task_raw.split("|") if str(part).strip()]
        if parts:
            target_campaign = parts[0]
        target_count = max(1, self._int(meta.get("task_target"), 1))
        count = target_count if target_campaign > 0 and self._campaign_star(target_campaign) > 0 else 0
        expected = self._mission_row(
            self.FIRST_STORY_MISSION,
            count=count,
            is_complete=1 if count >= target_count else 0,
        )
        if missions.get(key) != expected:
            missions[key] = expected
            changed = True
        return changed

    def load_by_type(self, mission_type: Any) -> dict[str, Any] | None:
        if self._int(mission_type) != self.STORY_TYPE:
            return None
        self.normalize_story_80001()
        story = self._state_root()
        rows = [dict(row) for row in story["missions"].values() if isinstance(row, dict)]
        rows.sort(key=lambda row: self._int(row.get("table_id")))
        return {"mission_list": rows}

    def record_campaign_clear(self, campaign_id: Any) -> list[dict[str, int]]:
        """Advance supported Story missions from a canonical successful clear.

        ``WorldRepository`` has already committed the Campaign star before this
        hook runs. ``normalize_story_80001`` may therefore be the operation that
        first observes Campaign 100004 as cleared. Preserve that fact so the
        same MID114 response still carries a ``story_mission_`` delta even when
        no second row mutation is required afterwards.
        """
        cid = self._int(campaign_id)
        normalized_changed = self.normalize_story_80001()
        story = self._state_root()
        key = str(self.FIRST_STORY_MISSION)
        row = story["missions"].get(key)
        meta = self._meta_row(self.FIRST_STORY_MISSION)
        if not isinstance(row, dict) or not meta:
            return []

        task_raw = str(meta.get("task_num_raw") or "")
        parts = [self._int(part) for part in task_raw.split("|") if str(part).strip()]
        target_campaign = parts[0] if parts else 0
        if cid != target_campaign:
            return []
        target_count = max(1, self._int(meta.get("task_target"), 1))
        old = dict(row)
        row["count"] = min(target_count, max(self._int(row.get("count")), 1))
        row["is_complete"] = 1 if self._int(row.get("count")) >= target_count else 0
        row["is_reward"] = 0
        return [dict(row)] if normalized_changed or row != old else []

    def claim(self, table_id: Any, *, persist: bool = True) -> dict[str, Any] | None:
        tid = self._int(table_id)
        if tid != self.FIRST_STORY_MISSION:
            return None
        self.normalize_story_80001()
        story = self._state_root()
        receipts = story["claim_receipts"]
        receipt = receipts.get(str(tid))
        if isinstance(receipt, dict):
            return copy.deepcopy(receipt)

        row = story["missions"].get(str(tid))
        if not isinstance(row, dict) or self._int(row.get("is_complete")) != 1 or self._int(row.get("is_reward")) != 0:
            return {"error_code": 1}
        meta = self._meta_row(tid)
        reward = meta.get("reward") if isinstance(meta.get("reward"), dict) else {}
        response_awards = meta.get("response_awards") if isinstance(meta.get("response_awards"), list) else []

        # Cross-domain atomicity: preserve all touched canonical structures until
        # the single final save succeeds.
        before_mission = copy.deepcopy(self.player.mission_state)
        before_backpack = copy.deepcopy(self.player.backpack_items)
        before_economy = {
            "mana": self._int(self.player.mana),
            "crystal": self._int(self.player.crystal),
            "energy": self._int(self.player.energy),
            "exp": self._int(self.player.exp),
            "lev": self._int(self.player.lev, 1),
            "max_energy": self._int(self.player.max_energy),
            "func_ids": copy.deepcopy(self.player.func_ids),
        }
        try:
            economy_projection = self.economy.apply_deltas(
                mana_delta=max(0, self._int(reward.get("mana"))),
                crystal_delta=max(0, self._int(reward.get("crystal"))),
                player_exp_gain=max(0, self._int(reward.get("player_exp"))),
                persist=False,
            )
            item_awards: list[dict[str, int]] = []
            item_id = self._int(reward.get("item_id"))
            item_num = self._int(reward.get("item_num"))
            if item_id > 0 and item_num > 0:
                item_awards = self.inventory.add_items(
                    [{"item_id": item_id, "item_num": item_num}],
                    persist=False,
                )

            # The client expects response.awards in display/reward format. Keep
            # source-derived currency pseudo IDs while canonical persistence is
            # handled by EconomyRepository above.
            awards = [
                {"table_id": self._int(award.get("item_id")), "item_num": self._int(award.get("item_num"))}
                for award in response_awards
                if isinstance(award, dict) and self._int(award.get("item_id")) != 0 and self._int(award.get("item_num")) > 0
            ]
            # Ensure the persisted ordinary item is represented even if metadata
            # was hand-edited incorrectly.
            for award in item_awards:
                if not any(self._int(row.get("table_id")) == award["item_id"] for row in awards):
                    awards.append({"table_id": award["item_id"], "item_num": award["item_num"]})

            story["missions"].pop(str(tid), None)
            claimed = {self._int(value) for value in story.get("claimed", [])}
            claimed.add(tid)
            story["claimed"] = sorted(value for value in claimed if value > 0)
            result: dict[str, Any] = {"awards": awards}
            if economy_projection:
                result["economy_"] = economy_projection
            # Explicit empty delta tells Task:onTaskBackendEvent nothing new;
            # Task:getTaskReward removes the claimed row locally on OK.
            result["story_mission_"] = []
            receipts[str(tid)] = copy.deepcopy(result)
            if persist:
                self._save()
            return result
        except Exception:
            self.player.mission_state = before_mission
            self.player.backpack_items = before_backpack
            for field, value in before_economy.items():
                setattr(self.player, field, value)
            raise

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
