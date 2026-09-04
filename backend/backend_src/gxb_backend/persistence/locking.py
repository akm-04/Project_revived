"""Pass343 canonical-row lock registrations for I4 persistence authority."""
from __future__ import annotations

from sqlalchemy import select

from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.transactions.locking import ResourceLockRegistry

from .schema import account_global_state, players


def player_state_resource(player_id: int | str) -> ResourceKey:
    return ResourceKey.of(ResourceClass.PLAYER, "player_state", int(player_id))


def account_global_resource(account_uid: str) -> ResourceKey:
    return ResourceKey.of(ResourceClass.ACCOUNT_GLOBAL, "account_global_state", str(account_uid))


def register_i4_persistence_lockers(registry: ResourceLockRegistry) -> ResourceLockRegistry:
    """Register actual I4 canonical rows; no synthetic/generic lock table."""

    def lock_account_global(connection, resource: ResourceKey) -> None:
        if len(resource.identity) != 1:
            raise ValueError("account_global_state requires one account_uid")
        connection.execute(
            select(account_global_state.c.account_uid)
            .where(account_global_state.c.account_uid == str(resource.identity[0]))
            .with_for_update()
        ).first()

    def lock_player_state(connection, resource: ResourceKey) -> None:
        if len(resource.identity) != 1:
            raise ValueError("player_state requires one player_id")
        connection.execute(
            select(players.c.player_id)
            .where(players.c.player_id == int(resource.identity[0]))
            .with_for_update()
        ).first()

    registry.register(ResourceClass.ACCOUNT_GLOBAL, "account_global_state", lock_account_global)
    registry.register(ResourceClass.PLAYER, "player_state", lock_player_state)
    return registry
