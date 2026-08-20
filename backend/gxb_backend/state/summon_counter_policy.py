"""Source-preserving Vending counter/pity interfaces.

The historical transition math is not present in the recovered client.  This
module intentionally makes that absence executable: known topology can be
looked up, but callers cannot advance/reset a counter until a later pass installs
an evidence-backed transition engine and persistence key.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any, Protocol


class SummonCounterTransitionUnavailable(RuntimeError):
    """Raised when code attempts to execute an unrecovered counter transition."""


@dataclass(frozen=True)
class SummonCounterPolicy:
    policy_id: str
    family: str
    source_summon_row: int
    special_milestones: tuple[int, ...]
    special_dropboxes: tuple[int, ...]
    raw: dict[str, Any]
    transition_status: str
    persistence_key: str | None
    unknowns: tuple[str, ...]

    @property
    def transition_supported(self) -> bool:
        return self.transition_status in {
            "implemented",
            "implemented_private_policy",
            "implemented_private_sx_policy",
            "implemented_private_sx_policy_v2",
        } and bool(self.persistence_key)


@dataclass(frozen=True)
class SummonCounterTransition:
    before: int
    after: int
    selected_special_dropbox: int | None = None


class SummonCounterEngine(Protocol):
    def plan_transition(self, policy: SummonCounterPolicy, current: int, pull_count: int) -> SummonCounterTransition:
        ...


class PrivateServerSummonCounterEngine:
    """Result-slot counter semantics authorized by Custom Private Server Policy v1."""

    def plan_transition(self, policy: SummonCounterPolicy, current: int, pull_count: int) -> SummonCounterTransition:
        if not policy.transition_supported:
            raise SummonCounterTransitionUnavailable(f"counter transition is not active for {policy.policy_id}")
        if policy.family not in {"small", "medium"}:
            raise SummonCounterTransitionUnavailable(
                f"classic counter engine does not own family {policy.family}; use the family planner"
            )
        before = max(0, int(current))
        count = int(pull_count)
        if count != 1:
            raise SummonCounterTransitionUnavailable("private classic counter engine advances one result slot at a time")
        after = before + 1
        selected = None
        for milestone, dropbox in zip(policy.special_milestones, policy.special_dropboxes):
            if int(milestone) == after:
                selected = int(dropbox)
                break
        return SummonCounterTransition(before=before, after=after, selected_special_dropbox=selected)


class UnresolvedSummonCounterEngine:
    """Default Pass41.1 engine: fail closed rather than guessing counter math."""

    def plan_transition(self, policy: SummonCounterPolicy, current: int, pull_count: int) -> SummonCounterTransition:
        raise SummonCounterTransitionUnavailable(
            f"counter transition is unrecovered for {policy.policy_id}; activation remains fail closed"
        )


class SummonCounterPolicyRegistry:
    DATA_FILE = "summon_counter_policy.json"

    def __init__(self, data_dir: Path | str) -> None:
        self.data_dir = Path(data_dir)
        path = self.data_dir / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # pragma: no cover - startup guard
            raise RuntimeError(f"cannot load summon counter policy {path}: {exc}") from exc
        if not isinstance(raw, dict) or not isinstance(raw.get("policies"), list):
            raise RuntimeError(f"invalid summon counter policy: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self._policies: dict[str, SummonCounterPolicy] = {}
        for row in raw["policies"]:
            if not isinstance(row, dict):
                raise RuntimeError(f"invalid counter policy row in {path}")
            policy_id = str(row.get("id") or "")
            if not policy_id or policy_id in self._policies:
                raise RuntimeError(f"invalid/duplicate counter policy id {policy_id!r} in {path}")
            milestones = tuple(int(v) for v in row.get("special_milestones") or [])
            dropboxes = tuple(int(v) for v in row.get("special_dropboxes") or [])
            if dropboxes and len(dropboxes) != len(milestones):
                raise RuntimeError(f"counter policy {policy_id} milestone/dropbox lengths differ")
            policy = SummonCounterPolicy(
                policy_id=policy_id,
                family=str(row.get("family") or ""),
                source_summon_row=int(row.get("source_summon_row") or 0),
                special_milestones=milestones,
                special_dropboxes=dropboxes,
                raw=dict(row.get("raw") or {}),
                transition_status=str(row.get("transition_status") or "unknown_fail_closed"),
                persistence_key=(str(row["persistence_key"]) if row.get("persistence_key") else None),
                unknowns=tuple(str(v) for v in row.get("unknowns") or []),
            )
            if not policy.family or policy.source_summon_row <= 0:
                raise RuntimeError(f"counter policy {policy_id} lacks source identity")
            self._policies[policy_id] = policy

    def get(self, policy_id: str | None) -> SummonCounterPolicy | None:
        if not policy_id:
            return None
        return self._policies.get(str(policy_id))

    def require(self, policy_id: str) -> SummonCounterPolicy:
        policy = self.get(policy_id)
        if policy is None:
            raise KeyError(policy_id)
        return policy

    def ids(self) -> tuple[str, ...]:
        return tuple(sorted(self._policies))
