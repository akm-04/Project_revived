"""Immutable contracts for authenticated realtime transport and publication."""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Mapping, Protocol, TypeAlias


class RealtimeRole(str, Enum):
    WORLD = "WORLD"
    SERVICE = "SERVICE"
    GUILD = "GUILD"


@dataclass(frozen=True, slots=True)
class AuthenticatedPlayerIdentity:
    """Immutable admission snapshot resolved from canonical backend identity state.

    ``session_id`` and ``context_id`` are non-secret durable identities added by
    Pass344.  ``sid`` remains for the sealed legacy runtime contract but the I5
    relational resolver deliberately returns it empty and never retains the raw
    gameplay bearer used during TCP_LOGIN.
    """

    uid: str
    sid: str
    player_id: str
    region: int
    guild_id: int
    session_id: str | None = None
    context_id: str | None = None


@dataclass(frozen=True, slots=True)
class RoomAdmission:
    role: RealtimeRole
    room_id: int


class RealtimeIdentityResolver(Protocol):
    def resolve_realtime_identity(self, token: str, region: int) -> AuthenticatedPlayerIdentity | None:
        """Resolve canonical authenticated identity without retaining request scope."""


@dataclass(frozen=True, slots=True)
class PlayerAudience:
    """Select authenticated sessions for one canonical player.

    Empty ``roles`` deliberately means the frozen R4 compatibility default:
    WORLD only.  Explicit multi-role delivery must be chosen by the owning
    domain/schema rather than broadcasting to every socket implicitly.
    """

    player_id: str
    roles: tuple[RealtimeRole, ...] = ()


@dataclass(frozen=True, slots=True)
class RoomAudience:
    role: RealtimeRole
    room_id: int


@dataclass(frozen=True, slots=True)
class SessionAudience:
    connection_id: str


RealtimeAudience: TypeAlias = PlayerAudience | RoomAudience | SessionAudience


@dataclass(frozen=True, slots=True)
class RealtimeEventIntent:
    """Fully domain-decided server event; never a gameplay mutation command."""

    mid: int
    params: Mapping[str, object]
    audience: RealtimeAudience
    owner_domain: str
    delivery_class: str
    schema_key: str | None = None
