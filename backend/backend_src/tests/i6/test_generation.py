from __future__ import annotations
from types import SimpleNamespace
from uuid import uuid4
from gxb_backend.scheduler.generation import GenerationLifecycleService,GenerationRecord,GenerationStage,GenerationStateError

class Repo:
    def __init__(self,rows): self.rows=rows
    def load_for_update(self,tx,gid): return self.rows.get(gid)
    def transition(self,tx,gid,*,expected_stage,expected_state_version,next_stage):
        row=self.rows[gid]
        assert row.stage is expected_stage and row.state_version==expected_state_version
        row=GenerationRecord(row.domain,gid,next_stage,row.state_version+1); self.rows[gid]=row; return row
class Receipts:
    def __init__(self): self.rows={}
    def get(self,c,key): return self.rows.get(key.scope)
    def record_or_replay(self,c,*,key,request_fingerprint,result,**kw):
        rec=SimpleNamespace(request_fingerprint=request_fingerprint.hex(),result=dict(result),receipt_id=uuid4())
        old=self.rows.setdefault(key.scope,rec); return old,old is not rec
class Tx: connection=object()

def test_freeze_fences_new_writes_and_is_idempotent_after_freeze():
    r=Repo({'g':GenerationRecord('arena','g',GenerationStage.OPEN,0)}); svc=GenerationLifecycleService(r,Receipts())
    frozen=svc.freeze(Tx(),'g'); assert frozen.stage is GenerationStage.FROZEN
    assert svc.freeze(Tx(),'g').stage is GenerationStage.FROZEN
    try: svc.require_writable(Tx(),'g')
    except GenerationStateError: pass
    else: raise AssertionError('freeze must fence writes')

def test_finalization_receipt_makes_retry_externally_idempotent():
    repo=Repo({'g':GenerationRecord('arena','g',GenerationStage.FROZEN,1)}); receipts=Receipts(); svc=GenerationLifecycleService(repo,receipts); calls=[]
    first=svc.finalize(Tx(),'g',lambda tx,row:(calls.append(row.generation_id) or {'snapshot':'s1'}))
    assert first=={'snapshot':'s1'} and repo.rows['g'].stage is GenerationStage.FINALIZED
    second=svc.finalize(Tx(),'g',lambda tx,row:(_ for _ in ()).throw(AssertionError('must replay receipt')))
    assert second==first and calls==['g']

def test_generation_rollover_is_independent_identity():
    repo=Repo({'old':GenerationRecord('arena','old',GenerationStage.FINALIZED,3),'new':GenerationRecord('arena','new',GenerationStage.OPEN,0)})
    svc=GenerationLifecycleService(repo,Receipts()); assert svc.require_writable(Tx(),'new').generation_id=='new'; assert repo.rows['old'].stage is GenerationStage.FINALIZED


def test_full_generation_lifecycle_open_and_close_are_fenced_and_idempotent():
    repo=Repo({'g':GenerationRecord('arena','g',GenerationStage.PLANNED,0)}); svc=GenerationLifecycleService(repo,Receipts())
    assert svc.open_generation(Tx(),'g').stage is GenerationStage.OPEN
    assert svc.open_generation(Tx(),'g').stage is GenerationStage.OPEN
    assert svc.freeze(Tx(),'g').stage is GenerationStage.FROZEN
    svc.finalize(Tx(),'g',lambda tx,row:{'snapshot':'s'})
    assert repo.rows['g'].stage is GenerationStage.FINALIZED
    assert svc.close(Tx(),'g').stage is GenerationStage.CLOSED
    assert svc.close(Tx(),'g').stage is GenerationStage.CLOSED

def test_generation_cannot_skip_planned_open_frozen_finalized_boundaries():
    for stage, action in ((GenerationStage.PLANNED,'freeze'),(GenerationStage.OPEN,'close'),(GenerationStage.FROZEN,'close')):
        svc=GenerationLifecycleService(Repo({'g':GenerationRecord('arena','g',stage,0)}),Receipts())
        try: getattr(svc,action)(Tx(),'g')
        except GenerationStateError: pass
        else: raise AssertionError((stage,action))
