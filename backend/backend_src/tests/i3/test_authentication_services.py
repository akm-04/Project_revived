from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest

from gxb_backend.foundation.resource_keys import ResourceClass
from gxb_backend.identity.credentials import credential_digest
from gxb_backend.identity.errors import ContextStale, CredentialInvalid, CredentialMismatch
from gxb_backend.identity.models import (
    AccountPrincipal,
    AccountSessionSnapshot,
    CredentialKind,
    GameplayContextSnapshot,
    IdentityPolicy,
    ResolvedAccountCredential,
)
from gxb_backend.identity.service import AccountSessionAuthenticator, GameplayContextAuthenticator


NOW = datetime(2026, 9, 2, 12, 0, tzinfo=timezone.utc)
POLICY = IdentityPolicy(timedelta(days=7), timedelta(days=1), timedelta(minutes=10))


class Engine:
    @contextmanager
    def connect(self):
        yield object()


class Tx:
    def __init__(self):
        self.connection = object()


class Coordinator:
    def __init__(self):
        self.requests = []

    def run(self, request, operation):
        self.requests.append(request)
        return operation(Tx())


class Sessions:
    def __init__(self, sid_resolution, login_resolution=None):
        self.sid_resolution = sid_resolution
        self.login_resolution = login_resolution or sid_resolution
        self.touch_count = 0

    def resolve_credential_digest(self, connection, *, kind, credential_hash):
        assert len(credential_hash) == 32
        if kind is CredentialKind.SDK_SID_COMPAT:
            return self.sid_resolution
        return self.login_resolution

    def validate_liveness(self, session, *, policy, now):
        from gxb_backend.identity.repositories import SessionRepository
        return SessionRepository.validate_liveness(session, policy=policy, now=now)

    def get_session(self, connection, session_id):
        return self.sid_resolution.session

    def maybe_touch_activity(self, connection, *, session, policy, now):
        self.touch_count += 1
        return True


def resolved(*, session_id=None, last_activity=None, credential_expires_at=None):
    session = AccountSessionSnapshot(
        session_id or uuid4(),
        "20000001",
        NOW - timedelta(hours=2),
        last_activity or NOW - timedelta(minutes=5),
        NOW + timedelta(days=1),
        None,
    )
    return ResolvedAccountCredential(
        AccountPrincipal("20000001", "normal", "alice"),
        session,
        credential_expires_at,
    )


def test_account_auth_sid_only_and_sid_plus_login_same_session_are_supported() -> None:
    item = resolved()
    sessions = Sessions(item)
    coordinator = Coordinator()
    auth = AccountSessionAuthenticator(
        lambda: Engine(), coordinator, sessions=sessions, policy=POLICY, clock=lambda: NOW
    )
    assert auth.resolve(sid="sid", touch_activity=False).session.session_id == item.session.session_id
    assert auth.resolve(sid="sid", login_token="login", touch_activity=False).session.session_id == item.session.session_id


def test_account_auth_rejects_credential_pair_from_different_sessions() -> None:
    sessions = Sessions(resolved(), resolved())
    auth = AccountSessionAuthenticator(
        lambda: Engine(), Coordinator(), sessions=sessions, policy=POLICY, clock=lambda: NOW
    )
    with pytest.raises(CredentialMismatch):
        auth.resolve(sid="sid", login_token="login", touch_activity=False)


def test_account_auth_rejects_expired_credential_and_missing_credentials() -> None:
    expired = resolved(credential_expires_at=NOW)
    auth = AccountSessionAuthenticator(
        lambda: Engine(), Coordinator(), sessions=Sessions(expired), policy=POLICY, clock=lambda: NOW
    )
    with pytest.raises(CredentialInvalid):
        auth.resolve(sid="sid", touch_activity=False)
    with pytest.raises(CredentialInvalid):
        auth.resolve(touch_activity=False)


def test_account_auth_coalesces_activity_through_session_resource_transaction() -> None:
    item = resolved(last_activity=NOW - timedelta(minutes=20))
    sessions = Sessions(item)
    coordinator = Coordinator()
    auth = AccountSessionAuthenticator(
        lambda: Engine(), coordinator, sessions=sessions, policy=POLICY, clock=lambda: NOW
    )
    auth.resolve(sid="sid", request_id="r1", touch_activity=True)
    assert sessions.touch_count == 1
    assert len(coordinator.requests) == 1
    resource = coordinator.requests[0].resources[0]
    assert resource.resource_class is ResourceClass.SESSION
    assert resource.kind == "account_session"
    assert resource.identity == (item.session.session_id,)


