from __future__ import annotations
from types import SimpleNamespace
from gxb_backend.scheduler.runtime import SchedulerProcess, SchedulerProcessSettings


class Sched:
    def __init__(self, counts=()): self.counts=list(counts); self.calls=0
    def run_once(self):
        self.calls+=1
        return self.counts.pop(0) if self.counts else 0


class Proj:
    def __init__(self, counts=()): self.counts=list(counts); self.recovered=[]; self.calls=0
    def recover_stale_claims(self, *, stale_after_seconds): self.recovered.append(stale_after_seconds); return 2
    def poll_once(self):
        self.calls+=1
        return SimpleNamespace(claimed=(self.counts.pop(0) if self.counts else 0))


def test_scheduler_process_recovers_projection_claims_before_looping():
    s=Sched(); p=Proj(); proc=SchedulerProcess(s,p,settings=SchedulerProcessSettings(projection_stale_claim_seconds=17))
    assert proc.recover_startup()==2 and p.recovered==[17]


def test_scheduler_process_hosts_independent_scheduled_and_projection_lanes():
    s=Sched([3]); p=Proj([4]); proc=SchedulerProcess(s,p)
    assert proc.run_once()==(3,4) and s.calls==1 and p.calls==1


def test_scheduler_process_sleeps_only_when_both_durable_lanes_are_idle():
    sleeps=[]; s=Sched([0,1,0]); p=Proj([0,0,2]); proc=SchedulerProcess(s,p,sleep=lambda x:sleeps.append(x))
    stops=iter([False,False,False,True])
    proc.run_forever(stop=lambda:next(stops))
    assert p.recovered==[30]
    assert sleeps==[1.0]


def test_no_per_player_timer_fanout_is_introduced_in_i6_scheduler_code():
    from pathlib import Path
    root=Path(__file__).resolve().parents[2]
    text='\n'.join((root/'gxb_backend/scheduler'/name).read_text().lower() for name in ('worker.py','runtime.py','generation.py'))
    forbidden=('energy_regen','energy regen','daily_reset_job','daily reset job','player_regen','per-player regen')
    assert all(token not in text for token in forbidden)
