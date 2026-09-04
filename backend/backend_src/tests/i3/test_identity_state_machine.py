from __future__ import annotations

import threading
from contextlib import contextmanager
from datetime import datetime, timedelta, timezone
from types import SimpleNamespace
from uuid import UUID, uuid4

import pytest
from sqlalchemy.exc import IntegrityError

from gxb_backend.foundation.resource_keys import ResourceClass, order_resource_keys
from gxb_backend.identity.credentials import PasswordCredentialService
from gxb_backend.identity.errors import AccountConflict, ContextStale, RegionFull
from gxb_backend.identity.models import (
    AccountPrincipal,
    AccountSessionSnapshot,
    GameplayContextSnapshot,
    IdentityPolicy,
    PlayerDirectorySnapshot,
    RegionSnapshot,
    ResolvedAccountCredential,
)
from gxb_backend.identity.service import (
    ContextSelectionService,
    IdentityService,
    RegionDirectoryService,
    SessionRevocationService,
)

NOW = datetime(2026, 9, 2, 12, 0, tzinfo=timezone.utc)
POLICY = IdentityPolicy(timedelta(days=7), timedelta(days=1), timedelta(minutes=10))


class ReadConnection:
    in_transaction = False


class TxConnection:
    in_transaction = True


class Engine:
    @contextmanager
    def connect(self):
        yield ReadConnection()


class Transaction:
    def __init__(self):
        self.connection = TxConnection()
        self.outbox = []

    def stage_outbox(self, intent):
        self.outbox.append(intent)


class LockingCoordinator:
    """Logic-only stand-in for ResourceTransaction canonical resource locking."""

    def __init__(self):
        self._guard = threading.Lock()
        self._locks = {}
        self.requests = []
        self.outbox = []

    def _lock(self, resource):
        key = (resource.resource_class, resource.kind, resource.identity)
        with self._guard:
            return self._locks.setdefault(key, threading.RLock())

    def run(self, request, operation):
        request_resources = order_resource_keys(request.resources)
        self.requests.append(tuple(request_resources))
        locks = [self._lock(resource) for resource in request_resources]
        for lock in locks:
            lock.acquire()
        try:
            tx = Transaction()
            result = operation(tx)
            self.outbox.extend(tx.outbox)
            return result
        finally:
            for lock in reversed(locks):
                lock.release()


class SessionStore:
    def __init__(self, sessions):
        self.sessions = {item.session_id: item for item in sessions}
        self.revoked = set()

    def get_session(self, connection, session_id):
        return self.sessions.get(session_id)

    def validate_liveness(self, session, *, policy, now):
        from gxb_backend.identity.repositories import SessionRepository

        return SessionRepository.validate_liveness(session, policy=policy, now=now)

    def maybe_touch_activity(self, connection, *, session, policy, now):
        return False

    def revoke_session(self, connection, *, session_id, revoked_at, reason):
        item = self.sessions[session_id]
        self.sessions[session_id] = AccountSessionSnapshot(
            item.session_id,
            item.account_uid,
            item.issued_at,
            item.last_activity_at,
            item.absolute_expires_at,
            revoked_at,
            reason,
            item.device_metadata,
        )
        self.revoked.add(session_id)
        return True


class AccountAuthenticator:
    def __init__(self, sessions: SessionStore, sid_map):
        self.sessions = sessions
        self.policy = POLICY
        self.sid_map = dict(sid_map)

    def resolve(self, *, sid=None, login_token=None, request_id=None, touch_activity=True):
        del request_id, touch_activity
        key = str(sid or login_token or "")
        session = self.sessions.sessions[self.sid_map[key]]
        self.sessions.validate_liveness(session, policy=self.policy, now=NOW)
        return ResolvedAccountCredential(
            AccountPrincipal(session.account_uid, "normal", "alice"), session
        )


