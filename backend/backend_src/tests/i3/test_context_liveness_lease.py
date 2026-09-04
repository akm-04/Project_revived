from __future__ import annotations

from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from uuid import uuid4

import pytest

from gxb_backend.foundation.resource_keys import ResourceClass
from gxb_backend.identity.errors import ContextStale, CredentialInvalid
from gxb_backend.identity.models import AccountSessionSnapshot, GameplayContextSnapshot, IdentityPolicy
from gxb_backend.identity.service import GameplayContextAuthenticator

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


class Contexts:
    def __init__(self, resolved):
        self.resolved = resolved
        self.calls = 0

    def resolve_gameplay_digest(self, connection, *, credential_hash):
        self.calls += 1
        return self.resolved


class Sessions:
    def __init__(self, session):
        self.session = session
        self.touch_count = 0

    def validate_liveness(self, session, *, policy, now):
        from gxb_backend.identity.repositories import SessionRepository
        return SessionRepository.validate_liveness(session, policy=policy, now=now)

    def get_session(self, connection, session_id):
        return self.session

    def maybe_touch_activity(self, connection, *, session, policy, now):
        self.touch_count += 1
        return True


def snapshots(last_activity=NOW - timedelta(minutes=5)):
    session = AccountSessionSnapshot(
        uuid4(), "20000001", NOW - timedelta(hours=1), last_activity, NOW + timedelta(days=1), None
    )
    context = GameplayContextSnapshot(
        uuid4(), session.session_id, session.account_uid, 125, 12_500_001, NOW - timedelta(minutes=1)
    )
    return session, context


def test_read_only_gameplay_auth_revalidates_under_session_then_context_share_resources() -> None:
    session, context = snapshots()
    contexts = Contexts((session, context, NOW + timedelta(hours=1)))
    sessions = Sessions(session)
    coordinator = Coordinator()
    auth = GameplayContextAuthenticator(
        lambda: Engine(), coordinator, contexts=contexts, sessions=sessions, policy=POLICY, clock=lambda: NOW
    )
    result = auth.resolve(
        gameplay_token="token", supplied_region=125, request_id="r", auth_scope="SELECTED_PLAYER"
    )
    assert result.player_id == 12_500_001
    assert contexts.calls == 2  # candidate resolve + locked revalidation
    resources = coordinator.requests[0].resources
    assert [r.resource_class for r in resources] == [ResourceClass.SESSION, ResourceClass.CONTEXT]
    assert [r.kind for r in resources] == ["account_session_liveness", "gameplay_context_liveness"]
    assert sessions.touch_count == 0
    assert len(coordinator.requests) == 1


def test_gameplay_activity_touch_is_coalesced_and_uses_exclusive_session_resource_only_when_due() -> None:
    session, context = snapshots(last_activity=NOW - timedelta(minutes=20))
    contexts = Contexts((session, context, NOW + timedelta(hours=1)))
    sessions = Sessions(session)
    coordinator = Coordinator()
    auth = GameplayContextAuthenticator(
        lambda: Engine(), coordinator, contexts=contexts, sessions=sessions, policy=POLICY, clock=lambda: NOW
    )
    auth.resolve(gameplay_token="token", request_id="r", auth_scope="SELECTED_PLAYER")
    assert sessions.touch_count == 1
    assert len(coordinator.requests) == 2
    assert coordinator.requests[1].resources[0].kind == "account_session"


def test_prepared_lease_can_be_held_by_future_outer_mutation_and_detects_revocation_or_binding_change() -> None:
    session, context = snapshots()
    contexts = Contexts((session, context, NOW + timedelta(hours=1)))
    auth = GameplayContextAuthenticator(
        lambda: Engine(), Coordinator(), contexts=contexts, sessions=Sessions(session), policy=POLICY, clock=lambda: NOW
    )
    lease = auth.prepare_lease("token")
    assert lease.session_id == session.session_id
    assert lease.context_id == context.context_id

    contexts.resolved = None
    with pytest.raises(CredentialInvalid):
        auth.validate_lease(Tx(), lease, request_id="r", auth_scope="SELECTED_PLAYER")

    changed = GameplayContextSnapshot(
        uuid4(), session.session_id, session.account_uid, 125, 12_500_001, NOW
    )
    contexts.resolved = (session, changed, NOW + timedelta(hours=1))
    with pytest.raises(ContextStale):
        auth.validate_lease(Tx(), lease, request_id="r", auth_scope="SELECTED_PLAYER")
