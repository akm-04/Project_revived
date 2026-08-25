"""Commerce/VIP state owner, product history, completion outbox, and MID354 projection."""
from __future__ import annotations

import copy
from pathlib import Path
from typing import Any, Callable, TYPE_CHECKING

from gxb_backend.content.recharge_catalog import RechargeEolProduct, RechargeGiftbagProduct, RechargeSourceCatalog

from .player_state import PlayerState
from .server_clock import ServerClock
from .unit_of_work import PlayerUnitOfWork
from .vip_policy import VipPrivilegeResolver, VipProgressionPolicy

if TYPE_CHECKING:
    from .skin_ownership_service import SkinOwnershipService
    from .stack_inventory import StackInventory


SANDBOX_UID = "13371337"
PASS87_SANDBOX_MIGRATION = "pass87_sandbox_vip_charge_normalization_v1"
COMMERCE_SLICE_ID = "commerce_entitlements"
EOL_MIN_RESOURCE_VERSION = (1, 631, 9)


def parse_resource_version(value: Any) -> tuple[int, int, int] | None:
    parts = str(value or "").strip().split(".")
    if len(parts) != 3 or any(not part.isdigit() for part in parts):
        return None
    return tuple(int(part) for part in parts)


def eol_resource_enabled(value: Any) -> bool:
    parsed = parse_resource_version(value)
    return parsed is not None and parsed >= EOL_MIN_RESOURCE_VERSION


class CommerceStateError(ValueError):
    pass


