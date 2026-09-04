"""Pass348 I9 live PostgreSQL concurrency, idempotency, and crash proofs.

These tests deliberately exercise separate SQLAlchemy connections.  They are
valid while the I8 process-global HTTP RLock is still present and prove the
database transaction kernel before that compatibility lock is retired.
"""
from __future__ import annotations

import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
from threading import Barrier, Event
from uuid import uuid4

import pytest
from sqlalchemy import delete, func, select, text, update
from sqlalchemy.dialects.postgresql import insert

from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.foundation.database import DatabaseSettings, ProcessEngineProvider
from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.identity.errors import IdentityError
from gxb_backend.identity.locking import register_i3_identity_lockers
from gxb_backend.identity.models import IdentityPolicy
from gxb_backend.identity.repositories import RegionDirectoryRepository
from gxb_backend.identity.schema import accounts, gameplay_contexts, players as identity_players, regions
from gxb_backend.identity.service import (
    AccountSessionAuthenticator,
    ContextSelectionService,
    GameplayContextAuthenticator,
    IdentityService,
)
from gxb_backend.mail.locking import register_i6_mail_lockers
from gxb_backend.mail.models import MailDeliveryIntent
from gxb_backend.mail.repository import MailRepository
from gxb_backend.mail.schema import mail_items
from gxb_backend.persistence.locking import player_state_resource, register_i4_persistence_lockers
from gxb_backend.persistence.schema import players
from gxb_backend.transactions.coordinator import ResourceTransactionCoordinator
from gxb_backend.transactions.jobs import ScheduledJobRepository
from gxb_backend.transactions.locking import ResourceLockRegistry
from gxb_backend.transactions.models import DeliveryClass, OutboxIntent, ReceiptKey, ScheduledJobIntent
from gxb_backend.transactions.outbox import OutboxRepository
from gxb_backend.transactions.receipts import ReceiptRepository, canonical_request_fingerprint
from gxb_backend.transactions.schema import operation_receipts, outbox_events, scheduled_jobs


pytestmark = pytest.mark.postgresql
_SAFE_DATABASE = re.compile(r"^[a-z_][a-z0-9_]{0,62}(?:test|_test)$")


def _settings() -> DatabaseSettings:
    raw_url = os.environ.get("GXB_TEST_DATABASE_URL", "")
    if not raw_url:
        pytest.skip("GXB_TEST_DATABASE_URL not configured")
    settings = DatabaseSettings.from_env({"GXB_DATABASE_URL": raw_url})
    assert _SAFE_DATABASE.fullmatch(settings.url.database or "")
    return settings


def _provider() -> ProcessEngineProvider:
    return ProcessEngineProvider(_settings())


def _coordinator(provider: ProcessEngineProvider) -> ResourceTransactionCoordinator:
    locks = register_i6_mail_lockers(
        register_i4_persistence_lockers(register_i3_identity_lockers(ResourceLockRegistry()))
    )
    return ResourceTransactionCoordinator(
        provider.engine,
        lock_registry=locks,
        outbox_repository=OutboxRepository(),
        job_repository=ScheduledJobRepository(),
    )


def _seed_region(connection, region_id: int) -> None:
    connection.execute(
        insert(regions)
        .values(
            region_id=region_id,
            name=f"I9-{region_id}",
            next_player_id=region_id * 100_000 + 1,
            max_player_id=region_id * 100_000 + 99_999,
            allow_new_players=True,
            metadata={},
        )
        .on_conflict_do_nothing(index_elements=[regions.c.region_id])
    )


def _seed_account(connection, account_uid: str) -> None:
    connection.execute(
        accounts.insert().values(
            account_uid=account_uid,
            account_type="normal",
            username=f"i9-{account_uid}",
            metadata={},
        )
    )


def _seed_counter_players(provider: ProcessEngineProvider) -> tuple[int, int]:
    region_id = 991
    nonce = uuid4().int % 10_000
    player_ids = (region_id * 100_000 + 10_000 + nonce * 2, region_id * 100_000 + 10_001 + nonce * 2)
    account_uids = (f"i9-row-{uuid4().hex}", f"i9-row-{uuid4().hex}")
    with provider.engine().begin() as connection:
        _seed_region(connection, region_id)
        for account_uid, player_id in zip(account_uids, player_ids, strict=True):
            _seed_account(connection, account_uid)
            connection.execute(
                identity_players.insert().values(
                    player_id=player_id,
                    account_uid=account_uid,
                    region_id=region_id,
                    created_at=datetime.now(timezone.utc),
                )
            )
            connection.execute(
                update(players)
                .where(players.c.player_id == player_id)
                .values(
                    schema_version=1,
                    state_version=0,
                    payload={"i9_counter": 0},
                    updated_at=datetime.now(timezone.utc),
                )
            )
    return player_ids


