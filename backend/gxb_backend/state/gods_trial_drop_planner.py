"""Gods Trial drop selection over recovered campaign_dropbox source rows.

Pass170 H5. Trial owns row interpretation and stable-order policy; ROS remains
mechanical entropy only. First-clear rows are source-guaranteed. Repeat rows use
the frozen Pass164 10,000-scale quotient + residual Bernoulli compatibility rule.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Any

from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog
from .random_outcome_service import RandomOutcomeService


class GodsTrialDropError(ValueError):
    pass


@dataclass(frozen=True)
class GodsTrialDropOccurrence:
    item_id: int
    quantity: int
    dropbox_id: int
    row_id: int
    ordinal: int
    increase_rate: int


class GodsTrialRandomOutcomeAdapter:
    REPEAT_RESIDUAL = "horcrux.trial.repeat.residual"

    def __init__(self, service: RandomOutcomeService) -> None:
        if not isinstance(service, RandomOutcomeService):
            raise TypeError("service must be a RandomOutcomeService")
        self._service = service

    def residual(self, rate: int) -> bool:
        rate = int(rate)
        if rate <= 0 or rate >= 10_000:
            raise GodsTrialDropError("residual rate must be in 1..9999")
        return self._service.randbelow(self.REPEAT_RESIDUAL, 10_000) < rate


class GodsTrialDropPlanner:
    def __init__(self, source: HorcruxSourceCatalog, random_outcomes: GodsTrialRandomOutcomeAdapter) -> None:
        self.source = source
        self.random_outcomes = random_outcomes

    @staticmethod
    def _int(value: Any, label: str) -> int:
        try:
            return int(value)
        except (TypeError, ValueError) as exc:
            raise GodsTrialDropError(f"{label} must be an integer") from exc

    def _rows(self, dropbox_id: int):
        rows = self.source.trial_drop_rows(dropbox_id)
        if not rows:
            raise GodsTrialDropError(f"unknown Gods Trial dropbox {dropbox_id}")
        return rows

    def first_clear(self, dropbox_id: Any) -> tuple[GodsTrialDropOccurrence, ...]:
        """Project source-guaranteed first-clear rows without entropy.

        Current recovered first-clear rows are exact multiples of 10,000. Fail
        closed if future source evidence introduces a residual probability rather
        than silently applying the repeat compatibility policy to first-clear data.
        """
        pool_id = self._int(dropbox_id, "dropbox_id")
        out: list[GodsTrialDropOccurrence] = []
        for row in self._rows(pool_id):
            rate = self._int(row.get("increase_rate"), "increase_rate")
            if rate <= 0 or rate % 10_000 != 0:
                raise GodsTrialDropError(
                    f"Gods Trial first-clear row {row.get('id')} is not source-guaranteed"
                )
            quantity = rate // 10_000
            if quantity:
                out.append(GodsTrialDropOccurrence(
                    item_id=self._int(row.get("item_id"), "item_id"),
                    quantity=quantity,
                    dropbox_id=pool_id,
                    row_id=self._int(row.get("id"), "row_id"),
                    ordinal=self._int(row.get("ordinal"), "ordinal"),
                    increase_rate=rate,
                ))
        return tuple(out)

    def repeat(self, dropbox_id: Any) -> tuple[GodsTrialDropOccurrence, ...]:
        """Evaluate every repeat row independently in stable source order."""
        pool_id = self._int(dropbox_id, "dropbox_id")
        out: list[GodsTrialDropOccurrence] = []
        for row in self._rows(pool_id):
            rate = self._int(row.get("increase_rate"), "increase_rate")
            if rate < 0:
                raise GodsTrialDropError("increase_rate must be nonnegative")
            guaranteed, residual = divmod(rate, 10_000)
            quantity = guaranteed
            if residual and self.random_outcomes.residual(residual):
                quantity += 1
            if quantity:
                out.append(GodsTrialDropOccurrence(
                    item_id=self._int(row.get("item_id"), "item_id"),
                    quantity=quantity,
                    dropbox_id=pool_id,
                    row_id=self._int(row.get("id"), "row_id"),
                    ordinal=self._int(row.get("ordinal"), "ordinal"),
                    increase_rate=rate,
                ))
        return tuple(out)
