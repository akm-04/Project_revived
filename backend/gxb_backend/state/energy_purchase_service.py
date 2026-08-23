"""Pass100 exactly-once MID97 Energy purchase settlement."""
from __future__ import annotations

from typing import Any
import re

from gxb_backend.content.energy_purchase_catalog import EnergyPurchaseCatalogError, EnergyPurchaseSourceCatalog

from .economy_ledger import EconomyLedger
from .player_state import PlayerState
from .server_clock import ServerClock, ServerDayClock
from .temporal_policy_service import TemporalPolicyError, TemporalPolicyService
from .unit_of_work import OperationContext, PlayerUnitOfWork
from .vip_policy import VipPrivilegeResolver


class EnergyPurchaseService:
    RECEIPT_DOMAIN = "mid97_energy_purchase"
    OP_PREFIX = "p100-energy"

    def __init__(
        self,
        player: PlayerState,
        source: EnergyPurchaseSourceCatalog,
        privileges: VipPrivilegeResolver,
        ledger: EconomyLedger,
        temporal: TemporalPolicyService,
        uow: PlayerUnitOfWork,
        *,
        clock: ServerClock | None = None,
    ) -> None:
        self.player = player
        self.source = source
        self.privileges = privileges
        self.ledger = ledger
        self.temporal = temporal
        self.uow = uow
        self.clock = clock or ServerClock()
        self.day_clock = ServerDayClock(self.clock)

    @staticmethod
    def _int(value: Any, default: int = -1) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def total_allowance(self) -> int:
        allowance = self.privileges.energy_purchase_limit()
        if self._int(getattr(self.player, "privilege_left_card_day", 0), 0) > 0:
            allowance += self.source.monthly_privilege_num_energy
        return max(0, int(allowance))

    def _current_payload(self) -> dict[str, Any]:
        return {
            "buy_energy_times": max(0, self._int(self.player.buy_energy_times, 0)),
            "economy_": {
                "crystal": max(0, self._int(self.player.crystal, 0)),
                "energy": max(0, self._int(self.player.energy, 0)),
            },
        }

    @classmethod
    def operation_id(cls, day_id: int, expected: int, nonce: str) -> str:
        return f"{cls.OP_PREFIX}-{int(day_id)}-{int(expected)}-{str(nonce).strip().lower()}"

    @classmethod
    def _identity_matches(cls, operation_id: str, day_id: int, expected: int) -> bool:
        prefix = re.escape(f"{cls.OP_PREFIX}-{int(day_id)}-{int(expected)}-")
        return re.fullmatch(
            prefix + r"[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}",
            str(operation_id).strip().lower(),
        ) is not None

    def purchase(self, req: dict[str, Any]) -> dict[str, Any]:
        expected = self._int(req.get("expected_buy_energy_times"))
        request_day = self._int(req.get("energy_day_id"))
        supplied_op = str(req.get("energy_op_id") or "").strip()
        if expected < 0 or request_day < 0 or not supplied_op:
            return {"error_code": 1, "msg": "mid97_ota_identity_required", "buy_energy_times": max(0, self._int(self.player.buy_energy_times, 0))}

        canonical_op = supplied_op.lower()
        if not self._identity_matches(canonical_op, request_day, expected):
            return {"error_code": 1, "msg": "mid97_operation_identity_invalid", "buy_energy_times": max(0, self._int(self.player.buy_energy_times, 0))}
        fingerprint = f"day={request_day};expected={expected}"

        # A committed receipt wins before source-day/current-counter checks. This
        # reconciles a lost response even if the retry arrives after the next
        # 05:00 reset. Replay is read-only and projects *current* cumulative state
        # so it cannot rewind the client after later legitimate mutations.
        existing = self.uow.get_receipt(self.RECEIPT_DOMAIN, canonical_op)
        if existing is not None:
            old_fingerprint = str(existing.get("request_fingerprint") or "")
            if old_fingerprint and old_fingerprint != fingerprint:
                return {"error_code": 1, "msg": "mid97_receipt_fingerprint_conflict", "buy_energy_times": max(0, self._int(self.player.buy_energy_times, 0))}
            return self._current_payload()

        now = self.clock.now()
        current_day = self.day_clock.day_id(now)
        if request_day != current_day:
            return {"error_code": 1, "msg": "mid97_source_day_mismatch", "buy_energy_times": max(0, self._int(self.player.buy_energy_times, 0))}

        current = max(0, self._int(self.player.buy_energy_times, 0))
        if expected != current:
            return {"error_code": 1, "msg": "mid97_expected_ordinal_mismatch", "buy_energy_times": current}

        allowance = self.total_allowance()
        if current >= allowance:
            return {"error_code": 1, "msg": "mid97_purchase_limit_exhausted", "buy_energy_times": current}

        try:
            effective_energy = self.temporal.preview("energy", "MATERIALIZE", now=now).after.balance
        except TemporalPolicyError:
            return {"error_code": 1, "msg": "mid97_energy_policy_unavailable", "buy_energy_times": current}
        if effective_energy >= self.source.energy_purchase_threshold:
            return {"error_code": 1, "msg": "mid97_energy_threshold_reached", "buy_energy_times": current}

        try:
            cost = self.source.cost(current + 1)
        except EnergyPurchaseCatalogError:
            return {"error_code": 1, "msg": "mid97_cost_unavailable", "buy_energy_times": current}
        if self.ledger.balance("crystal") < cost:
            return {"error_code": 1, "msg": "crystal_insufficient", "buy_energy_times": current}

        context = OperationContext(
            actor_player_id=str(self.player.player_id),
            protocol_mid=97,
            domain="economy",
            operation_name="add_energy",
            idempotency_key=canonical_op,
            idempotency_mode="CLIENT_UUID_EXPECTED_ORDINAL",
            request_fingerprint=fingerprint,
            server_time=now,
        )
        with self.uow.transaction(context):
            # Re-check inside the atomic section for future concurrency-safe use.
            existing = self.uow.get_receipt(self.RECEIPT_DOMAIN, canonical_op)
            if existing is not None:
                if str(existing.get("request_fingerprint") or "") not in ("", fingerprint):
                    self.uow.set_rollback_only()
                    return {"error_code": 1, "msg": "mid97_receipt_fingerprint_conflict", "buy_energy_times": max(0, self._int(self.player.buy_energy_times, 0))}
                return self._current_payload()
            if max(0, self._int(self.player.buy_energy_times, 0)) != expected:
                self.uow.set_rollback_only()
                return {"error_code": 1, "msg": "mid97_expected_ordinal_mismatch", "buy_energy_times": max(0, self._int(self.player.buy_energy_times, 0))}
            if self.ledger.debit("crystal", cost) is None:
                self.uow.set_rollback_only()
                return {"error_code": 1, "msg": "crystal_insufficient", "buy_energy_times": current}
            self.temporal.apply_transition("energy", "CREDIT", self.source.energy_grant, origin_ref=canonical_op)
            self.player.buy_energy_times = expected + 1
            self.uow.mark_changed("daily_purchase_counters")
            committed_payload = self._current_payload()
            self.uow.stage_receipt(
                domain=self.RECEIPT_DOMAIN,
                operation="ADD_ENERGY",
                key=canonical_op,
                mode="CLIENT_UUID_EXPECTED_ORDINAL",
                request_fingerprint=fingerprint,
                replay_payload={
                    "buy_energy_times": expected + 1,
                    "cost": cost,
                    "energy_grant": self.source.energy_grant,
                    "source_day_id": request_day,
                },
                retention_policy="CLIENT_UUID_PERMANENT",
            )
        return committed_payload
