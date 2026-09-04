"""Memoized request-scoped composition root for canonical player services."""
from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path
from typing import Callable

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.item_sale_catalog import ItemSaleCatalog
from gxb_backend.content.consumable_effect_catalog import ConsumableEffectCatalog
from gxb_backend.content.campaign_drop_source_catalog import CampaignDropSourceCatalog
from gxb_backend.content.magic_summon_source_catalog import MagicSummonSourceCatalog
from gxb_backend.content.skin_source_catalog import SkinSourceCatalog
from gxb_backend.content.gift_opening_source_catalog import GiftOpeningSourceCatalog
from gxb_backend.content.fumo_restoration_source_catalog import FumoRestorationSourceCatalog
from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog
from gxb_backend.content.emblem_source_catalog import EmblemSourceCatalog
from gxb_backend.content.battle_pass_redmark_source_catalog import BattlePassRedmarkSourceCatalog
from gxb_backend.content.vow_source_catalog import VowSourceCatalog
from gxb_backend.synchronization import SynchronizationCatalogs, HydrationSnapshotAssembler, DeferredUiStatusAdapterService
from gxb_backend.realtime.publisher import RealtimeEventSchemaRegistry, RealtimeIntentStager
from gxb_backend.content.summon_operation_catalog import SummonOperationCatalog
from gxb_backend.content.summon_pool_catalog import SummonPoolCatalog
from gxb_backend.content.sx_soul_box_source_catalog import SXSoulBoxSourceCatalog
from gxb_backend.content.recharge_catalog import RechargeSourceCatalog
from gxb_backend.content.vip_award_catalog import VipAwardSourceCatalog
from gxb_backend.content.campaign_reset_catalog import CampaignResetSourceCatalog
from gxb_backend.content.energy_purchase_catalog import EnergyPurchaseSourceCatalog
from gxb_backend.content.summon_featured_catalog import SummonFeaturedCatalog
from gxb_backend.content.course_source_catalog import CourseSourceCatalog
from gxb_backend.content.white_album_source_catalog import WhiteAlbumSourceCatalog
from gxb_backend.content.workshop_source_catalog import WorkshopSourceCatalog
from gxb_backend.content.element_equipment_source_catalog import ElementEquipmentSourceCatalog
from gxb_backend.content.awakening_source_catalog import AwakeningSourceCatalog
from gxb_backend.content.awakening_compatibility_policy import AwakeningCompatibilityPolicy
from gxb_backend.content.occult_source_catalog import OccultSourceCatalog

from .awakening_mission_service import AwakeningMissionService
from .awakening_equipment_coordinator import AwakeningEquipmentCoordinator
from .awakening_campaign_overlay_planner import AwakeningCampaignOverlayPlanner
from .awakening_campaign_objective_validator import AwakeningCampaignObjectiveValidator
from .kongming_awake_skill_service import KongMingAwakeSkillService
from .commerce_service import CommerceEntitlementService, RechargeCatalogService, RechargeEolAvailabilityPolicy
from .commerce_purchase import (
    CommerceSettlementService,
    RechargeGiftbagPolicy,
    RechargeGiftbagRandomOutcomeAdapter,
)
from .vip_policy import VipPrivilegeResolver, VipProgressionPolicy
from .vip_award_service import VipAwardService
from .campaign_reset_policy import CampaignResetPolicy
from .campaign_composition import CampaignComposition
from .energy_purchase_service import EnergyPurchaseService
from .campaign_drop_planner import (
    CampaignDropPlanner,
    CampaignDropPolicyRegistry,
    CampaignRepeatPolicyRegistry,
    CampaignRandomOutcomeAdapter,
)
from .economy_ledger import EconomyLedger
from .economy_repository import EconomyRepository
from .function_state_repository import FunctionStateRepository
from .fumo_restoration_planner import FumoRestorationPlanner
from .gear_pack_materializer import GearPackMaterializer
from .gift_opening_service import (
    GiftOpeningPlanner,
    GiftOpeningService,
    GiftRandomOutcomeAdapter,
)
from .global_response_semantics import GlobalResponseSemantics, GlobalSemanticEnvelopeAssembler
from .hero_entity_mutation_service import HeroEntityMutationService
from .emblem_policy import EmblemPolicyRegistry
from .emblem_outcome_planner import EmblemOutcomePlanner
from .emblem_state_repository import EmblemStateRepository
from .emblem_service import EmblemService
from .emblem_eligibility_coordinator import EmblemEligibilityCoordinator
from .hero_advanced_progression_repository import HeroAdvancedProgressionRepository
from .hero_equipment_repository import HeroEquipmentRepository
from .hero_progression_repository import HeroProgressionRepository
from .hero_repository import HeroRepository
from .hero_creation_initializers import HeroCreationInitializerRegistry
from .durable_timed_job import DurableTimedJobPolicy
from .event_centre_acceleration_policy import EventCentreAccelerationPolicy
from .event_centre_building_service import EventCentreBuildingService
from .cabinet_research_service import CabinetResearchService
from .p1_foundation_state import P1FoundationStateNormalizer
from .white_album_service import WhiteAlbumService
from .course_study_progress_policy import CourseStudyProgressPolicy
from .course_service import CourseService
from .element_equipment_eligibility_policy import ElementEquipmentEligibilityPolicy
from .horcrux_policy import HorcruxPolicyRegistry
from .horcrux_enhancement import HorcruxEnhancementPlanner
from .horcrux_repository import HorcruxRepository
from .horcrux_materializer import (
    HorcruxGeneratedRewardOwner,
    HorcruxGiftRewardAdapter,
    HorcruxMaterializer,
    HorcruxRandomOutcomeAdapter,
)
from .horcrux_service import HorcruxService
from .gods_trial_service import GodsTrialService
from .gods_trial_drop_planner import GodsTrialDropPlanner, GodsTrialRandomOutcomeAdapter
from .inventory_repository import InventoryRepository
from .inventory_sale_service import InventorySaleService
from .mission_repository import MissionRepository
from .generic_redmark_projection import GenericRedmarkProjectionService
from .message_push_preference_service import MessagePushPreferenceService
from .mutation_settlement_service import MutationSettlementService
from .derived_mutation_rules import DerivedMutationRuleRegistry
from .occult_entity_mutation_service import OccultEntityMutationService
from .occult_stamina_accrual_rule import OccultStaminaAccrualRule
from .occult_service import OccultService
from .awakening_projection_builder import AwakeningProjectionBuilder
from .item_composition_service import ItemCompositionService, CabinetCompositionProvider, AwakeningCompositionProvider, EmblemCompositionProvider
from .player_progression_service import PlayerProgressionService
from .player_state import PlayerState
from .reward_transaction_service import RewardTransactionService
from .random_outcome_service import (
    EntropyProvider,
    NamespacedRandbelowAdapter,
    RandomOutcomeService,
)
from .resource_registry import ResourceRegistry
from .server_clock import ServerClock
from .skin_ownership_service import SkinOwnershipService
from .temporal_policy_service import TemporalPolicyService
from .summon_operation_registry import SummonOperationRegistry
from .summon_cost_plan import SummonCostPlanRegistry
from .summon_counter_policy import SummonCounterPolicyRegistry, PrivateServerSummonCounterEngine
from .summon_duplicate_conversion import ConfiguredSummonDuplicateConversionResolver
from .summon_duplicate_policy import SummonDuplicateConversionPolicy
from .summon_result_plan import SummonResultRenderer
from .summon_private_policy import SummonPrivateServerPolicy, ClassicVendingPrivatePlanner
from .classic_vending_balance_policy import ClassicVendingBalancePolicy, ClassicVendingBalancePlanner
from .magic_summon_private_policy import MagicSummonPrivatePlanner, MagicSummonPrivatePolicy
from .sx_soul_box_private_policy import SXSoulBoxPrivatePlanner, SXSoulBoxPrivatePolicy
from .summon_featured_rotation import SummonFeaturedRotationPolicy
from .medium_legacy_private_policy import MediumLegacyPrivatePlanner, MediumLegacyPrivatePolicy
from .summon_result_policy import SummonResultPolicyRegistry
from .summon_state_contract import SummonStateContract
from .summon_repository import SummonRepository
from .tutorial_milestone_repository import TutorialMilestoneRepository
from .unit_of_work import UnitOfWork
from .world_repository import WorldRepository
from .vow_service import VowService


