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

from gxb_backend.content.recharge_catalog import RechargeProduct, RechargeSourceCatalog

from .commerce_service import CommerceEntitlementService
from .economy_ledger import EconomyLedger
from .player_state import PlayerState
from .server_clock import ServerClock
from .unit_of_work import OperationContext, PlayerUnitOfWork, ReceiptConflict
from .vip_policy import VipProgressionPolicy


PURCHASE_RECEIPT_DOMAIN = "commerce_purchase"
COMMERCE_SLICE_ID = "commerce_entitlements"


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
        return cls(intent_id=intent_id, charge_id=charge_id, platform=platform)


@dataclass(frozen=True)
class AuthorizedPurchase:
    intent: PurchaseIntent
    product: RechargeProduct
    provider: str = "AUTO_AUTHORIZE_LOCAL"


class AutoAuthorizePurchaseProvider:
    """Private-server authorization policy for the seven MID354 direct packs."""

    # Effective VipRechargeWindow.lua explicitly hides 80001030 on iOS even
    # though MID354 may advertise the direct product row. Preserve that source
    # client eligibility rule at the authorization boundary as defense in depth.
    IOS_HIDDEN_CHARGE_IDS = frozenset({80001030})

    def __init__(self, catalog: RechargeSourceCatalog) -> None:
        self.catalog = catalog

    def authorize(self, intent: PurchaseIntent) -> AuthorizedPurchase:
        product = self.catalog.get(intent.charge_id)
        if product is None:
            raise UnsupportedPurchaseProduct(
                f"charge_id={intent.charge_id} is not advertised by the direct Crystal catalog"
            )
        if intent.platform == "ios" and int(product.charge_id) in self.IOS_HIDDEN_CHARGE_IDS:
            raise UnsupportedPurchaseProduct(
                f"charge_id={intent.charge_id} is source-hidden on iOS"
            )
        return AuthorizedPurchase(intent=intent, product=product)


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
    """Exactly-once direct Crystal purchase settlement inside PlayerUnitOfWork."""

    def __init__(
        self,
        player: PlayerState,
        source_catalog: RechargeSourceCatalog,
        entitlements: CommerceEntitlementService,
        economy: EconomyLedger,
        vip_policy: VipProgressionPolicy,
        uow: PlayerUnitOfWork,
        *,
        clock: ServerClock | None = None,
        authorizer: AutoAuthorizePurchaseProvider | None = None,
        product_policy: CommerceProductPolicy | None = None,
    ) -> None:
        self.player = player
        self.source_catalog = source_catalog
        self.entitlements = entitlements
        self.economy = economy
        self.vip_policy = vip_policy
        self.uow = uow
        self.clock = clock or ServerClock()
        self.authorizer = authorizer or AutoAuthorizePurchaseProvider(source_catalog)
        self.product_policy = product_policy or CommerceProductPolicy()

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

        now = int(self.clock.now())
        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            operation_name="direct_crystal_purchase",
            domain="COMMERCE",
            protocol_mid=36857,
            idempotency_key=intent.intent_id,
            idempotency_mode="PURCHASE_INTENT_RECEIPT",
            request_fingerprint=fingerprint,
            server_time=now,
        )

        try:
            with self.uow.transaction(context):
                # Read purchase history *inside* the transaction snapshot. The
                # repository serializes player requests, and this also keeps the
                # first-buy decision aligned with the exact state being committed.
                history = self.entitlements.product_history(authorized.product.charge_id)
                plan = self.product_policy.plan(authorized.product, history)

                # Crystal stays EconomyLedger-owned.
                self.economy.credit("crystal", plan.crystal_delta)

                # charge/vip/history stay Commerce-owned within the same UoW.
                self.player.charge = max(0, int(self.player.charge or 0)) + plan.vip_progression_delta
                self.player.vip = self.vip_policy.derive_vip(self.player.charge)
                self.entitlements.record_product_purchase(
                    authorized.product.charge_id,
                    charge_count=plan.charge_count_after,
                    last_buy_time=now,
                )
                self.uow.mark_changed(COMMERCE_SLICE_ID)

                params = self._completion_params(
                    charge_id=authorized.product.charge_id,
                    crystal_delta=plan.crystal_delta,
                )
                event = self._event(params)
                settlement = {
                    "provider": authorized.provider,
                    "charge_id": authorized.product.charge_id,
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
                    operation="direct_crystal_purchase",
                    key=intent.intent_id,
                    mode="PURCHASE_INTENT_RECEIPT",
                    request_fingerprint=fingerprint,
                    replay_payload=replay_payload,
                    retention_policy="PERMANENT_NO_EVICTION",
                )
        except ReceiptConflict as exc:
            # Under StateRepository's serialized request scope this should only
            # happen after external/manual state interference, but fail safely.
            raise PurchaseReceiptConflict(str(exc)) from exc

        return CommerceSettlementResult(
            intent_id=intent.intent_id,
            status="COMMITTED",
            replayed=False,
            recharge_event=event,
            settlement=settlement,
        )
