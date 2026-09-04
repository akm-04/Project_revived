"""Source-bounded Campaign drop planning and Pass113 repeat-RNG foundation.

Effective ``src_64`` does not recover the historical server's repeat-drop
algorithm.  Pass112 therefore froze an explicit private-server compatibility
policy for ordinary MID117 repeat pools.  This module keeps immutable source
facts, executable policy, entropy mechanics, and settlement separate.

Pass113 implements the policy and the RandomOutcomeService adapter only.  Live
MID117 settlement remains intentionally inert until the separately bounded
activation pass.
"""
from __future__ import annotations

import json
import secrets
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Protocol

from gxb_backend.content.campaign_drop_source_catalog import (
    CampaignDropSourceCatalog,
    CampaignDropSourceRow,
)
from gxb_backend.state.random_outcome_service import RandomOutcomeService


CAMPAIGN_REPEAT_POLICY_ID = "campaign_repeat_rate_decomposition_v1"
CAMPAIGN_REPEAT_POLICY_VERSION = 1
CAMPAIGN_REPEAT_STRATEGY = "rate_decomposition_10000_residual"
CAMPAIGN_REPEAT_RATE_BASE = 10000
CAMPAIGN_REPEAT_NAMESPACE = "campaign.repeat.residual"
CAMPAIGN_FIRST_CLEAR_POLICY_ID = "campaign_first_clear_bernoulli_v1"
CAMPAIGN_FIRST_CLEAR_POLICY_VERSION = 1
CAMPAIGN_FIRST_CLEAR_STRATEGY = "independent_bernoulli_10000"
CAMPAIGN_FIRST_CLEAR_RATE_BASE = 10000
CAMPAIGN_FIRST_CLEAR_NAMESPACE = "campaign.first_clear.row"


class RandomSource(Protocol):
    def draw_int(self, upper_exclusive: int) -> int:
        """Return an integer in [0, upper_exclusive)."""


class SystemRandomSource:
    """Legacy-compatible randomness provider for isolated repository tests."""

    def draw_int(self, upper_exclusive: int) -> int:
        if int(upper_exclusive) <= 0:
            raise ValueError("upper_exclusive must be positive")
        return secrets.randbelow(int(upper_exclusive))


class CampaignRandomOutcomeAdapter:
    """Campaign-domain adapter over request-scoped RandomOutcomeService.

    The adapter owns no Campaign probability semantics.  It only binds a
    source-reviewed Campaign entropy namespace to the planner's tiny
    ``draw_int`` seam.
    """

    _ALLOWED_NAMESPACES = {
        CAMPAIGN_REPEAT_NAMESPACE,
        CAMPAIGN_FIRST_CLEAR_NAMESPACE,
    }

    def __init__(
        self,
        service: RandomOutcomeService,
        namespace: str = CAMPAIGN_REPEAT_NAMESPACE,
    ) -> None:
        if not isinstance(service, RandomOutcomeService):
            raise TypeError("service must be a RandomOutcomeService")
        if str(namespace) not in self._ALLOWED_NAMESPACES:
            raise ValueError(f"unsupported Campaign RNG namespace: {namespace!r}")
        self._service = service
        self.namespace = str(namespace)

    def draw_int(self, upper_exclusive: int) -> int:
        return self._service.randbelow(self.namespace, upper_exclusive)


class CampaignRepeatPoolUnavailableError(ValueError):
    """A positive source repeat-pool id has no recovered effective-source rows."""


class CampaignDropSourceCorruptionError(ValueError):
    """Recovered/generated Campaign source rows violate the frozen policy domain."""


@dataclass(frozen=True)
class CampaignDropPolicy:
    policy_id: str
    version: int
    enabled: bool
    channel: str
    wire_campaign_types: tuple[int, ...]
    pool_ids: tuple[int, ...] | None
    strategy: str
    parameters: dict[str, Any]
    evidence: str


