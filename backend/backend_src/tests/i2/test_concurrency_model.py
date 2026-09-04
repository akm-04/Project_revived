from __future__ import annotations

import threading
import time
from collections import defaultdict

from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.foundation.resource_keys import ResourceClass, ResourceKey
from gxb_backend.transactions.coordinator import ResourceTransactionCoordinator, RetryPolicy
from gxb_backend.transactions.locking import ResourceLockRegistry


class LockingTransaction:
    def __init__(self, connection):
        self.connection = connection

    def __enter__(self):
        return self

    def __exit__(self, exc_type, exc, tb):
        self.connection.release_all()
        return False


class LockingConnection:
    def __init__(self, locks):
        self._locks = locks
        self._held = []

    def __enter__(self): return self
    def __exit__(self, exc_type, exc, tb): return False
    def begin(self): return LockingTransaction(self)

    def acquire(self, key):
        lock = self._locks[key]
        acquired = lock.acquire(timeout=2)
        if not acquired:
            raise TimeoutError(f"deadlock-model timeout acquiring {key}")
        self._held.append(lock)

    def release_all(self):
        for lock in reversed(self._held):
            lock.release()
        self._held.clear()


class LockingEngine:
    def __init__(self):
        self.locks = defaultdict(threading.Lock)

    def connect(self):
        return LockingConnection(self.locks)


def registry() -> ResourceLockRegistry:
    result = ResourceLockRegistry()
    for cls, kind in [
        (ResourceClass.SHARED, "shared"),
        (ResourceClass.PLAYER, "player"),
        (ResourceClass.CHILD, "child"),
    ]:
        result.register(cls, kind, lambda connection, key: connection.acquire(key))
    return result


def test_different_players_can_enter_transaction_body_concurrently() -> None:
    engine = LockingEngine()
    coordinator = ResourceTransactionCoordinator(
        lambda: engine, lock_registry=registry(), retry_policy=RetryPolicy(max_attempts=1)
    )
    barrier = threading.Barrier(2, timeout=2)
    entered = []
    errors = []

    def worker(player_id):
        try:
            coordinator.run(
                TransactionRequest(str(player_id), "local", (ResourceKey.player(player_id),)),
                lambda tx: (entered.append(player_id), barrier.wait()),
            )
        except Exception as exc:  # pragma: no cover - asserted below
            errors.append(exc)

    threads = [threading.Thread(target=worker, args=(1,)), threading.Thread(target=worker, args=(2,))]
    for thread in threads: thread.start()
    for thread in threads: thread.join(timeout=3)
    assert not errors
    assert sorted(entered) == [1, 2]
    assert all(not thread.is_alive() for thread in threads)


def test_same_player_transactions_serialize_in_model() -> None:
    engine = LockingEngine()
    coordinator = ResourceTransactionCoordinator(lambda: engine, lock_registry=registry())
    first_entered = threading.Event()
    allow_first_exit = threading.Event()
    second_entered = threading.Event()
    errors = []

    def first_body(tx):
        first_entered.set()
        assert allow_first_exit.wait(timeout=2)

    def second_body(tx):
        second_entered.set()

    def run_first():
        try:
            coordinator.run(TransactionRequest("1", "same", (ResourceKey.player(9),)), first_body)
        except Exception as exc: errors.append(exc)

    def run_second():
        try:
            coordinator.run(TransactionRequest("2", "same", (ResourceKey.player(9),)), second_body)
        except Exception as exc: errors.append(exc)

    t1 = threading.Thread(target=run_first)
    t2 = threading.Thread(target=run_second)
    t1.start()
    assert first_entered.wait(timeout=1)
    t2.start()
    time.sleep(0.05)
    assert not second_entered.is_set()
    allow_first_exit.set()
    t1.join(timeout=2); t2.join(timeout=2)
    assert second_entered.is_set()
    assert not errors


def test_opposite_declared_shared_resource_order_is_canonicalized_and_does_not_deadlock() -> None:
    engine = LockingEngine()
    coordinator = ResourceTransactionCoordinator(lambda: engine, lock_registry=registry())
    shared_a = ResourceKey.of(ResourceClass.SHARED, "shared", "A")
    shared_b = ResourceKey.of(ResourceClass.SHARED, "shared", "B")
    completed = []
    errors = []

    def worker(name, resources):
        try:
            coordinator.run(
                TransactionRequest(name, "multi-shared", resources),
                lambda tx: (time.sleep(0.02), completed.append(name)),
            )
        except Exception as exc: errors.append(exc)

    t1 = threading.Thread(target=worker, args=("one", (shared_a, shared_b, ResourceKey.player(1))))
    t2 = threading.Thread(target=worker, args=("two", (shared_b, shared_a, ResourceKey.player(2))))
    t1.start(); t2.start(); t1.join(timeout=3); t2.join(timeout=3)
    assert not errors
    assert sorted(completed) == ["one", "two"]
    assert not t1.is_alive() and not t2.is_alive()


def _order_in_worker(resources):
    from gxb_backend.foundation.resource_keys import order_resource_keys
    return [(int(key.resource_class), key.kind, key.identity) for key in order_resource_keys(resources)]


def test_independent_processes_derive_identical_canonical_lock_plan() -> None:
    from concurrent.futures import ProcessPoolExecutor
    from multiprocessing import get_context

    resources = (
        ResourceKey.player(10),
        ResourceKey.of(ResourceClass.SHARED, "shared", "B"),
        ResourceKey.player(2),
        ResourceKey.of(ResourceClass.CHILD, "child", "x"),
        ResourceKey.of(ResourceClass.SHARED, "shared", "A"),
    )
    with ProcessPoolExecutor(max_workers=2, mp_context=get_context("spawn")) as pool:
        one = pool.submit(_order_in_worker, resources)
        two = pool.submit(_order_in_worker, tuple(reversed(resources)))
        assert one.result(timeout=5) == two.result(timeout=5)