def _counter(connection, player_id: int) -> int:
    return int(connection.scalar(select(players.c.state_version).where(players.c.player_id == player_id)))


def _increment(connection, player_id: int) -> int:
    value = _counter(connection, player_id)
    connection.execute(
        update(players).where(players.c.player_id == player_id).values(state_version=value + 1)
    )
    return value + 1


def test_independent_players_overlap_while_same_player_serializes() -> None:
    provider = _provider()
    try:
        first, second = _seed_counter_players(provider)
        coordinator = _coordinator(provider)
        first_locked = Event()
        release_first = Event()
        second_committed = Event()

        def hold_first() -> None:
            request = TransactionRequest("i9-independent-a", "i9.probe", (player_state_resource(first),))
            with coordinator.begin(request) as tx:
                _increment(tx.connection, first)
                first_locked.set()
                assert release_first.wait(5)

        def update_second() -> None:
            assert first_locked.wait(5)
            request = TransactionRequest("i9-independent-b", "i9.probe", (player_state_resource(second),))
            with coordinator.begin(request) as tx:
                _increment(tx.connection, second)
            second_committed.set()

        with ThreadPoolExecutor(max_workers=2) as pool:
            held = pool.submit(hold_first)
            independent = pool.submit(update_second)
            assert second_committed.wait(2), "distinct PLAYER rows were globally serialized"
            release_first.set()
            held.result(timeout=5)
            independent.result(timeout=5)

        same_locked = Event()
        release_same = Event()
        second_entered = Event()

        def same_a() -> None:
            request = TransactionRequest("i9-same-a", "i9.probe", (player_state_resource(first),))
            with coordinator.begin(request) as tx:
                _increment(tx.connection, first)
                same_locked.set()
                assert release_same.wait(5)

        def same_b() -> None:
            assert same_locked.wait(5)
            request = TransactionRequest("i9-same-b", "i9.probe", (player_state_resource(first),))
            with coordinator.begin(request) as tx:
                second_entered.set()
                _increment(tx.connection, first)

        with ThreadPoolExecutor(max_workers=2) as pool:
            held = pool.submit(same_a)
            waiting = pool.submit(same_b)
            assert not second_entered.wait(0.25), "same PLAYER row lock did not serialize"
            release_same.set()
            held.result(timeout=5)
            waiting.result(timeout=5)

        with provider.engine().connect() as connection:
            assert _counter(connection, first) == 3
            assert _counter(connection, second) == 1
    finally:
        provider.dispose()


def test_reversed_multi_player_inputs_canonicalize_without_deadlock() -> None:
    provider = _provider()
    try:
        first, second = _seed_counter_players(provider)
        coordinator = _coordinator(provider)
        start = Barrier(2)

        def mutate(name: str, ordered_ids: tuple[int, int]) -> None:
            start.wait(timeout=5)
            request = TransactionRequest(
                f"i9-order-{name}",
                "i9.multi-player",
                tuple(player_state_resource(player_id) for player_id in ordered_ids),
            )
            with coordinator.begin(request) as tx:
                for player_id in ordered_ids:
                    _increment(tx.connection, player_id)

        with ThreadPoolExecutor(max_workers=2) as pool:
            left = pool.submit(mutate, "left", (first, second))
            right = pool.submit(mutate, "right", (second, first))
            left.result(timeout=10)
            right.result(timeout=10)
        with provider.engine().connect() as connection:
            assert (_counter(connection, first), _counter(connection, second)) == (2, 2)
    finally:
        provider.dispose()


