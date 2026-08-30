"""Typed synchronization compatibility/operational policy registry.

These entries are deliberately distinct from recovered source facts.  They are
replaceable EOL compatibility or operational choices constrained by current
client/native evidence.  Gameplay-domain private policies remain owned by their
existing domain modules.
"""
from __future__ import annotations

import copy
import json
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping


_ALLOWED_CLASSIFICATIONS = frozenset({
    "COMPATIBILITY_POLICY",
    "COMPATIBILITY_POLICY_WITH_SOURCE_BACKED_PREDICATES",
    "COMPATIBILITY_POLICY_MIRROR_CURRENT_CLIENT",
    "OPERATIONAL_POLICY",
})


@dataclass(frozen=True)
class SynchronizationCompatibilityPolicy:
    policy_id: str
    classification: str
    owner_component: str
    decision: Any
    source_constraints: tuple[str, ...]
    rationale: str
    acceptance_gates: tuple[str, ...]
    replacement_trigger: str


class SynchronizationCompatibilityPolicyRegistry:
    """Fail-closed immutable registry for synchronization-only policy choices."""

    REQUIRED_POLICY_IDS = frozenset({
        "PRACTICE_INACTIVE_BASELINE",
        "TREASURE_INACTIVE_BASELINE",
        "GUILD_WAR_INACTIVE_BASELINE",
        "PET_CAMPAIGN_INACTIVE_INFO",
        "PET_CAMPAIGN_INACTIVE_RED",
        "MISSION_REDMARK_POLICY",
        "BATTLEPASS_REDMARK_POLICY",
        "REALTIME_SEQUENCE",
        "REALTIME_ENTERED_EXTRAS",
        "REALTIME_PREAUTH_TIMEOUT",
        "REALTIME_IDLE_TIMEOUT",
        "REALTIME_OUTBOUND_BACKPRESSURE",
        "REALTIME_DEFAULT_ROLE",
        "REALTIME_AMF3_NUMERIC_PROFILE",
    })

    def __init__(self, policies: Mapping[str, SynchronizationCompatibilityPolicy]) -> None:
        rows = dict(policies)
        if set(rows) != set(self.REQUIRED_POLICY_IDS):
            missing = sorted(self.REQUIRED_POLICY_IDS - set(rows))
            extra = sorted(set(rows) - self.REQUIRED_POLICY_IDS)
            raise ValueError(f"synchronization policy census drift missing={missing} extra={extra}")
        self._policies = MappingProxyType(rows)

    @classmethod
    def load(cls, path: Path) -> "SynchronizationCompatibilityPolicyRegistry":
        raw = json.loads(Path(path).read_text(encoding="utf-8"))
        if int(raw.get("schema_version", 0) or 0) != 1:
            raise ValueError("unsupported synchronization compatibility policy schema")
        entries = raw.get("policies")
        if not isinstance(entries, list):
            raise ValueError("synchronization compatibility policy requires policies[]")
        policies: dict[str, SynchronizationCompatibilityPolicy] = {}
        for raw_row in entries:
            if not isinstance(raw_row, dict):
                raise ValueError("invalid synchronization compatibility policy row")
            policy_id = str(raw_row.get("policy_id") or "").strip()
            classification = str(raw_row.get("classification") or "").strip()
            owner = str(raw_row.get("owner_component") or "").strip()
            replacement = str(raw_row.get("replacement_trigger") or "").strip()
            if not policy_id or not owner or not replacement:
                raise ValueError("policy_id/owner_component/replacement_trigger are required")
            if classification not in _ALLOWED_CLASSIFICATIONS:
                raise ValueError(f"unsupported policy classification {classification!r} for {policy_id}")
            if policy_id in policies:
                raise ValueError(f"duplicate synchronization policy {policy_id}")
            policies[policy_id] = SynchronizationCompatibilityPolicy(
                policy_id=policy_id,
                classification=classification,
                owner_component=owner,
                decision=copy.deepcopy(raw_row.get("decision")),
                source_constraints=tuple(str(v) for v in raw_row.get("source_constraints", []) if str(v)),
                rationale=str(raw_row.get("rationale") or ""),
                acceptance_gates=tuple(str(v) for v in raw_row.get("acceptance_gates", []) if str(v)),
                replacement_trigger=replacement,
            )
        return cls(policies)

    def require(self, policy_id: str) -> SynchronizationCompatibilityPolicy:
        try:
            return self._policies[str(policy_id)]
        except KeyError as exc:
            raise KeyError(f"unknown synchronization compatibility policy: {policy_id}") from exc

    def decision(self, policy_id: str) -> Any:
        return copy.deepcopy(self.require(policy_id).decision)

    def all(self) -> tuple[SynchronizationCompatibilityPolicy, ...]:
        return tuple(self._policies[key] for key in sorted(self._policies))
