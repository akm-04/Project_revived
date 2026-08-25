"""Pass88 direct-Crystal PurchaseIntent authorization and exactly-once settlement.

This module deliberately starts *after* the unrecovered native store boundary.
Effective src_64 calls xyd.androidPurchase/xyd.sdkPurchase from VipRechargeWindow,
then later consumes MID36857 RECHARGE as a server completion event.  The private
server therefore accepts an authenticated preservation PurchaseIntent and emits
one source-shaped committed completion; it never models MID36857 as a request.
"""
from __future__ import annotations

import copy
import hashlib
import json
from dataclasses import dataclass
from typing import Any, Mapping

from gxb_backend.content import CatalogNamespace, ContentRef
from gxb_backend.content.recharge_catalog import RechargeEolProduct, RechargeGiftbagProduct, RechargeProduct, RechargeSourceCatalog

from .commerce_service import (
    COMMERCE_SLICE_ID,
    CommerceEntitlementService,
    RechargeEolAvailabilityPolicy,
    RechargeGiftbagAvailabilityPolicy,
    eol_resource_enabled,
)
from .economy_ledger import EconomyLedger
from .reward_transaction_service import (
    EconomyGrant,
    InventoryGrant,
    RewardOrigin,
    RewardPlan,
    RewardResult,
    RewardTransactionService,
)
from .player_state import PlayerState
from .random_outcome_service import RandomOutcomeService
from .server_clock import ServerClock
from .skin_ownership_service import SkinOwnershipError, SkinOwnershipService
from .unit_of_work import OperationContext, PlayerUnitOfWork, ReceiptConflict
from .vip_policy import VipProgressionPolicy


PURCHASE_RECEIPT_DOMAIN = "commerce_purchase"
RECHARGE_GIFTBAG_RNG_NAMESPACE = "recharge.giftbag"




class RechargeGiftbagRandomOutcomeAdapter:
    """Thin Recharge-domain binding to request-scoped ROS mechanics."""

    def __init__(
        self,
        service: RandomOutcomeService,
        namespace: str = RECHARGE_GIFTBAG_RNG_NAMESPACE,
    ) -> None:
        if not isinstance(service, RandomOutcomeService):
            raise TypeError("service must be a RandomOutcomeService")
        if str(namespace) != RECHARGE_GIFTBAG_RNG_NAMESPACE:
            raise ValueError(f"unsupported Recharge giftbag RNG namespace: {namespace!r}")
        self._service = service
        self.namespace = RECHARGE_GIFTBAG_RNG_NAMESPACE

    def weighted_index(self, weights: tuple[int, ...]) -> int:
        return self._service.weighted_index(self.namespace, weights)


class CommercePurchaseError(ValueError):
    code = "COMMERCE_PURCHASE_ERROR"


class InvalidPurchaseIntent(CommercePurchaseError):
    code = "INVALID_PURCHASE_INTENT"


class UnsupportedPurchaseProduct(CommercePurchaseError):
    code = "UNSUPPORTED_PURCHASE_PRODUCT"


class PurchaseLimitReached(CommercePurchaseError):
    code = "PURCHASE_LIMIT_REACHED"


class PurchaseReceiptConflict(CommercePurchaseError):
    code = "PURCHASE_RECEIPT_CONFLICT"


