"""Server-directed duplicate-conversion seam for Summon results.

Pass41.7 uses the global evidence-backed native-star conversion policy. Deferred
Hero-producing families can reuse the same resolver without copying quantities.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from .summon_duplicate_policy import SummonDuplicateConversionPolicy
from .summon_result_plan import SummonResultRowPlan


class SummonDuplicateConversionUnavailable(RuntimeError):
    pass


@dataclass(frozen=True)
class SummonDuplicateCandidate:
    hero_table_id: int
    fragment_item_id: int
    source_family: str
    initial_star: int | None = None


class SummonDuplicateConversionResolver(Protocol):
    def resolve(self, candidate: SummonDuplicateCandidate) -> SummonResultRowPlan:
        ...


class ConfiguredSummonDuplicateConversionResolver:
    """Global recovered native-star duplicate -> fragment conversion."""

    def __init__(self, policy: SummonDuplicateConversionPolicy) -> None:
        self.policy = policy

    def resolve(self, candidate: SummonDuplicateCandidate) -> SummonResultRowPlan:
        star = int(candidate.initial_star or 0)
        if int(candidate.fragment_item_id) <= 0 or star <= 0:
            raise SummonDuplicateConversionUnavailable(
                "duplicate candidate lacks source fragment/native-star metadata"
            )
        try:
            quantity = self.policy.quantity_for_initial_star(star)
        except RuntimeError as exc:
            raise SummonDuplicateConversionUnavailable(str(exc)) from exc
        row = SummonResultRowPlan.to_stone(
            fragment_item_id=int(candidate.fragment_item_id),
            item_num=quantity,
        )
        return SummonResultRowPlan(
            kind=row.kind,
            table_id=row.table_id,
            item_num=row.item_num,
            evidence_status="recovered_historical_video",
        )


# Compatibility alias for any out-of-tree tooling that imported the old class name.
PrivatePolicySummonDuplicateConversionResolver = ConfiguredSummonDuplicateConversionResolver


class UnresolvedSummonDuplicateConversionResolver:
    """Fail-closed resolver retained for intentionally unsupported families."""

    def resolve(self, candidate: SummonDuplicateCandidate) -> SummonResultRowPlan:
        raise SummonDuplicateConversionUnavailable(
            "duplicate conversion quantity/policy is unavailable for this summon family"
        )