class ContextStore:
    def __init__(self):
        self.by_session = {}
        self.by_id = {}
        self.revoked_gameplay = set()
        self.gameplay_credentials = {}

    def get_active_for_session(self, connection, session_id):
        context = self.by_session.get(session_id)
        return context if context is not None and context.ended_at is None else None

    def end_context(self, connection, *, context_id, ended_at, reason, superseded_by_context_id=None):
        old = self.by_id[context_id]
        ended = GameplayContextSnapshot(
            old.context_id,
            old.session_id,
            old.account_uid,
            old.region_id,
            old.player_id,
            old.created_at,
            ended_at,
            reason,
            superseded_by_context_id,
        )
        self.by_id[context_id] = ended
        self.by_session[old.session_id] = ended
        return True

    def set_superseded_by(self, connection, *, context_id, superseded_by_context_id):
        old = self.by_id[context_id]
        assert old.ended_at is not None
        assert superseded_by_context_id in self.by_id, "new FK target must exist before superseded link"
        linked = GameplayContextSnapshot(
            old.context_id,
            old.session_id,
            old.account_uid,
            old.region_id,
            old.player_id,
            old.created_at,
            old.ended_at,
            old.end_reason,
            superseded_by_context_id,
        )
        self.by_id[context_id] = linked
        return True

    def revoke_gameplay_credentials(self, connection, *, context_id, revoked_at):
        del revoked_at
        self.revoked_gameplay.add(context_id)
        return 1

    def create_context(self, connection, *, context_id, session_id, account_uid, region_id, player_id, created_at):
        context = GameplayContextSnapshot(
            context_id, session_id, account_uid, region_id, player_id, created_at
        )
        self.by_id[context_id] = context
        self.by_session[session_id] = context

    def create_gameplay_credential(
        self,
        connection,
        *,
        credential_id,
        credential_hash,
        session_id,
        context_id,
        issued_at,
        expires_at,
    ):
        self.gameplay_credentials[context_id] = {
            "credential_id": credential_id,
            "credential_hash": credential_hash,
            "session_id": session_id,
            "issued_at": issued_at,
            "expires_at": expires_at,
        }

    def resolve_gameplay_digest(self, connection, *, credential_hash):
        del connection
        for context_id, row in self.gameplay_credentials.items():
            if row["credential_hash"] != credential_hash or context_id in self.revoked_gameplay:
                continue
            context = self.by_id.get(context_id)
            if context is None or context.ended_at is not None:
                continue
            session = SimpleNamespace(session_id=row["session_id"], account_uid=context.account_uid)
            return session, context, row["expires_at"]
        return None


class Directory:
    def __init__(self, barrier=None):
        self.players = {}
        self.next_id = {125: 12_500_001, 126: 12_600_001}
        self.full = set()
        self.allocations = 0
        self.barrier = barrier
        self._barrier_hits = 0
        self._guard = threading.Lock()

    def find_player(self, connection, *, account_uid, region_id):
        key = (str(account_uid), int(region_id))
        if not getattr(connection, "in_transaction", False) and self.barrier is not None:
            # Capture the pre-read before releasing either caller, so this probe
            # deterministically models two processes that both observe "absent".
            observed = self.players.get(key)
            with self._guard:
                self._barrier_hits += 1
                should_wait = self._barrier_hits <= 2
            if should_wait:
                self.barrier.wait(timeout=5)
            return observed
        return self.players.get(key)

    def allocate_player(self, connection, *, account_uid, region_id, created_at):
        key = (str(account_uid), int(region_id))
        if key in self.players:
            return self.players[key]
        if int(region_id) in self.full:
            raise RegionFull("full")
        player_id = self.next_id[int(region_id)]
        self.next_id[int(region_id)] += 1
        item = PlayerDirectorySnapshot(player_id, str(account_uid), int(region_id), created_at)
        self.players[key] = item
        self.allocations += 1
        return item

    def list_regions(self, connection):
        return (RegionSnapshot(125, "Deep Valley", self.next_id[125], 12_599_999, True),)

    def list_account_players(self, connection, account_uid):
        return tuple(v for (uid, _), v in self.players.items() if uid == str(account_uid))


