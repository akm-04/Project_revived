"""Source-bounded Campaign MID117 EXP/Mana compatibility policy.

The recovered client consumes ``economys[i].exp`` as a *base* Campaign EXP
amount and applies a sweep-display multiplier locally: 1x while its simulated
pre-run level is <=10, then ``SelfPlayer:getExpMulti()`` (3 in effective
``src_64``) after that boundary.  ``economys[i].mana`` is displayed directly.

This module owns no player state, persistence, RNG, authorization or balances.
It only plans deterministic values for the existing MID117 transaction owners.
The <=10 transition is a private-server compatibility decision backed by the
client-visible rule; it is not recovered official-server settlement code.
"""
from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass
from typing import Any


CAMPAIGN_SWEEP_ECONOMY_POLICY_ID = "campaign_sweep_exp_mana_src64_client_mirror"
CAMPAIGN_SWEEP_ECONOMY_POLICY_VERSION = 1


class CampaignSweepEconomyPolicyError(ValueError):
    """Invalid source facts or progression snapshot for a sweep economy plan."""


@dataclass(frozen=True)
class SweepEconomyRow:
    """One immutable MID117 sweep economy row plus its account EXP settlement."""

    base_exp: int
    mana: int
    account_exp_gain: int

    def wire(self) -> dict[str, int]:
        return {"exp": self.base_exp, "mana": self.mana}


@dataclass(frozen=True)
class SweepEconomyPlan:
    """Pure deterministic output consumed by the existing MID117 UoW."""

    rows: tuple[SweepEconomyRow, ...]
    total_player_exp_gain: int
    total_mana_gain: int
    simulated_start_level: int
    simulated_end_level: int
    simulated_start_exp: int
    policy_id: str = CAMPAIGN_SWEEP_ECONOMY_POLICY_ID
    policy_version: int = CAMPAIGN_SWEEP_ECONOMY_POLICY_VERSION

    @property
    def per_run_account_exp(self) -> tuple[int, ...]:
        return tuple(row.account_exp_gain for row in self.rows)

    def wire_economys(self) -> list[dict[str, int]]:
        return [row.wire() for row in self.rows]


class CampaignSweepEconomyPolicy:
    """Plan ordinary Normal/Super MID117 account EXP and Mana without mutation."""

    LOW_LEVEL_MAX = 10

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @classmethod
    def plan(
        cls,
        *,
        base_exp: Any,
        mana_gain: Any,
        sweep_num: Any,
        start_level: Any,
        start_exp: Any,
        normal_exp_multiplier: Any,
        total_exp_threshold: Callable[[int], Any],
    ) -> SweepEconomyPlan:
        base = cls._int(base_exp, 0)
        mana = cls._int(mana_gain, 0)
        count = cls._int(sweep_num, 0)
        level = cls._int(start_level, 0)
        exp = cls._int(start_exp, -1)
        multiplier = cls._int(normal_exp_multiplier, 0)

        if base <= 0:
            raise CampaignSweepEconomyPolicyError("campaign sweep base EXP must be positive")
        if mana <= 0:
            raise CampaignSweepEconomyPolicyError("campaign sweep Mana gain must be positive")
        if count <= 0 or count > 100:
            raise CampaignSweepEconomyPolicyError("campaign sweep count must be in 1..100")
        if level <= 0:
            raise CampaignSweepEconomyPolicyError("campaign sweep start level must be positive")
        if exp < 0:
            raise CampaignSweepEconomyPolicyError("campaign sweep cumulative EXP must be nonnegative")
        if multiplier <= 0:
            raise CampaignSweepEconomyPolicyError("campaign sweep EXP multiplier must be positive")

        start_level_i = level
        start_exp_i = exp
        rows: list[SweepEconomyRow] = []

        for _ in range(count):
            if level <= cls.LOW_LEVEL_MAX:
                # SweepWindow mutates only its local pre-request snapshot here.
                # It advances at most one level per row and switches to the
                # normal multiplier only on the *next* row after crossing >10.
                account_gain = base
                exp += base
                threshold = cls._int(total_exp_threshold(level), 0)
                if threshold <= 0:
                    raise CampaignSweepEconomyPolicyError(
                        f"missing cumulative EXP threshold for player level {level}"
                    )
                if exp >= threshold:
                    level += 1
            else:
                account_gain = base * multiplier

            rows.append(
                SweepEconomyRow(
                    base_exp=base,
                    mana=mana,
                    account_exp_gain=account_gain,
                )
            )

        return SweepEconomyPlan(
            rows=tuple(rows),
            total_player_exp_gain=sum(row.account_exp_gain for row in rows),
            total_mana_gain=mana * count,
            simulated_start_level=start_level_i,
            simulated_end_level=level,
            simulated_start_exp=start_exp_i,
        )