@dataclass(frozen=True)
class RequestServiceImmutableCatalogs:
    """App-scoped immutable source/config objects shared by request graphs.

    Pass281 performance reconciliation: these classes are source catalogs or
    read-only policy registries. Static audit confirms they do not mutate
    instance state after construction. Sharing them removes repeated parsing
    without sharing any player/UoW/request state.
    """

    consumable_effects: ConsumableEffectCatalog
    course_source: CourseSourceCatalog
    white_album_source: WhiteAlbumSourceCatalog
    workshop_source: WorkshopSourceCatalog
    element_source: ElementEquipmentSourceCatalog
    recharge_source_catalog: RechargeSourceCatalog
    campaign_reset_source: CampaignResetSourceCatalog
    energy_purchase_source: EnergyPurchaseSourceCatalog
    occult_source: OccultSourceCatalog
    horcrux_source: HorcruxSourceCatalog
    horcrux_policy: HorcruxPolicyRegistry
    skin_source: SkinSourceCatalog
    emblem_source: EmblemSourceCatalog
    emblem_policy: EmblemPolicyRegistry
    fumo_restoration_source: FumoRestorationSourceCatalog
    vow_source: VowSourceCatalog
    gift_opening_source: GiftOpeningSourceCatalog
    vip_award_source: VipAwardSourceCatalog
    awakening_source: AwakeningSourceCatalog
    battle_pass_redmark_source: BattlePassRedmarkSourceCatalog
    campaign_drop_source: CampaignDropSourceCatalog
    campaign_drop_policy: CampaignDropPolicyRegistry
    campaign_repeat_policy: CampaignRepeatPolicyRegistry
    summon_operation_catalog: SummonOperationCatalog
    summon_counter_policies: SummonCounterPolicyRegistry
    summon_pool_catalog: SummonPoolCatalog
    summon_featured_catalog: SummonFeaturedCatalog
    summon_result_policy: SummonResultPolicyRegistry
    magic_summon_source: MagicSummonSourceCatalog
    sx_soul_box_source: SXSoulBoxSourceCatalog

    @classmethod
    def load(
        cls, data_dir: Path, *, game_data: GameDataCatalog,
        featured_catalog: SummonFeaturedCatalog | None = None,
    ) -> "RequestServiceImmutableCatalogs":
        data_dir = Path(data_dir)
        return cls(
            consumable_effects=ConsumableEffectCatalog(data_dir),
            course_source=CourseSourceCatalog(data_dir),
            white_album_source=WhiteAlbumSourceCatalog(data_dir),
            workshop_source=WorkshopSourceCatalog(data_dir),
            element_source=ElementEquipmentSourceCatalog(data_dir),
            recharge_source_catalog=RechargeSourceCatalog(data_dir),
            campaign_reset_source=CampaignResetSourceCatalog(data_dir),
            energy_purchase_source=EnergyPurchaseSourceCatalog(data_dir),
            occult_source=OccultSourceCatalog(data_dir),
            horcrux_source=HorcruxSourceCatalog(data_dir, game_data=game_data),
            horcrux_policy=HorcruxPolicyRegistry(data_dir),
            skin_source=SkinSourceCatalog(data_dir),
            emblem_source=EmblemSourceCatalog(data_dir),
            emblem_policy=EmblemPolicyRegistry(data_dir),
            fumo_restoration_source=FumoRestorationSourceCatalog(data_dir),
            vow_source=VowSourceCatalog(data_dir),
            gift_opening_source=GiftOpeningSourceCatalog(data_dir),
            vip_award_source=VipAwardSourceCatalog(data_dir),
            awakening_source=AwakeningSourceCatalog(data_dir),
            battle_pass_redmark_source=BattlePassRedmarkSourceCatalog(data_dir),
            campaign_drop_source=CampaignDropSourceCatalog(data_dir),
            campaign_drop_policy=CampaignDropPolicyRegistry(data_dir),
            campaign_repeat_policy=CampaignRepeatPolicyRegistry(data_dir),
            summon_operation_catalog=SummonOperationCatalog(data_dir),
            summon_counter_policies=SummonCounterPolicyRegistry(data_dir),
            summon_pool_catalog=SummonPoolCatalog(data_dir),
            summon_featured_catalog=featured_catalog or SummonFeaturedCatalog(data_dir),
            summon_result_policy=SummonResultPolicyRegistry(data_dir),
            magic_summon_source=MagicSummonSourceCatalog(data_dir),
            sx_soul_box_source=SXSoulBoxSourceCatalog(data_dir),
        )


