"""Pass40.1 modular Campaign drop planning seam.

The historical Campaign RNG formula is not recovered.  This module therefore
keeps source facts, executable policy, randomness and planning as separate
components.  Only the already-supported deterministic first-clear compatibility
policy is executable in Pass40.1; repeat RNG remains explicitly disabled.
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


class RandomSource(Protocol):
    def draw_int(self, upper_exclusive: int) -> int:
        """Return an integer in [0, upper_exclusive)."""


class SystemRandomSource:
    """Randomness provider only; no Campaign reward semantics live here."""

    def draw_int(self, upper_exclusive: int) -> int:
        if int(upper_exclusive) <= 0:
            raise ValueError("upper_exclusive must be positive")
        return secrets.randbelow(int(upper_exclusive))


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
    """Pure selector. Persistence remains owned by WorldRepository at MID113."""

    def __init__(
        self,
        source_catalog: CampaignDropSourceCatalog,
        policy_registry: CampaignDropPolicyRegistry,
        random_source: RandomSource,
    ) -> None:
        self.source_catalog = source_catalog
        self.policy_registry = policy_registry
        self.random_source = random_source

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
            return CampaignDropPlan(
                campaign_id=int(campaign_id), wire_campaign_type=int(wire_campaign_type), channel=channel,
                source_pool_id=int(pool_id), policy_id="none", policy_version=0,
                policy_registry_version=self.policy_registry.registry_version,
                status="no_matching_policy", occurrences=(), canonical_awards=(),
            )
        if not policy.enabled or policy.strategy == "disabled_unknown":
            return CampaignDropPlan(
                campaign_id=int(campaign_id), wire_campaign_type=int(wire_campaign_type), channel=channel,
                source_pool_id=int(pool_id), policy_id=policy.policy_id, policy_version=policy.version,
                policy_registry_version=self.policy_registry.registry_version,
                status="disabled_unknown", occurrences=(), canonical_awards=(),
            )
        if policy.strategy != "deterministic_rows_matching_rate":
            raise ValueError(f"unsupported enabled Campaign drop strategy: {policy.strategy}")

        required_rate = int(policy.parameters.get("required_increase_rate") or 0)
        quantity = max(1, int(policy.parameters.get("quantity_per_occurrence") or 1))
        occurrences: list[DropOccurrence] = []
        for source_row in rows:
            if source_row.increase_rate != required_rate:
                continue
            occurrences.append(self._deterministic_occurrence(source_row, quantity, len(occurrences) + 1))
        return CampaignDropPlan(
            campaign_id=int(campaign_id), wire_campaign_type=int(wire_campaign_type), channel=channel,
            source_pool_id=int(pool_id), policy_id=policy.policy_id, policy_version=policy.version,
            policy_registry_version=self.policy_registry.registry_version,
            status="planned", occurrences=tuple(occurrences),
            canonical_awards=self._aggregate(occurrences),
        )

    @staticmethod
    def _deterministic_occurrence(source_row: CampaignDropSourceRow, quantity: int, index: int) -> DropOccurrence:
        return DropOccurrence(
            occurrence_id=f"{source_row.dropbox_id}:{source_row.row_id}:{index}",
            source_pool_id=source_row.dropbox_id,
            source_row_id=source_row.row_id,
            source_pool_ordinal=source_row.pool_ordinal,
            item_id=int(source_row.item.table_id),
            quantity=int(quantity),
            slot_id=f"source_row:{source_row.pool_ordinal}",
        )
