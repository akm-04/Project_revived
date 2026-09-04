from __future__ import annotations

from uuid import UUID

import pytest

from gxb_backend.foundation.resource_keys import (
    ResourceClass,
    ResourceKey,
    order_resource_keys,
    require_canonical_order,
)


def test_frozen_resource_class_order_is_exact() -> None:
    assert [(item.name, item.value) for item in ResourceClass] == [
        ("SESSION", 10),
        ("CONTEXT", 20),
        ("ACCOUNT_GLOBAL", 30),
        ("REGION", 40),
        ("GENERATION", 50),
        ("SHARED", 60),
        ("PLAYER", 70),
        ("CHILD", 80),
    ]


def test_order_is_deterministic_and_player_ids_are_numeric() -> None:
    resources = [
        ResourceKey.player("10"),
        ResourceKey.of(ResourceClass.SHARED, "guild", 4),
        ResourceKey.player(2),
        ResourceKey.of(ResourceClass.SESSION, "session", UUID(int=3)),
        ResourceKey.player(2),
    ]
    ordered = order_resource_keys(resources)
    assert [item.resource_class for item in ordered] == [
        ResourceClass.SESSION,
        ResourceClass.SHARED,
        ResourceClass.PLAYER,
        ResourceClass.PLAYER,
    ]
    assert [item.identity for item in ordered[-2:]] == [(2,), (10,)]


def test_require_canonical_order_rejects_duplicates_and_reordering() -> None:
    first = ResourceKey.of(ResourceClass.SESSION, "session", "a")
    second = ResourceKey.player(1)
    assert require_canonical_order((first, second)) == (first, second)
    with pytest.raises(ValueError):
        require_canonical_order((second, first))
    with pytest.raises(ValueError):
        require_canonical_order((first, first))


@pytest.mark.parametrize("bad", [True, object(), "", "   "])
def test_invalid_identity_rejected(bad: object) -> None:
    with pytest.raises((TypeError, ValueError)):
        ResourceKey.of(ResourceClass.REGION, "region", bad)  # type: ignore[arg-type]