@dataclass(frozen=True)
class PurchaseIntent:
    intent_id: str
    charge_id: int
    platform: str
    resource_version: str = ""

    @classmethod
    def from_mapping(cls, raw: Mapping[str, Any]) -> "PurchaseIntent":
        intent_id = str(raw.get("intent_id") or "").strip()
        if not intent_id or len(intent_id) > 128:
            raise InvalidPurchaseIntent("intent_id is required and must be <=128 characters")
        if any(ch not in "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789._:-" for ch in intent_id):
            raise InvalidPurchaseIntent("intent_id contains unsupported characters")
        try:
            charge_id = int(raw.get("charge_id") or 0)
        except (TypeError, ValueError) as exc:
            raise InvalidPurchaseIntent("charge_id must be an integer") from exc
        if charge_id <= 0:
            raise InvalidPurchaseIntent("charge_id must be positive")
        platform = str(raw.get("platform") or "preservation_manual").strip().lower()
        if platform not in {"android", "ios", "preservation_manual", "lua_preservation"}:
            raise InvalidPurchaseIntent(f"unsupported platform {platform!r}")
        resource_version = str(raw.get("resource_version") or "").strip()
        if len(resource_version) > 32:
            raise InvalidPurchaseIntent("resource_version must be <=32 characters")
        return cls(
            intent_id=intent_id, charge_id=charge_id, platform=platform,
            resource_version=resource_version,
        )


@dataclass(frozen=True)
class AuthorizedPurchase:
    intent: PurchaseIntent
    product: RechargeProduct | RechargeGiftbagProduct | RechargeEolProduct
    provider: str = "AUTO_AUTHORIZE_LOCAL"


class AutoAuthorizePurchaseProvider:
    """Private-server authorization policy for the seven MID354 direct packs."""

    # Effective VipRechargeWindow.lua explicitly hides 80001030 on iOS even
    # though MID354 may advertise the direct product row. Preserve that source
    # client eligibility rule at the authorization boundary as defense in depth.
    IOS_HIDDEN_CHARGE_IDS = frozenset({80001030})

    def __init__(
        self,
        catalog: RechargeSourceCatalog,
        giftbag_availability: RechargeGiftbagAvailabilityPolicy | None = None,
        eol_availability: RechargeEolAvailabilityPolicy | None = None,
    ) -> None:
        self.catalog = catalog
        self.giftbag_availability = giftbag_availability
        self.eol_availability = eol_availability

    def authorize(self, intent: PurchaseIntent) -> AuthorizedPurchase:
        direct = self.catalog.get(intent.charge_id)
        if direct is not None:
            if intent.platform == "ios" and int(direct.charge_id) in self.IOS_HIDDEN_CHARGE_IDS:
                raise UnsupportedPurchaseProduct(
                    f"charge_id={intent.charge_id} is source-hidden on iOS"
                )
            return AuthorizedPurchase(intent=intent, product=direct)

        giftbag = self.catalog.get_giftbag(intent.charge_id)
        if giftbag is not None and giftbag.source_native_supported:
            if self.giftbag_availability is None or not self.giftbag_availability.available(giftbag):
                raise PurchaseLimitReached(
                    f"charge_id={intent.charge_id} is not currently advertised/available"
                )
            return AuthorizedPurchase(intent=intent, product=giftbag)

        eol = self.catalog.get_eol_product(intent.charge_id)
        if eol is not None:
            if self.eol_availability is None or not eol_resource_enabled(intent.resource_version):
                raise UnsupportedPurchaseProduct(
                    f"charge_id={intent.charge_id} requires synthetic EOL OTA 1.631.9+"
                )
            if not self.eol_availability.available(eol, intent.resource_version):
                raise PurchaseLimitReached(
                    f"charge_id={intent.charge_id} is not currently advertised/available"
                )
            return AuthorizedPurchase(intent=intent, product=eol)

        raise UnsupportedPurchaseProduct(
            f"charge_id={intent.charge_id} is not currently supported by Recharge settlement"
        )


@dataclass(frozen=True)
class CommerceProductPlan:
    charge_id: int
    first_purchase: bool
    crystal_delta: int
    vip_progression_delta: int
    charge_count_before: int
    charge_count_after: int


