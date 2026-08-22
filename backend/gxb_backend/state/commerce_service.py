"""Commerce/VIP state owner, product history, completion outbox, and MID354 projection."""
from __future__ import annotations

import copy
from pathlib import Path
from typing import Any, Callable

from gxb_backend.content.recharge_catalog import RechargeSourceCatalog

from .player_state import PlayerState
from .server_clock import ServerClock
from .unit_of_work import PlayerUnitOfWork
from .vip_policy import VipPrivilegeResolver, VipProgressionPolicy


SANDBOX_UID = "13371337"
PASS87_SANDBOX_MIGRATION = "pass87_sandbox_vip_charge_normalization_v1"


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

    def query_charge_data(self) -> dict[str, Any]:
        charges = []
        for product in self.source_catalog.direct_products():
            history = self.entitlements.product_history(product.charge_id)
            charges.append({
                "charge_id": product.charge_id,
                "charge_count": history["charge_count"],
                "last_buy_time": history["last_buy_time"],
            })
        # Effective SelfPlayer.lua consumes charges/giftbags/server_time. Keep
        # giftbags explicitly empty because charge_list/card lifecycles are not
        # implemented in this phase; do not invent unsupported product rows.
        return {
            "charges": charges,
            "giftbags": [],
            "server_time": self.clock.now(),
        }
