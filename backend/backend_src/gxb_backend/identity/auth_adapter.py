"""Candidate relational adapter behind the Pass340 authentication-scope seam.

I3 deliberately leaves this adapter unwired from EngineDispatcher.  It is tested
as the future authority adapter and becomes runtime-active only at a later
strangler/cutover gate.
"""

from __future__ import annotations

from dataclasses import dataclass
from typing import Mapping, Any

from gxb_backend.auth.perimeter import AuthDecision, AuthScope

from .errors import IdentityError
from .models import AuthenticatedRequestContext
from .service import AccountSessionAuthenticator, GameplayContextAuthenticator


@dataclass(frozen=True, slots=True)
class RelationalAuthResult:
    decision: AuthDecision
    context: AuthenticatedRequestContext | None = None


class RelationalAuthAdapter:
    def __init__(
        self,
        account_authenticator: AccountSessionAuthenticator,
        gameplay_authenticator: GameplayContextAuthenticator,
    ) -> None:
        self.accounts = account_authenticator
        self.gameplay = gameplay_authenticator

    @staticmethod
    def _request_id(request: Mapping[str, Any]) -> str:
        value = request.get("request_id") or request.get("client_op_id") or "auth"
        return str(value)

    @staticmethod
    def _denied(scope: AuthScope | None, exc: IdentityError) -> RelationalAuthResult:
        return RelationalAuthResult(
            AuthDecision(
                False,
                scope,
                status_code=int(exc.status_code),
                error_class="auth",
                error_kind=str(exc.error_kind),
                message=str(exc),
            )
        )

    def authorize(self, scope: AuthScope | None, request: Mapping[str, Any]) -> RelationalAuthResult:
        request_id = self._request_id(request)
        if scope is None:
            return RelationalAuthResult(
                AuthDecision(
                    False,
                    None,
                    status_code=403,
                    error_class="authorization",
                    error_kind="AUTH_SCOPE_UNCLASSIFIED",
                    message="Request route is not assigned an authentication scope",
                )
            )
        if scope is AuthScope.PUBLIC_BOOTSTRAP:
            return RelationalAuthResult(
                AuthDecision(True, scope),
                AuthenticatedRequestContext(request_id=request_id, auth_scope=scope.value),
            )
        if scope in {AuthScope.ACCOUNT_SESSION, AuthScope.CONTEXT_SELECTION}:
            try:
                # Generic gameplay token is intentionally ignored on account-scope transitions.
                resolved = self.accounts.resolve(
                    sid=request.get("sid"),
                    login_token=request.get("login_token"),
                    request_id=request_id,
                )
            except IdentityError as exc:
                return self._denied(scope, exc)
            return RelationalAuthResult(
                AuthDecision(True, scope),
                AuthenticatedRequestContext(
                    request_id=request_id,
                    auth_scope=scope.value,
                    account_uid=resolved.account.account_uid,
                    session_id=resolved.session.session_id,
                ),
            )
        if scope in {AuthScope.SELECTED_PLAYER, AuthScope.REALTIME_ADMISSION}:
            try:
                # sid/login_token cannot choose a gameplay actor. The gameplay token
                # resolves one context directly; region is only a consistency fence.
                context = self.gameplay.resolve(
                    gameplay_token=request.get("token"),
                    supplied_region=request.get("region"),
                    request_id=request_id,
                    auth_scope=scope.value,
                )
            except IdentityError as exc:
                return self._denied(scope, exc)
            return RelationalAuthResult(AuthDecision(True, scope), context)
        return RelationalAuthResult(
            AuthDecision(
                False,
                scope,
                status_code=403,
                error_class="authorization",
                error_kind="AUTH_SCOPE_WRONG_INGRESS",
                message="Authentication scope is not valid on this adapter ingress",
            )
        )