class CommerceProductPolicy:
    """Source-bounded direct-pack settlement policy.

    Crystal grant uses charge.lua base diamond + first/repeat bonus.  VIP
    progression is deliberately read from the generated policy field and is not
    inferred from the *total* Crystal grant because charge_list.lua proves those
    concepts are independent in the wider commerce plane.
    """

    def plan(self, product: RechargeProduct, history: Mapping[str, Any]) -> CommerceProductPlan:
        try:
            count = max(0, int(history.get("charge_count") or 0))
        except (TypeError, ValueError):
            count = 0
        if product.buy_limit >= 0 and count >= product.buy_limit:
            raise PurchaseLimitReached(f"charge_id={product.charge_id} buy_limit reached")
        first = count == 0
        extra = product.first_extra_crystal if first else product.repeat_extra_crystal
        crystal_delta = int(product.base_crystal) + int(extra)
        if crystal_delta <= 0:
            raise CommercePurchaseError(f"charge_id={product.charge_id} resolved zero Crystal")
        return CommerceProductPlan(
            charge_id=int(product.charge_id),
            first_purchase=first,
            crystal_delta=crystal_delta,
            vip_progression_delta=max(0, int(product.vip_progression_delta)),
            charge_count_before=count,
            charge_count_after=count + 1,
        )


@dataclass(frozen=True)
class RechargeGiftbagPlan:
    charge_id: int
    gift_id: int
    charge_count_before: int
    charge_count_after: int
    rewards: RewardPlan
    vip_progression_delta: int
    product_kind: str
    random_selections: tuple[dict[str, int], ...] = ()


