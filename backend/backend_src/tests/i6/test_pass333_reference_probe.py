"""One-for-one implementation trace of PASS333_SCHEDULER_PROJECTION_PROBE.json."""
from __future__ import annotations
from contextlib import contextmanager
from datetime import datetime, timezone
from pathlib import Path
from types import SimpleNamespace
from uuid import uuid4
from unittest.mock import Mock
from sqlalchemy.dialects import postgresql

from gxb_backend.mail.models import MailDeliveryIntent
from gxb_backend.mail.service import MailDeliveryService
from gxb_backend.projections.repository import RankProjectionRepository
from gxb_backend.scheduler.generation import GenerationLifecycleService, GenerationRecord, GenerationStage, GenerationStateError
from gxb_backend.transactions.jobs import ScheduledJobRepository
from gxb_backend.transactions.models import ScheduledJobIntent

ROOT=Path(__file__).resolve().parents[2]

class Cap:
    rowcount=1
    def mappings(self): return self
    def all(self): return []
    def scalar_one_or_none(self): return None
    def scalar_one(self): return 1

def job_claim_sql():
    c=Mock(); c.execute.return_value=Cap()
    ScheduledJobRepository().claim_due(c,worker_id='sched',lease_seconds=30,limit=8)
    return str(c.execute.call_args_list[0].args[0].compile(dialect=postgresql.dialect(),compile_kwargs={'literal_binds':True})).lower()

def test_job_not_claimed_early():
    sql=job_claim_sql(); assert 'due_at <=' in sql and 'now()' in sql

def test_overdue_job_claimed():
    sql=job_claim_sql(); assert "status in ('scheduled', 'retry')" in sql or ('scheduled' in sql and 'retry' in sql)

def test_expired_lease_reclaimed():
    sql=job_claim_sql(); assert 'running' in sql and 'lease_until <=' in sql

def test_job_dedupe_key():
    c=Mock(); c.execute.return_value=SimpleNamespace(scalar_one_or_none=lambda:7)
    intent=ScheduledJobIntent('arena:g1:finalize','FINALIZE','generation','g1',datetime(2026,1,1,tzinfo=timezone.utc),{},generation_id='g1')
    assert ScheduledJobRepository().schedule(c,intent)==(7,False)
    sql=str(c.execute.call_args.args[0].compile(dialect=postgresql.dialect())).lower(); assert 'uq_scheduled_jobs_dedupe_key' in sql

class GRepo:
    def __init__(self,rows): self.rows=rows
    def load_for_update(self,tx,gid): return self.rows.get(gid)
    def transition(self,tx,gid,*,expected_stage,expected_state_version,next_stage):
        row=self.rows[gid]; assert row.stage is expected_stage and row.state_version==expected_state_version
        row=GenerationRecord(row.domain,gid,next_stage,row.state_version+1); self.rows[gid]=row; return row
class GReceipts:
    def __init__(self): self.rows={}
    def get(self,c,key): return self.rows.get(key.scope)
    def record_or_replay(self,c,*,key,request_fingerprint,result,**kw):
        new=SimpleNamespace(request_fingerprint=request_fingerprint.hex(),result=dict(result),receipt_id=uuid4())
        old=self.rows.setdefault(key.scope,new); return old,old is not new
class Tx: connection=object()

def test_freeze_fences_new_scores():
    repo=GRepo({'g':GenerationRecord('arena','g',GenerationStage.OPEN,0)}); svc=GenerationLifecycleService(repo,GReceipts()); svc.freeze(Tx(),'g')
    try: svc.require_writable(Tx(),'g')
    except GenerationStateError: pass
    else: raise AssertionError('FROZEN must reject new score writes')

def test_finalize_idempotent():
    repo=GRepo({'g':GenerationRecord('arena','g',GenerationStage.FROZEN,1)}); rec=GReceipts(); calls=[]; svc=GenerationLifecycleService(repo,rec)
    first=svc.finalize(Tx(),'g',lambda tx,row:(calls.append('x') or {'snapshot':'s'})); second=svc.finalize(Tx(),'g',lambda tx,row:(_ for _ in ()).throw(AssertionError()))
    assert first==second and calls==['x']

def test_historical_snapshot_retained():
    text=(ROOT/'gxb_backend/projections/repository.py').read_text(); assert 'insert_snapshot' in text and 'delete(rank_snapshots)' not in text

def test_generation_rollover_independent():
    repo=GRepo({'old':GenerationRecord('arena','old',GenerationStage.FINALIZED,4),'new':GenerationRecord('arena','new',GenerationStage.OPEN,0)}); svc=GenerationLifecycleService(repo,GReceipts())
    assert svc.require_writable(Tx(),'new').generation_id=='new' and repo.rows['old'].stage is GenerationStage.FINALIZED

def test_mail_delivery_key_idempotent():
    text=(ROOT/'gxb_backend/mail/repository.py').read_text(); assert 'uq_mail_items_delivery_key' in text and 'MailDeliveryConflict' in text

def test_mail_claim_first():
    text=(ROOT/'gxb_backend/mail/service.py').read_text(); assert 'settlement.settle' in text and 'mark_claimed' in text and 'record_or_replay' in text

def test_mail_claim_replay_blocked():
    # Pass345 refines the old probe: duplicate *grant* is blocked by semantic receipt replay.
    text=(ROOT/'gxb_backend/mail/service.py').read_text(); assert 'existing = self.receipts.get' in text and 'return result_from_receipt' in text

def test_projection_rebuild_from_canonical():
    repo=RankProjectionRepository()
    try: repo.replace_live_scope(object(),scope_type='GLOBAL',scope_id='0',rank_type='arena',rows=())
    except RuntimeError: pass
    else: raise AssertionError('rebuild must require explicit quiesced canonical source')

def test_no_per_player_regen_job():
    text='\n'.join(p.read_text().lower() for p in (ROOT/'gxb_backend/scheduler').glob('*.py'))
    assert all(x not in text for x in ('energy_regen','daily_reset_job','player_regen'))

def test_durable_before_notification():
    calls=[]
    class Repo:
        def deliver(self,c,intent): calls.append('durable'); return SimpleNamespace(),False
    class T:
        connection=object()
        def stage_outbox(self,x): calls.append('notify')
    MailDeliveryService(Repo()).deliver(T(),MailDeliveryIntent(1,'d','x','1',{}),notification='n')
    assert calls==['durable','notify']