def test_region_allocator_and_context_supersession_converge() -> None:
    provider = _provider()
    try:
        coordinator = _coordinator(provider)
        policy = IdentityPolicy(
            absolute_session_ttl=timedelta(days=30),
            idle_session_ttl=timedelta(days=1),
            activity_write_interval=timedelta(seconds=60),
        )
        identity = IdentityService(provider.engine, coordinator, policy=policy)
        account_auth = AccountSessionAuthenticator(provider.engine, coordinator, policy=policy)
        selection = ContextSelectionService(provider.engine, coordinator, account_auth)
        context_auth = GameplayContextAuthenticator(provider.engine, coordinator, policy=policy)
        region_id = 992
        account_uids = tuple(f"i9-alloc-{uuid4().hex}" for _ in range(12))
        with provider.engine().begin() as connection:
            _seed_region(connection, region_id)
            initial_next_id = int(
                connection.scalar(select(regions.c.next_player_id).where(regions.c.region_id == region_id))
            )
            for account_uid in account_uids:
                _seed_account(connection, account_uid)
        issued = tuple(
            identity.issue_fresh_anonymous_session(account_uid=uid, request_id=f"i9-session-{uid}")
            for uid in account_uids
        )
        start = Barrier(len(issued))

        def choose(index: int):
            start.wait(timeout=10)
            session = issued[index]
            return selection.select(
                region_id=region_id,
                request_id=f"i9-allocator-{index}",
                sid=session.sid,
                login_token=session.login_token,
            )

        with ThreadPoolExecutor(max_workers=len(issued)) as pool:
            selected = tuple(pool.map(choose, range(len(issued))))
        allocated_ids = {item.player_id for item in selected}
        assert len(allocated_ids) == len(issued)
        assert all(player_id // 100_000 == region_id for player_id in allocated_ids)
        with provider.engine().connect() as connection:
            next_id = connection.scalar(select(regions.c.next_player_id).where(regions.c.region_id == region_id))
            assert int(next_id) == initial_next_id + len(issued)

        one = issued[0]
        start_two = Barrier(2)

        def supersede(index: int):
            start_two.wait(timeout=5)
            return selection.select(
                region_id=region_id,
                request_id=f"i9-context-{index}",
                sid=one.sid,
                login_token=one.login_token,
                client_operation_id=f"i9-context-op-{index}",
            )

        with ThreadPoolExecutor(max_workers=2) as pool:
            results = tuple(pool.map(supersede, range(2)))
        resolved = 0
        stale = 0
        for result in results:
            try:
                context_auth.resolve(
                    gameplay_token=result.gameplay_token,
                    supplied_region=region_id,
                    request_id="i9-context-validate",
                    auth_scope="I9_PROBE",
                )
                resolved += 1
            except IdentityError:
                stale += 1
        assert (resolved, stale) == (1, 1)
        with provider.engine().connect() as connection:
            active = connection.scalar(
                select(func.count()).select_from(gameplay_contexts).where(
                    gameplay_contexts.c.session_id == results[0].session_id,
                    gameplay_contexts.c.ended_at.is_(None),
                )
            )
            assert int(active) == 1
    finally:
        provider.dispose()


def test_context_transition_waits_for_inflight_gameplay_liveness_lease() -> None:
    provider = _provider()
    try:
        coordinator = _coordinator(provider)
        policy = IdentityPolicy(
            absolute_session_ttl=timedelta(days=30),
            idle_session_ttl=timedelta(days=1),
            activity_write_interval=timedelta(seconds=60),
        )
        identity = IdentityService(provider.engine, coordinator, policy=policy)
        account_auth = AccountSessionAuthenticator(provider.engine, coordinator, policy=policy)
        selection = ContextSelectionService(provider.engine, coordinator, account_auth)
        context_auth = GameplayContextAuthenticator(provider.engine, coordinator, policy=policy)
        region_id = 993
        account_uid = f"i9-lease-{uuid4().hex}"
        with provider.engine().begin() as connection:
            _seed_region(connection, region_id)
            _seed_account(connection, account_uid)
        session = identity.issue_fresh_anonymous_session(
            account_uid=account_uid, request_id="i9-lease-session"
        )
        initial = selection.select(
            region_id=region_id,
            request_id="i9-lease-initial",
            sid=session.sid,
            login_token=session.login_token,
        )
        lease = context_auth.prepare_lease(initial.gameplay_token)
        validated = Event()
        release_gameplay = Event()
        transition_done = Event()

        def gameplay() -> None:
            request = TransactionRequest(
                "i9-inflight-gameplay",
                "i9.gameplay-liveness",
                context_auth.lease_resources(lease),
            )
            with coordinator.begin(request) as tx:
                context_auth.validate_lease(
                    tx,
                    lease,
                    supplied_region=region_id,
                    request_id=request.request_id,
                    auth_scope="I9_PROBE",
                )
                validated.set()
                assert release_gameplay.wait(5)

        def transition() -> None:
            assert validated.wait(5)
            selection.select(
                region_id=region_id,
                request_id="i9-lease-replacement",
                sid=session.sid,
                login_token=session.login_token,
            )
            transition_done.set()

        with ThreadPoolExecutor(max_workers=2) as pool:
            active = pool.submit(gameplay)
            replacement = pool.submit(transition)
            assert validated.wait(5)
            assert not transition_done.wait(0.25), "context changed beneath an active gameplay lease"
            release_gameplay.set()
            active.result(timeout=5)
            replacement.result(timeout=5)
        with pytest.raises(IdentityError):
            context_auth.resolve(
                gameplay_token=initial.gameplay_token,
                supplied_region=region_id,
                request_id="i9-old-context",
                auth_scope="I9_PROBE",
            )
    finally:
        provider.dispose()


def test_receipt_mail_job_and_queue_idempotency_under_race() -> None:
    provider = _provider()
    try:
        key_id = uuid4().hex
        receipt_key = ReceiptKey("player", key_id, "i9", "once", key_id)
        fingerprint = canonical_request_fingerprint({"key": key_id})
        barrier = Barrier(2)

        def write_receipt(index: int) -> bool:
            barrier.wait(timeout=5)
            with provider.engine().begin() as connection:
                _, replayed = ReceiptRepository().record_or_replay(
                    connection,
                    key=receipt_key,
                    request_fingerprint=fingerprint,
                    result={"winner": "semantic", "index_ignored": True},
                )
                return replayed

        with ThreadPoolExecutor(max_workers=2) as pool:
            receipt_results = tuple(pool.map(write_receipt, range(2)))
        assert sorted(receipt_results) == [False, True]

        player_id = _seed_counter_players(provider)[0]
        delivery_key = f"i9-mail-{key_id}"
        mail_intent = MailDeliveryIntent(
            player_id=player_id,
            delivery_key=delivery_key,
            source_type="I9",
            source_id=delivery_key,
            protocol_payload={"title": "I9"},
            protocol_mail_id=700_000_000 + (uuid4().int % 100_000_000),
        )
        barrier = Barrier(2)

        def deliver_mail(index: int) -> bool:
            barrier.wait(timeout=5)
            with provider.engine().begin() as connection:
                _, duplicate = MailRepository().deliver(connection, mail_intent)
                return duplicate

        with ThreadPoolExecutor(max_workers=2) as pool:
            delivery_results = tuple(pool.map(deliver_mail, range(2)))
        assert sorted(delivery_results) == [False, True]

        dedupe_due_at = datetime.now(timezone.utc) + timedelta(hours=1)
        job_intent = ScheduledJobIntent(
            dedupe_key=f"i9-job-{key_id}",
            job_type="I9_PROBE",
            scope_type="global",
            scope_id=key_id,
            due_at=dedupe_due_at,
            payload={"key": key_id},
        )
        barrier = Barrier(2)

        def schedule_job(index: int) -> bool:
            barrier.wait(timeout=5)
            with provider.engine().begin() as connection:
                _, duplicate = ScheduledJobRepository().schedule(connection, job_intent)
                return duplicate

        with ThreadPoolExecutor(max_workers=2) as pool:
            schedule_results = tuple(pool.map(schedule_job, range(2)))
        assert sorted(schedule_results) == [False, True]

        outbox = OutboxRepository()
        jobs = ScheduledJobRepository()
        due_at = datetime.now(timezone.utc) - timedelta(seconds=1)
        with provider.engine().begin() as connection:
            # This suite intentionally supports repeated execution against the
            # same disposable test database.  Remove only prior I9 queue probes
            # so expired leases cannot consume this run's bounded claim batch.
            connection.execute(delete(scheduled_jobs).where(scheduled_jobs.c.job_type == "I9_CLAIM"))
            connection.execute(delete(outbox_events).where(outbox_events.c.topic == "i9.queue"))
            outbox_ids = outbox.enqueue(
                connection,
                (
                    OutboxIntent(
                        topic="i9.queue",
                        resource_kind="probe",
                        resource_key=f"{key_id}-{index}",
                        payload={"index": index},
                        delivery_class=DeliveryClass.DURABLE_USER_DELIVERY,
                    )
                    for index in range(20)
                ),
            )
            for index in range(20):
                jobs.schedule(
                    connection,
                    ScheduledJobIntent(
                        dedupe_key=f"i9-claim-{key_id}-{index}",
                        job_type="I9_CLAIM",
                        scope_type="probe",
                        scope_id=str(index),
                        due_at=due_at,
                        payload={"index": index},
                        priority=-2_000_000_000,
                    ),
                )

        barrier = Barrier(4)

        def claim(worker: int) -> tuple[tuple[int, ...], tuple[int, ...]]:
            barrier.wait(timeout=5)
            with provider.engine().begin() as connection:
                claimed_outbox = outbox.claim_available(
                    connection,
                    worker_id=f"i9-outbox-{worker}",
                    limit=5,
                    delivery_classes=(DeliveryClass.DURABLE_USER_DELIVERY,),
                )
                claimed_jobs = jobs.claim_due(
                    connection,
                    worker_id=f"i9-job-{worker}",
                    lease_seconds=30,
                    limit=5,
                )
                return (
                    tuple(int(row["event_id"]) for row in claimed_outbox if int(row["event_id"]) in outbox_ids),
                    tuple(int(row["job_id"]) for row in claimed_jobs if str(row["dedupe_key"]).startswith(f"i9-claim-{key_id}-")),
                )

        with ThreadPoolExecutor(max_workers=4) as pool:
            claims = tuple(pool.map(claim, range(4)))
        claimed_outbox_ids = tuple(item for row in claims for item in row[0])
        claimed_job_ids = tuple(item for row in claims for item in row[1])
        assert len(claimed_outbox_ids) == len(set(claimed_outbox_ids)) == 20
        assert len(claimed_job_ids) == len(set(claimed_job_ids)) == 20

        with provider.engine().connect() as connection:
            assert int(connection.scalar(select(func.count()).select_from(operation_receipts).where(operation_receipts.c.idempotency_key == key_id))) == 1
            assert int(connection.scalar(select(func.count()).select_from(mail_items).where(mail_items.c.delivery_key == delivery_key))) == 1
            assert int(connection.scalar(select(func.count()).select_from(scheduled_jobs).where(scheduled_jobs.c.dedupe_key == f"i9-job-{key_id}"))) == 1
    finally:
        provider.dispose()


def test_process_death_rolls_back_uncommitted_and_preserves_committed_outbox() -> None:
    settings = _settings()
    provider = ProcessEngineProvider(settings)
    try:
        url = settings.url.set(drivername="postgresql").render_as_string(hide_password=False)
        rollback_key = f"i9-crash-rollback-{uuid4().hex}"
        commit_key = f"i9-crash-commit-{uuid4().hex}"
        script = r'''
import os, sys
import psycopg
url, key, commit = sys.argv[1:]
with psycopg.connect(url) as connection:
    with connection.cursor() as cursor:
        cursor.execute(
            "INSERT INTO gxb.outbox_events "
            "(topic,resource_kind,resource_key,payload,delivery_class,priority,dispatch_state) "
            "VALUES ('i9.crash','probe',%s,'{}'::jsonb,'DURABLE_USER_DELIVERY',100,'PENDING')",
            (key,),
        )
    if commit == "1":
        connection.commit()
    os._exit(73)
'''
        rolled_back = subprocess.run(
            [sys.executable, "-c", script, url, rollback_key, "0"], check=False
        )
        committed = subprocess.run(
            [sys.executable, "-c", script, url, commit_key, "1"], check=False
        )
        assert rolled_back.returncode == committed.returncode == 73
        with provider.engine().begin() as connection:
            count_rollback = connection.scalar(
                select(func.count()).select_from(outbox_events).where(outbox_events.c.resource_key == rollback_key)
            )
            count_commit = connection.scalar(
                select(func.count()).select_from(outbox_events).where(outbox_events.c.resource_key == commit_key)
            )
            claimed = OutboxRepository().claim_available(
                connection,
                worker_id="i9-restart",
                limit=100,
                delivery_classes=(DeliveryClass.DURABLE_USER_DELIVERY,),
            )
        assert int(count_rollback) == 0
        assert int(count_commit) == 1
        assert any(str(row["resource_key"]) == commit_key for row in claimed)
    finally:
        provider.dispose()