class CommerceEntitlementService:
    """Canonical owner for charge/vip and Commerce-owned product history.

    Pass87 introduced read/state normalization. Pass88 adds transaction-scoped
    purchase-history mutation and durable completion staging while settlement
    orchestration remains in CommerceSettlementService.
    """

    SCHEMA_VERSION = 2

    def __init__(
        self,
        player: PlayerState,
        policy: VipProgressionPolicy,
        save_callback: Callable[[], None] | None = None,
        *,
        uow: PlayerUnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.policy = policy
        self._save_callback = save_callback
        self.uow = uow

    def _root(self) -> dict[str, Any]:
        state = self.player.commerce_state if isinstance(self.player.commerce_state, dict) else {}
        if state is not self.player.commerce_state:
            self.player.commerce_state = state
        try:
            current_schema = max(0, int(state.get("schema_version") or 0))
        except (TypeError, ValueError):
            current_schema = 0
        state["schema_version"] = max(current_schema, self.SCHEMA_VERSION)
        products = state.get("products")
        if not isinstance(products, dict):
            state["products"] = {}
        migrations = state.get("migrations")
        if not isinstance(migrations, dict):
            state["migrations"] = {}
        outbox = state.get("completion_outbox")
        if not isinstance(outbox, dict):
            state["completion_outbox"] = {}
        return state

    def product_history(self, charge_id: Any) -> dict[str, int]:
        """Read MID354 history without mutating/initializing Commerce state."""
        try:
            key = str(int(charge_id))
        except (TypeError, ValueError):
            return {"charge_count": 0, "last_buy_time": 0}
        state = self.player.commerce_state if isinstance(self.player.commerce_state, dict) else {}
        products = state.get("products") if isinstance(state.get("products"), dict) else {}
        row = products.get(key) if isinstance(products, dict) else None
        if not isinstance(row, dict):
            return {"charge_count": 0, "last_buy_time": 0}
        try:
            count = max(0, int(row.get("charge_count") or 0))
        except (TypeError, ValueError):
            count = 0
        try:
            last = max(0, int(row.get("last_buy_time") or 0))
        except (TypeError, ValueError):
            last = 0
        return {"charge_count": count, "last_buy_time": last}

    def grant_vip_progression(self, delta: Any) -> dict[str, int]:
        """Grant explicit Commerce-owned VIP progression inside the active UoW.

        Effective src_64 persists cumulative ``player.charge`` and derives
        ``player.vip`` from vip.lua.  Recharge gift ``vip_exp`` is therefore an
        explicit Commerce progression grant, not a generic Economy currency.
        """
        if self.uow is None or not self.uow.active:
            raise CommerceStateError("VIP progression requires an active PlayerUnitOfWork")
        try:
            amount = int(delta)
        except (TypeError, ValueError) as exc:
            raise CommerceStateError("VIP progression delta must be an integer") from exc
        if amount <= 0:
            raise CommerceStateError("VIP progression delta must be positive")
        self.player.charge = max(0, int(self.player.charge or 0)) + amount
        self.player.vip = self.policy.derive_vip(self.player.charge)
        self.uow.mark_changed(COMMERCE_SLICE_ID)
        return {"charge": int(self.player.charge), "vip": int(self.player.vip)}

    def record_product_purchase(self, charge_id: Any, *, charge_count: int, last_buy_time: int) -> None:
        """Write canonical MID354 purchase history inside an active Commerce UoW."""
        if self.uow is None or not self.uow.active:
            raise CommerceStateError("product purchase history requires an active PlayerUnitOfWork")
        try:
            key = str(int(charge_id))
        except (TypeError, ValueError) as exc:
            raise CommerceStateError("invalid charge_id") from exc
        if int(charge_count) < 0 or int(last_buy_time) < 0:
            raise CommerceStateError("purchase history cannot be negative")
        self._root()["products"][key] = {
            "charge_count": int(charge_count),
            "last_buy_time": int(last_buy_time),
        }

    def stage_completion_outbox(
        self, intent_id: str, *, event: dict[str, Any], fingerprint: str, committed_at: int
    ) -> None:
        """Stage one durable post-commit bridge-delivery record.

        Delivery is intentionally at-least-once; mutation exactly-once comes from
        the permanent UoW receipt. A retry can therefore replay the same event
        after a lost bridge response without re-crediting the account.
        """
        if self.uow is None or not self.uow.active:
            raise CommerceStateError("completion outbox requires an active PlayerUnitOfWork")
        key = str(intent_id).strip()
        if not key:
            raise CommerceStateError("intent_id is required for completion outbox")
        outbox = self._root()["completion_outbox"]
        existing = outbox.get(key)
        if isinstance(existing, dict):
            old_fp = str(existing.get("request_fingerprint") or "")
            if old_fp and old_fp != str(fingerprint):
                raise CommerceStateError("completion outbox intent fingerprint conflict")
            return
        outbox[key] = {
            "schema_version": 1,
            "status": "COMMITTED_AVAILABLE",
            "request_fingerprint": str(fingerprint),
            "committed_at": max(0, int(committed_at)),
            "event": copy.deepcopy(event),
        }

    def normalize_derived_vip(self) -> bool:
        """Repair vip to the canonical level implied by cumulative charge."""
        expected = self.policy.derive_vip(self.player.charge)
        current = max(0, int(self.player.vip or 0))
        if current == expected:
            return False
        self.player.vip = expected
        return True

    def normalize_legacy_sandbox(self) -> bool:
        """One-time Pass87 migration for the established impossible VIP15/charge0 pair.

        This is STATE NORMALIZATION, never a purchase. It creates no product
        history, receipt, Crystal grant, card/skin entitlement, or first-buy use.
        """
        if str(getattr(self.player, "account_uid", "") or "") != SANDBOX_UID:
            return False
        state = self._root()
        migrations = state["migrations"]
        if migrations.get(PASS87_SANDBOX_MIGRATION):
            return False
        if int(getattr(self.player, "vip", 0) or 0) != 15 or int(getattr(self.player, "charge", 0) or 0) != 0:
            # Do not manufacture a migration marker for an account that does not
            # match the exact legacy signature.
            return False
        before_crystal = int(getattr(self.player, "crystal", 0) or 0)
        self.player.charge = self.policy.max_threshold
        self.player.vip = self.policy.derive_vip(self.player.charge)
        migrations[PASS87_SANDBOX_MIGRATION] = {
            "applied": 1,
            "classification": "STATE_NORMALIZATION_NOT_PURCHASE",
            "from": {"vip": 15, "charge": 0},
            "to": {"vip": int(self.player.vip), "charge": int(self.player.charge)},
            "crystal_delta": int(self.player.crystal) - before_crystal,
            "product_history_created": 0,
        }
        return True

    def maintenance_normalize(self) -> bool:
        changed = self.normalize_legacy_sandbox()
        # Once the legacy exceptional pair is repaired, enforce the source
        # charge->VIP invariant for all players. Fresh players are 0/0.
        if self.normalize_derived_vip():
            changed = True
        return changed

    def snapshot(self) -> dict[str, Any]:
        return {
            "charge": max(0, int(self.player.charge or 0)),
            "vip": max(0, int(self.player.vip or 0)),
            "commerce_state": copy.deepcopy(self._root()),
        }


class RechargeGiftbagAvailabilityPolicy:
    """EOL visibility policy for source-complete supported page-2 Recharge packs.

    Source product/gift metadata is immutable; this policy owns the explicit
    preservation decisions: historical event windows and ``is_open`` are not
    enforced, while one-shot purchase removal and source require_charge chains
    remain meaningful. Random, Hero/entity and source-incomplete rows are not B2.
    """

    def __init__(self, entitlements: CommerceEntitlementService) -> None:
        self.entitlements = entitlements

    def available(self, product: RechargeGiftbagProduct) -> bool:
        if not product.source_native_supported:
            return False
        history = self.entitlements.product_history(product.charge_id)
        if product.one_shot and int(history["charge_count"]) > 0:
            return False
        if int(product.require_charge) > 0:
            required = self.entitlements.product_history(product.require_charge)
            if int(required["charge_count"]) <= 0:
                return False
        return True

    def projection(self, product: RechargeGiftbagProduct) -> dict[str, int]:
        if not self.available(product):
            raise CommerceStateError(f"charge_id={product.charge_id} is not currently available")
        history = self.entitlements.product_history(product.charge_id)
        return {
            "charge_id": int(product.charge_id),
            "charge_count": int(history["charge_count"]),
            "last_buy_time": int(history["last_buy_time"]),
            # EOL preservation intentionally removes expired event timing. A large
            # positive end_time keeps the stock countdown code harmless while the
            # actual product availability remains server-authoritative.
            "end_time": 2147483647,
        }


class RechargeEolAvailabilityPolicy:
    """Phase C visibility/authorization policy for synthetic EOL products.

    Source-native Recharge rows stay governed by RechargeGiftbagAvailabilityPolicy.
    Synthetic rows are a preservation compatibility surface and therefore require
    the matching OTA resource version before they can be advertised or purchased.
    """

    def __init__(
        self,
        entitlements: CommerceEntitlementService,
        stacks: "StackInventory",
        skin_ownership: "SkinOwnershipService",
    ) -> None:
        self.entitlements = entitlements
        self.stacks = stacks
        self.skin_ownership = skin_ownership

    def available(self, product: RechargeEolProduct, resource_version: Any) -> bool:
        if not eol_resource_enabled(resource_version):
            return False
        if product.product_kind == "SYNTHETIC_EOL_ELEMENTAL":
            return True
        if product.product_kind != "SYNTHETIC_EOL_SKIN":
            return False
        # Synthetic skin products are one-shot acquisition surfaces. Historical
        # purchase, an already-held physical skin item, permanent ownership, or
        # unresolved temporary ownership all suppress advertisement/authorization.
        history = self.entitlements.product_history(product.charge_id)
        if int(history["charge_count"]) > 0:
            return False
        if self.stacks.quantity(product.source_item_id) > 0:
            return False
        ownership = self.skin_ownership.ownership_state_for_item(product.source_item_id)
        if not ownership.get("supported"):
            return False
        if ownership.get("permanent") or ownership.get("timed"):
            return False
        return True

    def projection(self, product: RechargeEolProduct, resource_version: Any) -> dict[str, int]:
        if not self.available(product, resource_version):
            raise CommerceStateError(f"charge_id={product.charge_id} is not currently available")
        history = self.entitlements.product_history(product.charge_id)
        return {
            "charge_id": int(product.charge_id),
            "charge_count": int(history["charge_count"]),
            "last_buy_time": int(history["last_buy_time"]),
            # GiftViewWindow treats -1 as indefinite and hides the countdown.
            "end_time": -1,
        }


class RechargeCatalogService:
    """Read-only player-specific MID354 projection."""

    def __init__(
        self,
        player: PlayerState,
        source_catalog: RechargeSourceCatalog,
        entitlements: CommerceEntitlementService,
        *,
        clock: ServerClock | None = None,
    ) -> None:
        self.player = player
        self.source_catalog = source_catalog
        self.entitlements = entitlements
        self.clock = clock or ServerClock()
        self.giftbag_availability = RechargeGiftbagAvailabilityPolicy(entitlements)
        self.eol_availability: RechargeEolAvailabilityPolicy | None = None

    def attach_eol_availability(self, policy: RechargeEolAvailabilityPolicy) -> None:
        self.eol_availability = policy

    def query_charge_data(self, resource_version: Any = None) -> dict[str, Any]:
        charges = []
        for product in self.source_catalog.direct_products():
            history = self.entitlements.product_history(product.charge_id)
            charges.append({
                "charge_id": product.charge_id,
                "charge_count": history["charge_count"],
                "last_buy_time": history["last_buy_time"],
            })
        giftbags = [
            self.giftbag_availability.projection(product)
            for product in self.source_catalog.source_native_supported_giftbags()
            if self.giftbag_availability.available(product)
        ]
        if self.eol_availability is not None and eol_resource_enabled(resource_version):
            giftbags.extend(
                self.eol_availability.projection(product, resource_version)
                for product in self.source_catalog.eol_products()
                if self.eol_availability.available(product, resource_version)
            )
        # Effective SelfPlayer.lua consumes exactly charges/giftbags/server_time;
        # VipRechargeWindow renders only the server-advertised giftbag rows.
        return {
            "charges": charges,
            "giftbags": giftbags,
            "server_time": self.clock.now(),
        }
