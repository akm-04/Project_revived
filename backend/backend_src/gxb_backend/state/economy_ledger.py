"""Typed scalar economy owner introduced by Pass69.

The client exposes a broad ``economy_`` synchronization envelope, but only the
30 ResourceRegistry descriptors tagged ``scalar_ledger`` belong to this owner.
The ledger deliberately persists the existing PlayerState attributes so the
Phase-3 migration remains a strangler rather than a storage rewrite.
"""
from __future__ import annotations

import copy
from dataclasses import dataclass
from typing import Any, Callable, Iterable, Mapping

from .player_state import PlayerState
from .resource_registry import ResourceDescriptor, ResourceRegistry
from .unit_of_work import PlayerUnitOfWork


class EconomyLedgerError(ValueError):
    """Base validation error for a scalar-ledger command."""


class UnsupportedScalarResource(EconomyLedgerError):
    pass


class InsufficientScalarBalance(EconomyLedgerError):
    pass


@dataclass(frozen=True)
class ScalarMutationRecord:
    key: str
    before: int
    after: int
    delta: int
    descriptor: ResourceDescriptor


class EconomyLedger:
    """Canonical owner of ResourceRegistry's 30 scalar balance/material keys."""

    SLICE_ID = "scalar_economy"

    def __init__(
        self,
        player: PlayerState,
        registry: ResourceRegistry,
        save_callback: Callable[[], None] | None = None,
        *,
        uow: PlayerUnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.registry = registry
        self._save_callback = save_callback
        self.uow = uow
        # Fail fast at composition time if the runtime registry drifts from the
        # frozen Phase-2 contract.
        scalar = self.registry.scalar_keys()
        if len(scalar) != 30:
            raise UnsupportedScalarResource(f"expected 30 scalar resources, got {len(scalar)}")
        for key in scalar:
            self._descriptor(key)

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def _descriptor(self, key: str) -> ResourceDescriptor:
        desc = self.registry.require(str(key))
        if desc.legacy_adapter_class != "scalar_ledger" or desc.owner_service != "EconomyLedger":
            raise UnsupportedScalarResource(f"resource is not scalar-ledger owned: {key}")
        if desc.mutation_capability != "CREDIT_DEBIT":
            raise UnsupportedScalarResource(f"resource is not credit/debit mutable: {key}")
        prefix = "PlayerState."
        if not str(desc.storage_locator_v1).startswith(prefix):
            raise UnsupportedScalarResource(f"unsupported scalar storage locator: {desc.storage_locator_v1}")
        attr = str(desc.storage_locator_v1)[len(prefix):]
        if attr != desc.wire_key or not hasattr(self.player, attr):
            raise UnsupportedScalarResource(
                f"scalar storage mismatch: {desc.wire_key} -> {desc.storage_locator_v1}"
            )
        return desc

    def descriptor(self, key: str) -> ResourceDescriptor:
        return self._descriptor(key)

    def balance(self, key: str) -> int:
        desc = self._descriptor(key)
        return max(0, self._int(getattr(self.player, desc.wire_key), 0))

    def snapshot(self, keys: Iterable[str] | None = None) -> dict[str, int]:
        selected = tuple(keys) if keys is not None else self.registry.scalar_keys()
        return {str(key): self.balance(str(key)) for key in selected}

    def validate_deltas(self, deltas: Mapping[str, Any]) -> dict[str, int]:
        """Normalize a keyed delta set and preflight every resulting balance.

        Validation happens for the full set before any field is changed, which
        makes mixed-currency debits locally atomic even before the outer UoW
        provides the durable transaction boundary.
        """
        normalized: dict[str, int] = {}
        for raw_key, raw_delta in deltas.items():
            key = str(raw_key)
            self._descriptor(key)
            delta = self._int(raw_delta, 0)
            if delta:
                normalized[key] = normalized.get(key, 0) + delta

        for key, delta in normalized.items():
            after = self.balance(key) + delta
            if after < 0:
                raise InsufficientScalarBalance(
                    f"insufficient {key}: current={self.balance(key)} delta={delta}"
                )
        return normalized

    def apply_deltas(
        self,
        deltas: Mapping[str, Any],
        *,
        persist: bool = False,
    ) -> tuple[ScalarMutationRecord, ...]:
        normalized = self.validate_deltas(deltas)
        if not normalized:
            return ()

        before = {key: self.balance(key) for key in normalized}
        try:
            records: list[ScalarMutationRecord] = []
            for key in sorted(normalized):
                delta = normalized[key]
                after = before[key] + delta
                setattr(self.player, key, after)
                records.append(
                    ScalarMutationRecord(
                        key=key,
                        before=before[key],
                        after=after,
                        delta=delta,
                        descriptor=self._descriptor(key),
                    )
                )

            if self.uow is not None and self.uow.active:
                # A typed owner must make its durable intent explicit; callers
                # should not need a second unrelated mutation just to trigger a
                # save/version increment.
                self.uow.mark_changed(self.SLICE_ID)
            elif persist:
                self._save()
            return tuple(records)
        except Exception:
            for key, value in before.items():
                setattr(self.player, key, copy.deepcopy(value))
            raise

    def try_apply_deltas(self, deltas: Mapping[str, Any], *, persist: bool = False) -> tuple[ScalarMutationRecord, ...] | None:
        try:
            return self.apply_deltas(deltas, persist=persist)
        except EconomyLedgerError:
            return None

    def credit(self, key: str, amount: Any, *, persist: bool = False) -> ScalarMutationRecord | None:
        value = max(0, self._int(amount, 0))
        if value == 0:
            return None
        return self.apply_deltas({key: value}, persist=persist)[0]

    def debit(self, key: str, amount: Any, *, persist: bool = False) -> ScalarMutationRecord | None:
        value = max(0, self._int(amount, 0))
        if value == 0:
            return None
        rows = self.try_apply_deltas({key: -value}, persist=persist)
        return rows[0] if rows else None

    def _save(self) -> None:
        if self._save_callback:
            self._save_callback()
