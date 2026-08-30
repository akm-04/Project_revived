"""Emblem-domain outcome planning over policy-free RandomOutcomeService.

Pass244 I3 activates the internal, versioned outer Scholarship compatibility
policy while keeping protocol MIDs 1400/1401/1405/1406 fail-closed.  This module
owns draw topology only; costs, inventory, durable counters and proposals remain
with EmblemService/EmblemStateRepository.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from gxb_backend.content.emblem_source_catalog import EmblemSourceCatalog

from .emblem_policy import EmblemPolicyRegistry
from .random_outcome_service import RandomOutcomeService


class EmblemPolicyNotEnabled(RuntimeError):
    pass


@dataclass(frozen=True)
class EmblemCandidateDraw:
    item_id: int
    inscription_id: int
    namespace: str


@dataclass(frozen=True)
class EmblemScholarshipGateDraw:
    lane: str
    namespace: str
    misses_before: int
    attempt: int
    chance_bp: int
    hit: bool
    misses_after: int
    entropy_consumed: bool


@dataclass(frozen=True)
class EmblemGeneratedDraw:
    lane: str
    source_inscription_id: int
    item_id: int
    scholarship: bool
    scholarship_family_id: int
    ordinary_exclude_item_id: int
    gate: EmblemScholarshipGateDraw | None


class EmblemOutcomePlanner:
    _NS = {
        "forge": {
            "ordinary": "emblem.forge.ordinary",
            "gate": "emblem.forge.scholarship_gate",
            "family": "emblem.forge.scholarship_family",
            "item": "emblem.forge.scholarship_item",
        },
        "reforge": {
            "ordinary": "emblem.reforge.ordinary",
            "gate": "emblem.reforge.scholarship_gate",
            "family": "emblem.reforge.scholarship_family",
            "item": "emblem.reforge.scholarship_item",
        },
    }

    def __init__(
        self,
        source: EmblemSourceCatalog,
        policy: EmblemPolicyRegistry,
        random_outcomes: RandomOutcomeService,
    ) -> None:
        if not isinstance(source, EmblemSourceCatalog):
            raise TypeError("source must be EmblemSourceCatalog")
        if not isinstance(policy, EmblemPolicyRegistry):
            raise TypeError("policy must be EmblemPolicyRegistry")
        if not isinstance(random_outcomes, RandomOutcomeService):
            raise TypeError("random_outcomes must be RandomOutcomeService")
        self.source = source
        self.policy = policy
        self.random_outcomes = random_outcomes

    @staticmethod
    def _require_lane(lane: str) -> str:
        lane = str(lane)
        if lane not in {"forge", "reforge"}:
            raise ValueError(f"unknown Emblem outcome lane {lane!r}")
        return lane

    def ordinary_candidate(
        self,
        inscription_id: Any,
        *,
        namespace: str,
        exclude_item_id: Any = 0,
    ) -> EmblemCandidateDraw:
        candidates, weights = self.source.ordinary_candidate_pool(
            inscription_id, exclude_item_id=exclude_item_id
        )
        index = self.random_outcomes.weighted_index(namespace, weights)
        return EmblemCandidateDraw(
            item_id=int(candidates[index]),
            inscription_id=int(inscription_id),
            namespace=namespace,
        )

    def scholarship_family(self, *, namespace: str) -> int:
        families, weights = self.source.scholarship_family_pool()
        index = self.random_outcomes.weighted_index(namespace, weights)
        return int(families[index])

    def scholarship_candidate(self, family_id: Any, *, namespace: str) -> EmblemCandidateDraw:
        candidates, weights = self.source.scholarship_candidate_pool(family_id)
        index = self.random_outcomes.weighted_index(namespace, weights)
        return EmblemCandidateDraw(
            item_id=int(candidates[index]),
            inscription_id=int(family_id),
            namespace=namespace,
        )

    def scholarship_gate(self, lane: str, misses_since_special: int) -> EmblemScholarshipGateDraw:
        lane = self._require_lane(lane)
        if not self.policy.outer_scholarship_enabled:
            raise EmblemPolicyNotEnabled("outer Lv7 Scholarship policy is disabled")
        attempt, chance_bp, hard_special = self.policy.scholarship_chance(
            lane, misses_since_special
        )
        namespace = self._NS[lane]["gate"]
        if hard_special or chance_bp >= self.policy.FIXED_POINT_DENOMINATOR_BP:
            hit = True
            entropy_consumed = False
        elif chance_bp <= 0:
            hit = False
            entropy_consumed = False
        else:
            roll = self.random_outcomes.randbelow(
                namespace, self.policy.FIXED_POINT_DENOMINATOR_BP
            )
            hit = roll < chance_bp
            entropy_consumed = True
        return EmblemScholarshipGateDraw(
            lane=lane,
            namespace=namespace,
            misses_before=int(misses_since_special),
            attempt=attempt,
            chance_bp=chance_bp,
            hit=hit,
            misses_after=0 if hit else int(misses_since_special) + 1,
            entropy_consumed=entropy_consumed,
        )

    def generated_candidate(
        self,
        inscription_id: Any,
        *,
        lane: str,
        misses_since_special: int,
        source_item_id: Any = 0,
    ) -> EmblemGeneratedDraw:
        """Plan one Forge/Reforge output without mutating durable state.

        All source pools are validated *before* the first entropy draw.  Lv1-6
        do not touch Scholarship state or the Scholarship-gate namespace.  Lv7
        uses the versioned outer gate, then source 70/30 family and source item
        weights on a hit, otherwise the ordinary row weights.
        """

        lane = self._require_lane(lane)
        row = self.source.require_inscription(inscription_id)
        if int(row.get("special", 0) or 0) != 0:
            raise ValueError("generated candidate requires an ordinary inscription row")

        exclude_item_id = 0
        if lane == "reforge":
            source_item_id = int(source_item_id or 0)
            item = self.source.concrete_item(source_item_id)
            if item is None or int(item.get("inscription_id", 0) or 0) != int(row.get("id", 0) or 0):
                raise ValueError("reforge source item does not belong to inscription row")
            if self.source.is_scholarship_item(source_item_id):
                raise ValueError("Scholarship medals cannot be reforged")
            if self.policy.exclude_current_reforge_item:
                exclude_item_id = source_item_id

        # Prevalidate every pool that may be touched before consuming entropy.
        self.source.ordinary_candidate_pool(row["id"], exclude_item_id=exclude_item_id)
        is_lv7 = int(row.get("level", 0) or 0) == int(self.source.rules["scholarship_level"])
        if is_lv7:
            families, _ = self.source.scholarship_family_pool()
            for family_id in families:
                self.source.scholarship_candidate_pool(family_id)

        gate: EmblemScholarshipGateDraw | None = None
        if is_lv7:
            gate = self.scholarship_gate(lane, misses_since_special)
            if gate.hit:
                family_id = self.scholarship_family(namespace=self._NS[lane]["family"])
                item = self.scholarship_candidate(
                    family_id, namespace=self._NS[lane]["item"]
                )
                return EmblemGeneratedDraw(
                    lane=lane,
                    source_inscription_id=int(row["id"]),
                    item_id=item.item_id,
                    scholarship=True,
                    scholarship_family_id=family_id,
                    ordinary_exclude_item_id=exclude_item_id,
                    gate=gate,
                )

        ordinary = self.ordinary_candidate(
            row["id"],
            namespace=self._NS[lane]["ordinary"],
            exclude_item_id=exclude_item_id,
        )
        return EmblemGeneratedDraw(
            lane=lane,
            source_inscription_id=int(row["id"]),
            item_id=ordinary.item_id,
            scholarship=False,
            scholarship_family_id=0,
            ordinary_exclude_item_id=exclude_item_id,
            gate=gate,
        )
