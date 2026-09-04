"""I3 canonical-row lock registrations for Pass341 ResourceTransaction."""

from __future__ import annotations

from sqlalchemy import select

from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.transactions.locking import ResourceLockRegistry

from .schema import account_credentials, account_sessions, gameplay_contexts, players, regions


def _one_identity(resource: ResourceKey):
    if len(resource.identity) != 1:
        raise ValueError(f"{resource.kind} requires exactly one identity part")
    return resource.identity[0]


def register_i3_identity_lockers(registry: ResourceLockRegistry) -> ResourceLockRegistry:
    """Register only real I3 canonical rows; no generic lock table exists."""

    def lock_account_credential(connection, resource: ResourceKey) -> None:
        subject = str(_one_identity(resource))
        connection.execute(
            select(account_credentials.c.credential_id)
            .where(
                account_credentials.c.provider == "LOCAL_PASSWORD",
                account_credentials.c.subject_normalized == subject,
            )
            .with_for_update()
        ).first()

    def lock_session_update(connection, resource: ResourceKey) -> None:
        session_id = _one_identity(resource)
        connection.execute(
            select(account_sessions.c.session_id)
            .where(account_sessions.c.session_id == session_id)
            .with_for_update()
        ).first()

    def lock_session_share(connection, resource: ResourceKey) -> None:
        session_id = _one_identity(resource)
        connection.execute(
            select(account_sessions.c.session_id)
            .where(account_sessions.c.session_id == session_id)
            .with_for_update(read=True)
        ).first()

    def lock_active_context_update(connection, resource: ResourceKey) -> None:
        session_id = _one_identity(resource)
        connection.execute(
            select(gameplay_contexts.c.context_id)
            .where(
                gameplay_contexts.c.session_id == session_id,
                gameplay_contexts.c.ended_at.is_(None),
            )
            .with_for_update()
        ).first()

    def lock_context_share(connection, resource: ResourceKey) -> None:
        context_id = _one_identity(resource)
        connection.execute(
            select(gameplay_contexts.c.context_id)
            .where(gameplay_contexts.c.context_id == context_id)
            .with_for_update(read=True)
        ).first()

    def lock_region_allocator(connection, resource: ResourceKey) -> None:
        region_id = int(_one_identity(resource))
        connection.execute(
            select(regions.c.region_id)
            .where(regions.c.region_id == region_id)
            .with_for_update()
        ).first()

    def lock_player_directory_share(connection, resource: ResourceKey) -> None:
        player_id = int(_one_identity(resource))
        connection.execute(
            select(players.c.player_id)
            .where(players.c.player_id == player_id)
            .with_for_update(read=True)
        ).first()

    registry.register(ResourceClass.SESSION, "account_credential", lock_account_credential)
    registry.register(ResourceClass.SESSION, "account_session", lock_session_update)
    registry.register(ResourceClass.SESSION, "account_session_liveness", lock_session_share)
    registry.register(ResourceClass.CONTEXT, "active_context_for_session", lock_active_context_update)
    registry.register(ResourceClass.CONTEXT, "gameplay_context_liveness", lock_context_share)
    registry.register(ResourceClass.REGION, "region_allocator", lock_region_allocator)
    registry.register(ResourceClass.PLAYER, "player_directory", lock_player_directory_share)
    return registry
