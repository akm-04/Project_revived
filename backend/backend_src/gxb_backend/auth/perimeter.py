"""Pass340 I1 explicit authentication scopes and legacy perimeter adapter.

I1 intentionally does *not* invent the I3 PostgreSQL session/context authority.
It gives the existing backend a default-deny ingress classification and a narrow
adapter over the still-canonical Pass299 JSON request binding.  I3 will replace
that adapter behind this seam with durable session/context repositories.
"""

from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Protocol

from gxb_backend.transport.result import EngineTransportResult


class AuthScope(str, Enum):
    PUBLIC_BOOTSTRAP = "PUBLIC_BOOTSTRAP"
    ACCOUNT_SESSION = "ACCOUNT_SESSION"
    CONTEXT_SELECTION = "CONTEXT_SELECTION"
    SELECTED_PLAYER = "SELECTED_PLAYER"
    REALTIME_ADMISSION = "REALTIME_ADMISSION"
    ADMIN_OPERATOR = "ADMIN_OPERATOR"


@dataclass(frozen=True, slots=True)
class AuthDecision:
    allowed: bool
    scope: AuthScope | None
    status_code: int = 200
    error_class: str | None = None
    error_kind: str | None = None
    message: str | None = None

    def transport_result(self) -> EngineTransportResult | None:
        if self.allowed:
            return None
        body: dict[str, object] = {
            "error_code": 1,
            "error_class": self.error_class or "authorization",
            "error_kind": self.error_kind or "AUTH_SCOPE_DENIED",
        }
        if self.message:
            body["error_msg"] = self.message
        return EngineTransportResult(body=body, status_code=int(self.status_code))


class BoundRequestState(Protocol):
    def has_authenticated_session(self) -> bool: ...
    def current_player_or_none(self): ...


class AuthScopeRegistry:
    """Classify HTTP engine MIDs; unclassified traffic is denied by default.

    Current source proves MID18 and MID1 are account/context-selection boundaries.
    The small public set is limited to login/bootstrap requests that are observed
    before player selection. Current src_64 plus Pass251/253 stock runtime evidence
    proves MID2864 (GET_PLAYER_GROUP_BY_KEY) occurs before MID1 and its handler is
    a context-free AB-test compatibility lookup, so it is public bootstrap traffic.  All other *known* engine MIDs are selected-player
    requests.  Unknown endpoints never silently become public.
    """

    PUBLIC_MIDS = frozenset({2, 7, 2_864, 20_480})
    ACCOUNT_SESSION_MIDS = frozenset({18})
    CONTEXT_SELECTION_MIDS = frozenset({1})

    def resolve(self, mid: int, *, known_engine_mid: bool) -> AuthScope | None:
        value = int(mid)
        if value in self.PUBLIC_MIDS:
            return AuthScope.PUBLIC_BOOTSTRAP
        if value in self.ACCOUNT_SESSION_MIDS:
            return AuthScope.ACCOUNT_SESSION
        if value in self.CONTEXT_SELECTION_MIDS:
            return AuthScope.CONTEXT_SELECTION
        if known_engine_mid:
            return AuthScope.SELECTED_PLAYER
        return None


class LegacyAuthPerimeter:
    """Default-deny I1 adapter over the already-bound Pass299 request snapshot.

    This adapter is deliberately mechanism-light.  It does not issue credentials,
    persist contexts, or query PostgreSQL; those are I3 responsibilities.  It only
    decides whether the current request may reach handler/domain code.
    """

    def authorize(self, scope: AuthScope | None, state: BoundRequestState) -> AuthDecision:
        if scope is None:
            return AuthDecision(
                False,
                None,
                status_code=403,
                error_class="authorization",
                error_kind="AUTH_SCOPE_UNCLASSIFIED",
                message="Request route is not assigned an authentication scope",
            )
        if scope is AuthScope.PUBLIC_BOOTSTRAP:
            return AuthDecision(True, scope)
        if scope in {AuthScope.ACCOUNT_SESSION, AuthScope.CONTEXT_SELECTION}:
            if state.has_authenticated_session():
                return AuthDecision(True, scope)
            return AuthDecision(
                False,
                scope,
                status_code=401,
                error_class="auth",
                error_kind="CREDENTIAL_INVALID",
                message="Invalid or expired account session",
            )
        if scope is AuthScope.SELECTED_PLAYER:
            if not state.has_authenticated_session():
                return AuthDecision(
                    False,
                    scope,
                    status_code=401,
                    error_class="auth",
                    error_kind="CREDENTIAL_INVALID",
                    message="Invalid or expired gameplay credential",
                )
            if state.current_player_or_none() is None:
                return AuthDecision(
                    False,
                    scope,
                    status_code=409,
                    error_class="auth",
                    error_kind="CONTEXT_STALE",
                    message="No selected player context is bound to this request",
                )
            return AuthDecision(True, scope)
        # ADMIN_OPERATOR and REALTIME_ADMISSION are explicit separate ingress
        # planes.  This HTTP adapter must never silently authorize them.
        return AuthDecision(
            False,
            scope,
            status_code=403,
            error_class="authorization",
            error_kind="AUTH_SCOPE_WRONG_INGRESS",
            message="Authentication scope is not valid on the engine HTTP ingress",
        )
