"""Non-request composition root for player load/fresh-state normalization.

Pass 35.1 keeps maintenance/bootstrap repository wiring in one place so the
request-scoped ``RequestServices`` graph and offline/player-load normalization
cannot silently drift into different constructor conventions.  This object has
no UnitOfWork and no request semantics: callers remain responsible for deciding
whether/when normalized PlayerState is persisted.
"""
from __future__ import annotations

from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.summon_featured_catalog import SummonFeaturedCatalog

from .economy_repository import EconomyRepository
from .hero_progression_repository import HeroProgressionRepository
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .player_state import PlayerState
from .summon_repository import SummonRepository
from .summon_featured_rotation import SummonFeaturedRotationPolicy
from .world_repository import WorldRepository


class PlayerMaintenanceServices:
    """Shared repository wiring for non-request player maintenance."""

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        *,
        featured_rotation: SummonFeaturedRotationPolicy | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self.catalog = GameDataCatalog.load(self.data_dir / "game_data_catalog.json")
        self.featured_catalog = SummonFeaturedCatalog(self.data_dir)
        self.featured_rotation = featured_rotation or SummonFeaturedRotationPolicy(
            self.data_dir, self.featured_catalog, emit_startup_log=False
        )

        # No save callback here: MultiUserDatabase.normalize_player() owns the
        # single persistence decision after all normalizers have run.
        self.economy = EconomyRepository(player, self.data_dir)
        self.inventory = InventoryRepository(player)
        self.heroes = HeroRepository(
            player,
            data_dir=self.data_dir,
            economy=self.economy,
            catalog=self.catalog,
        )
        self.hero_progression = HeroProgressionRepository(
            player,
            self.data_dir,
            inventory=self.inventory,
            heroes=self.heroes,
            catalog=self.catalog,
        )
        self.world = WorldRepository(
            player,
            self.data_dir,
            inventory=self.inventory,
            economy=self.economy,
            hero_progression=self.hero_progression,
            catalog=self.catalog,
        )
        self.summon = SummonRepository(
            player,
            self.data_dir,
            heroes=self.heroes,
            inventory=self.inventory,
            catalog=self.catalog,
            featured_rotation=self.featured_rotation,
        )