class RechargeGiftbagPolicy:
    """Translate source-complete Recharge Packs into canonical reward owners.

    Fixed B2 products consume no entropy.  The single B3 source-native random
    product keeps pool/order/relative-weight policy in Commerce and delegates
    only the bounded weighted draw to request-scoped ROS.
    """

    SCALAR_FIELDS = {
        "crystal": "crystal",
        "mana": "mana",
        "energy": "energy",
        "skin_coin": "skin_coin",
    }

    def __init__(self, random_outcomes: RechargeGiftbagRandomOutcomeAdapter | None = None) -> None:
        self.random_outcomes = random_outcomes

    @staticmethod
    def _history_count(product: RechargeGiftbagProduct, history: Mapping[str, Any]) -> int:
        try:
            count = max(0, int(history.get("charge_count") or 0))
        except (TypeError, ValueError):
            count = 0
        if product.one_shot and count > 0:
            raise PurchaseLimitReached(f"charge_id={product.charge_id} is one-shot and already purchased")
        return count

    def _reward_plan(
        self,
        product: RechargeGiftbagProduct,
        *,
        extra_inventory: tuple[InventoryGrant, ...] = (),
        field_path: str = "gift.items|gift.scalars",
    ) -> RewardPlan:
        economy = []
        for source_field, target_field in self.SCALAR_FIELDS.items():
            amount = product.scalar(source_field)
            if amount > 0:
                economy.append(EconomyGrant(target_field, amount))
        inventory = [
            InventoryGrant(ContentRef(CatalogNamespace.ITEM, int(item.item_id)), int(item.item_num))
            for item in product.items
        ]
        inventory.extend(extra_inventory)
        return RewardPlan(
            origin=RewardOrigin(
                domain="commerce",
                operation="recharge_giftbag_purchase",
                protocol_mid=36857,
                source_table="giftbag.lua|gift.lua|dropbox.lua",
                source_id=int(product.gift_id),
                field_path=field_path,
            ),
            economy=tuple(economy),
            inventory=tuple(inventory),
        )

    def _validate_random_source(self, product: RechargeGiftbagProduct) -> None:
        if not product.random_b3_supported:
            raise UnsupportedPurchaseProduct(f"charge_id={product.charge_id} is not a B3 random Pack")
        # Pass150 activates exactly the one recovered source-native random Pack.
        # Any future random Recharge shape must be researched before activation.
        if int(product.charge_id) != 90002112 or int(product.gift_id) != 90011123:
            raise UnsupportedPurchaseProduct("unexpected Recharge random Pack source drift")
        if tuple(product.drops) != (600002,) or len(product.drop_occurrences) != 1:
            raise UnsupportedPurchaseProduct("unexpected Recharge random drop occurrence topology")
        occurrence = product.drop_occurrences[0]
        if int(occurrence.dropbox_id) != 600002 or len(occurrence.candidates) != 5:
            raise UnsupportedPurchaseProduct("unexpected Recharge random dropbox 600002 shape")
        positive = False
        for candidate in occurrence.candidates:
            if candidate.item_id <= 0 or candidate.item_num <= 0:
                raise UnsupportedPurchaseProduct("invalid Recharge random candidate item payload")
            if candidate.item_type in {-1, 24}:
                raise UnsupportedPurchaseProduct("Recharge random candidate requires deferred materialization")
            if candidate.drop_rate < 0 or candidate.roll_type != 1:
                raise UnsupportedPurchaseProduct("unsupported Recharge random candidate policy")
            positive = positive or candidate.drop_rate > 0
        if not positive:
            raise UnsupportedPurchaseProduct("Recharge random dropbox has no positive relative weight")

    def preflight_rewards(
        self, product: RechargeGiftbagProduct, history: Mapping[str, Any]
    ) -> tuple[RewardPlan, ...]:
        """Return every possible canonical reward plan without consuming entropy."""
        self._history_count(product, history)
        if product.fixed_b2_supported:
            if product.drops or product.drop_occurrences:
                raise UnsupportedPurchaseProduct(f"charge_id={product.charge_id} malformed fixed Pack")
            plan = self._reward_plan(product)
            if not plan.economy and not plan.inventory and product.scalar("vip_exp") <= 0:
                raise CommercePurchaseError(f"charge_id={product.charge_id} resolves to no supported reward")
            return (plan,)
        self._validate_random_source(product)
        occurrence = product.drop_occurrences[0]
        plans = []
        for candidate in occurrence.candidates:
            plans.append(self._reward_plan(
                product,
                extra_inventory=(InventoryGrant(
                    ContentRef(CatalogNamespace.ITEM, int(candidate.item_id)), int(candidate.item_num)
                ),),
                field_path=f"gift.items|gift.scalars|gift.drops[{occurrence.occurrence_index}]",
            ))
        return tuple(plans)

    def plan(self, product: RechargeGiftbagProduct, history: Mapping[str, Any]) -> RechargeGiftbagPlan:
        count = self._history_count(product, history)
        if product.fixed_b2_supported:
            rewards = self.preflight_rewards(product, history)[0]
            return RechargeGiftbagPlan(
                charge_id=int(product.charge_id),
                gift_id=int(product.gift_id),
                charge_count_before=count,
                charge_count_after=count + 1,
                rewards=rewards,
                vip_progression_delta=max(0, int(product.scalar("vip_exp"))),
                product_kind="SOURCE_NATIVE_FIXED_GIFTBAG",
            )
        self._validate_random_source(product)
        if self.random_outcomes is None:
            raise CommercePurchaseError("Recharge random Pack is not composed with request entropy")
        occurrence = product.drop_occurrences[0]
        weights = tuple(int(candidate.drop_rate) for candidate in occurrence.candidates)
        selected_index = self.random_outcomes.weighted_index(weights)
        selected = occurrence.candidates[selected_index]
        rewards = self._reward_plan(
            product,
            extra_inventory=(InventoryGrant(
                ContentRef(CatalogNamespace.ITEM, int(selected.item_id)), int(selected.item_num)
            ),),
            field_path=f"gift.items|gift.scalars|gift.drops[{occurrence.occurrence_index}]",
        )
        return RechargeGiftbagPlan(
            charge_id=int(product.charge_id),
            gift_id=int(product.gift_id),
            charge_count_before=count,
            charge_count_after=count + 1,
            rewards=rewards,
            vip_progression_delta=max(0, int(product.scalar("vip_exp"))),
            product_kind="SOURCE_NATIVE_RANDOM_GIFTBAG",
            random_selections=({
                "dropbox_id": int(occurrence.dropbox_id),
                "row_id": int(selected.row_id),
                "item_id": int(selected.item_id),
                "item_num": int(selected.item_num),
                "drop_rate": int(selected.drop_rate),
                "roll_type": int(selected.roll_type),
            },),
        )


