"""Side-effect-free derived MutationPlan augmentation seam (Pass205 Stage A)."""
from __future__ import annotations

import copy
from dataclasses import dataclass
from typing import Protocol

from .mutation_plan import MutationPlan
from .player_state import PlayerState
from .unit_of_work import PlayerUnitOfWork


@dataclass(frozen=True)
class DerivedMutationContext:
    player: PlayerState
    state_version: int


class DerivedMutationRule(Protocol):
    name: str

    def augment(self, plan: MutationPlan, context: DerivedMutationContext) -> MutationPlan:
        ...


class DerivedMutationRuleRegistry:
    """Deterministic ordered derived-mutation pipeline.

    Rules must be pure with respect to PlayerState. Stage A initially registered no
    rules; Pass211 Stage F installs the first authorized consumer, the Occult
    stamina-accrual rule, without granting it direct mutation authority.
    """

    def __init__(self) -> None:
        self._rules: list[DerivedMutationRule] = []

    @property
    def names(self) -> tuple[str, ...]:
        return tuple(str(rule.name) for rule in self._rules)

    def register(self, rule: DerivedMutationRule) -> None:
        name = str(getattr(rule, "name", "") or "").strip()
        if not name:
            raise ValueError("derived mutation rule name must be non-empty")
        if name in self.names:
            raise ValueError(f"derived mutation rule already registered: {name}")
        if not hasattr(rule, "augment"):
            raise ValueError(f"derived mutation rule lacks augment(): {name}")
        self._rules.append(rule)

    def augment(self, plan: MutationPlan, *, player: PlayerState, uow: PlayerUnitOfWork) -> MutationPlan:
        current = plan
        if not self._rules:
            return current
        context = DerivedMutationContext(player=player, state_version=uow.current_state_version)
        for rule in self._rules:
            before_state = copy.deepcopy(vars(player))
            derived = rule.augment(current, context)
            if not isinstance(derived, MutationPlan):
                raise TypeError(f"derived mutation rule {rule.name} did not return MutationPlan")
            if vars(player) != before_state:
                raise RuntimeError(f"derived mutation rule {rule.name} mutated PlayerState")
            current = derived
        return current
