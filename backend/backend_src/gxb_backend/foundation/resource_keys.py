"""Typed, deterministic resource ordering for the future transaction layer.

Pass339 introduces the vocabulary only.  The legacy JSON request path does not
use these keys yet and therefore retains its exact Pass299 behavior.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import IntEnum
from typing import Iterable, TypeAlias
from uuid import UUID


ResourceIdentity: TypeAlias = int | str | UUID


class ResourceClass(IntEnum):
    """Frozen Pass336 universal resource-class order."""

    SESSION = 10
    CONTEXT = 20
    ACCOUNT_GLOBAL = 30
    REGION = 40
    GENERATION = 50
    SHARED = 60
    PLAYER = 70
    CHILD = 80


def _validate_identity(value: ResourceIdentity) -> None:
    if isinstance(value, bool) or not isinstance(value, (int, str, UUID)):
        raise TypeError("resource identity parts must be int, str, or UUID")
    if isinstance(value, str) and not value.strip():
        raise ValueError("resource identity strings must not be empty")


def _sort_identity(value: ResourceIdentity) -> tuple[int, int | str]:
    if isinstance(value, int) and not isinstance(value, bool):
        return (0, value)
    if isinstance(value, UUID):
        return (1, value.hex)
    return (2, str(value))


@dataclass(frozen=True)
class ResourceKey:
    """One canonical lockable resource.

    ``kind`` gives each domain a stable namespace inside its resource class.
    ``identity`` is explicit and sortable; player constructors coerce numeric
    IDs to integers so PLAYER ordering is numeric rather than lexical.
    """

    resource_class: ResourceClass
    kind: str
    identity: tuple[ResourceIdentity, ...]

    def __post_init__(self) -> None:
        if not isinstance(self.resource_class, ResourceClass):
            raise TypeError("resource_class must be ResourceClass")
        normalized_kind = str(self.kind).strip()
        if not normalized_kind:
            raise ValueError("resource kind must not be empty")
        if not self.identity:
            raise ValueError("resource identity must contain at least one part")
        for part in self.identity:
            _validate_identity(part)
        object.__setattr__(self, "kind", normalized_kind)

    @classmethod
    def of(
        cls,
        resource_class: ResourceClass,
        kind: str,
        *identity: ResourceIdentity,
    ) -> "ResourceKey":
        return cls(resource_class=resource_class, kind=kind, identity=tuple(identity))

    @classmethod
    def player(cls, player_id: int | str) -> "ResourceKey":
        if isinstance(player_id, bool):
            raise TypeError("player_id must be an integer")
        return cls.of(ResourceClass.PLAYER, "player", int(player_id))

    @property
    def sort_key(self) -> tuple[object, ...]:
        return (
            int(self.resource_class),
            self.kind,
            tuple(_sort_identity(part) for part in self.identity),
        )


def order_resource_keys(resources: Iterable[ResourceKey]) -> tuple[ResourceKey, ...]:
    """Return unique resources in the frozen universal acquisition order."""

    unique: dict[ResourceKey, None] = {}
    for resource in resources:
        if not isinstance(resource, ResourceKey):
            raise TypeError("all resources must be ResourceKey instances")
        unique[resource] = None
    return tuple(sorted(unique, key=lambda item: item.sort_key))


def require_canonical_order(resources: Iterable[ResourceKey]) -> tuple[ResourceKey, ...]:
    """Validate that callers already supplied a unique canonical sequence."""

    supplied = tuple(resources)
    ordered = order_resource_keys(supplied)
    if supplied != ordered:
        raise ValueError("resources are not unique and canonically ordered")
    return supplied
