"""Memoized request-scoped composition root for canonical player services."""
from __future__ import annotations

from pathlib import Path
from typing import Callable

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.item_sale_catalog import ItemSaleCatalog
from gxb_backend.content.consumable_effect_catalog import ConsumableEffectCatalog
from gxb_backend.content.campaign_drop_source_catalog import CampaignDropSourceCatalog
from gxb_backend.content.magic_summon_source_catalog import MagicSummonSourceCatalog
from gxb_backend.content.skin_source_catalog import SkinSourceCatalog
from gxb_backend.content.gift_opening_source_catalog import GiftOpeningSourceCatalog
from gxb_backend.content.summon_operation_catalog import SummonOperationCatalog
from gxb_backend.content.summon_pool_catalog import SummonPoolCatalog
from gxb_backend.content.sx_soul_box_source_catalog import SXSoulBoxSourceCatalog
from gxb_backend.content.recharge_catalog import RechargeSourceCatalog
from gxb_backend.content.vip_award_catalog import VipAwardSourceCatalog
from gxb_backend.content.campaign_reset_catalog import CampaignResetSourceCatalog
from gxb_backend.content.energy_purchase_catalog import EnergyPurchaseSourceCatalog
from gxb_backend.content.summon_featured_catalog import SummonFeaturedCatalog

from .awakening_mission_service import AwakeningMissionService
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
from .gift_opening_service import (
    GiftOpeningPlanner,
    GiftOpeningService,
    GiftRandomOutcomeAdapter,
)
from .global_response_semantics import GlobalResponseSemantics
from .hero_entity_mutation_service import HeroEntityMutationService
from .hero_advanced_progression_repository import HeroAdvancedProgressionRepository
from .hero_equipment_repository import HeroEquipmentRepository
from .hero_progression_repository import HeroProgressionRepository
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .inventory_sale_service import InventorySaleService
from .mission_repository import MissionRepository
from .mutation_settlement_service import MutationSettlementService
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
    ) -> None:
        self.player = player
        self.data_dir = Path(data_dir)
        self.catalog = catalog
        self.consumable_effects = ConsumableEffectCatalog(self.data_dir)
        self.uow = UnitOfWork(player, commit_callback)
        # Pass110 RNG foundation remains request-scoped mechanics only. Pass111
        # injects namespaced adapters into MID50 planners below; Campaign remains
        # deliberately unmigrated until its separate bounded pass.
        self.random_outcomes = RandomOutcomeService(entropy_provider)
        self.resource_registry = ResourceRegistry.load(self.data_dir / "resource_registry.json")
        self.response_semantics = GlobalResponseSemantics(player, self.uow)
        save = self.uow.request_save
        self.server_clock = server_clock or ServerClock()
        # Pass87 Commerce/VIP policy is request-scoped and source-generated.
        # charge/vip remain Commerce-owned; Crystal remains EconomyLedger-owned.
        self.vip_progression = VipProgressionPolicy(self.data_dir)
        self.vip_privileges = VipPrivilegeResolver(player, self.vip_progression)
        self.recharge_source_catalog = RechargeSourceCatalog(self.data_dir)
        self.commerce = CommerceEntitlementService(
            player, self.vip_progression, save, uow=self.uow
        )
        self.recharge_catalog = RechargeCatalogService(
            player, self.recharge_source_catalog, self.commerce, clock=self.server_clock
        )
        # Pass92 source-bounded Super Campaign reset policy. VIP remains the
        # canonical base privilege owner; active Monthly Privilege contributes
        # only its source num_elite addend. Campaign owns the actual mutation.
        self.campaign_reset_source = CampaignResetSourceCatalog(self.data_dir)
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
        self.energy_purchase_source = EnergyPurchaseSourceCatalog(self.data_dir)
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
        self.mutation_settlement = MutationSettlementService(
            catalog=self.catalog,
            ledger=self.economy_ledger,
            stacks=self.stack_inventory,
            uow=self.uow,
            temporal=self.temporal,
        )
        self.heroes = HeroRepository(
            player, save, self.data_dir, economy=self.economy, catalog=self.catalog, uow=self.uow,
            temporal=self.temporal, settlement=self.mutation_settlement,
            vip_privileges=self.vip_privileges,
        )
        # Pass151 runtime reconciliation: permanent Girl skin ownership plus the
        # source-distinct MID2979 cosmetic appearance selector. MID60/MID61/MID2979
        # share the existing Hero/Stack/UoW owners; Pet MID60 overload and temporary
        # skin lifecycle remain deliberately outside this service.
        self.skin_source = SkinSourceCatalog(self.data_dir)
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
        )
        self.hero_advanced = HeroAdvancedProgressionRepository(
            player, self.data_dir, save, inventory=self.inventory, heroes=self.heroes,
            uow=self.uow, settlement=self.mutation_settlement,
        )
        self.item_sale_catalog = ItemSaleCatalog.load(self.data_dir / "item_sale_catalog.json")
        self.inventory_sales = InventorySaleService(
            player, self.item_sale_catalog, self.mutation_settlement, self.uow
        )
        self.rewards = RewardTransactionService(
            self.catalog, self.player_progression, self.inventory, self.heroes, self.uow,
            resource_registry=self.resource_registry, settlement=self.mutation_settlement,
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
        self.gift_opening_source = GiftOpeningSourceCatalog(self.data_dir)
        self.gift_random_outcomes = GiftRandomOutcomeAdapter(
            self.random_outcomes, "gift.open"
        )
        self.gift_opening_planner = GiftOpeningPlanner(
            self.gift_opening_source, self.gift_random_outcomes
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
        self.vip_award_source = VipAwardSourceCatalog(self.data_dir)
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
        self.awakening_missions = AwakeningMissionService(
            player, self.data_dir, save, heroes=self.heroes, inventory=self.inventory,
            uow=self.uow, settlement=self.mutation_settlement,
        )
        # Pass113/114 Campaign RNG plane. Effective-source facts and domain
        # policy remain separate from entropy mechanics. Ordinary MID117 alone
        # calls plan_repeat_sweep(); MID113 retains its legacy disabled policy.
        self.campaign_drop_source = CampaignDropSourceCatalog(self.data_dir)
        self.campaign_drop_policy = CampaignDropPolicyRegistry(self.data_dir)
        self.campaign_repeat_policy = CampaignRepeatPolicyRegistry(self.data_dir)
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
        self.summon_operation_catalog = SummonOperationCatalog(self.data_dir)
        self.summon_operation_registry = SummonOperationRegistry(self.summon_operation_catalog)
        self.summon_state_contract = SummonStateContract(self.data_dir)
        self.summon_cost_plans = SummonCostPlanRegistry(self.data_dir)
        self.summon_counter_policies = SummonCounterPolicyRegistry(self.data_dir)
        self.summon_counter_engine = PrivateServerSummonCounterEngine()
        self.summon_pool_catalog = SummonPoolCatalog(self.data_dir)
        self.summon_featured_catalog = SummonFeaturedCatalog(self.data_dir)
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
        self.summon_result_policy = SummonResultPolicyRegistry(self.data_dir)
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
        self.magic_summon_source = MagicSummonSourceCatalog(self.data_dir)
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
        self.sx_soul_box_source = SXSoulBoxSourceCatalog(self.data_dir)
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
