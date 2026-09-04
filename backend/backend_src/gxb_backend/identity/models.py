"""Typed Pass342 identity/session/context snapshots and results."""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta
from enum import StrEnum
from typing import Any, Mapping
from uuid import UUID


class CredentialKind(StrEnum):
    SDK_SID_COMPAT = "SDK_SID_COMPAT"
    LOGIN_TOKEN = "LOGIN_TOKEN"
    GAMEPLAY_TOKEN = "GAMEPLAY_TOKEN"


@dataclass(frozen=True, slots=True)
class IdentityPolicy:
    """Deployment-configurable lifecycle policy; Pass331 did not freeze TTL values."""

    absolute_session_ttl: timedelta | None
    idle_session_ttl: timedelta | None
    activity_write_interval: timedelta

    def __post_init__(self) -> None:
        for name in ("absolute_session_ttl", "idle_session_ttl"):
            value = getattr(self, name)
            if value is not None and value.total_seconds() <= 0:
                raise ValueError(f"{name} must be positive or None")
        if self.activity_write_interval.total_seconds() <= 0:
            raise ValueError("activity_write_interval must be positive")
        if (
            self.idle_session_ttl is not None
            and self.activity_write_interval >= self.idle_session_ttl
        ):
            raise ValueError("activity_write_interval must be safely smaller than idle_session_ttl")


@dataclass(frozen=True, slots=True)
class AccountPrincipal:
    account_uid: str
    account_type: str
    username: str


@dataclass(frozen=True, slots=True)
class AccountSessionSnapshot:
    session_id: UUID
    account_uid: str
    issued_at: datetime
    last_activity_at: datetime
    absolute_expires_at: datetime | None
    revoked_at: datetime | None
    revocation_reason: str | None = None
    device_metadata: Mapping[str, Any] | None = None


@dataclass(frozen=True, slots=True)
class PlayerDirectorySnapshot:
    player_id: int
    account_uid: str
    region_id: int
    created_at: datetime


@dataclass(frozen=True, slots=True)
class GameplayContextSnapshot:
    context_id: UUID
    session_id: UUID
    account_uid: str
    region_id: int
    player_id: int
    created_at: datetime
    ended_at: datetime | None = None
    end_reason: str | None = None
    superseded_by_context_id: UUID | None = None


@dataclass(frozen=True, slots=True)
class ContextLivenessLease:
    """Non-secret candidate identity used to reacquire session/context liveness in an outer transaction."""

    credential_hash: bytes
    session_id: UUID
    context_id: UUID
    account_uid: str
    region_id: int
    player_id: int
    last_activity_at: datetime


@dataclass(frozen=True, slots=True)
class AuthenticatedRequestContext:
    request_id: str
    auth_scope: str
    account_uid: str | None = None
    session_id: UUID | None = None
    context_id: UUID | None = None
    region_id: int | None = None
    player_id: int | None = None


@dataclass(frozen=True, slots=True)
class ResolvedAccountCredential:
    account: AccountPrincipal
    session: AccountSessionSnapshot
    credential_expires_at: datetime | None = None


@dataclass(frozen=True, slots=True)
class IssuedSession:
    account: AccountPrincipal
    session: AccountSessionSnapshot
    sid: str
    login_token: str


@dataclass(frozen=True, slots=True)
class ContextSelectionResult:
    account_uid: str
    session_id: UUID
    context_id: UUID
    region_id: int
    player_id: int
    gameplay_token: str
    is_new_player: bool


@dataclass(frozen=True, slots=True)
class RegionSnapshot:
    region_id: int
    name: str
    next_player_id: int
    max_player_id: int
    allow_new_players: bool
    metadata: Mapping[str, Any] = field(default_factory=dict)

    @property
    def allocated_cursor(self) -> int:
        return max(self.region_id * 100_000, self.next_player_id - 1)

    @property
    def is_full_for_new_players(self) -> bool:
        return (not self.allow_new_players) or self.next_player_id > self.max_player_id