class CampaignDropPolicyRegistry:
    """Versioned executable policy loaded separately from immutable source facts."""

    def __init__(self, data_dir: Path) -> None:
        self.path = Path(data_dir) / "campaign_drop_policy.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        self.registry_version = str(raw.get("policy_registry_version") or "unknown")
        policies = raw.get("policies") or []
        if not isinstance(policies, list):
            raise ValueError("campaign_drop_policy policies must be a list")
        self._policies: tuple[CampaignDropPolicy, ...] = tuple(
            self._parse_policy(value) for value in policies if isinstance(value, dict)
        )

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _parse_policy(self, value: dict[str, Any]) -> CampaignDropPolicy:
        scope = value.get("scope") if isinstance(value.get("scope"), dict) else {}
        wire_types = scope.get("wire_campaign_types") or []
        pool_ids_raw = scope.get("pool_ids")
        pool_ids = None
        if isinstance(pool_ids_raw, list):
            pool_ids = tuple(self._int(item) for item in pool_ids_raw if self._int(item) > 0)
        return CampaignDropPolicy(
            policy_id=str(value.get("policy_id") or ""),
            version=self._int(value.get("version"), 0),
            enabled=bool(value.get("enabled")),
            channel=str(scope.get("channel") or ""),
            wire_campaign_types=tuple(self._int(item) for item in wire_types if self._int(item) > 0),
            pool_ids=pool_ids,
            strategy=str(value.get("strategy") or ""),
            parameters=dict(value.get("parameters")) if isinstance(value.get("parameters"), dict) else {},
            evidence=str(value.get("evidence") or "unknown"),
        )

    def resolve(self, *, wire_campaign_type: int, channel: str, pool_id: int) -> CampaignDropPolicy | None:
        for policy in self._policies:
            if policy.channel != channel:
                continue
            if policy.wire_campaign_types and int(wire_campaign_type) not in policy.wire_campaign_types:
                continue
            if policy.pool_ids is not None and int(pool_id) not in policy.pool_ids:
                continue
            return policy
        return None


class CampaignRepeatPolicyRegistry:
    """Dedicated MID117 repeat policy registry; legacy MID113 never consults it."""

    def __init__(self, data_dir: Path) -> None:
        self.path = Path(data_dir) / "campaign_repeat_rng_policy.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        self.registry_version = str(raw.get("policy_registry_version") or "unknown")
        value = raw.get("policy")
        if not isinstance(value, dict):
            raise ValueError("campaign_repeat_rng_policy policy must be an object")
        wire_types = value.get("wire_campaign_types") or []
        self.policy = CampaignDropPolicy(
            policy_id=str(value.get("policy_id") or ""),
            version=CampaignDropPolicyRegistry._int(value.get("version"), 0),
            enabled=bool(value.get("enabled")),
            channel="repeat",
            wire_campaign_types=tuple(
                CampaignDropPolicyRegistry._int(item)
                for item in wire_types
                if CampaignDropPolicyRegistry._int(item) > 0
            ),
            pool_ids=None,
            strategy=str(value.get("strategy") or ""),
            parameters=dict(value.get("parameters"))
            if isinstance(value.get("parameters"), dict)
            else {},
            evidence=str(value.get("evidence") or "unknown"),
        )

    def resolve(self, *, wire_campaign_type: int) -> CampaignDropPolicy | None:
        if self.policy.wire_campaign_types and int(wire_campaign_type) not in self.policy.wire_campaign_types:
            return None
        return self.policy


@dataclass(frozen=True)
class DropOccurrence:
    occurrence_id: str
    source_pool_id: int
    source_row_id: int
    source_pool_ordinal: int
    item_id: int
    quantity: int
    slot_id: str

    def wire_item(self) -> dict[str, int]:
        return {"item_id": self.item_id, "item_num": self.quantity}

    def persisted(self) -> dict[str, Any]:
        return {
            "occurrence_id": self.occurrence_id,
            "source_pool_id": self.source_pool_id,
            "source_row_id": self.source_row_id,
            "source_pool_ordinal": self.source_pool_ordinal,
            "item_id": self.item_id,
            "item_num": self.quantity,
            "slot_id": self.slot_id,
        }


@dataclass(frozen=True)
class CampaignDropPlan:
    campaign_id: int
    wire_campaign_type: int
    channel: str
    source_pool_id: int
    policy_id: str
    policy_version: int
    policy_registry_version: str
    status: str
    occurrences: tuple[DropOccurrence, ...]
    canonical_awards: tuple[dict[str, int], ...]

    def battle_items(self) -> list[dict[str, int]]:
        return [occurrence.wire_item() for occurrence in self.occurrences]

    def persisted(self) -> dict[str, Any]:
        return {
            "schema_version": 1,
            "campaign_id": self.campaign_id,
            "wire_campaign_type": self.wire_campaign_type,
            "channel": self.channel,
            "source_pool_id": self.source_pool_id,
            "policy_id": self.policy_id,
            "policy_version": self.policy_version,
            "policy_registry_version": self.policy_registry_version,
            "status": self.status,
            "occurrences": [occurrence.persisted() for occurrence in self.occurrences],
            "canonical_awards": [dict(row) for row in self.canonical_awards],
        }


