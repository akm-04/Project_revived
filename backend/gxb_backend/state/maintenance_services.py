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
from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog
from gxb_backend.content.summon_featured_catalog import SummonFeaturedCatalog
from gxb_backend.content.white_album_source_catalog import WhiteAlbumSourceCatalog
from gxb_backend.content.emblem_source_catalog import EmblemSourceCatalog
from gxb_backend.content.workshop_source_catalog import WorkshopSourceCatalog

from .campaign_composition import CampaignComposition
from .economy_repository import EconomyRepository
from .function_state_repository import FunctionStateRepository
from .emblem_eligibility_coordinator import EmblemEligibilityCoordinator
from .emblem_policy import EmblemPolicyRegistry
from .emblem_state_repository import EmblemStateRepository
from .hero_progression_repository import HeroProgressionRepository
from .hero_repository import HeroRepository
from .horcrux_policy import HorcruxPolicyRegistry
from .horcrux_repository import HorcruxRepository
from .inventory_repository import InventoryRepository
from .player_progression_service import PlayerProgressionService
from .player_state import PlayerState
from .resource_registry import ResourceRegistry
from .summon_repository import SummonRepository
from .summon_featured_rotation import SummonFeaturedRotationPolicy
from .world_repository import WorldRepository
from .p1_foundation_state import P1FoundationStateNormalizer


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
        self.white_album_source = WhiteAlbumSourceCatalog(self.data_dir)
        self.workshop_source = WorkshopSourceCatalog(self.data_dir)
        self.p1_foundation = P1FoundationStateNormalizer(
            player, album=self.white_album_source, workshop=self.workshop_source,
            game_data=self.catalog,
        )
        self.featured_catalog = SummonFeaturedCatalog(self.data_dir)
        self.featured_rotation = featured_rotation or SummonFeaturedRotationPolicy(
            self.data_dir, self.featured_catalog, emit_startup_log=False
        )

        # No save callback here: MultiUserDatabase.normalize_player() owns the
        # single persistence decision after all normalizers have run. Maintenance
        # composition is read/normalize-only for economy resources, so legacy
        # direct mutation fallbacks are explicitly disabled.
        self.resource_registry = ResourceRegistry.load(self.data_dir / "resource_registry.json")
        self.function_state = FunctionStateRepository(player, self.catalog)
        self.campaign_composition = CampaignComposition.build(
            player, self.data_dir, self.function_state
        )
        self.challenge_campaign_catalog = self.campaign_composition.challenge_catalog
        self.challenge_campaign_projection = self.campaign_composition.challenge_projection
        self.super_campaign_catalog = self.campaign_composition.super_catalog
        self.super_campaign_projection = self.campaign_composition.super_projection
        self.super_campaign_access = self.campaign_composition.super_access
        self.elite_campaign_unlock = self.campaign_composition.elite_campaign_unlock
        self.player_progression = PlayerProgressionService(
            player, self.data_dir, function_unlocks=self.function_state,
            elite_campaign_unlock=self.elite_campaign_unlock,
            resource_registry=self.resource_registry,
            allow_legacy_direct_energy_mutation=False,
        )
        self.economy = EconomyRepository(
            player, self.data_dir, resource_registry=self.resource_registry,
            progression=self.player_progression, allow_legacy_direct_mutation=False,
        )
        self.inventory = InventoryRepository(player, data_dir=self.data_dir)
        self.heroes = HeroRepository(
            player,
            data_dir=self.data_dir,
            economy=self.economy,
            catalog=self.catalog,
        )
        # Pass243 I2: maintenance repairs Function45 for already-qualified
        # historical accounts without a request semantic callback / popup.
        self.emblem_source = EmblemSourceCatalog(self.data_dir)
        self.emblem_eligibility = EmblemEligibilityCoordinator(
            player, self.emblem_source, self.function_state, self.heroes
        )
        # Pass248 I6: durable load-time normalization owns server-only Emblem
        # pity/proposal schema repair just like request composition does.
        self.emblem_policy = EmblemPolicyRegistry(self.data_dir)
        self.emblem_state = EmblemStateRepository(
            player, self.emblem_source, self.emblem_policy
        )
        # Pass166 H1: maintenance uses the same Horcrux source/policy/repository
        # contracts as request services, but performs only load-time normalization.
        self.horcrux_source = HorcruxSourceCatalog(self.data_dir, game_data=self.catalog)
        self.horcrux_policy = HorcruxPolicyRegistry(self.data_dir)
        self.horcrux = HorcruxRepository(
            player, self.horcrux_source, heroes=self.heroes
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
            challenge_catalog=self.challenge_campaign_catalog,
            challenge_projection=self.challenge_campaign_projection,
            super_catalog=self.super_campaign_catalog,
            super_access_policy=self.super_campaign_access,
            super_projection=self.super_campaign_projection,
            elite_campaign_unlock=self.elite_campaign_unlock,
            strict_campaign_collaborators=True,
        )
        self.summon = SummonRepository(
            player,
            self.data_dir,
            heroes=self.heroes,
            inventory=self.inventory,
            catalog=self.catalog,
            featured_rotation=self.featured_rotation,
        )
