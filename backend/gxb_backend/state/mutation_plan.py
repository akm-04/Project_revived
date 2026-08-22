"""Executable subset of the frozen Pass65 MutationPlan contract.

Pass69 implements RESOURCE and STACK leaf operations. Pass71 activates the
source-bounded TEMPORAL family for regenerating resources. Pass72 activates
the frozen ENTITY family for typed Hero aggregate transitions; remaining
families stay explicit and fail closed until their owner waves.
"""
from __future__ import annotations

from dataclasses import asdict, dataclass, field
from typing import Any, Mapping


@dataclass(frozen=True)
class MutationOrigin:
    domain: str
    operation: str
    protocol_mid: int | None = None
    source_table: str | None = None
    source_id: int | None = None
    field_path: str | None = None


@dataclass(frozen=True)
class ActorRef:
    player_id: str
    account_uid: str | None = None


@dataclass(frozen=True)
class IdempotencySpec:
    mode: str = "NONE"
    key: str | None = None
    request_fingerprint: str | None = None


@dataclass(frozen=True)
class Precondition:
    kind: str
    subject: Mapping[str, Any]
    amount: int | None = None
    expected: Any = None


@dataclass(frozen=True)
class ResourceMutation:
    resource_key: str
    action: str
    amount: int
    kind: str = field(default="RESOURCE", init=False)


@dataclass(frozen=True)
class StackMutation:
    item_id: int
    action: str
    amount: int
    kind: str = field(default="STACK", init=False)


@dataclass(frozen=True)
class TemporalTransition:
    resource_key: str
    action: str
    amount: int = 0
    publish: bool = True
    kind: str = field(default="TEMPORAL", init=False)


@dataclass(frozen=True)
class EntityMutation:
    """Typed aggregate-owned entity transition.

    Pass72 activates only ``entity_type="HERO"``. ``action`` is a bounded
    domain verb interpreted by the registered Hero aggregate owner; ``indices``
    and ``counts`` carry fixed positional progression operations without
    permitting arbitrary dictionary patches.
    """

    entity_type: str
    entity_id: int
    action: str
    amount: int = 0
    indices: tuple[int, ...] = ()
    counts: tuple[int, ...] = ()
    kind: str = field(default="ENTITY", init=False)


MutationOp = ResourceMutation | StackMutation | TemporalTransition | EntityMutation


@dataclass(frozen=True)
class SemanticEvent:
    channel: str
    value: Any


@dataclass(frozen=True)
class MutationPlan:
    schema_version: int
    plan_id: str
    origin: MutationOrigin
    actor: ActorRef
    expected_state_version: int | None
    idempotency: IdempotencySpec
    preconditions: tuple[Precondition, ...]
    operations: tuple[MutationOp, ...]
    semantic_events: tuple[SemanticEvent, ...] = ()
    metadata: Mapping[str, Any] = field(default_factory=dict)


@dataclass(frozen=True)
class JournalEntry:
    seq: int
    owner: str
    category: str
    subject: Mapping[str, Any]
    action: str
    before: Any
    after: Any
    delta: int | None
    projection_tags: tuple[str, ...] = ()
    origin_ref: str | None = None

    def as_dict(self) -> dict[str, Any]:
        return asdict(self)


@dataclass(frozen=True)
class MutationResult:
    schema_version: int
    plan_id: str
    status: str
    actor_player_id: str
    committed_at_server_time: int | None
    state_version_before: int | None
    state_version_after: int | None
    journal: tuple[JournalEntry, ...]
    owner_versions: Mapping[str, int] = field(default_factory=dict)
    idempotency_receipt: Mapping[str, Any] | None = None
    projection_hints: tuple[Mapping[str, Any], ...] = ()

    def journal_dicts(self) -> list[dict[str, Any]]:
        return [entry.as_dict() for entry in self.journal]
