#!/usr/bin/env python3
from __future__ import annotations
import tempfile
import sys, types
if "flask" not in sys.modules:
    fake=types.ModuleType("flask"); fake.Request=object; fake.jsonify=lambda data=None,**kwargs:data; fake.make_response=lambda data=None,status=200,**kwargs:data; fake.send_file=lambda *args,**kwargs:None; sys.modules["flask"]=fake
from dataclasses import replace
from pathlib import Path

from gxb_backend.config import SETTINGS
from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
from gxb_backend.state.repository import StateRepository
from gxb_backend.state.unit_of_work import OperationContext

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / 'data'


def make_repo(td: str):
    repo = StateRepository(
        DATA / 'player_db.json', profile='established', legacy_path=ROOT / 'state/gxb_state.json',
        multiuser_root=Path(td) / 'server_state'
    )
    disp = EngineDispatcher(repo, replace(SETTINGS, runtime_log_dir=Path(td)/'logs'), None)
    return repo, disp


def login_player(repo, disp, login: str, region: int):
    acct, msg = repo.sdk_register(login, 'pw')
    assert acct is not None, msg
    ident = repo.sdk_login(login, 'pw')
    assert ident is not None
    out = disp.dispatch({'mid':1,'sid':ident.sid,'login_token':ident.token,'region':region})
    return ident, out


def main():
    with tempfile.TemporaryDirectory(prefix='pass281-') as td:
        repo, disp = make_repo(td)
        ida, a1 = login_player(repo, disp, 'alpha', 194)
        idb, b1 = login_player(repo, disp, 'beta', 194)
        pa = repo.store.player_id_for_account_region(ida.uid, 194)
        pb = repo.store.player_id_for_account_region(idb.uid, 194)
        assert pa and pb and pa != pb

        # Canonical working-set identity is stable across distinct request scopes.
        reqa = {'mid':17,'token':ida.token,'region':194}
        with repo.request_scope(reqa):
            a_obj1 = repo.get_player()
            svc1 = repo.get_services()
            shared1 = svc1.immutable_catalogs
            old_mana = int(a_obj1.mana)
        with repo.request_scope(reqa):
            a_obj2 = repo.get_player()
            svc2 = repo.get_services()
            assert a_obj2 is a_obj1
            assert svc2 is not svc1
            assert svc2.immutable_catalogs is shared1 is repo._immutable_request_catalogs
            # representative expensive catalogs are the same app-scoped objects
            assert svc2.awakening_source is svc1.awakening_source
            assert svc2.gift_opening_source is svc1.gift_opening_source
            assert svc2.horcrux_source is svc1.horcrux_source

        # Different accounts never share canonical player objects/state.
        reqb = {'mid':17,'token':idb.token,'region':194}
        with repo.request_scope(reqb):
            b_obj = repo.get_player()
            assert b_obj is not a_obj1
            b_mana = int(b_obj.mana)

        # UoW rollback restores the same canonical in-memory object.
        with repo.request_scope(reqa):
            p = repo.get_player(); svc = repo.get_services()
            try:
                with svc.uow.transaction(OperationContext(actor_player_id=str(p.player_id), domain="pass281", operation_name="rollback")):
                    p.mana = old_mana + 123
                    svc.uow.request_save()
                    raise RuntimeError('rollback probe')
            except RuntimeError:
                pass
            assert int(p.mana) == old_mana
        with repo.request_scope(reqb):
            assert int(repo.get_player().mana) == b_mana

        # Durable save updates the canonical object and survives repository restart.
        with repo.request_scope(reqa):
            p = repo.get_player(); svc = repo.get_services()
            with svc.uow.transaction(OperationContext(actor_player_id=str(p.player_id), domain="pass281", operation_name="commit")):
                p.mana = old_mana + 7
                svc.uow.request_save()
            assert int(p.mana) == old_mana + 7
        repo2 = StateRepository(
            DATA / 'player_db.json', profile='established', legacy_path=ROOT / 'state/gxb_state.json',
            multiuser_root=Path(td) / 'server_state'
        )
        with repo2.request_scope(reqa):
            assert int(repo2.get_player().mana) == old_mana + 7

        # refresh() is an explicit durable reload boundary and replaces cache identity.
        with repo.request_scope(reqa):
            before = repo.get_player()
            repo.refresh()
            after = repo.get_player()
            assert after is not before
            assert int(after.mana) == old_mana + 7

        # Global request serialization intentionally remains; this pass does not
        # pull the full concurrency redesign forward.
        assert hasattr(repo, '_lock')

    print('PASS281 bounded backend performance selftest: PASS')

if __name__ == '__main__':
    main()
