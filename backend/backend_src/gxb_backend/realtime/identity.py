"""Relational I5 TCP admission identity adapter.

The raw gameplay bearer is consumed only by GameplayContextAuthenticator and is
never retained in the returned realtime session identity.
"""
from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from gxb_backend.auth.perimeter import AuthScope
from gxb_backend.identity.errors import IdentityError
from gxb_backend.identity.service import GameplayContextAuthenticator

from .contracts import AuthenticatedPlayerIdentity


@dataclass(frozen=True, slots=True)
class RealtimePlayerMetadata:
    guild_id: int = 0


class RealtimePlayerMetadataResolver(Protocol):
    def resolve_realtime_metadata(self, player_id: int) -> RealtimePlayerMetadata | None: ...


class RelationalRealtimeIdentityResolver:
    """Resolve TCP_LOGIN against the durable context-bound gameplay credential."""

    def __init__(
        self,
        gameplay_authenticator: GameplayContextAuthenticator,
        player_metadata: RealtimePlayerMetadataResolver,
    ) -> None:
        self.gameplay = gameplay_authenticator
        self.player_metadata = player_metadata

    def resolve_realtime_identity(self, token: str, region: int) -> AuthenticatedPlayerIdentity | None:
        try:
            context = self.gameplay.resolve(
                gameplay_token=token,
                supplied_region=region,
                request_id="realtime-admission",
                auth_scope=AuthScope.REALTIME_ADMISSION.value,
            )
        except IdentityError:
            return None
        if (
            context.account_uid is None
            or context.session_id is None
            or context.context_id is None
            or context.region_id is None
            or context.player_id is None
        ):
            return None
        metadata = self.player_metadata.resolve_realtime_metadata(int(context.player_id))
        if metadata is None:
            return None
        return AuthenticatedPlayerIdentity(
            uid=str(context.account_uid),
            sid="",  # raw SID is not realtime authority in the relational path
            player_id=str(int(context.player_id)),
            region=int(context.region_id),
            guild_id=max(0, int(metadata.guild_id)),
            session_id=str(context.session_id),
            context_id=str(context.context_id),
        )
