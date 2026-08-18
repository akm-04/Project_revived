"""Memoized request-scoped composition root for canonical player services."""
from __future__ import annotations

from pathlib import Path
from typing import Callable

from gxb_backend.content import GameDataCatalog

from .economy_repository import EconomyRepository
from .function_state_repository import FunctionStateRepository
from .global_response_semantics import GlobalResponseSemantics
from .hero_equipment_repository import HeroEquipmentRepository
from .hero_progression_repository import HeroProgressionRepository
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .mission_repository import MissionRepository
from .player_state import PlayerState
from .reward_transaction_service import RewardTransactionService
from .summon_repository import SummonRepository
from .tutorial_milestone_repository import TutorialMilestoneRepository
from .unit_of_work import UnitOfWork
from .world_repository import WorldRepository


class RequestServices:
    """One shared repository/service graph for one bound player request."""

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        commit_callback: Callable[[], None],
        *,
        catalog: GameDataCatalog,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self.catalog = catalog
        self.uow = UnitOfWork(player, commit_callback)
        self.response_semantics = GlobalResponseSemantics(player, self.uow)
        save = self.uow.request_save

        self.function_state = FunctionStateRepository(player, self.catalog, save, self.uow.stage_semantic)
        self.tutorial = TutorialMilestoneRepository(player, self.function_state, save)
        self.economy = EconomyRepository(
            player, self.data_dir, save, function_unlocks=self.function_state
        )
        self.inventory = InventoryRepository(player, save)
        self.heroes = HeroRepository(
            player, save, self.data_dir, economy=self.economy, catalog=self.catalog, uow=self.uow
        )
        self.hero_progression = HeroProgressionRepository(
            player,
            self.data_dir,
            save,
            inventory=self.inventory,
            heroes=self.heroes,
            uow=self.uow,
            response_semantics=self.response_semantics,
        )
        self.hero_equipment = HeroEquipmentRepository(
            player,
            self.data_dir,
            save,
            inventory=self.inventory,
            heroes=self.heroes,
            progression=self.hero_progression,
            economy=self.economy,
        )
        self.rewards = RewardTransactionService(
            self.catalog, self.economy, self.inventory, self.heroes, self.uow
        )
        self.missions = MissionRepository(
            player,
            self.data_dir,
            save,
            economy=self.economy,
            inventory=self.inventory,
            catalog=self.catalog,
            rewards=self.rewards,
            uow=self.uow,
        )
        self.summon = SummonRepository(
            player,
            self.data_dir,
            save,
            heroes=self.heroes,
            inventory=self.inventory,
            catalog=self.catalog,
            uow=self.uow,
        )
        self.world = WorldRepository(
            player,
            self.data_dir,
            save,
            inventory=self.inventory,
            economy=self.economy,
            hero_progression=self.hero_progression,
            missions=self.missions,
            catalog=self.catalog,
            rewards=self.rewards,
            tutorial=self.tutorial,
            uow=self.uow,
        )

    def apply_semantic_deltas(self, payload):
        """Merge explicit committed semantic events into an endpoint payload."""
        if not isinstance(payload, dict):
            return payload
        deltas = self.uow.consume_semantic()
        if not deltas:
            return payload
        result = dict(payload)

        raw_economy = deltas.get("economy_", [])
        if raw_economy:
            merged_economy = dict(result.get("economy_")) if isinstance(result.get("economy_"), dict) else {}
            for row in raw_economy:
                if isinstance(row, dict):
                    merged_economy.update(row)
            if merged_economy:
                # Explicitly staged cumulative fields are normalized to the
                # canonical post-commit player state where a local owner exists.
                if "skill_point" in merged_economy:
                    try:
                        merged_economy["skill_point"] = max(0, int(self.player.skill_point))
                    except (TypeError, ValueError):
                        merged_economy["skill_point"] = 0
                result["economy_"] = merged_economy

        raw_funcs = deltas.get("new_funcs_", [])
        if raw_funcs:
            existing = result.get("new_funcs_") if isinstance(result.get("new_funcs_"), list) else []
            values: set[int] = set()
            for raw in [*existing, *raw_funcs]:
                try:
                    value = int(raw)
                except (TypeError, ValueError):
                    continue
                if value > 0:
                    values.add(value)
            if values:
                result["new_funcs_"] = sorted(values)
        return result
