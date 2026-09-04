"""Function45 and per-Hero Emblem eligibility coordination (Pass243 I2).

SOURCE_FACT boundary:
- function.lua row 45 is Emblem with level spec 7|100;
- FunctionOpenTable treats kind 7 as a level gate;
- current NormalHero/SuperHero expose Emblem only when the Hero is Blood
  Awakened and Hero level >= Function45's level.

Function45 announcement is guide-sensitive compatibility state.  It is not an
authorization boundary for Emblem item/equipment mutations.
"""
from __future__ import annotations

from typing import Any

from gxb_backend.content.emblem_source_catalog import EmblemSourceCatalog

from .function_state_repository import FunctionStateRepository
from .hero_repository import HeroRepository
from .player_state import PlayerState
from .unit_of_work import UnitOfWork


class EmblemEligibilityCoordinator:
    FUNCTION_ID = 45

    def __init__(
        self,
        player: PlayerState,
        source: EmblemSourceCatalog,
        function_state: FunctionStateRepository,
        heroes: HeroRepository,
        *,
        uow: UnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.source = source
        self.function_state = function_state
        self.heroes = heroes
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @property
    def required_level(self) -> int:
        return max(1, self._int(self.source.identity.get("function_level"), 100))

    def hero_eligible(self, hero: dict[str, Any] | None) -> bool:
        if not isinstance(hero, dict):
            return False
        return (
            self._int(hero.get("twice_awake_stage"), 0) >= 3
            and self._int(hero.get("lev"), 0) >= self.required_level
        )

    def partner_eligible(self, partner_id: Any) -> bool:
        return self.hero_eligible(self.heroes.get(self._int(partner_id, 0)))

    def any_eligible_hero(self) -> bool:
        # Read the canonical PlayerState Hero collection through HeroRepository;
        # do not infer eligibility from mission state or Function45 itself.
        heroes = self.heroes.payload().get("heros") or {}
        return any(self.hero_eligible(hero) for hero in heroes.values() if isinstance(hero, dict))

    def operationally_enabled(self) -> bool:
        """Global Emblem operational gate for server-side Forge/Reforge.

        SOURCE_SHAPED IMPLEMENTATION boundary: current client access is reachable
        only from a Blood-stage-3, level-100 Hero, while Function45 itself is
        guide-sensitive state and must never become authorization. Recovery paths
        for already-paid proposals (Save/Abandon) deliberately do not use this
        gate so eligibility loss cannot strand durable proposal state.
        """
        return self.any_eligible_hero()

    def _ensure_global_level_eligibility(self) -> bool:
        return self.function_state.ensure_level_eligible(
            self.FUNCTION_ID,
            self._int(getattr(self.player, "lev", 1), 1),
            persist=False,
        )

    def reconcile(self, *, announce: bool) -> list[int]:
        """Reconcile Function45 from canonical player+Hero state.

        ``announce=True`` is used in a live request (Blood terminal claim) and
        therefore may stage NEW_FUNC_OPEN via FunctionStateRepository's semantic
        callback.  Maintenance composition has no semantic callback, so the same
        announcement merely repairs persisted func_ids without a login popup.
        """
        self._ensure_global_level_eligibility()
        if not self.function_state.is_eligible(self.FUNCTION_ID):
            return []
        if not self.any_eligible_hero():
            return []
        added = self.function_state.announce([self.FUNCTION_ID], persist=False)
        if added and self.uow is not None and self.uow.active:
            self.uow.mark_changed("emblem_function45")
        return added if announce else added

    def on_blood_terminal(self, partner_id: Any) -> list[int]:
        # Fail closed to the exact Hero just terminally mutated.  The broader
        # any_eligible_hero() check inside reconcile is retained for historical
        # accounts and makes the operation idempotent if another qualifying Hero
        # already opened the function.
        if not self.partner_eligible(partner_id):
            return []
        return self.reconcile(announce=True)

    def maintenance_reconcile(self) -> bool:
        before_eligible = self.function_state.is_eligible(self.FUNCTION_ID)
        before_announced = self.function_state.is_announced(self.FUNCTION_ID)
        self.reconcile(announce=False)
        return (
            before_eligible != self.function_state.is_eligible(self.FUNCTION_ID)
            or before_announced != self.function_state.is_announced(self.FUNCTION_ID)
        )