class RequestServices:
    """One shared repository/service graph for one bound player request."""

    def __init__(
        self,
        player: PlayerState,
        data_dir: Path,
        commit_callback: Callable[[], None],
        *,
        catalog: GameDataCatalog,
        featured_rotation: SummonFeaturedRotationPolicy | None = None,
        server_clock: ServerClock | None = None,
        entropy_provider: EntropyProvider | None = None,
        synchronization_catalogs: SynchronizationCatalogs | None = None,
        immutable_catalogs: RequestServiceImmutableCatalogs | None = None,
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self.catalog = catalog
        # Wave B consumes the frozen channel registry, so direct test/service
        # construction loads the same immutable metadata when StateRepository
        # has not injected it explicitly.
        self.synchronization_catalogs = synchronization_catalogs or SynchronizationCatalogs.load(self.data_dir)
        self.immutable_catalogs = immutable_catalogs or RequestServiceImmutableCatalogs.load(
            self.data_dir, game_data=self.catalog
        )
        self.consumable_effects = self.immutable_catalogs.consumable_effects
        self.uow = UnitOfWork(player, commit_callback)
        # U4B Wave E: request-scoped realtime staging can validate only against
        # immutable schemas and write the generic post-commit topic. It has no
        # session/socket access and therefore cannot publish before commit.
        self.realtime_event_schemas = RealtimeEventSchemaRegistry(self.synchronization_catalogs)
        self.realtime_intents = RealtimeIntentStager(self.uow, self.realtime_event_schemas)
        # Pass110 RNG foundation remains request-scoped mechanics only. Pass111
        # injects namespaced adapters into MID50 planners below; Campaign remains
        # deliberately unmigrated until its separate bounded pass.
        self.random_outcomes = RandomOutcomeService(entropy_provider)
        self.resource_registry = ResourceRegistry.load(self.data_dir / "resource_registry.json")
        self.response_semantics = GlobalResponseSemantics(player, self.uow)
        save = self.uow.request_save
        self.server_clock = server_clock or ServerClock()
        # Pass186 P1-I1 source-only catalogs and shared mechanics. These are
        # composed now so later P1 semantic owners reuse one request graph.
        self.course_source = self.immutable_catalogs.course_source
        self.white_album_source = self.immutable_catalogs.white_album_source
        self.workshop_source = self.immutable_catalogs.workshop_source
        self.element_source = self.immutable_catalogs.element_source
        self.durable_jobs = DurableTimedJobPolicy()
        self.event_centre_acceleration = EventCentreAccelerationPolicy()
        self.hero_creation_initializers = HeroCreationInitializerRegistry()
        # Pass189 P1-I4A: newly acquired Normal Girls inherit the account's
        # canonical Bookshelf projection through the existing narrow creation seam.
        def _bookshelf_initializer(hero, bound_player):
            try:
                table_id = int(hero.get("table_id", 0) or 0)
            except (TypeError, ValueError):
                table_id = 0
            if table_id <= 0 or not self.catalog.exists(ContentRef(CatalogNamespace.PARTNER, table_id)):
                return
            rows = bound_player.building_list_payload().get("building_list", {})
            shelf = rows.get(str(self.workshop_source.BOOKSHELF_BUILDING_TYPE), {})
            try:
                level = max(0, min(100, int(shelf.get("lev", 1) or 1)))
            except (TypeError, ValueError):
                level = 1
            hero["book_shelf_lev"] = level
        self.hero_creation_initializers.register("workshop_bookshelf_projection", _bookshelf_initializer)
        self.p1_foundation_state = P1FoundationStateNormalizer(
            player, album=self.white_album_source, workshop=self.workshop_source,
            game_data=self.catalog,
        )
        # Pass87 Commerce/VIP policy is request-scoped and source-generated.
        # charge/vip remain Commerce-owned; Crystal remains EconomyLedger-owned.
        self.vip_progression = VipProgressionPolicy(self.data_dir)
        self.vip_privileges = VipPrivilegeResolver(player, self.vip_progression)
        self.recharge_source_catalog = self.immutable_catalogs.recharge_source_catalog
        self.commerce = CommerceEntitlementService(
            player, self.vip_progression, save, uow=self.uow
        )
        self.recharge_catalog = RechargeCatalogService(
            player, self.recharge_source_catalog, self.commerce, clock=self.server_clock
        )
        # Pass92 source-bounded Super Campaign reset policy. VIP remains the
        # canonical base privilege owner; active Monthly Privilege contributes
        # only its source num_elite addend. Campaign owns the actual mutation.
        self.campaign_reset_source = self.immutable_catalogs.campaign_reset_source
        self.campaign_reset_policy = CampaignResetPolicy(
            player, self.vip_privileges, self.campaign_reset_source
        )
        self.temporal = TemporalPolicyService(
            player, self.data_dir, save, clock=self.server_clock, uow=self.uow,
            vip_privileges=self.vip_privileges,
        )

        self.function_state = FunctionStateRepository(player, self.catalog, save, self.uow.stage_semantic)
        # Pass129: request and maintenance roots share one construction contract
        # for Challenge/Super Campaign collaborators.  The bundle constructs but
        # does not own policy; each catalog/projection/access/coordinator keeps
        # its distinct Pass128 authority.
        self.campaign_composition = CampaignComposition.build(
            player, self.data_dir, self.function_state, uow=self.uow
        )
        self.challenge_campaign_catalog = self.campaign_composition.challenge_catalog
        self.challenge_campaign_projection = self.campaign_composition.challenge_projection
        self.super_campaign_catalog = self.campaign_composition.super_catalog
        self.super_campaign_projection = self.campaign_composition.super_projection
        self.super_campaign_access = self.campaign_composition.super_access
        self.elite_campaign_unlock = self.campaign_composition.elite_campaign_unlock
        self.tutorial = TutorialMilestoneRepository(player, self.function_state, save)
        self.economy_ledger = EconomyLedger(
            player, self.resource_registry, save, uow=self.uow
        )
        # Pass100 MID97 source-day/expected-ordinal bridge. Crystal remains
        # EconomyLedger-owned; Energy remains TemporalPolicyService-owned.
        self.energy_purchase_source = self.immutable_catalogs.energy_purchase_source
        self.energy_purchase = EnergyPurchaseService(
            player, self.energy_purchase_source, self.vip_privileges,
            self.economy_ledger, self.temporal, self.uow, clock=self.server_clock,
        )
        self.player_progression = PlayerProgressionService(
            player, self.data_dir, save, function_unlocks=self.function_state,
            elite_campaign_unlock=self.elite_campaign_unlock,
            resource_registry=self.resource_registry, uow=self.uow, temporal=self.temporal,
            allow_legacy_direct_energy_mutation=False,
        )
        self.economy = EconomyRepository(
            player, self.data_dir, save, function_unlocks=self.function_state,
            resource_registry=self.resource_registry, ledger=self.economy_ledger, uow=self.uow,
            temporal=self.temporal, progression=self.player_progression,
            allow_legacy_direct_mutation=False,
        )
        self.inventory = InventoryRepository(player, save, data_dir=self.data_dir, uow=self.uow)
        self.stack_inventory = self.inventory
        # Pass205 P2 Stage A installed a generic derived-plan augmentation seam.
        # Pass211 Stage F is its first authorized consumer; rules remain pure and
        # actual state mutation still belongs to registered settlement owners.
        self.derived_mutation_rules = DerivedMutationRuleRegistry()
        self.mutation_settlement = MutationSettlementService(
            catalog=self.catalog,
            ledger=self.economy_ledger,
            stacks=self.stack_inventory,
            uow=self.uow,
            temporal=self.temporal,
            derived_rules=self.derived_mutation_rules,
        )
        # Pass211 Stage F: occult_ticket is intentionally domain-owned by
        # SorceryWarAggregate (resource_registry), not EconomyLedger. Ticket +
        # stamina progress therefore settle through one typed OCCULT authority.
        self.occult_source = self.immutable_catalogs.occult_source
        self.occult_entities = OccultEntityMutationService(player, self.occult_source, self.uow)
        self.mutation_settlement.register_entity_owner("OCCULT", self.occult_entities)
        self.derived_mutation_rules.register(OccultStaminaAccrualRule(self.occult_source))
        self.heroes = HeroRepository(
            player, save, self.data_dir, economy=self.economy, catalog=self.catalog, uow=self.uow,
            temporal=self.temporal, settlement=self.mutation_settlement,
            vip_privileges=self.vip_privileges,
            creation_initializers=self.hero_creation_initializers,
        )
        # Pass166 H1 Horcrux foundation. The repository owns unique instances
        # over player.spirit_list plus server-only horcrux_state; existing Hero,
        # Temporal, UoW and GameDataCatalog authorities remain canonical.
        self.horcrux_source = self.immutable_catalogs.horcrux_source
        self.horcrux_policy = self.immutable_catalogs.horcrux_policy
        self.horcrux_repository = HorcruxRepository(
            player, self.horcrux_source, heroes=self.heroes, uow=self.uow
        )
        # Pass168 H3 generated-instance bridge. ROS remains policy-free; these
        # adapters bind only the frozen Horcrux namespaces/materialization rules.
        self.horcrux_random_outcomes = HorcruxRandomOutcomeAdapter(self.random_outcomes)
        self.horcrux_materializer = HorcruxMaterializer(
            self.horcrux_source, self.horcrux_policy, self.horcrux_random_outcomes
        )
        self.horcrux_generated_rewards = HorcruxGeneratedRewardOwner(
            self.horcrux_materializer, self.horcrux_repository
        )
        self.horcrux_gift_rewards = HorcruxGiftRewardAdapter(
            self.horcrux_source, self.horcrux_policy
        )
        self.horcrux_enhancement = HorcruxEnhancementPlanner(
            self.horcrux_source, self.horcrux_policy, self.horcrux_random_outcomes
        )
        self.horcrux = HorcruxService(
            self.horcrux_repository, self.heroes, self.horcrux_policy, self.uow,
            economy=self.economy_ledger, enhancement=self.horcrux_enhancement,
        )
        # Pass151 runtime reconciliation: permanent Girl skin ownership plus the
        # source-distinct MID2979 cosmetic appearance selector. MID60/MID61/MID2979
        # share the existing Hero/Stack/UoW owners; Pet MID60 overload and temporary
        # skin lifecycle remain deliberately outside this service.
        self.skin_source = self.immutable_catalogs.skin_source
        self.skin_ownership = SkinOwnershipService(
            player, self.skin_source, self.heroes, self.stack_inventory, self.uow
        )
        # Pass152 Phase C: synthetic EOL Recharge visibility/authorization is
        # attached only after canonical StackInventory + SkinOwnership owners
        # exist. The catalog itself remains the earlier read-only source owner.
        self.recharge_eol_availability = RechargeEolAvailabilityPolicy(
            self.commerce, self.stack_inventory, self.skin_ownership
        )
        self.recharge_catalog.attach_eol_availability(self.recharge_eol_availability)
        self.hero_progression = HeroProgressionRepository(
            player,
            self.data_dir,
            save,
            inventory=self.inventory,
            heroes=self.heroes,
            uow=self.uow,
            response_semantics=self.response_semantics,
            catalog=self.catalog,
            temporal=self.temporal,
            settlement=self.mutation_settlement,
        )
        self.hero_entities = HeroEntityMutationService(
            self.heroes, self.hero_progression, self.uow
        )
        self.mutation_settlement.register_entity_owner("HERO", self.hero_entities)
        # Pass241 Emblem I0: source/policy/state/RNG/service foundation only.
        # Public deterministic Inscription MIDs remain on the accepted Pass232
        # owner until I1; server-RNG MIDs remain fail-closed until I4/I5.
        self.emblem_source = self.immutable_catalogs.emblem_source
        self.emblem_policy = self.immutable_catalogs.emblem_policy
        self.emblem_state = EmblemStateRepository(
            player, self.emblem_source, self.emblem_policy, uow=self.uow
        )
        self.emblem_outcomes = EmblemOutcomePlanner(
            self.emblem_source, self.emblem_policy, self.random_outcomes
        )
        # Pass243 I2: Function45 is guide-sensitive and per-Hero Emblem access
        # remains anchored to canonical Blood-Awakening + Hero-level state.
        self.emblem_eligibility = EmblemEligibilityCoordinator(
            player, self.emblem_source, self.function_state, self.heroes, uow=self.uow
        )
        self.emblem = EmblemService(
            player, self.emblem_source, self.emblem_policy, self.emblem_outcomes,
            self.emblem_state, self.emblem_eligibility, inventory=self.inventory, heroes=self.heroes,
            settlement=self.mutation_settlement, uow=self.uow,
        )
        # Pass187 P1-I2 White Album: client owns stat calculation; this service
        # persists only validated monotonic normal stages + special claim state.
        self.white_album = WhiteAlbumService(
            player, self.white_album_source, self.catalog, self.heroes, self.hero_entities, self.uow
        )
        # Pass188 P1-I3 Courses: deterministic lifecycle over the existing
        # Hero Course arrays + study_infos, with the unrecovered completion
        # formula isolated behind an explicit compatibility policy.
        self.course_study_progress = CourseStudyProgressPolicy()
        self.courses = CourseService(
            player, self.course_source, self.heroes, self.hero_entities, self.inventory,
            self.mutation_settlement, self.vip_privileges, self.durable_jobs,
            self.course_study_progress, self.server_clock, self.uow,
        )
        # Pass189 P1-I4A: shared Event Centre building lifecycle + Bookshelf
        # projection. Cabinet skill research remains the next bounded Workshop slice.
        self.workshop_buildings = EventCentreBuildingService(
            player, self.workshop_source, self.catalog, self.heroes, self.hero_entities,
            self.mutation_settlement, self.durable_jobs, self.event_centre_acceleration,
            self.server_clock, self.uow,
        )
        # Pass190 P1-I4B: Cabinet global book_info/research lifecycle reuses
        # the same source catalog, UoW, stack/economy owners and timed-job policy.
        self.cabinet_research = CabinetResearchService(
            player, self.workshop_source, self.catalog, self.heroes, self.hero_entities,
            self.inventory, self.mutation_settlement, self.durable_jobs,
            self.event_centre_acceleration, self.workshop_buildings, self.server_clock, self.uow,
        )
        self.fumo_restoration_source = self.immutable_catalogs.fumo_restoration_source
        self.fumo_restoration = FumoRestorationPlanner(self.fumo_restoration_source)
        self.hero_equipment = HeroEquipmentRepository(
            player,
            self.data_dir,
            save,
            inventory=self.inventory,
            heroes=self.heroes,
            progression=self.hero_progression,
            economy=self.economy,
            uow=self.uow,
            settlement=self.mutation_settlement,
            fumo_restoration=self.fumo_restoration,
        )
        self.element_eligibility = ElementEquipmentEligibilityPolicy(
            player, self.element_source, self.catalog, self.hero_equipment
        )
        self.hero_advanced = HeroAdvancedProgressionRepository(
            player, self.data_dir, save, inventory=self.inventory, heroes=self.heroes,
            uow=self.uow, settlement=self.mutation_settlement,
            element_eligibility=self.element_eligibility,
            emblem_service=self.emblem,
        )
        # Pass172 Vows acquisition/tab closure: source prerequisites/exchange
        # facts remain read-only; Hero/Stack/UoW stay canonical mutation owners.
        self.vow_source = self.immutable_catalogs.vow_source
        self.vows = VowService(player, self.vow_source, self.catalog, self.heroes, self.stack_inventory, self.uow)
        self.item_sale_catalog = ItemSaleCatalog.load(self.data_dir / "item_sale_catalog.json")
        self.inventory_sales = InventorySaleService(
            player, self.item_sale_catalog, self.mutation_settlement, self.uow
        )
        self.rewards = RewardTransactionService(
            self.catalog, self.player_progression, self.inventory, self.heroes, self.uow,
            resource_registry=self.resource_registry, settlement=self.mutation_settlement,
        )
        self.rewards.register_specialized_owner(
            HorcruxGeneratedRewardOwner.OWNER, self.horcrux_generated_rewards
        )
        # Pass170 H5 Gods Trial: Trial owns source-row/rate policy while the
        # shared ROS and RewardTransactionService remain mechanics/settlement owners.
        self.gods_trial_random_outcomes = GodsTrialRandomOutcomeAdapter(self.random_outcomes)
        self.gods_trial_drops = GodsTrialDropPlanner(
            self.horcrux_source, self.gods_trial_random_outcomes
        )
        self.gods_trial = GodsTrialService(
            player, self.horcrux_source, self.horcrux_policy,
            self.horcrux_repository, self.temporal, self.uow,
            heroes=self.heroes, catalog=self.catalog, rewards=self.rewards,
            drops=self.gods_trial_drops, server_clock=self.server_clock,
        )
        # Pass149 B1/B2 + Pass150 B3: Recharge giftbags settle through the same
        # Commerce receipt/UoW plane and canonical RewardTransaction owners.
        # The single recovered random Pack binds only entropy mechanics to ROS
        # under recharge.giftbag; Recharge retains pool/rate/settlement policy.
        self.recharge_giftbag_random_outcomes = RechargeGiftbagRandomOutcomeAdapter(
            self.random_outcomes
        )
        self.recharge_giftbag_policy = RechargeGiftbagPolicy(
            self.recharge_giftbag_random_outcomes
        )
        self.commerce_settlement = CommerceSettlementService(
            player,
            self.recharge_source_catalog,
            self.commerce,
            self.economy_ledger,
            self.vip_progression,
            self.uow,
            self.rewards,
            clock=self.server_clock,
            giftbag_availability=self.recharge_catalog.giftbag_availability,
            giftbag_policy=self.recharge_giftbag_policy,
            eol_availability=self.recharge_eol_availability,
            skin_ownership=self.skin_ownership,
        )
        # Pass138/140 MID241 Gift Opening. Source/table facts remain immutable;
        # Pass140 binds only the ordinary random lane to request-scoped ROS under
        # gift.open. Pool/rate/batching policy remains inside the Gift domain.
        self.gift_opening_source = self.immutable_catalogs.gift_opening_source
        self.gear_pack_materializer = GearPackMaterializer(self.data_dir)
        self.gift_random_outcomes = GiftRandomOutcomeAdapter(
            self.random_outcomes, "gift.open"
        )
        self.gift_opening_planner = GiftOpeningPlanner(
            self.gift_opening_source, self.gift_random_outcomes, self.horcrux_gift_rewards,
            self.gear_pack_materializer,
        )
        self.gift_opening = GiftOpeningService(
            self.gift_opening_source,
            self.gift_opening_planner,
            self.stack_inventory,
            self.rewards,
            self.uow,
        )
        # Pass91 finalizes the core VIP lifecycle: source VIP reward_item ->
        # gift.lua metadata settles through the existing typed reward/UoW spine,
        # while VipAwardService owns one-time eligibility/claim state.
        self.vip_award_source = self.immutable_catalogs.vip_award_source
        self.vip_awards = VipAwardService(
            player, self.vip_award_source, self.vip_privileges, self.rewards, self.uow
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
        # Pass205 Stage A source/persistence/projection foundation. These are
        # wired into the existing AwakeningMissionService owner without changing
        # its externally visible Pass74 lifecycle yet.
        self.awakening_source = self.immutable_catalogs.awakening_source
        self.awakening_projection = AwakeningProjectionBuilder()
        self.awakening_compatibility = AwakeningCompatibilityPolicy(self.data_dir)
        self.item_composition = ItemCompositionService(
            player, inventory=self.inventory, settlement=self.mutation_settlement, uow=self.uow,
            providers=(
                CabinetCompositionProvider(self.workshop_source),
                AwakeningCompositionProvider(self.data_dir, self.awakening_source),
                EmblemCompositionProvider(self.emblem_source),
            ),
        )
        self.awakening_missions = AwakeningMissionService(
            player, self.data_dir, save, heroes=self.heroes, inventory=self.inventory,
            uow=self.uow, settlement=self.mutation_settlement,
            source=self.awakening_source, projection=self.awakening_projection,
            compatibility=self.awakening_compatibility,
            emblem_eligibility=self.emblem_eligibility,
        )
        # U4B Wave B: one read-only derived owner for the only generic client
        # badge families supported by the frozen contract. BattlePass source
        # thresholds/reward availability are generated from current src_64.
        self.battle_pass_redmark_source = self.immutable_catalogs.battle_pass_redmark_source
        self.generic_redmarks = GenericRedmarkProjectionService(
            player, self.missions, self.awakening_missions, self.battle_pass_redmark_source
        )
        self.semantic_envelope = GlobalSemanticEnvelopeAssembler(
            player, self.uow, self.synchronization_catalogs, self.generic_redmarks
        )
        # U4B Wave C: read-only deferred status projection and durable
        # MessagePush preference ownership remain distinct concerns.
        self.deferred_status = DeferredUiStatusAdapterService(
            player, self.synchronization_catalogs, self.server_clock
        )
        self.message_push_preferences = MessagePushPreferenceService(
            player, self.synchronization_catalogs, self.uow, self.server_clock
        )
        # Pass211 Stage F: minimal Sorcery War dependency only. Full manual/co-op
        # Occult remains fenced; MID2362/MID2385 reuse canonical Awakening/UoW owners.
        self.occult = OccultService(
            player, self.occult_source, self.awakening_missions, self.occult_entities,
            self.mutation_settlement, self.uow,
        )
        # Pass210 Stage E: KongMing's permanent post-Awakening skill switch reuses
        # canonical Hero/Stack/UoW owners; Book-V items gate ownership and are never consumed.
        self.kongming_awake_skills = KongMingAwakeSkillService(
            player, self.heroes, self.inventory, self.mutation_settlement, self.uow
        )
        self.awakening_equipment = AwakeningEquipmentCoordinator(
            player, equipment=self.hero_equipment, awakening=self.awakening_missions,
            settlement=self.mutation_settlement, uow=self.uow,
        )
        # Pass209 Stage D: source-special Awakening/Blood Campaign awards reuse
        # the same request-scoped entropy mechanics and existing Campaign UoW.
        self.awakening_campaign_overlay = AwakeningCampaignOverlayPlanner(
            self.awakening_source, self.random_outcomes
        )
        self.awakening_campaign_objectives = AwakeningCampaignObjectiveValidator()
        # Pass113/114 Campaign RNG plane. Effective-source facts and domain
        # policy remain separate from entropy mechanics. Ordinary MID117 alone
        # calls plan_repeat_sweep(); MID113 retains its legacy disabled policy.
        self.campaign_drop_source = self.immutable_catalogs.campaign_drop_source
        self.campaign_drop_policy = self.immutable_catalogs.campaign_drop_policy
        self.campaign_repeat_policy = self.immutable_catalogs.campaign_repeat_policy
        self.campaign_random = CampaignRandomOutcomeAdapter(
            self.random_outcomes, "campaign.repeat.residual"
        )
        self.campaign_first_clear_random = CampaignRandomOutcomeAdapter(
            self.random_outcomes, "campaign.first_clear.row"
        )
        self.campaign_drop_planner = CampaignDropPlanner(
            self.campaign_drop_source,
            self.campaign_drop_policy,
            self.campaign_random,
            repeat_policy_registry=self.campaign_repeat_policy,
            first_clear_random_source=self.campaign_first_clear_random,
        )
        # Pass41.7 Summon composition. Recovered operation/state/cost/pool facts
        # remain separate from explicitly authorized private-server policy.
        # Classic Small/Medium stays active; Magic MID70/MID71 now has its own
        # source catalog + policy/planner. Tickets/coupons defer; Pass42.14 activates Small x100 through the same classic planner; SX has its own dedicated Pass42.6 corrected planner.
        self.summon_operation_catalog = self.immutable_catalogs.summon_operation_catalog
        self.summon_operation_registry = SummonOperationRegistry(self.summon_operation_catalog)
        self.summon_state_contract = SummonStateContract(self.data_dir)
        self.summon_cost_plans = SummonCostPlanRegistry(self.data_dir)
        self.summon_counter_policies = self.immutable_catalogs.summon_counter_policies
        self.summon_counter_engine = PrivateServerSummonCounterEngine()
        self.summon_pool_catalog = self.immutable_catalogs.summon_pool_catalog
        self.summon_featured_catalog = self.immutable_catalogs.summon_featured_catalog
        self.summon_featured_rotation = featured_rotation or SummonFeaturedRotationPolicy(
            self.data_dir, self.summon_featured_catalog, emit_startup_log=False
        )
        self.medium_legacy_policy = MediumLegacyPrivatePolicy(
            self.data_dir, self.summon_featured_catalog
        )
        self.medium_legacy_planner = MediumLegacyPrivatePlanner(
            self.summon_featured_catalog,
            self.medium_legacy_policy,
            random_source=NamespacedRandbelowAdapter(
                self.random_outcomes, "summon.medium_legacy"
            ),
        )
        self.summon_private_policy = SummonPrivateServerPolicy(self.data_dir)
        self.classic_vending_balance_policy = ClassicVendingBalancePolicy(self.data_dir)
        self.classic_vending_balance_planner = ClassicVendingBalancePlanner(
            self.classic_vending_balance_policy,
            self.catalog,
            random_source=NamespacedRandbelowAdapter(
                self.random_outcomes, "summon.classic.balance"
            ),
        )
        self.summon_private_planner = ClassicVendingPrivatePlanner(
            self.summon_pool_catalog,
            self.summon_private_policy,
            random_source=NamespacedRandbelowAdapter(
                self.random_outcomes, "summon.classic.pool"
            ),
            balance_planner=self.classic_vending_balance_planner,
        )
        self.summon_result_policy = self.immutable_catalogs.summon_result_policy
        self.summon_result_renderer = SummonResultRenderer()
        # Pass41.7: duplicate conversion is global evidence-backed Vending behavior,
        # not a private RNG knob. Native 1/2/3-star Girls convert to 7/14/30
        # source stone_id fragments; unsupported native stars fail closed.
        self.summon_duplicate_policy = SummonDuplicateConversionPolicy(self.data_dir)
        self.summon_duplicate_conversion = ConfiguredSummonDuplicateConversionResolver(
            self.summon_duplicate_policy
        )
        # Pass41.6 Magic is a separate MID70/MID71 protocol plane. Recovered
        # target/cost/rate facts stay isolated from versioned private policy.
        self.magic_summon_source = self.immutable_catalogs.magic_summon_source
        self.magic_summon_policy = MagicSummonPrivatePolicy(
            self.data_dir, self.magic_summon_source
        )
        self.magic_summon_planner = MagicSummonPrivatePlanner(
            self.magic_summon_source,
            self.summon_pool_catalog,
            self.magic_summon_policy,
            random_source=NamespacedRandbelowAdapter(
                self.random_outcomes, "summon.magic"
            ),
        )
        # Pass42.6 SX/Soul Box remains its own MID50 type4 planner. Five
        # item slots are recovered source; the sixth slot is a mixed Soul-Casket
        # class planner with current partner.is_sx authority and private class rates.
        self.sx_soul_box_source = self.immutable_catalogs.sx_soul_box_source
        self.sx_soul_box_policy = SXSoulBoxPrivatePolicy(
            self.data_dir, self.sx_soul_box_source
        )
        self.sx_soul_box_planner = SXSoulBoxPrivatePlanner(
            self.sx_soul_box_source,
            self.sx_soul_box_policy,
            random_source=NamespacedRandbelowAdapter(
                self.random_outcomes, "summon.sx"
            ),
        )
        self.summon = SummonRepository(
            player,
            self.data_dir,
            save,
            heroes=self.heroes,
            inventory=self.inventory,
            economy=self.economy,
            catalog=self.catalog,
            rewards=self.rewards,
            operation_catalog=self.summon_operation_catalog,
            operation_registry=self.summon_operation_registry,
            state_contract=self.summon_state_contract,
            cost_plans=self.summon_cost_plans,
            counter_policies=self.summon_counter_policies,
            counter_engine=self.summon_counter_engine,
            result_policy=self.summon_result_policy,
            result_renderer=self.summon_result_renderer,
            duplicate_conversion=self.summon_duplicate_conversion,
            private_policy=self.summon_private_policy,
            private_planner=self.summon_private_planner,
            featured_rotation=self.summon_featured_rotation,
            medium_legacy_policy=self.medium_legacy_policy,
            medium_legacy_planner=self.medium_legacy_planner,
            magic_source=self.magic_summon_source,
            magic_policy=self.magic_summon_policy,
            magic_planner=self.magic_summon_planner,
            sx_source=self.sx_soul_box_source,
            sx_policy=self.sx_soul_box_policy,
            sx_planner=self.sx_soul_box_planner,
            vip_privileges=self.vip_privileges,
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
            awakening_missions=self.awakening_missions,
            awakening_campaign_overlay=self.awakening_campaign_overlay,
            awakening_campaign_objectives=self.awakening_campaign_objectives,
            catalog=self.catalog,
            rewards=self.rewards,
            tutorial=self.tutorial,
            drop_planner=self.campaign_drop_planner,
            settlement=self.mutation_settlement,
            uow=self.uow,
            campaign_reset_policy=self.campaign_reset_policy,
            vip_privileges=self.vip_privileges,
            challenge_catalog=self.challenge_campaign_catalog,
            challenge_projection=self.challenge_campaign_projection,
            super_catalog=self.super_campaign_catalog,
            super_access_policy=self.super_campaign_access,
            super_projection=self.super_campaign_projection,
            elite_campaign_unlock=self.elite_campaign_unlock,
            strict_campaign_collaborators=True,
        )
        # Wave C server hydration plane: exact Pass248 Stage3 allow-list built
        # from domain-owned serializers. This owns no cached gameplay state.
        self.hydration_snapshot = HydrationSnapshotAssembler(
            self.synchronization_catalogs,
            {
                17: player.player_info_payload,
                49: self.heroes.payload,
                56: self.summon.payload,
                81: self.inventory.payload,
                112: player.world_map_payload,
                115: player.trial_infos_payload,
                176: player.friends_payload,
                229: player.activities_payload,
                289: player.arena_records_payload,
                336: player.march_payload,
                352: lambda: {"awards": [], "is_signed": 1, "partner_id": 0, "sign_times": 0, "month": 1, "is_skin": 0},
                368: player.mail_payload,
                384: player.invite_payload,
                612: player.guild_payload,
                624: player.world_boss_payload,
                780: player.pets_payload,
                836: player.library_payload,
                2137: player.study_payload,
                2416: player.adventure_payload,
                2485: player.peak_records_payload,
                2560: self.generic_redmarks.snapshot,
                2984: player.battle_pass_payload,
            },
        )

    def apply_semantic_deltas(self, payload, *, profile=None):
        """Compatibility facade over the typed Wave-B semantic assembler."""
        return self.semantic_envelope.apply(payload, profile=profile)
