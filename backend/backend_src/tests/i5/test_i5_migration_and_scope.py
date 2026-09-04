from __future__ import annotations

import hashlib, json, os, subprocess, sys
from pathlib import Path

ROOT=Path(__file__).resolve().parents[2]


def offline_sql():
    env=dict(os.environ); env["PYTHONPATH"]=str(ROOT); env["GXB_DATABASE_URL"]="postgresql+psycopg://gxb:pass344-secret@localhost/gxb"
    r=subprocess.run([sys.executable,"-m","alembic","upgrade","0005_pass344_i5","--sql"],cwd=ROOT,env=env,check=True,text=True,stdout=subprocess.PIPE,stderr=subprocess.STDOUT)
    return r.stdout.lower()


def test_i5_migration_adds_only_outbox_wakeup_trigger():
    sql=offline_sql()
    assert "running upgrade 0004_pass343_i4 -> 0005_pass344_i5" in sql
    assert "notify_outbox_insert" in sql and "pg_notify('gxb_outbox', 'wake')" in sql
    assert "create trigger trg_outbox_notify" in sql
    # I5 does not create scheduler/mail/projection/realtime authority tables.
    for forbidden in ("create table gxb.mail_items","create table gxb.global_projections","create table gxb.realtime_sessions"):
        assert forbidden not in sql
    assert "pass344-secret" not in sql


def test_i5_remains_candidate_unwired_from_current_app_runtime_and_rlock_retained():
    app=(ROOT/'gxb_backend/app_factory.py').read_text()
    run=(ROOT/'gxb_backend/run.py').read_text()
    repo=(ROOT/'gxb_backend/state/repository.py').read_text()
    assert 'RealtimeRuntime(settings.chat_host, settings.chat_port, repo)' in app
    assert 'gxb_backend.realtime.gateway' not in app
    assert 'realtime_runtime.start()' in run
    assert 'threading.RLock()' in repo


def test_current_src64_critical_files_match_sealed_pass343_crosscheck():
    cross=json.loads((ROOT/'docs/json/PASS343_SOURCE_BACKEND_CROSSCHECK.json').read_text())
    expected={}
    for row in cross.get("client_runtime_rechecked",[]):
        if isinstance(row,dict) and row.get("path") and row.get("sha256"):
            expected[row["path"]]=row["sha256"]
    critical=["Backend.lua","LoadingScene.lua","LoginWindow.lua","SwitchItem.lua","mid.lua"]
    found=0
    for name in critical:
        p=ROOT/'local_assets/src_64'/name
        if not p.exists():
            matches=list((ROOT/'local_assets/src_64').rglob(name))
            assert matches, name
            p=matches[0]
        got=hashlib.sha256(p.read_bytes()).hexdigest()
        candidates={str(k):v for k,v in expected.items() if str(k).endswith('/'+name) or str(k)==name}
        if candidates:
            allowed=set(candidates.values())
            if name == "Backend.lua":
                p349=json.loads((ROOT/'docs/json/PASS349_I10_PRELOGIN_MID2864_RECONCILIATION.json').read_text())
                allowed.add(p349['candidate_hashes']['local_assets/src_64/app/common/network/Backend.lua'])
            if name == "LoginWindow.lua":
                p352=json.loads((ROOT/'docs/json/PASS352_I10_STOCK_RUNTIME_RECONCILIATION.json').read_text())
                allowed.add(p352['candidate_hashes']['local_assets/src_64/app/windows/LoginWindow.lua'])
            assert got in allowed, (name,got,candidates)
            found+=1
    assert found>=3, "Pass343 crosscheck should expose critical src_64 hashes"
