"""Read-only Mission/BattlePass generic redmark projection.

Wave B intentionally derives client badge readiness from canonical domain facts.
It never persists a generic badge aggregate and never interprets unsupported
Mission families as ready.
"""
from __future__ import annotations

from typing import Any

from gxb_backend.content.battle_pass_redmark_source_catalog import BattlePassRedmarkSourceCatalog

from .awakening_mission_service import AwakeningMissionService
from .mission_repository import MissionRepository
from .player_state import PlayerState


class GenericRedmarkProjectionService:
    MISSION_FUNCTION_ID = 27
    BATTLE_PASS_FUNCTION_ID = 97

    STORY_TASK = 2704
    AWAKE_TASK = 2705
    BATTLE_PASS_LEVEL_UP = 2801
    BATTLE_PASS_MISSION_COMPLETE = 2802

    def __init__(
        self,
        player: PlayerState,
        missions: MissionRepository,
        awakening_missions: AwakeningMissionService,
        battle_pass_source: BattlePassRedmarkSourceCatalog,
    ) -> None:
        self.player = player
        self.missions = missions
        self.awakening_missions = awakening_missions
        self.battle_pass_source = battle_pass_source

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @classmethod
    def _row(cls, function_id: int, marks: list[int]) -> dict[str, Any]:
        return {"function_id": int(function_id), "redmark_list": sorted({int(v) for v in marks if int(v) > 0})}

    def _mission_marks(self) -> list[int]:
        marks: list[int] = []
        if self.missions.has_claimable_story():
            marks.append(self.STORY_TASK)
        if self.awakening_missions.has_claimable_awake():
            marks.append(self.AWAKE_TASK)
        return marks

    def _battle_pass_level_ready(self, payload: dict[str, Any]) -> bool:
        base = payload.get("base_info") if isinstance(payload.get("base_info"), dict) else {}
        point = max(0, self._int(base.get("point")))
        level = point // self.battle_pass_source.point_per_level
        threshold = self.battle_pass_source.award_max_level - self.battle_pass_source.award_loop_range

        def lane_ready(awarded: int, *, advanced: bool) -> bool:
            awarded = max(0, awarded)
            if level <= awarded:
                return False
            if awarded >= threshold:
                return (level - awarded) / self.battle_pass_source.award_loop_range >= 1
            return any(
                self.battle_pass_source.reward_gift(candidate, advanced=advanced) > 0
                for candidate in range(awarded + 1, level + 1)
            )

        if lane_ready(self._int(base.get("awarded_lev")), advanced=False):
            return True
        return self._int(base.get("is_advanced")) == 1 and lane_ready(
            self._int(base.get("adv_awarded_lev")), advanced=True
        )

    def _battle_pass_mission_ready(self, payload: dict[str, Any]) -> bool:
        info = payload.get("mission_info") if isinstance(payload.get("mission_info"), dict) else {}
        mission_list = info.get("mission_list") if isinstance(info.get("mission_list"), list) else []
        counts = info.get("mission_counts") if isinstance(info.get("mission_counts"), list) else []
        awarded = info.get("is_award") if isinstance(info.get("is_award"), list) else []
        for index, raw_id in enumerate(mission_list):
            mission_id = self._int(raw_id)
            if mission_id <= 0:
                continue
            count = self._int(counts[index]) if index < len(counts) else 0
            is_award = self._int(awarded[index]) if index < len(awarded) else 0
            required = self.battle_pass_source.mission_required_count(mission_id)
            if is_award == 0 and required > 0 and count >= required:
                return True
        return False

    def _battle_pass_marks(self) -> list[int]:
        payload = self.player.battle_pass_payload()
        marks: list[int] = []
        if self._battle_pass_level_ready(payload):
            marks.append(self.BATTLE_PASS_LEVEL_UP)
        if self._battle_pass_mission_ready(payload):
            marks.append(self.BATTLE_PASS_MISSION_COMPLETE)
        # 2803 is deliberately not persistent/foundation badge state.
        return marks

    def family_row(self, function_id: Any) -> dict[str, Any] | None:
        fid = self._int(function_id)
        if fid == self.MISSION_FUNCTION_ID:
            return self._row(fid, self._mission_marks())
        if fid == self.BATTLE_PASS_FUNCTION_ID:
            return self._row(fid, self._battle_pass_marks())
        return None

    def snapshot(self) -> list[dict[str, Any]]:
        """MID2560/bootstrap snapshot: emit only non-empty supported families."""
        out: list[dict[str, Any]] = []
        for fid in (self.MISSION_FUNCTION_ID, self.BATTLE_PASS_FUNCTION_ID):
            row = self.family_row(fid)
            if row is not None and row["redmark_list"]:
                out.append(row)
        return out

    def sideband(self, dirty_function_ids: list[Any] | tuple[Any, ...] | set[Any]) -> dict[str, dict[str, Any]]:
        """Response-wide sideband: dirty family replacement, including empty clear."""
        out: dict[str, dict[str, Any]] = {}
        for raw in dirty_function_ids:
            fid = self._int(raw)
            row = self.family_row(fid)
            if row is not None:
                out[str(fid)] = row
        return out