def make_session(account_uid="20000001"):
    return AccountSessionSnapshot(
        uuid4(), account_uid, NOW - timedelta(hours=1), NOW, NOW + timedelta(days=1), None
    )


def make_context_service(*, sessions, sid_map, directory=None, contexts=None, coordinator=None):
    session_store = SessionStore(sessions)
    auth = AccountAuthenticator(session_store, sid_map)
    return ContextSelectionService(
        lambda: Engine(),
        coordinator or LockingCoordinator(),
        auth,
        sessions=session_store,
        contexts=contexts or ContextStore(),
        directory=directory or Directory(),
        clock=lambda: NOW,
    )


def test_same_account_same_region_concurrent_first_creation_allocates_exactly_one_player() -> None:
    s1, s2 = make_session(), make_session()
    barrier = threading.Barrier(2)
    directory = Directory(barrier=barrier)
    contexts = ContextStore()
    coordinator = LockingCoordinator()
    service = make_context_service(
        sessions=(s1, s2),
        sid_map={"s1": s1.session_id, "s2": s2.session_id},
        directory=directory,
        contexts=contexts,
        coordinator=coordinator,
    )
    results = []
    errors = []

    def run(sid):
        try:
            results.append(service.select(region_id=125, request_id=sid, sid=sid))
        except Exception as exc:  # pragma: no cover - diagnostic path
            errors.append(exc)

    t1 = threading.Thread(target=run, args=("s1",))
    t2 = threading.Thread(target=run, args=("s2",))
    t1.start(); t2.start(); t1.join(5); t2.join(5)
    assert not t1.is_alive() and not t2.is_alive()
    assert not errors
    assert directory.allocations == 1
    assert {result.player_id for result in results} == {12_500_001}
    assert sorted(result.is_new_player for result in results) == [False, True]
    region_requests = [
        resources for resources in coordinator.requests
        if any(r.resource_class is ResourceClass.REGION for r in resources)
    ]
    assert len(region_requests) == 2




def test_same_session_concurrent_first_mid1_does_not_revoke_winning_context() -> None:
    session = make_session()
    barrier = threading.Barrier(2)
    directory = Directory(barrier=barrier)
    contexts = ContextStore()
    coordinator = LockingCoordinator()
    service = make_context_service(
        sessions=(session,),
        sid_map={"sid": session.session_id},
        directory=directory,
        contexts=contexts,
        coordinator=coordinator,
    )
    results = []
    errors = []

    def run(label):
        try:
            results.append(
                service.select(
                    region_id=125, request_id=label, sid="sid", login_token="login-token"
                )
            )
        except Exception as exc:
            errors.append(exc)

    a = threading.Thread(target=run, args=("mid1-a",))
    b = threading.Thread(target=run, args=("mid1-b",))
    a.start(); b.start(); a.join(5); b.join(5)
    assert not a.is_alive() and not b.is_alive()
    assert not errors
    assert directory.allocations == 1
    assert len({row.context_id for row in results}) == 1
    assert len({row.gameplay_token for row in results}) == 1
    assert not contexts.revoked_gameplay
    assert len(contexts.gameplay_credentials) == 1


def test_same_session_reselection_rotates_context_and_token_after_fk_target_exists() -> None:
    session = make_session()
    directory = Directory()
    player = PlayerDirectorySnapshot(12_500_001, session.account_uid, 125, NOW)
    directory.players[(session.account_uid, 125)] = player
    contexts = ContextStore()
    old = GameplayContextSnapshot(
        uuid4(), session.session_id, session.account_uid, 125, player.player_id, NOW - timedelta(minutes=5)
    )
    contexts.by_session[session.session_id] = old
    contexts.by_id[old.context_id] = old
    service = make_context_service(
        sessions=(session,), sid_map={"s": session.session_id}, directory=directory, contexts=contexts
    )

    result = service.select(region_id=125, request_id="rotate", sid="s")
    assert result.player_id == player.player_id
    assert not result.is_new_player
    assert result.context_id != old.context_id
    assert len(result.gameplay_token) == 64
    ended = contexts.by_id[old.context_id]
    assert ended.ended_at == NOW
    assert ended.superseded_by_context_id == result.context_id
    assert old.context_id in contexts.revoked_gameplay
    assert contexts.by_session[session.session_id].context_id == result.context_id




