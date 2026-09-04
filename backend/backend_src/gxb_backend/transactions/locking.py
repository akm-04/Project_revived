"""Registry-driven resource locking in the frozen universal acquisition order."""

from __future__ import annotations

from collections.abc import Callable, Iterable
from dataclasses import dataclass
from typing import Any

from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey, order_resource_keys


ResourceLocker = Callable[[Any, ResourceKey], None]


@dataclass(frozen=True)
class LockerRegistration:
    resource_class: ResourceClass
    kind: str
    locker: ResourceLocker


class ResourceLockRegistry:
    """Maps typed resources to canonical-row lockers supplied by later waves/domains.

    I2 deliberately does not create a generic resource-lock table. I3/I4 and
    shared-domain waves register lock functions for their actual canonical rows.
    """

    def __init__(self) -> None:
        self._lockers: dict[tuple[ResourceClass, str], ResourceLocker] = {}

    def register(self, resource_class: ResourceClass, kind: str, locker: ResourceLocker) -> None:
        if not isinstance(resource_class, ResourceClass):
            raise TypeError("resource_class must be ResourceClass")
        normalized = str(kind).strip()
        if not normalized:
            raise ValueError("resource kind must not be empty")
        if not callable(locker):
            raise TypeError("locker must be callable")
        key = (resource_class, normalized)
        if key in self._lockers:
            raise ValueError(f"locker already registered for {resource_class.name}:{normalized}")
        self._lockers[key] = locker

    def acquire_all(self, connection: Any, resources: Iterable[ResourceKey]) -> tuple[ResourceKey, ...]:
        ordered = order_resource_keys(resources)
        for resource in ordered:
            locker = self._lockers.get((resource.resource_class, resource.kind))
            if locker is None:
                raise KeyError(
                    f"no canonical-row locker registered for "
                    f"{resource.resource_class.name}:{resource.kind}"
                )
            locker(connection, resource)
        return ordered
