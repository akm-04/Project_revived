"""Mechanism-neutral contracts for the Pass339 foundation.

These protocols deliberately do not replace or wire the Pass299 repository.
They define the seams implemented by later I2-I4 PostgreSQL adapters.
"""

from __future__ import annotations

from contextlib import AbstractContextManager
from dataclasses import dataclass
from typing import Any, Mapping, Protocol, Sequence, runtime_checkable

from .resource_keys import ResourceKey


@dataclass(frozen=True)
class TransactionRequest:
    request_id: str
    operation_name: str
    resources: tuple[ResourceKey, ...]
    client_operation_id: str | None = None
    retry_safe: bool = False


@dataclass(frozen=True)
class PlayerAggregateRecord:
    player_id: int
    account_uid: str
    region_id: int
    schema_version: int
    state_version: int
    payload: Mapping[str, Any]


@runtime_checkable
class ResourceTransaction(Protocol):
    """One outer durable transaction shared by every participating repository."""

    @property
    def request(self) -> TransactionRequest: ...

    @property
    def connection(self) -> Any: ...

    def stage_post_commit(self, topic: str, payload: Mapping[str, Any]) -> None: ...


@runtime_checkable
class TransactionCoordinator(Protocol):
    def begin(self, request: TransactionRequest) -> AbstractContextManager[ResourceTransaction]: ...


@runtime_checkable
class PlayerAggregateRepository(Protocol):
    def load_for_update(
        self,
        transaction: ResourceTransaction,
        player_id: int,
    ) -> PlayerAggregateRecord | None: ...

    def save(
        self,
        transaction: ResourceTransaction,
        record: PlayerAggregateRecord,
        *,
        expected_state_version: int,
    ) -> PlayerAggregateRecord: ...


@runtime_checkable
class PostCommitEventBus(Protocol):
    def publish(self, topic: str, payloads: Sequence[Mapping[str, Any]]) -> None: ...


@runtime_checkable
class RequestRuntimeAdapter(Protocol):
    """Compatibility boundary used while StateRepository remains the runtime."""

    def request_scope(self, request: Mapping[str, Any] | None) -> AbstractContextManager[None]: ...