def test_same_session_same_region_reentrant_mid1_reuses_context_and_bearer() -> None:
    session = make_session()
    directory = Directory()
    directory.players[(session.account_uid, 125)] = PlayerDirectorySnapshot(
        12_500_001, session.account_uid, 125, NOW
    )
    contexts = ContextStore()
    service = make_context_service(
        sessions=(session,), sid_map={"sid": session.session_id}, directory=directory, contexts=contexts
    )

    first = service.select(
        region_id=125, request_id="mid1-a", sid="sid", login_token="login-token"
    )
    second = service.select(
        region_id=125, request_id="mid1-b", sid="sid", login_token="login-token"
    )

    assert second.context_id == first.context_id
    assert second.gameplay_token == first.gameplay_token
    assert first.context_id not in contexts.revoked_gameplay
    assert contexts.by_session[session.session_id].ended_at is None
    assert len(contexts.gameplay_credentials) == 1


def test_full_region_blocks_new_character_but_not_existing_character_selection() -> None:
    session = make_session()
    directory = Directory()
    directory.full.add(125)
    service = make_context_service(
        sessions=(session,), sid_map={"s": session.session_id}, directory=directory
    )
    with pytest.raises(RegionFull):
        service.select(region_id=125, request_id="new-full", sid="s")

    directory.players[(session.account_uid, 125)] = PlayerDirectorySnapshot(
        12_500_111, session.account_uid, 125, NOW
    )
    selected = service.select(region_id=125, request_id="existing-full", sid="s")
    assert selected.player_id == 12_500_111
    assert not selected.is_new_player


def test_mid18_directory_revalidates_session_inside_share_lease() -> None:
    session = make_session()
    store = SessionStore((session,))
    auth = AccountAuthenticator(store, {"s": session.session_id})
    coordinator = LockingCoordinator()
    directory = Directory()
    directory.players[(session.account_uid, 125)] = PlayerDirectorySnapshot(
        12_500_001, session.account_uid, 125, NOW
    )
    service = RegionDirectoryService(
        lambda: Engine(), coordinator, auth, directory=directory, sessions=store, clock=lambda: NOW
    )
    result = service.load_for_account(sid="s", request_id="mid18")
    assert result.account_uid == session.account_uid
    assert result.players[0].player_id == 12_500_001
    resource = coordinator.requests[-1][0]
    assert resource.resource_class is ResourceClass.SESSION
    assert resource.kind == "account_session_liveness"


def test_session_revocation_ends_active_context_revokes_credentials_and_stages_durable_control() -> None:
    session = make_session()
    store = SessionStore((session,))
    auth = AccountAuthenticator(store, {"s": session.session_id})
    contexts = ContextStore()
    active = GameplayContextSnapshot(
        uuid4(), session.session_id, session.account_uid, 125, 12_500_001, NOW - timedelta(minutes=5)
    )
    contexts.by_id[active.context_id] = active
    contexts.by_session[session.session_id] = active
    coordinator = LockingCoordinator()
    service = SessionRevocationService(
        coordinator, auth, sessions=store, contexts=contexts, clock=lambda: NOW
    )
    assert service.revoke(request_id="logout", reason="manual", sid="s")
    assert session.session_id in store.revoked
    assert contexts.by_id[active.context_id].end_reason == "SESSION_REVOKED"
    assert active.context_id in contexts.revoked_gameplay
    assert coordinator.outbox[-1].topic == "identity.session_invalidated"
    assert coordinator.outbox[-1].context_id == active.context_id


