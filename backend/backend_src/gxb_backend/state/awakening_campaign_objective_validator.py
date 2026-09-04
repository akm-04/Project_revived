"""Pure Stage-D validator for ordinary Awakening final Campaign objectives."""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping


SELF_KILL = 1
DAMAGE_ACHIEVE = 2
ALONE_KILL = 3
ALL_ALIVE = 4
SUPPORTED_GOALS = {SELF_KILL, DAMAGE_ACHIEVE, ALONE_KILL, ALL_ALIVE}


@dataclass(frozen=True)
class AwakeningCampaignObjectiveDecision:
    allowed: bool
    reason: str
    evidence_class: str


class AwakeningCampaignObjectiveValidator:
    """Validate only facts recoverable at the Campaign server boundary.

    Effective ``BattleCreate:getAwakeMissionResult`` computes kill, damage and
    all-alive facts locally and sends ``awake_mission`` only on success.  Those
    facts therefore remain CLIENT_ATTESTED.  Formation, target participation,
    campaign/session identity and the no-extra-Hero/no-pet shape for ALONE are
    independently server-checkable from the frozen MID113 request.
    """

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @classmethod
    def _formation_ids(cls, value: Any) -> tuple[int, ...]:
        out: list[int] = []
        for token in str(value or "").split("|"):
            token = token.strip()
            if not token:
                continue
            partner_id = cls._int(token, 0)
            if partner_id > 0:
                out.append(partner_id)
        return tuple(out)

    @classmethod
    def freeze_context(
        cls,
        *,
        active: Mapping[str, Any] | None,
        mission_row: Mapping[str, Any] | None,
        campaign_id: Any,
        campaign_type: Any,
        request: Mapping[str, Any],
    ) -> dict[str, Any] | None:
        if not isinstance(active, Mapping) or not isinstance(mission_row, Mapping):
            return None
        if cls._int(active.get("stage"), 0) != 2 or bool(active.get("complete")):
            return None
        mission_id = cls._int(active.get("mission_id"), 0)
        generation = cls._int(active.get("generation"), 0)
        if mission_id <= 0 or generation <= 0:
            return None
        cid = cls._int(campaign_id, 0)
        go_ids = {cls._int(v, 0) for v in mission_row.get("go_ids") or ()}
        if cid <= 0 or cid not in go_ids:
            return None
        goal = cls._int(mission_row.get("copy_challenge"), 0)
        if goal not in SUPPORTED_GOALS:
            return None
        formation = str(request.get("formation") or "")
        return {
            "schema_version": 1,
            "awake_type": 1,
            "mission_id": mission_id,
            "generation": generation,
            "campaign_id": cid,
            "campaign_type": cls._int(campaign_type, 0),
            "hero_partner_id": cls._int(active.get("hero_partner_id"), 0),
            "hero_table_id": cls._int(active.get("hero_table_id"), 0),
            "goal_type": goal,
            "challenge_num": cls._int(mission_row.get("challenge_num"), 0),
            "formation_snapshot": formation,
            "pet_id": cls._int(request.get("pet_id"), 0),
            "rent_pet_id": cls._int(request.get("rent_pet_id"), 0),
            "rent_pet_player_id": cls._int(request.get("rent_pet_player_id"), 0),
            "rent_formation": str(request.get("rent_formation") or ""),
            "rent_player_id": cls._int(request.get("rent_player_id"), 0),
            "rent_hero_id": cls._int(request.get("rent_hero_id"), 0),
            "tutor_rent_hero_present": isinstance(request.get("tutor_rent_hero"), Mapping),
        }

    def validate(
        self,
        *,
        request: Mapping[str, Any],
        session: Mapping[str, Any],
        active: Mapping[str, Any] | None,
        mission_row: Mapping[str, Any] | None,
    ) -> AwakeningCampaignObjectiveDecision:
        marker = self._int(request.get("awake_mission"), 0)
        if marker <= 0:
            return AwakeningCampaignObjectiveDecision(False, "client_objective_marker_absent", "CLIENT_ATTESTED")
        if self._int(request.get("star"), 0) <= 0:
            return AwakeningCampaignObjectiveDecision(False, "campaign_not_won", "SOURCE_FACT")
        frozen = session.get("awakening_objective") if isinstance(session, Mapping) else None
        if not isinstance(frozen, Mapping):
            return AwakeningCampaignObjectiveDecision(False, "objective_not_frozen_at_mid113", "SOURCE_FACT")
        if not isinstance(active, Mapping) or not isinstance(mission_row, Mapping):
            return AwakeningCampaignObjectiveDecision(False, "ordinary_awake_final_not_active", "SOURCE_FACT")

        expected_mid = self._int(frozen.get("mission_id"), 0)
        expected_generation = self._int(frozen.get("generation"), 0)
        if marker != expected_mid:
            return AwakeningCampaignObjectiveDecision(False, "awake_mission_marker_mismatch", "SOURCE_FACT")
        if self._int(active.get("mission_id"), 0) != expected_mid or self._int(active.get("generation"), 0) != expected_generation:
            return AwakeningCampaignObjectiveDecision(False, "awake_generation_changed_since_mid113", "SOURCE_FACT")
        if self._int(active.get("stage"), 0) != 2 or bool(active.get("complete")):
            return AwakeningCampaignObjectiveDecision(False, "ordinary_awake_final_not_incomplete", "SOURCE_FACT")
        if self._int(request.get("campaign_id"), 0) != self._int(frozen.get("campaign_id"), 0):
            return AwakeningCampaignObjectiveDecision(False, "awake_campaign_mismatch", "SOURCE_FACT")
        if self._int(request.get("campaign_type"), 0) != self._int(frozen.get("campaign_type"), 0):
            return AwakeningCampaignObjectiveDecision(False, "awake_campaign_type_mismatch", "SOURCE_FACT")
        if str(request.get("formation") or "") != str(frozen.get("formation_snapshot") or ""):
            return AwakeningCampaignObjectiveDecision(False, "awake_result_formation_changed", "SOURCE_FACT")

        go_ids = {self._int(v, 0) for v in mission_row.get("go_ids") or ()}
        if self._int(frozen.get("campaign_id"), 0) not in go_ids:
            return AwakeningCampaignObjectiveDecision(False, "awake_source_campaign_mismatch", "SOURCE_FACT")
        goal = self._int(mission_row.get("copy_challenge"), 0)
        if goal != self._int(frozen.get("goal_type"), 0) or goal not in SUPPORTED_GOALS:
            return AwakeningCampaignObjectiveDecision(False, "awake_goal_source_drift", "SOURCE_FACT")

        formation = self._formation_ids(frozen.get("formation_snapshot"))
        target_partner = self._int(frozen.get("hero_partner_id"), 0)
        if target_partner <= 0 or target_partner not in formation:
            return AwakeningCampaignObjectiveDecision(False, "awake_target_not_in_frozen_formation", "SOURCE_FACT")

        if goal == ALONE_KILL:
            has_pet = any(
                self._int(frozen.get(key), 0) > 0
                for key in ("pet_id", "rent_pet_id", "rent_pet_player_id")
            )
            has_rent_hero = bool(str(frozen.get("rent_formation") or "").strip()) or self._int(frozen.get("rent_hero_id"), 0) > 0 or bool(frozen.get("tutor_rent_hero_present"))
            if len(formation) != 1 or has_pet or has_rent_hero:
                return AwakeningCampaignObjectiveDecision(False, "awake_solo_shape_invalid", "SOURCE_FACT")
            return AwakeningCampaignObjectiveDecision(True, "solo_shape_and_client_marker_valid", "MIXED_SERVER_AND_CLIENT_ATTESTED")

        # SELF_KILL, DAMAGE_ACHIEVE and ALL_ALIVE have no equivalent server
        # telemetry.  The matching marker is the recovered client attestation.
        return AwakeningCampaignObjectiveDecision(True, "client_objective_marker_accepted", "CLIENT_ATTESTED")
