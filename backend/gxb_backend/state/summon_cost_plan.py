"""Typed Vending CostPlan registry.

Pass41.1 deliberately separates *known cost semantics* from result/RNG
activation.  A plan can be inspected and later validated/executed by a family
strategy, but this module never spends player resources by itself.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class SummonCostComponent:
    kind: str
    amount: int
    field: str | None = None
    item_id: int | None = None
    client_local_post_success_remove: bool = False


@dataclass(frozen=True)
class SummonStateGate:
    kind: str
    field: str


@dataclass(frozen=True)
class SummonCostPlan:
    plan_id: str
    family: str
    pull_count: int
    components: tuple[SummonCostComponent, ...]
    state_gates: tuple[SummonStateGate, ...]
    vip_min: int
    execution_status: str

    @property
    def is_free(self) -> bool:
        return not self.components

    @property
    def result_activation_allowed(self) -> bool:
        # Pass41.1 only recognizes the already-implemented tutorial-free slice.
        return self.execution_status in {"tutorial_active_free_only", "private_policy_active"}


class SummonCostPlanRegistry:
    DATA_FILE = "summon_cost_policy.json"
    ECONOMY_FIELDS = {"mana", "crystal"}

    def __init__(self, data_dir: Path | str) -> None:
        self.data_dir = Path(data_dir)
        path = self.data_dir / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # pragma: no cover - startup guard
            raise RuntimeError(f"cannot load summon cost policy {path}: {exc}") from exc
        if not isinstance(raw, dict) or not isinstance(raw.get("plans"), list):
            raise RuntimeError(f"invalid summon cost policy: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self._plans: dict[str, SummonCostPlan] = {}
        for row in raw["plans"]:
            if not isinstance(row, dict):
                raise RuntimeError(f"invalid CostPlan row in {path}")
            plan_id = str(row.get("id") or "")
            if not plan_id or plan_id in self._plans:
                raise RuntimeError(f"invalid/duplicate CostPlan id {plan_id!r} in {path}")
            components: list[SummonCostComponent] = []
            for component in row.get("components") or []:
                if not isinstance(component, dict):
                    raise RuntimeError(f"invalid component in CostPlan {plan_id}")
                kind = str(component.get("kind") or "")
                amount = int(component.get("amount") or 0)
                field = str(component["field"]) if component.get("field") else None
                item_id = int(component["item_id"]) if component.get("item_id") is not None else None
                if kind == "economy":
                    if field not in self.ECONOMY_FIELDS or amount <= 0 or item_id is not None:
                        raise RuntimeError(f"invalid economy component in CostPlan {plan_id}")
                elif kind == "inventory":
                    if item_id is None or item_id <= 0 or amount <= 0 or field is not None:
                        raise RuntimeError(f"invalid inventory component in CostPlan {plan_id}")
                else:
                    raise RuntimeError(f"unsupported CostPlan component kind {kind!r}")
                components.append(
                    SummonCostComponent(
                        kind=kind,
                        amount=amount,
                        field=field,
                        item_id=item_id,
                        client_local_post_success_remove=bool(component.get("client_local_post_success_remove")),
                    )
                )
            gates: list[SummonStateGate] = []
            for gate in row.get("state_gates") or []:
                if not isinstance(gate, dict) or not gate.get("kind") or not gate.get("field"):
                    raise RuntimeError(f"invalid state gate in CostPlan {plan_id}")
                gates.append(SummonStateGate(str(gate["kind"]), str(gate["field"])))
            plan = SummonCostPlan(
                plan_id=plan_id,
                family=str(row.get("family") or ""),
                pull_count=max(1, int(row.get("pull_count") or 1)),
                components=tuple(components),
                state_gates=tuple(gates),
                vip_min=max(0, int(row.get("vip_min") or 0)),
                execution_status=str(row.get("execution_status") or "deferred_fail_closed"),
            )
            if not plan.family:
                raise RuntimeError(f"CostPlan {plan_id} lacks family")
            self._plans[plan_id] = plan

    def get(self, plan_id: str | None) -> SummonCostPlan | None:
        if not plan_id:
            return None
        return self._plans.get(str(plan_id))

    def require(self, plan_id: str) -> SummonCostPlan:
        plan = self.get(plan_id)
        if plan is None:
            raise KeyError(plan_id)
        return plan

    def ids(self) -> tuple[str, ...]:
        return tuple(sorted(self._plans))