class FakeAccountRepository:
    def __init__(self):
        self.next_uid = 20_000_001
        self.rows = {}
        self.principals = {}
        self.upgrades = []
        self.raise_unique_after_create = False

    def next_account_uid(self, connection):
        value = str(self.next_uid)
        self.next_uid += 1
        return value

    def get_local_credential(self, connection, subject):
        return self.rows.get(subject)

    def create_local_account(self, connection, **kwargs):
        subject = kwargs["subject_normalized"]
        principal = AccountPrincipal(kwargs["account_uid"], kwargs.get("account_type", "normal"), kwargs["username"])
        self.principals[principal.account_uid] = principal
        self.rows[subject] = {
            "credential_id": kwargs["credential_id"],
            "account_uid": principal.account_uid,
            "provider": "LOCAL_PASSWORD",
            "subject_normalized": subject,
            "password_hash": kwargs["password_hash"],
            "password_algorithm": kwargs["password_algorithm"],
            "password_version": 1,
            "enabled": True,
            "account_type": principal.account_type,
            "username": principal.username,
        }
        if self.raise_unique_after_create:
            self.raise_unique_after_create = False
            raise IntegrityError("insert", {}, Exception("unique"))
        return principal

    def upgrade_password(self, connection, *, credential_id, password_hash, password_algorithm, updated_at):
        for row in self.rows.values():
            if row["credential_id"] == credential_id:
                row["password_hash"] = password_hash
                row["password_algorithm"] = password_algorithm
                row["password_version"] += 1
                self.upgrades.append((credential_id, updated_at))
                return True
        return False

    def get_principal(self, connection, account_uid):
        return self.principals.get(account_uid)


class FakeSessionRepository:
    def __init__(self):
        self.created = []

    def create_session(self, connection, **kwargs):
        item = AccountSessionSnapshot(
            kwargs["session_id"], kwargs["account_uid"], kwargs["issued_at"], kwargs["issued_at"],
            kwargs["absolute_expires_at"], None, device_metadata=kwargs["device_metadata"]
        )
        self.created.append((item, kwargs))
        return item


def identity_service(accounts=None, sessions=None):
    accounts = accounts or FakeAccountRepository()
    sessions = sessions or FakeSessionRepository()
    return IdentityService(
        lambda: Engine(), LockingCoordinator(), accounts=accounts, sessions=sessions,
        policy=POLICY, clock=lambda: NOW
    ), accounts, sessions


def test_registration_is_idempotent_for_same_credentials_and_conflicts_for_different_password() -> None:
    service, accounts, _ = identity_service()
    first = service.register_local(username="Alice@Example.com", password="secret", request_id="r1")
    second = service.register_local(username="alice@example.com", password="secret", request_id="r2")
    assert first.account_uid == second.account_uid
    with pytest.raises(AccountConflict):
        service.register_local(username="ALICE@example.com", password="different", request_id="r3")


def test_concurrent_unique_registration_loser_reconciles_same_committed_credential() -> None:
    accounts = FakeAccountRepository()
    accounts.raise_unique_after_create = True
    service, _, _ = identity_service(accounts=accounts)
    result = service.register_local(username="alice", password="secret", request_id="race")
    assert result.account_uid == "20000001"


def test_login_issues_independent_sessions_and_upgrades_legacy_pbkdf2_in_same_credential_transaction() -> None:
    service, accounts, sessions = identity_service()
    principal = service.register_local(username="alice", password="secret", request_id="register")
    # Replace the stored modern hash with a real Pass299-compatible PBKDF2 record.
    import hashlib
    salt = bytes.fromhex("00112233445566778899aabbccddeeff")
    digest = hashlib.pbkdf2_hmac("sha256", b"secret", salt, 200_000)
    row = accounts.rows["alice"]
    row["password_hash"] = PasswordCredentialService.encode_legacy_pbkdf2(
        iterations=200_000, salt_hex=salt.hex(), hash_hex=digest.hex()
    )
    row["password_algorithm"] = PasswordCredentialService.LEGACY_ALGORITHM

    first = service.login_local(username="alice", password="secret", request_id="l1")
    second = service.login_local(username="alice", password="secret", request_id="l2")
    assert first.account.account_uid == principal.account_uid
    assert first.session.session_id != second.session.session_id
    assert first.sid != second.sid and first.login_token != second.login_token
    assert len(sessions.created) == 2
    assert accounts.rows["alice"]["password_algorithm"] == PasswordCredentialService.ARGON2_ALGORITHM
    assert accounts.upgrades


