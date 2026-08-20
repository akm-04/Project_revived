"""Explicit one-shot Summon operation receipt boundary for Pass41.2.

This store is intentionally scoped to canonical one-shot tutorial operations.
Repeated paid pulls may legitimately reuse the same MID50 parameter tuple and
must receive a different operation-identity design in a later evidence-backed
pass.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass
from typing import Any, MutableMapping


class SummonReceiptError(RuntimeError):
    pass


@dataclass(frozen=True)
class SummonReceiptIdentity:
    key: str
    semantic: str
    protocol_mid: int
    summon_type: int
    summon_index: int
    receipt_name: str | None
    scope: str = "tutorial_one_shot"


class SummonOperationReceiptStore:
    STORE_KEY = "tutorial_operation_receipts"

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def __init__(self, summon_state: MutableMapping[str, Any]) -> None:
        self.summon_state = summon_state

    def get(self, identity: SummonReceiptIdentity) -> dict[str, Any] | None:
        receipts = self.summon_state.get(self.STORE_KEY)
        if not isinstance(receipts, dict):
            return None
        row = receipts.get(identity.key)
        if not isinstance(row, dict) or self._int(row.get("committed"), 0) != 1:
            return None
        if str(row.get("semantic") or "") != identity.semantic:
            return None
        if self._int(row.get("protocol_mid"), 0) != identity.protocol_mid:
            return None
        if self._int(row.get("summon_type"), 0) != identity.summon_type:
            return None
        if self._int(row.get("summon_index"), 0) != identity.summon_index:
            return None
        response = row.get("response")
        if not isinstance(response, dict):
            return None
        # Schema v1 receipts predate the explicit scope field. They are the same
        # canonical tutorial-only store and remain readable for upgrade safety.
        scope = str(row.get("scope") or "tutorial_one_shot")
        if scope != identity.scope:
            return None
        return copy.deepcopy(row)

    def store(
        self,
        identity: SummonReceiptIdentity,
        response: dict[str, Any],
        *,
        committed_at: int,
        legacy_adoption: bool = False,
        result_plan_summary: list[dict[str, Any]] | None = None,
    ) -> None:
        receipts = self.summon_state.setdefault(self.STORE_KEY, {})
        if not isinstance(receipts, dict):
            raise SummonReceiptError("summon operation receipt store has invalid shape")
        if identity.key in receipts:
            raise SummonReceiptError("summon operation receipt already exists")
        receipts[identity.key] = {
            "schema_version": 2,
            "scope": identity.scope,
            "committed": 1,
            "semantic": identity.semantic,
            "protocol_mid": identity.protocol_mid,
            "summon_type": identity.summon_type,
            "summon_index": identity.summon_index,
            "receipt_name": identity.receipt_name,
            "committed_at": int(committed_at),
            "legacy_adoption": 1 if legacy_adoption else 0,
            "result_plan": copy.deepcopy(result_plan_summary or []),
            "response": copy.deepcopy(response),
        }


class PaidSummonOperationReceiptStore:
    """Short-window replay boundary for repeatable private Summon operations.

    The historical class/storage name is retained for compatibility. Stock MID50/MID70
    requests have no operation token, so active private paid operations and the Pass41.9
    recurring Small free operation treat an identical semantic request inside a very short
    window as a transport retry. Only the latest repeatable-operation receipt is retained.
    """

    STORE_KEY = "paid_operation_receipt_v1"

    def __init__(self, summon_state: MutableMapping[str, Any]) -> None:
        self.summon_state = summon_state

    def replay(self, *, semantic: str, now_ms: int, window_ms: int) -> dict[str, Any] | None:
        row = self.summon_state.get(self.STORE_KEY)
        if not isinstance(row, dict) or int(row.get("committed", 0) or 0) != 1:
            return None
        if str(row.get("semantic") or "") != str(semantic):
            return None
        committed_at_ms = int(row.get("committed_at_ms", 0) or 0)
        if committed_at_ms <= 0 or int(now_ms) - committed_at_ms < 0:
            return None
        if int(now_ms) - committed_at_ms > max(0, int(window_ms)):
            return None
        response = row.get("response")
        return copy.deepcopy(response) if isinstance(response, dict) else None

    def store(
        self,
        *,
        semantic: str,
        protocol_mid: int,
        summon_type: int,
        summon_index: int,
        committed_at_ms: int,
        response: dict[str, Any],
    ) -> None:
        self.summon_state[self.STORE_KEY] = {
            "schema_version": 1,
            "scope": "paid_short_retry_window",
            "committed": 1,
            "semantic": str(semantic),
            "protocol_mid": int(protocol_mid),
            "summon_type": int(summon_type),
            "summon_index": int(summon_index),
            "committed_at_ms": int(committed_at_ms),
            "response": copy.deepcopy(response),
        }
