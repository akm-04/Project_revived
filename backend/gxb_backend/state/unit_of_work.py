"""Request-scoped one-player durable UnitOfWork.

Pass68 upgrades the Pass32.6 transaction coordinator to the Phase-2 contract:
whole-PlayerState rollback remains the physical rollback mechanism, while the
additive persistence envelope supplies logical state_version, optional slice
revisions, crash-safe receipt staging, and post-commit semantic publication.
"""
from __future__ import annotations

import copy
import hashlib
import json
import time
from contextlib import contextmanager
from dataclasses import dataclass
from typing import Any, Callable, Iterator

from .persistence_state import ensure_persistence_state, state_version
from .player_state import PlayerState


class StateVersionConflict(RuntimeError):
    pass


class ReceiptConflict(RuntimeError):
    pass


@dataclass(frozen=True)
class OperationContext:
    actor_player_id: str
    domain: str
    operation_name: str
    protocol_mid: int | None = None
    idempotency_key: str | None = None
    idempotency_mode: str = "NONE"
    request_fingerprint: str | None = None
    expected_state_version: int | None = None
    server_time: int | None = None


class PlayerUnitOfWork:
    """One-player transaction coordinator; never a cross-player transaction."""

    def __init__(self, player: PlayerState, commit_callback: Callable[[], None]) -> None:
        self.player = player
        self._commit_callback = commit_callback
        self._depth = 0
        self._snapshot: dict | None = None
        self._rollback_only = False
        self._save_requested = False
        self._contexts: list[OperationContext] = []
        self._staged_semantic: dict[str, list[object]] = {}
        self._committed_semantic: dict[str, list[object]] = {}
        self._touched_slices: set[str] = set()
        self._staged_receipts: list[dict[str, Any]] = []
        ensure_persistence_state(self.player)

    @property
    def active(self) -> bool:
        return self._depth > 0

    @property
    def current_context(self) -> OperationContext | None:
        return self._contexts[-1] if self._contexts else None

    @property
    def current_state_version(self) -> int:
        return state_version(self.player)

    def request_save(self) -> None:
        if self.active:
            self._save_requested = True
            return
        # Compatibility path for legacy handlers that still persist outside a
        # transaction. It deliberately does not fabricate a transaction receipt.
        self._commit_callback()

    def mark_changed(self, slice_id: str | None = None) -> None:
        if slice_id:
            self.touch_slice(slice_id)
        if self.active:
            self._save_requested = True
        else:
            self._commit_callback()

    def touch_slice(self, slice_id: str) -> None:
        if not self.active:
            raise RuntimeError("slice revisions may only be staged inside PlayerUnitOfWork")
        value = str(slice_id).strip()
        if value:
            self._touched_slices.add(value)

    def stage_semantic(self, channel: str, value: object) -> None:
        target = self._staged_semantic if self.active else self._committed_semantic
        target.setdefault(str(channel), []).append(copy.deepcopy(value))

    def consume_semantic(self) -> dict[str, list[object]]:
        out = copy.deepcopy(self._committed_semantic)
        self._committed_semantic.clear()
        return out

    def get_receipt(self, domain: str, key: str) -> dict[str, Any] | None:
        root = ensure_persistence_state(self.player).get("receipts", {})
        record = root.get(str(domain), {}).get(str(key)) if isinstance(root, dict) else None
        return copy.deepcopy(record) if isinstance(record, dict) else None

    def stage_receipt(
        self,
        *,
        domain: str,
        operation: str,
        key: str,
        mode: str = "DOMAIN_RECEIPT",
        request_fingerprint: str | None = None,
        replay_payload: dict[str, Any] | None = None,
        retention_policy: str = "DOMAIN_PERMANENT",
    ) -> None:
        if not self.active:
            raise RuntimeError("receipt must be staged inside PlayerUnitOfWork")
        existing = self.get_receipt(domain, key)
        if existing is not None:
            old_fp = existing.get("request_fingerprint")
            if request_fingerprint and old_fp and str(old_fp) != str(request_fingerprint):
                raise ReceiptConflict(f"receipt key reused with incompatible fingerprint: {domain}/{key}")
            raise ReceiptConflict(f"receipt already committed: {domain}/{key}")
        for pending in self._staged_receipts:
            if pending["domain"] == str(domain) and pending["key"] == str(key):
                raise ReceiptConflict(f"duplicate staged receipt: {domain}/{key}")
        self._staged_receipts.append({
            "schema_version": 1,
            "mode": str(mode),
            "domain": str(domain),
            "operation": str(operation),
            "key": str(key),
            "actor_player_id": str(self.player.player_id),
            "request_fingerprint": request_fingerprint,
            "status": "STAGED",
            "committed_at": None,
            "state_version_before": self.current_state_version,
            "state_version_after": None,
            "result_digest": None,
            "replay_payload": copy.deepcopy(replay_payload) if replay_payload is not None else None,
            "retention_policy": str(retention_policy),
        })
        self._save_requested = True

    def set_rollback_only(self) -> None:
        if self.active:
            self._rollback_only = True

    def _take_snapshot(self) -> dict:
        return copy.deepcopy(vars(self.player))

    def _restore_snapshot(self) -> None:
        if self._snapshot is None:
            return
        current = vars(self.player)
        current.clear()
        current.update(copy.deepcopy(self._snapshot))

    @staticmethod
    def _digest_payload(payload: Any) -> str:
        blob = json.dumps(payload, sort_keys=True, separators=(",", ":"), ensure_ascii=False).encode("utf-8")
        return hashlib.sha256(blob).hexdigest()

    def _prepare_persistence_commit(self, context: OperationContext) -> None:
        root = ensure_persistence_state(self.player)
        before = int(root.get("state_version", 0))
        after = before + 1
        committed_at = int(context.server_time if context.server_time is not None else time.time())
        root["state_version"] = after
        revisions = root.setdefault("slice_revisions", {})
        if not isinstance(revisions, dict):
            revisions = {}
            root["slice_revisions"] = revisions
        for slice_id in sorted(self._touched_slices):
            try:
                current = max(0, int(revisions.get(slice_id, 0)))
            except (TypeError, ValueError):
                current = 0
            revisions[slice_id] = current + 1

        receipts = root.setdefault("receipts", {})
        if not isinstance(receipts, dict):
            receipts = {}
            root["receipts"] = receipts
        for record in self._staged_receipts:
            domain = record["domain"]
            key = record["key"]
            bucket = receipts.setdefault(domain, {})
            if not isinstance(bucket, dict):
                bucket = {}
                receipts[domain] = bucket
            if key in bucket:
                raise ReceiptConflict(f"receipt appeared before commit: {domain}/{key}")
            final = copy.deepcopy(record)
            final["status"] = "COMMITTED"
            final["committed_at"] = committed_at
            final["state_version_before"] = before
            final["state_version_after"] = after
            final["result_digest"] = self._digest_payload(final.get("replay_payload"))
            bucket[key] = final

        root["last_commit"] = {
            "schema_version": 1,
            "committed_at": committed_at,
            "state_version_before": before,
            "state_version_after": after,
            "domain": str(context.domain),
            "operation": str(context.operation_name),
            "protocol_mid": context.protocol_mid,
        }
        self.player.persistence_state = root

    @contextmanager
    def transaction(self, context: OperationContext) -> Iterator["PlayerUnitOfWork"]:
        outermost = self._depth == 0
        if outermost:
            ensure_persistence_state(self.player)
            if context.expected_state_version is not None and int(context.expected_state_version) != self.current_state_version:
                raise StateVersionConflict(
                    f"expected state_version={context.expected_state_version}, actual={self.current_state_version}"
                )
            self._snapshot = self._take_snapshot()
            self._rollback_only = False
            self._save_requested = False
            self._staged_semantic = {}
            self._touched_slices = set()
            self._staged_receipts = []
        self._depth += 1
        self._contexts.append(context)
        try:
            yield self
        except Exception:
            self._rollback_only = True
            raise
        finally:
            self._contexts.pop()
            self._depth -= 1
            if outermost:
                try:
                    if self._rollback_only:
                        self._restore_snapshot()
                        self._staged_semantic = {}
                    elif self._save_requested:
                        try:
                            self._prepare_persistence_commit(context)
                            self._commit_callback()
                        except Exception:
                            self._restore_snapshot()
                            self._staged_semantic = {}
                            raise
                        for channel, values in self._staged_semantic.items():
                            self._committed_semantic.setdefault(channel, []).extend(copy.deepcopy(values))
                        self._staged_semantic = {}
                    else:
                        self._staged_semantic = {}
                finally:
                    self._snapshot = None
                    self._rollback_only = False
                    self._save_requested = False
                    self._touched_slices = set()
                    self._staged_receipts = []


# Compatibility alias: existing repositories continue importing UnitOfWork.
UnitOfWork = PlayerUnitOfWork