class ReplayCoordinator:
    """Run the same retry-safe operation twice against rollback-like fake stores."""

    def __init__(self):
        self.requests = []

    def run(self, request, operation):
        self.requests.append(request)
        first = operation(Transaction())
        second = operation(Transaction())
        self.first_result = first
        return second


class RollbackLikeContextStore(ContextStore):
    """Record writes but expose the same pre-attempt state on every retry."""

    def __init__(self):
        super().__init__()
        self.context_creates = []
        self.credential_creates = []

    def get_active_for_session(self, connection, session_id):
        return None

    def create_context(self, connection, *, context_id, session_id, account_uid, region_id, player_id, created_at):
        self.context_creates.append((context_id, session_id, account_uid, region_id, player_id, created_at))

    def create_gameplay_credential(self, connection, **kwargs):
        self.credential_creates.append(dict(kwargs))


class ExistingDirectory(Directory):
    def __init__(self, player):
        super().__init__()
        self.player = player

    def find_player(self, connection, *, account_uid, region_id):
        return self.player


class FixedBearer:
    def __init__(self, raw="g" * 64, digest=b"d" * 32):
        self.raw = raw
        self.digest = digest


class FixedBearerIssuer:
    def __init__(self):
        self.calls = 0
        self.value = FixedBearer()

    def gameplay_token(self):
        self.calls += 1
        return self.value

    def gameplay_token_for_context(self, **_kwargs):
        self.calls += 1
        return self.value


def test_mid1_retry_reuses_context_id_and_gameplay_credential_material() -> None:
    session = make_session()
    player = PlayerDirectorySnapshot(12_500_001, session.account_uid, 125, NOW)
    coordinator = ReplayCoordinator()
    contexts = RollbackLikeContextStore()
    issuer = FixedBearerIssuer()
    ids = iter(
        [
            UUID("11111111-1111-1111-1111-111111111111"),
            UUID("22222222-2222-2222-2222-222222222222"),
        ]
    )
    session_store = SessionStore((session,))
    auth = AccountAuthenticator(session_store, {"sid": session.session_id})
    service = ContextSelectionService(
        lambda: Engine(),
        coordinator,
        auth,
        sessions=session_store,
        contexts=contexts,
        directory=ExistingDirectory(player),
        bearer_issuer=issuer,
        clock=lambda: NOW,
        uuid_factory=lambda: next(ids),
    )

    result = service.select(region_id=125, request_id="retry", sid="sid", client_operation_id="op-7")

    assert coordinator.first_result.context_id == result.context_id == UUID(
        "11111111-1111-1111-1111-111111111111"
    )
    assert coordinator.first_result.gameplay_token == result.gameplay_token == "g" * 64
    assert issuer.calls == 1
    assert [row[0] for row in contexts.context_creates] == [result.context_id, result.context_id]
    assert [row["credential_id"] for row in contexts.credential_creates] == [
        UUID("22222222-2222-2222-2222-222222222222"),
        UUID("22222222-2222-2222-2222-222222222222"),
    ]
    assert [row["credential_hash"] for row in contexts.credential_creates] == [b"d" * 32, b"d" * 32]
    assert coordinator.requests[0].client_operation_id == "op-7"