class CampaignDropPlanner:
    """Pure selector. Persistence remains owned by WorldRepository."""

    def __init__(
        self,
        source_catalog: CampaignDropSourceCatalog,
        policy_registry: CampaignDropPolicyRegistry,
        random_source: RandomSource,
        repeat_policy_registry: CampaignRepeatPolicyRegistry | None = None,
        first_clear_random_source: RandomSource | None = None,
    ) -> None:
        self.source_catalog = source_catalog
        self.policy_registry = policy_registry
        # Compatibility name retained for MID117 callers/tests.
        self.random_source = random_source
        self.repeat_random_source = random_source
        self.first_clear_random_source = first_clear_random_source or random_source
        self.repeat_policy_registry = repeat_policy_registry

    @staticmethod
    def _aggregate(occurrences: list[DropOccurrence]) -> tuple[dict[str, int], ...]:
        order: list[int] = []
        totals: dict[int, int] = {}
        for occurrence in occurrences:
            if occurrence.item_id not in totals:
                order.append(occurrence.item_id)
                totals[occurrence.item_id] = 0
            totals[occurrence.item_id] += max(0, int(occurrence.quantity))
        return tuple(
            {"item_id": item_id, "item_num": totals[item_id]}
            for item_id in order
            if item_id > 0 and totals[item_id] > 0
        )

    def plan(self, *, campaign_id: int, wire_campaign_type: int, first_clear: bool) -> CampaignDropPlan:
        channel = "first_clear" if first_clear else "repeat"
        pool_id, rows = self.source_catalog.pool_for(campaign_id, channel)
        policy = self.policy_registry.resolve(
            wire_campaign_type=int(wire_campaign_type), channel=channel, pool_id=pool_id
        )
        if policy is None:
            return self._empty_plan(
                campaign_id=campaign_id,
                wire_campaign_type=wire_campaign_type,
                channel=channel,
                pool_id=pool_id,
                policy_id="none",
                policy_version=0,
                status="no_matching_policy",
            )
        if not policy.enabled or policy.strategy == "disabled_unknown":
            return self._empty_plan(
                campaign_id=campaign_id,
                wire_campaign_type=wire_campaign_type,
                channel=channel,
                pool_id=pool_id,
                policy_id=policy.policy_id,
                policy_version=policy.version,
                status="disabled_unknown",
            )
        if policy.strategy == "deterministic_rows_matching_rate":
            return self._plan_deterministic_rows(
                campaign_id=campaign_id,
                wire_campaign_type=wire_campaign_type,
                channel=channel,
                pool_id=pool_id,
                rows=rows,
                policy=policy,
            )
        if policy.strategy == CAMPAIGN_FIRST_CLEAR_STRATEGY:
            return self._plan_first_clear_bernoulli(
                campaign_id=campaign_id,
                wire_campaign_type=wire_campaign_type,
                channel=channel,
                pool_id=pool_id,
                rows=rows,
                policy=policy,
            )
        raise ValueError(f"unsupported enabled Campaign drop strategy: {policy.strategy}")

    def plan_repeat_sweep(
        self,
        *,
        campaign_id: int,
        wire_campaign_type: int,
    ) -> CampaignDropPlan:
        """Plan one ordinary MID117 repeat sweep without mutating player state.

        This explicit entry point is intentionally separate from ``plan()``.
        The latter is already used by MID113 battle staging and must retain its
        historical repeat-RNG-disabled behavior until separately authorized.
        """

        if self.repeat_policy_registry is None:
            raise RuntimeError("MID117 repeat policy registry is not configured")
        pool_id, rows = self.source_catalog.pool_for(campaign_id, "repeat")
        policy = self.repeat_policy_registry.resolve(wire_campaign_type=int(wire_campaign_type))
        if policy is None:
            return self._empty_plan(
                campaign_id=campaign_id,
                wire_campaign_type=wire_campaign_type,
                channel="repeat",
                pool_id=pool_id,
                policy_id="none",
                policy_version=0,
                status="no_matching_policy",
                policy_registry_version=self.repeat_policy_registry.registry_version,
            )
        if not policy.enabled:
            return self._empty_plan(
                campaign_id=campaign_id,
                wire_campaign_type=wire_campaign_type,
                channel="repeat",
                pool_id=pool_id,
                policy_id=policy.policy_id,
                policy_version=policy.version,
                status="disabled_unknown",
                policy_registry_version=self.repeat_policy_registry.registry_version,
            )
        if policy.strategy != CAMPAIGN_REPEAT_STRATEGY:
            raise ValueError(f"unsupported MID117 Campaign repeat strategy: {policy.strategy}")
        return self._plan_repeat_rate_decomposition(
            campaign_id=campaign_id,
            wire_campaign_type=wire_campaign_type,
            pool_id=pool_id,
            rows=rows,
            policy=policy,
        )

    def _plan_deterministic_rows(
        self,
        *,
        campaign_id: int,
        wire_campaign_type: int,
        channel: str,
        pool_id: int,
        rows: tuple[CampaignDropSourceRow, ...],
        policy: CampaignDropPolicy,
    ) -> CampaignDropPlan:
        required_rate = int(policy.parameters.get("required_increase_rate") or 0)
        quantity = max(1, int(policy.parameters.get("quantity_per_occurrence") or 1))
        occurrences: list[DropOccurrence] = []
        for source_row in rows:
            if source_row.increase_rate != required_rate:
                continue
            occurrences.append(
                self._deterministic_occurrence(source_row, quantity, len(occurrences) + 1)
            )
        return self._planned(
            campaign_id=campaign_id,
            wire_campaign_type=wire_campaign_type,
            channel=channel,
            pool_id=pool_id,
            policy=policy,
            occurrences=occurrences,
        )

    def _plan_first_clear_bernoulli(
        self,
        *,
        campaign_id: int,
        wire_campaign_type: int,
        channel: str,
        pool_id: int,
        rows: tuple[CampaignDropSourceRow, ...],
        policy: CampaignDropPolicy,
    ) -> CampaignDropPlan:
        if channel != "first_clear":
            raise ValueError("first-clear Bernoulli policy may only execute on first_clear")
        if policy.policy_id != CAMPAIGN_FIRST_CLEAR_POLICY_ID or policy.version != CAMPAIGN_FIRST_CLEAR_POLICY_VERSION:
            raise ValueError("Campaign first-clear policy identity/version drift")
        base = int(policy.parameters.get("rate_base") or CAMPAIGN_FIRST_CLEAR_RATE_BASE)
        if base != CAMPAIGN_FIRST_CLEAR_RATE_BASE:
            raise ValueError(
                f"Campaign first-clear rate base must remain {CAMPAIGN_FIRST_CLEAR_RATE_BASE}"
            )
        if int(pool_id) == 0:
            return self._planned(
                campaign_id=campaign_id,
                wire_campaign_type=wire_campaign_type,
                channel=channel,
                pool_id=0,
                policy=policy,
                occurrences=[],
            )
        if int(pool_id) < 0:
            raise CampaignDropSourceCorruptionError("first-clear pool id must be nonnegative")
        if not rows:
            raise CampaignDropSourceCorruptionError(
                f"campaign_first_clear_pool_unavailable:{int(pool_id)}"
            )
        occurrences: list[DropOccurrence] = []
        for source_row in rows:
            rate = source_row.increase_rate
            if isinstance(rate, bool) or not isinstance(rate, int) or rate < 0 or rate > base:
                raise CampaignDropSourceCorruptionError(
                    f"invalid first-clear increase_rate for source row {source_row.row_id}: {rate!r}"
                )
            if rate == 0:
                continue
            granted = rate == base
            if not granted:
                granted = self.first_clear_random_source.draw_int(base) < rate
            if granted:
                occurrences.append(
                    self._deterministic_occurrence(source_row, 1, len(occurrences) + 1)
                )
        return self._planned(
            campaign_id=campaign_id,
            wire_campaign_type=wire_campaign_type,
            channel=channel,
            pool_id=pool_id,
            policy=policy,
            occurrences=occurrences,
        )

    def _plan_repeat_rate_decomposition(
        self,
        *,
        campaign_id: int,
        wire_campaign_type: int,
        pool_id: int,
        rows: tuple[CampaignDropSourceRow, ...],
        policy: CampaignDropPolicy,
    ) -> CampaignDropPlan:
        base = int(policy.parameters.get("rate_base") or CAMPAIGN_REPEAT_RATE_BASE)
        if base != CAMPAIGN_REPEAT_RATE_BASE:
            raise ValueError(
                f"Campaign repeat rate base must remain {CAMPAIGN_REPEAT_RATE_BASE}"
            )
        if policy.policy_id != CAMPAIGN_REPEAT_POLICY_ID or policy.version != CAMPAIGN_REPEAT_POLICY_VERSION:
            raise ValueError("Campaign repeat policy identity/version drift")

        # Source-authority distinction frozen in Pass112: a zero pool id is a
        # legitimate deterministic-only stage; a positive id with no recovered
        # rows is source content unavailable and must never be synthesized.
        if int(pool_id) == 0:
            return self._planned(
                campaign_id=campaign_id,
                wire_campaign_type=wire_campaign_type,
                channel="repeat",
                pool_id=0,
                policy=policy,
                occurrences=[],
                policy_registry_version=(
                    self.repeat_policy_registry.registry_version
                    if self.repeat_policy_registry is not None
                    else None
                ),
            )
        if int(pool_id) < 0:
            raise CampaignDropSourceCorruptionError("repeat pool id must be nonnegative")
        if not rows:
            raise CampaignRepeatPoolUnavailableError(
                f"campaign_repeat_pool_unavailable:{int(pool_id)}"
            )

        occurrences: list[DropOccurrence] = []
        for source_row in rows:
            rate = source_row.increase_rate
            if isinstance(rate, bool) or not isinstance(rate, int) or rate < 0:
                raise CampaignDropSourceCorruptionError(
                    f"invalid increase_rate for source row {source_row.row_id}: {rate!r}"
                )
            guaranteed, residual = divmod(rate, base)
            quantity = guaranteed
            if residual:
                draw = self.repeat_random_source.draw_int(base)
                if draw < residual:
                    quantity += 1
            if quantity <= 0:
                continue
            occurrences.append(
                self._deterministic_occurrence(source_row, quantity, len(occurrences) + 1)
            )

        return self._planned(
            campaign_id=campaign_id,
            wire_campaign_type=wire_campaign_type,
            channel="repeat",
            pool_id=pool_id,
            policy=policy,
            occurrences=occurrences,
            policy_registry_version=(
                self.repeat_policy_registry.registry_version
                if self.repeat_policy_registry is not None
                else None
            ),
        )

    def _planned(
        self,
        *,
        campaign_id: int,
        wire_campaign_type: int,
        channel: str,
        pool_id: int,
        policy: CampaignDropPolicy,
        occurrences: list[DropOccurrence],
        policy_registry_version: str | None = None,
    ) -> CampaignDropPlan:
        return CampaignDropPlan(
            campaign_id=int(campaign_id),
            wire_campaign_type=int(wire_campaign_type),
            channel=channel,
            source_pool_id=int(pool_id),
            policy_id=policy.policy_id,
            policy_version=policy.version,
            policy_registry_version=(policy_registry_version or self.policy_registry.registry_version),
            status="planned",
            occurrences=tuple(occurrences),
            canonical_awards=self._aggregate(occurrences),
        )

    def _empty_plan(
        self,
        *,
        campaign_id: int,
        wire_campaign_type: int,
        channel: str,
        pool_id: int,
        policy_id: str,
        policy_version: int,
        status: str,
        policy_registry_version: str | None = None,
    ) -> CampaignDropPlan:
        return CampaignDropPlan(
            campaign_id=int(campaign_id),
            wire_campaign_type=int(wire_campaign_type),
            channel=channel,
            source_pool_id=int(pool_id),
            policy_id=policy_id,
            policy_version=int(policy_version),
            policy_registry_version=(policy_registry_version or self.policy_registry.registry_version),
            status=status,
            occurrences=(),
            canonical_awards=(),
        )

    @staticmethod
    def _deterministic_occurrence(
        source_row: CampaignDropSourceRow,
        quantity: int,
        index: int,
    ) -> DropOccurrence:
        return DropOccurrence(
            occurrence_id=f"{source_row.dropbox_id}:{source_row.row_id}:{index}",
            source_pool_id=source_row.dropbox_id,
            source_row_id=source_row.row_id,
            source_pool_ordinal=source_row.pool_ordinal,
            item_id=int(source_row.item.table_id),
            quantity=int(quantity),
            slot_id=f"source_row:{source_row.pool_ordinal}",
        )
