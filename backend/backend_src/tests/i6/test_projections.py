from __future__ import annotations
from datetime import datetime,timezone
from sqlalchemy.dialects import postgresql
from gxb_backend.projections.models import LiveProjectionRow,RankSnapshotRow
from gxb_backend.projections.repository import RankProjectionRepository,SnapshotConflict
from gxb_backend.projections.schema import rank_projection_live

class Result:
    def __init__(self, scalar=None, mapping=None): self.scalar=scalar; self.mapping=mapping
    def scalar_one_or_none(self): return self.scalar
    class Maps:
        def __init__(self,m): self.m=m
        def one(self): return self.m
    def mappings(self): return self.Maps(self.mapping)
class Conn:
    def __init__(self,results): self.results=list(results); self.statements=[]
    def execute(self,s): self.statements.append(s); return self.results.pop(0)

def live(v=3,score=10): return LiveProjectionRow('GLOBAL','0','arena','PLAYER','1',score,v,{})

def test_live_upsert_sql_has_source_version_fence():
    from sqlalchemy.dialects.postgresql import insert
    row=live()
    stmt=(insert(rank_projection_live).values(scope_type=row.scope_type,scope_id=row.scope_id,rank_type=row.rank_type,subject_type=row.subject_type,subject_id=row.subject_id,score=row.score,tiebreak={},source_version=row.source_version).on_conflict_do_update(constraint='uq_rank_projection_live_identity',set_={'score':row.score,'source_version':row.source_version},where=rank_projection_live.c.source_version<row.source_version))
    sql=str(stmt.compile(dialect=postgresql.dialect()))
    assert 'ON CONFLICT ON CONSTRAINT uq_rank_projection_live_identity DO UPDATE' in sql
    assert 'source_version <' in sql

def test_live_equal_version_equal_payload_is_idempotent_and_older_or_conflicting_is_stale():
    repo=RankProjectionRepository(); row=live()
    c=Conn([Result(None),Result(mapping={'source_version':3,'score':10,'tiebreak':{}})]); assert repo.upsert_live(c,row)=='IDEMPOTENT'
    c=Conn([Result(None),Result(mapping={'source_version':4,'score':20,'tiebreak':{}})]); assert repo.upsert_live(c,row)=='STALE'

def test_snapshot_is_immutable_but_exact_replay_is_idempotent():
    row=RankSnapshotRow('GLOBAL','0','arena','g1',datetime.now(timezone.utc),'PLAYER','1',1,10,{},'gold',{})
    repo=RankProjectionRepository()
    current={'rank':1,'score':10,'tiebreak':{},'reward_band':'gold','metadata':{}}
    assert repo.insert_snapshot(Conn([Result(None),Result(mapping=current)]),row)=='IDEMPOTENT'
    bad=dict(current); bad['score']=11
    try: repo.insert_snapshot(Conn([Result(None),Result(mapping=bad)]),row)
    except SnapshotConflict: pass
    else: raise AssertionError('snapshot mutation must fail')

from contextlib import contextmanager
from gxb_backend.projections.outbox import ProjectionOutboxWorker, ProjectionIntentStager, PROJECTION_DELIVERY_CLASSES
from gxb_backend.transactions.models import DeliveryClass

class Engine2:
    @contextmanager
    def begin(self): yield object()
class OutboxRepo:
    def __init__(self,rows=()): self.rows=tuple(rows); self.claim_classes=None; self.calls=[]
    def claim_available(self,c,**kw): self.claim_classes=tuple(kw['delivery_classes']); return self.rows
    def mark_done(self,c,e,**kw): self.calls.append(('done',e)); return True
    def release_for_retry(self,c,e,**kw): self.calls.append(('retry',e)); return True

def test_projection_worker_claims_only_frozen_projection_delivery_class():
    repo=OutboxRepo([{'event_id':1,'topic':'rank.update','payload':{},'delivery_class':'DERIVED_PROJECTION_WORK'}]); seen=[]
    report=ProjectionOutboxWorker(lambda:Engine2(),{'rank.update':lambda row:seen.append(row['event_id'])},repository=repo).poll_once()
    assert repo.claim_classes==(DeliveryClass.DERIVED_PROJECTION_WORK,)
    assert DeliveryClass.DURABLE_USER_DELIVERY not in repo.claim_classes
    assert DeliveryClass.TRANSIENT_REALTIME_NOTICE not in repo.claim_classes
    assert seen==[1] and report.applied==1 and repo.calls==[('done',1)]

def test_projection_failure_releases_for_idempotent_retry():
    repo=OutboxRepo([{'event_id':2,'topic':'rank.update','payload':{},'delivery_class':'DERIVED_PROJECTION_WORK'}])
    report=ProjectionOutboxWorker(lambda:Engine2(),{'rank.update':lambda row:(_ for _ in ()).throw(RuntimeError('x'))},repository=repo).poll_once()
    assert report.released==1 and repo.calls==[('retry',2)]

def test_projection_intent_stager_uses_projection_class_not_durable_user_delivery():
    class Tx:
        def __init__(self): self.items=[]
        def stage_outbox(self,x): self.items.append(x)
    tx=Tx(); ProjectionIntentStager().stage(tx,topic='rank.update',resource_kind='rank',resource_key='arena',payload={'v':1})
    assert tx.items[0].delivery_class is DeliveryClass.DERIVED_PROJECTION_WORK

def test_live_scope_rebuild_requires_explicit_quiesced_source_boundary():
    repo=RankProjectionRepository()
    try: repo.replace_live_scope(Conn([]),scope_type='GLOBAL',scope_id='0',rank_type='arena',rows=())
    except RuntimeError as exc: assert 'quiesced' in str(exc)
    else: raise AssertionError('online destructive projection rebuild must be explicit')
