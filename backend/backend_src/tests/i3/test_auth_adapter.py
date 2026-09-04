from __future__ import annotations

from datetime import datetime, timezone
from uuid import uuid4

from gxb_backend.auth.perimeter import AuthScope
from gxb_backend.identity.auth_adapter import RelationalAuthAdapter
from gxb_backend.identity.errors import ContextStale, CredentialInvalid
from gxb_backend.identity.models import (
    AccountPrincipal,
    AccountSessionSnapshot,
    AuthenticatedRequestContext,
    ResolvedAccountCredential,
)


NOW = datetime(2026, 9, 2, tzinfo=timezone.utc)


class AccountAuth:
    def __init__(self):
        self.calls = []
        self.session_id = uuid4()

    def resolve(self, **kwargs):
        self.calls.append(kwargs)
        if kwargs.get("sid") == "bad":
            raise CredentialInvalid("bad sid")
        session = AccountSessionSnapshot(
            self.session_id, "20000001", NOW, NOW, None, None
        )
        return ResolvedAccountCredential(
            AccountPrincipal("20000001", "normal", "alice"), session
        )


class GameplayAuth:
    def __init__(self):
        self.calls = []

    def resolve(self, **kwargs):
        self.calls.append(kwargs)
        if kwargs.get("gameplay_token") == "bad":
            raise ContextStale("stale")
        return AuthenticatedRequestContext(
            request_id=kwargs["request_id"],
            auth_scope=kwargs["auth_scope"],
            account_uid="20000001",
            session_id=uuid4(),
            context_id=uuid4(),
            region_id=125,
            player_id=12_500_001,
        )


def test_account_scope_uses_only_sid_login_token_and_ignores_generic_gameplay_token() -> None:
    account = AccountAuth()
    gameplay = GameplayAuth()
    adapter = RelationalAuthAdapter(account, gameplay)
    result = adapter.authorize(
        AuthScope.CONTEXT_SELECTION,
        {"sid": "sid-1", "login_token": "login-1", "token": "must-ignore", "region": 125},
    )
    assert result.decision.allowed
    assert result.context and result.context.player_id is None
    assert account.calls[0]["sid"] == "sid-1"
    assert account.calls[0]["login_token"] == "login-1"
    assert "token" not in account.calls[0]
    assert not gameplay.calls


def test_selected_player_scope_uses_only_gameplay_token_and_region_as_consistency_fence() -> None:
    account = AccountAuth()
    gameplay = GameplayAuth()
    adapter = RelationalAuthAdapter(account, gameplay)
    result = adapter.authorize(
        AuthScope.SELECTED_PLAYER,
        {"sid": "must-ignore", "login_token": "must-ignore", "token": "game", "region": 125},
    )
    assert result.decision.allowed
    assert result.context and result.context.player_id == 12_500_001
    assert gameplay.calls[0]["gameplay_token"] == "game"
    assert gameplay.calls[0]["supplied_region"] == 125
    assert not account.calls


def test_public_bootstrap_never_opportunistically_authenticates() -> None:
    account = AccountAuth()
    gameplay = GameplayAuth()
    adapter = RelationalAuthAdapter(account, gameplay)
    result = adapter.authorize(
        AuthScope.PUBLIC_BOOTSTRAP,
        {"sid": "bad", "token": "bad", "region": 999},
    )
    assert result.decision.allowed
    assert result.context and result.context.account_uid is None
    assert not account.calls and not gameplay.calls


def test_unclassified_admin_and_invalid_credentials_fail_closed() -> None:
    adapter = RelationalAuthAdapter(AccountAuth(), GameplayAuth())
    assert adapter.authorize(None, {}).decision.error_kind == "AUTH_SCOPE_UNCLASSIFIED"
    assert adapter.authorize(AuthScope.ADMIN_OPERATOR, {}).decision.error_kind == "AUTH_SCOPE_WRONG_INGRESS"
    denied = adapter.authorize(AuthScope.ACCOUNT_SESSION, {"sid": "bad"})
    assert not denied.decision.allowed
    assert denied.decision.status_code == 401
    assert denied.decision.error_kind == "CREDENTIAL_INVALID"