@dataclass(frozen=True)
class CommerceSettlementResult:
    intent_id: str
    status: str
    replayed: bool
    recharge_event: dict[str, Any]
    settlement: dict[str, Any]

    def to_bridge_payload(self) -> dict[str, Any]:
        return {
            "ok": 1,
            "intent_id": self.intent_id,
            "status": self.status,
            "replayed": 1 if self.replayed else 0,
            "recharge_event": copy.deepcopy(self.recharge_event),
            "settlement": copy.deepcopy(self.settlement),
            "delivery": {
                "mode": "BRIDGE_RESPONSE_POST_COMMIT",
                "mid": 36857,
                "client_injection_required": 1,
            },
        }


class CommerceSettlementService:
    """Exactly-once direct-Crystal and fixed Recharge Pack settlement in one UoW."""

    def __init__(
        self,
        player: PlayerState,
        source_catalog: RechargeSourceCatalog,
        entitlements: CommerceEntitlementService,
        economy: EconomyLedger,
        vip_policy: VipProgressionPolicy,
        uow: PlayerUnitOfWork,
        rewards: RewardTransactionService | None = None,
        *,
        clock: ServerClock | None = None,
        authorizer: AutoAuthorizePurchaseProvider | None = None,
        product_policy: CommerceProductPolicy | None = None,
        giftbag_policy: RechargeGiftbagPolicy | None = None,
        giftbag_availability: RechargeGiftbagAvailabilityPolicy | None = None,
        eol_availability: RechargeEolAvailabilityPolicy | None = None,
        skin_ownership: SkinOwnershipService | None = None,
    ) -> None:
        self.player = player
        self.source_catalog = source_catalog
        self.entitlements = entitlements
        self.economy = economy
        self.vip_policy = vip_policy
        self.uow = uow
        self.rewards = rewards
        self.clock = clock or ServerClock()
        self.giftbag_availability = giftbag_availability or RechargeGiftbagAvailabilityPolicy(entitlements)
        self.eol_availability = eol_availability
        self.skin_ownership = skin_ownership
        self.authorizer = authorizer or AutoAuthorizePurchaseProvider(
            source_catalog, self.giftbag_availability, self.eol_availability
        )
        self.product_policy = product_policy or CommerceProductPolicy()
        self.giftbag_policy = giftbag_policy or RechargeGiftbagPolicy()

    @staticmethod
    def _fingerprint(*, player_id: str, region: int, intent: PurchaseIntent) -> str:
        canonical = {
            "player_id": str(player_id),
            "region": int(region),
            "charge_id": int(intent.charge_id),
            "platform": str(intent.platform),
        }
        blob = json.dumps(canonical, sort_keys=True, separators=(",", ":")).encode("utf-8")
        return hashlib.sha256(blob).hexdigest()

    def _completion_params(self, *, charge_id: int, crystal_delta: int) -> dict[str, Any]:
        # Effective SelfPlayer:onRecharge_ consumes these exact cumulative fields.
        return {
            "delta": int(crystal_delta),
            "total": max(0, int(self.player.crystal or 0)),
            "vip": max(0, int(self.player.vip or 0)),
            "charge": max(0, int(self.player.charge or 0)),
            "charge_id": int(charge_id),
            "left_card_day": max(0, int(self.player.left_card_day or 0)),
            "left_week_card_day": max(0, int(self.player.left_week_card_day or 0)),
            "left_month_tili_day": max(0, int(self.player.left_month_tili_day or 0)),
            "privilege_left_card_day": max(0, int(self.player.privilege_left_card_day or 0)),
            "privilege_month_card_end": max(0, int(self.player.privilege_month_card_end or 0)),
        }

    def _giftbag_completion_params(
        self, *, charge_id: int, result: RewardResult, crystal_delta: int
    ) -> dict[str, Any]:
        params = self._completion_params(charge_id=charge_id, crystal_delta=crystal_delta)
        params["items"] = [
            {"table_id": int(row["item_id"]), "item_num": int(row["item_num"])}
            for row in result.inventory_awards
        ]
        params["economy"] = dict(result.economy)
        return params

    @staticmethod
    def _event(params: Mapping[str, Any]) -> dict[str, Any]:
        # Lua preservation bridge dispatches this object as Event.params.  That
        # gives SelfPlayer:onRecharge_ the source-observed event.params.params.
        return {"mid": 36857, "params": dict(params)}

    def _existing_result(self, intent: PurchaseIntent, fingerprint: str) -> CommerceSettlementResult | None:
        receipt = self.uow.get_receipt(PURCHASE_RECEIPT_DOMAIN, intent.intent_id)
        if receipt is None:
            return None
        old_fp = str(receipt.get("request_fingerprint") or "")
        if old_fp and old_fp != fingerprint:
            raise PurchaseReceiptConflict(
                f"intent_id={intent.intent_id!r} reused with a different purchase fingerprint"
            )
        replay = receipt.get("replay_payload")
        if not isinstance(replay, dict):
            raise PurchaseReceiptConflict(f"intent_id={intent.intent_id!r} has no replay payload")
        event = replay.get("recharge_event")
        settlement = replay.get("settlement")
        if not isinstance(event, dict) or not isinstance(settlement, dict):
            raise PurchaseReceiptConflict(f"intent_id={intent.intent_id!r} replay payload is malformed")
        return CommerceSettlementResult(
            intent_id=intent.intent_id,
            status="REPLAYED",
            replayed=True,
            recharge_event=copy.deepcopy(event),
            settlement=copy.deepcopy(settlement),
        )

    def settle(self, raw_intent: Mapping[str, Any]) -> CommerceSettlementResult:
        intent = PurchaseIntent.from_mapping(raw_intent)
        fingerprint = self._fingerprint(
            player_id=str(self.player.player_id), region=int(self.player.region), intent=intent
        )
        # Permanent receipt replay outranks current catalog policy. A product may
        # be hidden in a later build, but a previously committed intent must
        # remain replayable after a lost response without re-authorizing it.
        existing = self._existing_result(intent, fingerprint)
        if existing is not None:
            return existing
        authorized = self.authorizer.authorize(intent)

        if isinstance(authorized.product, RechargeGiftbagProduct):
            if self.rewards is None:
                raise CommercePurchaseError("Recharge giftbag settlement requires RewardTransactionService")
            history = self.entitlements.product_history(authorized.product.charge_id)
            for preflight_rewards in self.giftbag_policy.preflight_rewards(authorized.product, history):
                self.rewards.validate(preflight_rewards)
        elif isinstance(authorized.product, RechargeEolProduct):
            if self.rewards is None or self.eol_availability is None:
                raise CommercePurchaseError("synthetic EOL settlement requires canonical reward/availability owners")
            if authorized.product.product_kind == "SYNTHETIC_EOL_SKIN" and self.skin_ownership is None:
                raise CommercePurchaseError("synthetic skin settlement requires SkinOwnershipService")
            # Elemental and no-Girl skin branches grant one canonical stack item.
            # Validation is safe to run for all EOL products even when the owned-Girl
            # skin branch later materializes ownership directly instead.
            preflight = RewardPlan(
                origin=RewardOrigin(
                    domain="commerce", operation="synthetic_eol_recharge_purchase",
                    protocol_mid=36857, source_table="recharge_eol_product_meta.json",
                    source_id=int(authorized.product.gift_id), field_path="source_item_id",
                ),
                inventory=(InventoryGrant(
                    ContentRef(CatalogNamespace.ITEM, int(authorized.product.source_item_id)), 1
                ),),
            )
            self.rewards.validate(preflight)

        now = int(self.clock.now())
        is_giftbag = isinstance(authorized.product, RechargeGiftbagProduct)
        is_eol = isinstance(authorized.product, RechargeEolProduct)
        operation_name = (
            "recharge_giftbag_purchase" if is_giftbag else
            "synthetic_eol_recharge_purchase" if is_eol else
            "direct_crystal_purchase"
        )
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            operation_name=operation_name,
            domain="COMMERCE",
            protocol_mid=36857,
            idempotency_key=intent.intent_id,
            idempotency_mode="PURCHASE_INTENT_RECEIPT",
            request_fingerprint=fingerprint,
            server_time=now,
        )

        try:
            with self.uow.transaction(context):
                history = self.entitlements.product_history(authorized.product.charge_id)
                if is_giftbag:
                    product = authorized.product
                    if not self.giftbag_availability.available(product):
                        raise PurchaseLimitReached(
                            f"charge_id={product.charge_id} is no longer available"
                        )
                    plan = self.giftbag_policy.plan(product, history)
                    reward_result = self.rewards.apply(plan.rewards)
                    if plan.vip_progression_delta > 0:
                        self.entitlements.grant_vip_progression(plan.vip_progression_delta)
                    self.entitlements.record_product_purchase(
                        product.charge_id,
                        charge_count=plan.charge_count_after,
                        last_buy_time=now,
                    )
                    self.uow.mark_changed(COMMERCE_SLICE_ID)
                    params = self._giftbag_completion_params(
                        charge_id=product.charge_id,
                        result=reward_result,
                        crystal_delta=product.scalar("crystal"),
                    )
                    event = self._event(params)
                    settlement = {
                        "provider": authorized.provider,
                        "product_kind": plan.product_kind,
                        "charge_id": product.charge_id,
                        "gift_id": product.gift_id,
                        "vip_progression_delta": plan.vip_progression_delta,
                        "charge_count": plan.charge_count_after,
                        "last_buy_time": now,
                        "awards": copy.deepcopy(params["items"]),
                        "economy": copy.deepcopy(params["economy"]),
                        "random_selections": copy.deepcopy(list(plan.random_selections)),
                        "state": {
                            "crystal": int(self.player.crystal),
                            "charge": int(self.player.charge),
                            "vip": int(self.player.vip),
                        },
                    }
                elif is_eol:
                    product = authorized.product
                    if self.eol_availability is None or not self.eol_availability.available(
                        product, intent.resource_version
                    ):
                        raise PurchaseLimitReached(
                            f"charge_id={product.charge_id} is no longer available"
                        )
                    before_count = max(0, int(history.get("charge_count") or 0))
                    reward_result = None
                    direct_skin = None
                    if product.product_kind == "SYNTHETIC_EOL_SKIN":
                        try:
                            direct_skin = self.skin_ownership.grant_permanent_skin_item(
                                product.source_item_id
                            )
                        except SkinOwnershipError as exc:
                            raise PurchaseLimitReached(str(exc)) from exc
                    if direct_skin is None:
                        reward_plan = RewardPlan(
                            origin=RewardOrigin(
                                domain="commerce", operation="synthetic_eol_recharge_purchase",
                                protocol_mid=36857, source_table="recharge_eol_product_meta.json",
                                source_id=int(product.gift_id), field_path="source_item_id",
                            ),
                            inventory=(InventoryGrant(
                                ContentRef(CatalogNamespace.ITEM, int(product.source_item_id)), 1
                            ),),
                        )
                        reward_result = self.rewards.apply(reward_plan)
                        awards = [
                            {"table_id": int(row["item_id"]), "item_num": int(row["item_num"])}
                            for row in reward_result.inventory_awards
                        ]
                    else:
                        # Source SelfPlayer:onRecharge_ first handleRewards(items), then
                        # applies skin_ids and removes one item locally. The server does
                        # not persist that transient client-facing item in this branch.
                        awards = [{"table_id": int(product.source_item_id), "item_num": 1}]

                    count_after = before_count + 1
                    self.entitlements.record_product_purchase(
                        product.charge_id, charge_count=count_after, last_buy_time=now
                    )
                    self.uow.mark_changed(COMMERCE_SLICE_ID)
                    params = self._completion_params(
                        charge_id=product.charge_id, crystal_delta=0
                    )
                    params["items"] = awards
                    params["economy"] = {} if reward_result is None else dict(reward_result.economy)
                    if direct_skin is not None:
                        params["skin_ids"] = copy.deepcopy(direct_skin["skin_ids"])
                        params["remove_item"] = 1
                    event = self._event(params)
                    settlement = {
                        "provider": authorized.provider,
                        "product_kind": product.product_kind,
                        "charge_id": int(product.charge_id),
                        "gift_id": int(product.gift_id),
                        "source_item_id": int(product.source_item_id),
                        "vip_progression_delta": 0,
                        "crystal_delta": 0,
                        "charge_count": count_after,
                        "last_buy_time": now,
                        "awards": copy.deepcopy(awards),
                        "direct_skin_ownership": 1 if direct_skin is not None else 0,
                        "state": {
                            "crystal": int(self.player.crystal),
                            "charge": int(self.player.charge),
                            "vip": int(self.player.vip),
                        },
                    }
                else:
                    product = authorized.product
                    plan = self.product_policy.plan(product, history)
                    self.economy.credit("crystal", plan.crystal_delta)
                    if plan.vip_progression_delta > 0:
                        self.entitlements.grant_vip_progression(plan.vip_progression_delta)
                    self.entitlements.record_product_purchase(
                        product.charge_id,
                        charge_count=plan.charge_count_after,
                        last_buy_time=now,
                    )
                    self.uow.mark_changed(COMMERCE_SLICE_ID)
                    params = self._completion_params(
                        charge_id=product.charge_id,
                        crystal_delta=plan.crystal_delta,
                    )
                    event = self._event(params)
                    settlement = {
                        "provider": authorized.provider,
                        "product_kind": "DIRECT_CRYSTAL",
                        "charge_id": product.charge_id,
                        "first_purchase": 1 if plan.first_purchase else 0,
                        "crystal_delta": plan.crystal_delta,
                        "vip_progression_delta": plan.vip_progression_delta,
                        "charge_count": plan.charge_count_after,
                        "last_buy_time": now,
                        "state": {
                            "crystal": int(self.player.crystal),
                            "charge": int(self.player.charge),
                            "vip": int(self.player.vip),
                        },
                    }

                replay_payload = {
                    "recharge_event": copy.deepcopy(event),
                    "settlement": copy.deepcopy(settlement),
                }
                self.entitlements.stage_completion_outbox(
                    intent.intent_id,
                    event=event,
                    fingerprint=fingerprint,
                    committed_at=now,
                )
                self.uow.stage_receipt(
                    domain=PURCHASE_RECEIPT_DOMAIN,
                    operation=operation_name,
                    key=intent.intent_id,
                    mode="PURCHASE_INTENT_RECEIPT",
                    request_fingerprint=fingerprint,
                    replay_payload=replay_payload,
                    retention_policy="PERMANENT_NO_EVICTION",
                )
        except ReceiptConflict as exc:
            raise PurchaseReceiptConflict(str(exc)) from exc

        return CommerceSettlementResult(
            intent_id=intent.intent_id,
            status="COMMITTED",
            replayed=False,
            recharge_event=event,
            settlement=settlement,
        )
