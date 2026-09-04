from __future__ import annotations
import hashlib, json, os, subprocess, sys
from pathlib import Path
from gxb_backend.mail.schema import mail_items
from gxb_backend.projections.schema import rank_projection_live, rank_snapshots

ROOT=Path(__file__).resolve().parents[2]

def offline_sql()->str:
    env=dict(os.environ); env['PYTHONPATH']=str(ROOT); env['GXB_DATABASE_URL']='postgresql+psycopg://gxb:pass345-secret@localhost/gxb'
    r=subprocess.run([sys.executable,'-m','alembic','upgrade','0006_pass345_i6','--sql'],cwd=ROOT,env=env,check=True,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    return r.stdout.lower()

def test_i6_schema_adds_only_mail_and_derived_projection_tables():
    sql=offline_sql()
    assert 'running upgrade 0005_pass344_i5 -> 0006_pass345_i6' in sql
    for name in ('mail_items','rank_projection_live','rank_snapshots'):
        assert f'create table gxb.{name}' in sql
    assert 'uq_mail_items_protocol_identity' in sql
    assert "derived_projection_work" in sql
    assert 'unique (player_id, is_region, protocol_mail_id)' in sql
    for forbidden in ('create table gxb.domain_generation_rows','create table gxb.shared_resources','create table gxb.scheduler_state','create table gxb.realtime_sessions'):
        assert forbidden not in sql
    assert 'pass345-secret' not in sql

def test_i6_mail_schema_preserves_source_proven_dual_namespace_identity():
    names={c.name for c in mail_items.constraints}
    assert 'uq_mail_items_delivery_key' in names
    assert 'uq_mail_items_protocol_identity' in names
    uq=next(c for c in mail_items.constraints if c.name=='uq_mail_items_protocol_identity')
    assert [c.name for c in uq.columns]==['player_id','is_region','protocol_mail_id']

def test_i6_projection_tables_are_explicit_derived_and_snapshot_owners():
    assert {'source_version','score','tiebreak'} <= set(rank_projection_live.c.keys())
    assert {'generation_id','rank','reward_band','snapshot_at'} <= set(rank_snapshots.c.keys())

def test_i6_remains_unwired_from_default_runtime_and_rlock_is_retained():
    app=(ROOT/'gxb_backend/app_factory.py').read_text()
    run=(ROOT/'gxb_backend/run.py').read_text()
    mail=(ROOT/'gxb_backend/handlers/mail.py').read_text()
    repo=(ROOT/'gxb_backend/state/repository.py').read_text()
    assert 'gxb_backend.scheduler.worker' not in app+run
    assert 'gxb_backend.mail.repository' not in app+run
    assert 'gxb_backend.projections.repository' not in app+run
    assert 'get_player().mail_payload()' in mail
    assert 'threading.RLock()' in repo

def test_current_src64_critical_files_match_sealed_pass344():
    cross=json.loads((ROOT/'docs/json/PASS344_SOURCE_BACKEND_CROSSCHECK.json').read_text())
    expected={}
    for row in cross.get('client_runtime_rechecked',[]):
        if isinstance(row,dict) and row.get('path') and row.get('sha256'): expected[row['path']]=row['sha256']
    found=0
    for name in ('Backend.lua','LoadingScene.lua','LoginWindow.lua','SwitchItem.lua','mid.lua'):
        matches=list((ROOT/'local_assets/src_64').rglob(name)); assert matches,name
        got=hashlib.sha256(matches[0].read_bytes()).hexdigest()
        candidates=[v for k,v in expected.items() if str(k).endswith('/'+name) or str(k)==name]
        if candidates:
            allowed=set(candidates)
            if name == 'Backend.lua':
                p349=json.loads((ROOT/'docs/json/PASS349_I10_PRELOGIN_MID2864_RECONCILIATION.json').read_text())
                allowed.add(p349['candidate_hashes']['local_assets/src_64/app/common/network/Backend.lua'])
            if name == 'LoginWindow.lua':
                p352=json.loads((ROOT/'docs/json/PASS352_I10_STOCK_RUNTIME_RECONCILIATION.json').read_text())
                allowed.add(p352['candidate_hashes']['local_assets/src_64/app/windows/LoginWindow.lua'])
            assert got in allowed,(name,got,candidates); found+=1
    assert found>=3
