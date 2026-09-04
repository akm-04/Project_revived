"""Stage-D Campaign acquisition overlay for Girl Awakening/Blood Awakening.

The effective client exposes special Awakening Campaign dropboxes, but the
historical server-side RNG implementation is not recovered.  Pass204 therefore
froze a compatibility policy: interpret the referenced ``increase_rate`` on the
already-established 10,000 Campaign denominator and freeze the resulting
occurrence inside the owning Campaign transaction/receipt.

This planner is deliberately stateless.  AwakeningMissionService remains the
sole mutable mission owner and WorldRepository remains the Campaign transaction
owner.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Mapping

from gxb_backend.content.awakening_source_catalog import AwakeningSourceCatalog
from gxb_backend.state.random_outcome_service import RandomOutcomeService


AWAKENING_CAMPAIGN_POLICY_ID = "awakening_campaign_special_bernoulli_10000_v1"
AWAKENING_CAMPAIGN_POLICY_VERSION = 1
AWAKENING_CAMPAIGN_RATE_BASE = 10000
_ORDINARY_NAMESPACE = "awakening.campaign.ordinary"
_BLOOD_NAMESPACE = "awakening.campaign.blood"


class AwakeningCampaignOverlayError(ValueError):
    """Source/canonical-state mismatch in the special Campaign overlay."""


@dataclass(frozen=True)
class ResolvedAwakeningCampaignDrop:
    awake_type: int
    mission_id: int
    generation: int
    campaign_id: int
    wire_campaign_type: int
    source_campaign_type: int
    dropbox_id: int
    source_row_id: int
    item_id: int
    increase_rate: int

    def audit(self) -> dict[str, int]:
        return {
            "awake_type": self.awake_type,
            "mission_id": self.mission_id,
            "generation": self.generation,
            "campaign_id": self.campaign_id,
            "wire_campaign_type": self.wire_campaign_type,
            "source_campaign_type": self.source_campaign_type,
            "dropbox_id": self.dropbox_id,
            "source_row_id": self.source_row_id,
            "item_id": self.item_id,
            "increase_rate": self.increase_rate,
        }


@dataclass(frozen=True)
class AwakeningCampaignOverlayResolution:
    campaign_id: int
    wire_campaign_type: int
    resolved: tuple[ResolvedAwakeningCampaignDrop, ...]

    def audit(self) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "policy_id": AWAKENING_CAMPAIGN_POLICY_ID,
            "policy_version": AWAKENING_CAMPAIGN_POLICY_VERSION,
            "rate_base": AWAKENING_CAMPAIGN_RATE_BASE,
            "campaign_id": self.campaign_id,
            "wire_campaign_type": self.wire_campaign_type,
            "resolved": [row.audit() for row in self.resolved],
        }


@dataclass(frozen=True)
class AwakeningCampaignOverlayPlan:
    resolution: AwakeningCampaignOverlayResolution
    occurrences: tuple[dict[str, Any], ...]
    canonical_awards: tuple[dict[str, int], ...]

    def battle_items(self) -> list[dict[str, int]]:
        return [dict(row) for row in self.canonical_awards]

    def persisted(self) -> dict[str, Any]:
        out = self.resolution.audit()
        out["occurrences"] = [dict(row) for row in self.occurrences]
        out["canonical_awards"] = [dict(row) for row in self.canonical_awards]
        return out


class AwakeningCampaignOverlayPlanner:
    """Resolve canonical stage-one routes, then perform bounded policy draws."""

    HERO = AwakeningSourceCatalog.HERO
    HERO_TWICE = AwakeningSourceCatalog.HERO_TWICE

    def __init__(self, source: AwakeningSourceCatalog, random_outcomes: RandomOutcomeService) -> None:
        if not isinstance(source, AwakeningSourceCatalog):
            raise TypeError("source must be AwakeningSourceCatalog")
        if not isinstance(random_outcomes, RandomOutcomeService):
            raise TypeError("random_outcomes must be RandomOutcomeService")
        self.source = source
        self.random_outcomes = random_outcomes

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @staticmethod
    def _wire_type_for_source_campaign_type(source_campaign_type: int) -> int:
        # Effective source Campaign ownership (Pass75): raw node types 1/2 are
        # wire NORMAL(1), while raw node type 3 is wire SUPER(2).
        if int(source_campaign_type) in (1, 2):
            return 1
        if int(source_campaign_type) == 3:
            return 2
        return 0

    def _resolve_one(
        self,
        *,
        awake_type: int,
        active: Mapping[str, Any] | None,
        campaign_id: int,
        wire_campaign_type: int,
    ) -> ResolvedAwakeningCampaignDrop | None:
        if not isinstance(active, Mapping):
            return None
        if self._int(active.get("awake_type"), awake_type) != awake_type:
            return None
        if self._int(active.get("stage"), 0) != 1:
            return None
        mission_id = self._int(active.get("mission_id"), 0)
        generation = self._int(active.get("generation"), 0)
        if mission_id <= 0 or generation <= 0:
            raise AwakeningCampaignOverlayError("active Awakening stage-one identity is incomplete")
        route = self.source.stage1_route(mission_id, awake_type)
        if route is None or str(route.get("route_class") or "") != "CAMPAIGN":
            return None

        matches: list[Mapping[str, Any]] = []
        for candidate in route.get("campaigns") or ():
            if not isinstance(candidate, Mapping):
                continue
            if self._int(candidate.get("campaign_id"), 0) != campaign_id:
                continue
            source_type = self._int(candidate.get("campaign_type"), 0)
            if self._wire_type_for_source_campaign_type(source_type) != wire_campaign_type:
                continue
            matches.append(candidate)
        if not matches:
            return None
        if len(matches) != 1:
            raise AwakeningCampaignOverlayError(
                f"ambiguous Awakening Campaign route {awake_type}/{mission_id}/{campaign_id}"
            )
        mapping = matches[0]
        dropbox_id = self._int(mapping.get("dropbox_id"), 0)
        if dropbox_id <= 0:
            raise AwakeningCampaignOverlayError("Awakening Campaign route has no dropbox")
        rows = self.source.dropbox(dropbox_id)
        if len(rows) != 1:
            raise AwakeningCampaignOverlayError(
                f"Awakening special dropbox {dropbox_id} must contain exactly one source row"
            )
        row = rows[0]
        item_id = self._int(row.get("item_id"), 0)
        increase_rate = self._int(row.get("increase_rate"), -1)
        source_row_id = self._int(row.get("row_id"), 0)
        if item_id <= 0 or source_row_id <= 0:
            raise AwakeningCampaignOverlayError("Awakening special dropbox item/source row is invalid")
        if increase_rate < 0 or increase_rate > AWAKENING_CAMPAIGN_RATE_BASE:
            raise AwakeningCampaignOverlayError("Awakening special dropbox rate is outside 0..10000")
        return ResolvedAwakeningCampaignDrop(
            awake_type=awake_type,
            mission_id=mission_id,
            generation=generation,
            campaign_id=campaign_id,
            wire_campaign_type=wire_campaign_type,
            source_campaign_type=self._int(mapping.get("campaign_type"), 0),
            dropbox_id=dropbox_id,
            source_row_id=source_row_id,
            item_id=item_id,
            increase_rate=increase_rate,
        )

    def resolve(
        self,
        *,
        campaign_id: Any,
        wire_campaign_type: Any,
        ordinary_active: Mapping[str, Any] | None,
        blood_active: Mapping[str, Any] | None,
        ordinary_wire_mission: Any = 0,
    ) -> AwakeningCampaignOverlayResolution:
        cid = self._int(campaign_id, 0)
        wire_type = self._int(wire_campaign_type, 0)
        if cid <= 0 or wire_type not in (1, 2):
            return AwakeningCampaignOverlayResolution(cid, wire_type, ())

        ordinary = self._resolve_one(
            awake_type=self.HERO,
            active=ordinary_active,
            campaign_id=cid,
            wire_campaign_type=wire_type,
        )
        marker = self._int(ordinary_wire_mission, 0)
        # Effective NewMapDetail/SweepWindow can carry the ordinary stage-one
        # mission, while legacy MapDetail may omit it.  It is therefore a strict
        # cross-check only when a canonical ordinary acquisition overlay exists.
        if ordinary is not None and marker > 0 and marker != ordinary.mission_id:
            raise AwakeningCampaignOverlayError("ordinary awake_mission does not match active Campaign acquisition mission")

        blood = self._resolve_one(
            awake_type=self.HERO_TWICE,
            active=blood_active,
            campaign_id=cid,
            wire_campaign_type=wire_type,
        )
        resolved = tuple(row for row in (ordinary, blood) if row is not None)
        return AwakeningCampaignOverlayResolution(cid, wire_type, resolved)

    def plan(self, resolution: AwakeningCampaignOverlayResolution) -> AwakeningCampaignOverlayPlan:
        occurrences: list[dict[str, Any]] = []
        awards: list[dict[str, int]] = []
        for resolved in resolution.resolved:
            namespace = _ORDINARY_NAMESPACE if resolved.awake_type == self.HERO else _BLOOD_NAMESPACE
            roll = self.random_outcomes.randbelow(namespace, AWAKENING_CAMPAIGN_RATE_BASE)
            awarded = roll < resolved.increase_rate
            occurrence = {
                **resolved.audit(),
                "roll": roll,
                "awarded": bool(awarded),
                "item_num": 1 if awarded else 0,
            }
            occurrences.append(occurrence)
            if awarded:
                awards.append({"item_id": resolved.item_id, "item_num": 1})
        return AwakeningCampaignOverlayPlan(
            resolution=resolution,
            occurrences=tuple(occurrences),
            canonical_awards=tuple(awards),
        )