class ConcurrentRegionDirectory(Directory):
    def __init__(self, barrier):
        super().__init__()
        self.tx_barrier = barrier

    def allocate_player(self, connection, *, account_uid, region_id, created_at):
        # If unrelated REGION locks are incorrectly serialized, one caller can
        # never reach this barrier and the test fails instead of masking it.
        self.tx_barrier.wait(timeout=3)
        return super().allocate_player(
            connection, account_uid=account_uid, region_id=region_id, created_at=created_at
        )


def test_different_region_allocators_can_progress_independently() -> None:
    s1, s2 = make_session(), make_session()
    barrier = threading.Barrier(2)
    directory = ConcurrentRegionDirectory(barrier)
    coordinator = LockingCoordinator()
    service = make_context_service(
        sessions=(s1, s2),
        sid_map={"s1": s1.session_id, "s2": s2.session_id},
        directory=directory,
        contexts=ContextStore(),
        coordinator=coordinator,
    )
    results = []
    errors = []

    def run(sid, region):
        try:
            results.append(service.select(region_id=region, request_id=sid, sid=sid))
        except Exception as exc:  # pragma: no cover - diagnostic path
            errors.append(exc)

    a = threading.Thread(target=run, args=("s1", 125))
    b = threading.Thread(target=run, args=("s2", 126))
    a.start(); b.start(); a.join(5); b.join(5)
    assert not a.is_alive() and not b.is_alive()
    assert errors == []
    assert {item.region_id for item in results} == {125, 126}
    assert directory.allocations == 2


def test_login_whole_transaction_retry_reuses_password_verification_upgrade_and_session_material() -> None:
    from gxb_backend.identity.credentials import PasswordVerification

    class CountingPasswords:
        ARGON2_ALGORITHM = "argon2id"
        LEGACY_ALGORITHM = "pbkdf2-sha256"

        def __init__(self):
            self.verify_calls = 0

        def verify(self, *, algorithm, encoded_hash, password):
            assert (algorithm, encoded_hash, password) == ("pbkdf2-sha256", "legacy", "secret")
            self.verify_calls += 1
            return PasswordVerification(True, upgraded_hash="stable-upgrade", upgraded_algorithm="argon2id")

        def hash_new(self, password):  # pragma: no cover - login only
            raise AssertionError("registration hashing not expected")

    class RollbackUpgradeAccountRepository(FakeAccountRepository):
        def upgrade_password(self, connection, *, credential_id, password_hash, password_algorithm, updated_at):
            # Model a retry after rollback: record the attempted upgrade but keep
            # the pre-attempt credential row visible to the next attempt.
            self.upgrades.append((credential_id, updated_at, password_hash, password_algorithm))
            return True

    accounts = RollbackUpgradeAccountRepository()
    credential_id = uuid4()
    accounts.rows["alice"] = {
        "credential_id": credential_id,
        "account_uid": "20000001",
        "provider": "LOCAL_PASSWORD",
        "subject_normalized": "alice",
        "password_hash": "legacy",
        "password_algorithm": "pbkdf2-sha256",
        "password_version": 1,
        "enabled": True,
        "account_type": "normal",
        "username": "alice",
    }
    accounts.principals["20000001"] = AccountPrincipal("20000001", "normal", "alice")
    sessions = FakeSessionRepository()
    coordinator = ReplayCoordinator()
    passwords = CountingPasswords()
    service = IdentityService(
        lambda: Engine(),
        coordinator,
        accounts=accounts,
        sessions=sessions,
        passwords=passwords,
        policy=POLICY,
        clock=lambda: NOW,
    )

    result = service.login_local(username="alice", password="secret", request_id="retry-login")

    assert passwords.verify_calls == 1
    assert len(sessions.created) == 2
    assert sessions.created[0][0].session_id == sessions.created[1][0].session_id == result.session.session_id
    assert sessions.created[0][1]["sid_digest"] == sessions.created[1][1]["sid_digest"]
    assert sessions.created[0][1]["login_digest"] == sessions.created[1][1]["login_digest"]
