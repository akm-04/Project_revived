from __future__ import annotations
from contextlib import contextmanager
from gxb_backend.scheduler.worker import SchedulerSettings, SchedulerWorker

class Engine:
    def __init__(self): self.depth=0; self.txns=0
    @contextmanager
    def begin(self):
        self.depth+=1; self.txns+=1
        try: yield object()
        finally:self.depth-=1
class Repo:
    def __init__(self,rows): self.rows=tuple(rows); self.calls=[]
    def claim_due(self,c,**kw): self.calls.append(('claim',kw)); return self.rows
    def mark_succeeded(self,c,j,**kw): self.calls.append(('success',j,kw)); return True
    def mark_retry(self,c,j,**kw): self.calls.append(('retry',j,kw)); return True
    def mark_dead(self,c,j,**kw): self.calls.append(('dead',j,kw)); return True

def row(job_id=1,attempt=1,job_type='FINALIZE'): return {'job_id':job_id,'attempt_count':attempt,'job_type':job_type}

def test_scheduler_claims_short_executes_handler_outside_queue_transaction_and_settles_short():
    engine=Engine(); repo=Repo([row()]); seen=[]
    def handler(r): assert engine.depth==0; seen.append(r['job_id'])
    worker=SchedulerWorker(lambda:engine,repo,SchedulerSettings('w'),{'FINALIZE':handler})
    assert worker.run_once()==1 and seen==[1] and engine.txns==2
    assert [x[0] for x in repo.calls]==['claim','success']

def test_scheduler_failure_retries_before_attempt_limit():
    repo=Repo([row(attempt=2)]); engine=Engine()
    worker=SchedulerWorker(lambda:engine,repo,SchedulerSettings('w',max_attempts=3),{'FINALIZE':lambda r:(_ for _ in ()).throw(RuntimeError('boom'))})
    worker.run_once(); assert repo.calls[-1][0]=='retry'

def test_scheduler_failure_becomes_dead_at_attempt_limit_and_unknown_type_is_not_silently_successful():
    repo=Repo([row(attempt=3,job_type='UNKNOWN')]); engine=Engine()
    worker=SchedulerWorker(lambda:engine,repo,SchedulerSettings('w',max_attempts=3),{})
    worker.run_once(); assert repo.calls[-1][0]=='dead'

def test_scheduler_configuration_is_bounded():
    for kw in ({'worker_id':''},{'worker_id':'w','lease_seconds':0},{'worker_id':'w','batch_size':0},{'worker_id':'w','max_attempts':0}):
        try: SchedulerSettings(**kw)
        except ValueError: pass
        else: raise AssertionError(kw)

def test_scheduler_never_silently_settles_after_lease_loss():
    class LostRepo(Repo):
        def mark_retry(self,c,j,**kw): self.calls.append(('retry',j,kw)); return False
    repo=LostRepo([row(attempt=1)]); engine=Engine()
    worker=SchedulerWorker(lambda:engine,repo,SchedulerSettings('w',max_attempts=3),{'FINALIZE':lambda r:(_ for _ in ()).throw(RuntimeError('boom'))})
    try: worker.run_once()
    except RuntimeError as exc: assert 'lost scheduler lease' in str(exc)
    else: raise AssertionError('lease loss must surface')