class Contexts:
    def __init__(self, value):
        self.value = value
        self.last_digest = None

    def resolve_gameplay_digest(self, connection, *, credential_hash):
        self.last_digest = credential_hash
        return self.value


class LiveSessions:
    def __init__(self):
        self.touches = 0
        self._session = None

    def validate_liveness(self, session, *, policy, now):
        self._session = session
        return None

    def get_session(self, connection, session_id):
        return self._session

    def maybe_touch_activity(self, connection, *, session, policy, now):
        self.touches += 1
        return True


def test_gameplay_auth_token_directly_binds_actor_and_region_never_selects_actor() -> None:
    session = resolved().session
    context = GameplayContextSnapshot(
        uuid4(), session.session_id, session.account_uid, 125, 12_500_001, NOW
    )
    contexts = Contexts((session, context, NOW + timedelta(hours=1)))
    auth = GameplayContextAuthenticator(
        lambda: Engine(), Coordinator(), contexts=contexts, sessions=LiveSessions(), policy=POLICY, clock=lambda: NOW
    )
    result = auth.resolve(
        gameplay_token="game-token", supplied_region=125, request_id="r", auth_scope="SELECTED_PLAYER"
    )
    assert result.player_id == 12_500_001
    assert result.region_id == 125
    assert contexts.last_digest == credential_digest(CredentialKind.GAMEPLAY_TOKEN, "game-token")
    with pytest.raises(ContextStale):
        auth.resolve(
            gameplay_token="game-token", supplied_region=126, request_id="r", auth_scope="SELECTED_PLAYER"
        )


def test_gameplay_auth_rejects_ended_context_and_expired_credential() -> None:
    session = resolved().session
    ended = GameplayContextSnapshot(
        uuid4(), session.session_id, session.account_uid, 125, 12_500_001, NOW - timedelta(hours=1), ended_at=NOW
    )
    auth = GameplayContextAuthenticator(
        lambda: Engine(), Coordinator(), contexts=Contexts((session, ended, NOW + timedelta(hours=1))), sessions=LiveSessions(), policy=POLICY, clock=lambda: NOW
    )
    with pytest.raises(ContextStale):
        auth.resolve(gameplay_token="x", supplied_region=125, request_id="r", auth_scope="SELECTED_PLAYER")
    live = GameplayContextSnapshot(uuid4(), session.session_id, session.account_uid, 125, 12_500_001, NOW)
    auth = GameplayContextAuthenticator(
        lambda: Engine(), Coordinator(), contexts=Contexts((session, live, NOW)), sessions=LiveSessions(), policy=POLICY, clock=lambda: NOW
    )
    with pytest.raises(CredentialInvalid):
        auth.resolve(gameplay_token="x", supplied_region=125, request_id="r", auth_scope="SELECTED_PLAYER")


def test_gameplay_repository_defensively_rejects_cross_session_context_binding() -> None:
    from gxb_backend.identity.repositories import ContextRepository

    session_id = uuid4()
    other_session_id = uuid4()

    class MappingResult:
        def mappings(self):
            return self

        def first(self):
            return {
                "credential_revoked_at": None,
                "session_id": session_id,
                "account_uid": "20000001",
                "context_session_id": other_session_id,
                "context_account_uid": "20000001",
            }

    class Connection:
        def __init__(self):
            self.statement = None

        def execute(self, statement):
            self.statement = statement
            return MappingResult()

    connection = Connection()
    assert ContextRepository().resolve_gameplay_digest(
        connection, credential_hash=b"x" * 32
    ) is None
    compiled = str(
        connection.statement.compile(
            dialect=__import__("sqlalchemy.dialects.postgresql", fromlist=["dialect"]).dialect(),
            compile_kwargs={"literal_binds": True},
        )
    ).lower()
    assert "session_credentials.session_id = gxb.gameplay_contexts.session_id" in compiled
