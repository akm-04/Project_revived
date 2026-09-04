from __future__ import annotations

from dataclasses import replace
from types import SimpleNamespace

import pytest

from gxb_backend.persistence.codec import PlayerPayloadCodec
from gxb_backend.persistence.store import TransactionBoundPostgresPlayerStateStore, relational_player_sub_uow
from gxb_backend.persistence.locking import player_state_resource
from gxb_backend.foundation.contracts import TransactionRequest
from gxb_backend.state.persistence_state import ensure_persistence_state
from gxb_backend.state.profiles import make_fresh_player
from gxb_backend.state.unit_of_work import OperationContext


def _player(version=4):
    p = make_fresh_player(account_uid="20000001", player_id="12500001", region=125, region_name="Deep Valley")
    p.player_name = "Before"
    ensure_persistence_state(p)["state_version"] = version
    return p


class _Repo:
    def __init__(self, player=None):
        self.record = PlayerPayloadCodec.transform(player or _player()).record
        self.saves = []

    def load_for_update(self, tx, player_id):
        assert player_id == 12_500_001
        return self.record

    def save(self, tx, record, *, expected_state_version):
        self.saves.append((tx, record, expected_state_version))
        self.record = record
        return record


def _base():
    return make_fresh_player(account_uid="base", player_id="1", region=1, region_name="Local-1")



def _tx(player_id=12_500_001):
    request = TransactionRequest(request_id="i4-test", operation_name="mutate", resources=(player_state_resource(player_id),), retry_safe=False)
    return SimpleNamespace(request=request)

def _op():
    return OperationContext(actor_player_id="12500001", domain="i4-test", operation_name="mutate", protocol_mid=17)


def test_postgres_store_fails_closed_without_outer_resource_transaction_binding() -> None:
    store = TransactionBoundPostgresPlayerStateStore(_Repo(), _base)
    with pytest.raises(RuntimeError, match="active ResourceTransaction"):
        store.load(12_500_001)


def test_existing_player_uow_commits_as_subtransaction_and_advances_exactly_one_version() -> None:
    repo = _Repo(_player(4))
    store = TransactionBoundPostgresPlayerStateStore(repo, _base)
    tx = _tx()
    with relational_player_sub_uow(store, tx, 12_500_001, _op()) as uow:
        uow.player.player_name = "After"
        uow.request_save()
    assert len(repo.saves) == 1
    saved_tx, saved, expected = repo.saves[0]
    assert saved_tx is tx
    assert expected == 4
    assert saved.state_version == 5
    assert saved.payload["identity"]["player_name"] == "After"


def test_player_uow_exception_restores_in_memory_state_and_does_not_persist() -> None:
    repo = _Repo(_player(9))
    store = TransactionBoundPostgresPlayerStateStore(repo, _base)
    captured = None
    with pytest.raises(ValueError, match="boom"):
        with relational_player_sub_uow(store, _tx(), 12_500_001, _op()) as uow:
            captured = uow.player
            uow.player.player_name = "Should Roll Back"
            uow.request_save()
            raise ValueError("boom")
    assert captured is not None
    assert captured.player_name == "Before"
    assert ensure_persistence_state(captured)["state_version"] == 9
    assert repo.saves == []


def test_repeated_save_inside_same_outer_binding_uses_new_expected_version() -> None:
    repo = _Repo(_player(1))
    store = TransactionBoundPostgresPlayerStateStore(repo, _base)
    tx = _tx()
    with store.bind(tx):
        p = store.load(12_500_001)
        ensure_persistence_state(p)["state_version"] = 2
        store.save(p)
        ensure_persistence_state(p)["state_version"] = 3
        store.save(p)
    assert [row[2] for row in repo.saves] == [1, 2]


def test_player_sub_uow_rejects_undeclared_late_player_lock():
    repo = _Repo(_player(1))
    store = TransactionBoundPostgresPlayerStateStore(repo, _base)
    tx = SimpleNamespace(request=TransactionRequest(request_id="bad", operation_name="bad", resources=(), retry_safe=False))
    with pytest.raises(RuntimeError, match="did not declare PLAYER:player_state"):
        with relational_player_sub_uow(store, tx, 12_500_001, _op()):
            pass


def test_outer_transaction_tracks_expected_versions_independently_for_multiple_players() -> None:
    class MultiRepo:
        def __init__(self):
            self.records = {}
            for pid, version in ((12_500_001, 3), (12_500_002, 8)):
                p = make_fresh_player(account_uid="20000001", player_id=str(pid), region=125, region_name="Deep Valley")
                ensure_persistence_state(p)["state_version"] = version
                self.records[pid] = PlayerPayloadCodec.transform(p).record
            self.saves = []
        def load_for_update(self, tx, player_id):
            return self.records[int(player_id)]
        def save(self, tx, record, *, expected_state_version):
            self.saves.append((int(record.player_id), int(expected_state_version), int(record.state_version)))
            self.records[int(record.player_id)] = record
            return record

    repo = MultiRepo()
    store = TransactionBoundPostgresPlayerStateStore(repo, _base)
    tx = SimpleNamespace(request=TransactionRequest(
        request_id="multi-player", operation_name="shared-op",
        resources=(player_state_resource(12_500_001), player_state_resource(12_500_002)), retry_safe=False,
    ))
    with store.bind(tx):
        a = store.load(12_500_001)
        b = store.load(12_500_002)
        ensure_persistence_state(a)["state_version"] = 4
        ensure_persistence_state(b)["state_version"] = 9
        # Save in the opposite order from load to prove no single-version slot
        # can bleed across player aggregates.
        store.save(b)
        store.save(a)
    assert repo.saves == [(12_500_002, 8, 9), (12_500_001, 3, 4)]
