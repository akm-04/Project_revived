#!/usr/bin/env python3
"""Pass170 H5 Gods Trial source/state-machine regression gate."""
from __future__ import annotations

import copy
from datetime import datetime, timezone
from pathlib import Path
import subprocess
import sys
import tempfile
import types

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog
from gxb_backend.protocol.mids import MID
from gxb_backend.state.gods_trial_service import GodsTrialServiceError
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.random_outcome_service import EntropyDrawRequest
from gxb_backend.state.request_services import RequestServices
from gxb_backend.state.server_clock import ServerClock
from gxb_backend.transport.result import EngineTransportResult

GAME = GameDataCatalog.load(DATA / "game_data_catalog.json")
SOURCE = HorcruxSourceCatalog(DATA, game_data=GAME)
MONDAY_EPOCH = int(datetime(2026, 8, 24, 0, 0, tzinfo=timezone.utc).timestamp())


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


class MutableClock:
    def __init__(self, now: int): self.value = int(now)
    def __call__(self): return self.value


class ScriptedEntropy:
    def __init__(self, values=()) -> None:
        self.values = list(values)
        self.requests: list[EntropyDrawRequest] = []
    def draw(self, request: EntropyDrawRequest) -> int:
        self.requests.append(request)
        value = self.values.pop(0) if self.values else request.upper_exclusive - 1
        if not 0 <= value < request.upper_exclusive:
            raise AssertionError(f"bad entropy {value} for {request}")
        return value


def services(*, now=MONDAY_EPOCH, energy=180, progress=None, spirits=None, entropy_values=(), pid="170001"):
    player = apply_established_profile(PlayerState())
    player.player_id = player.account_uid = pid
    player.player_name = "Pass170 H5"
    player.lev = 99
    player.spirit_energy = energy
    player.spirit_energy_time = 0
    player.heroes = {"10001": {"partner_id":10001,"table_id":10001001,"star":5,"spirit_equip":[0]*6}}
    player.spirit_list = copy.deepcopy(spirits or [])
    player.horcrux_state = {}
    if progress:
        player.horcrux_state = {"trial": {"campaign_progress": {str(k): {"win_count": int(v)} for k,v in progress.items()}}}
    clock = MutableClock(now)
    entropy = ScriptedEntropy(entropy_values)
    commits: list[int] = []
    svc = RequestServices(
        player, DATA, lambda: commits.append(1), catalog=GAME,
        server_clock=ServerClock(clock), entropy_provider=entropy,
    )
    svc.heroes.normalize(); svc.horcrux_repository.normalize()
    return player, svc, commits, entropy, clock


def minimal_spirits(count: int) -> list[dict]:
    return [{"spirit_id":i+1,"table_id":250000111,"is_equip":0,"is_lock":0,"collo_count":0} for i in range(count)]


def test_source_catalog_v4_and_wire_correction() -> None:
    req(SOURCE.trial_campaign_type == 79, f"CampaignType.HUNQI drift: {SOURCE.trial_campaign_type}")
    req(SOURCE.spirit_energy_interval_seconds == 360, "Spirit Energy interval drift")
    req(SOURCE.spirit_energy_natural_cap == 180, "Spirit Energy cap drift")
    req(SOURCE.spirit_auto_limit == 10 and SOURCE.spirit_auto_minutes == 5, "auto source limits drift")
    req(len(SOURCE.ordered_trial_dropbox_ids) == 84 and len(set(SOURCE.ordered_trial_dropbox_ids)) == 84, "Trial pool census drift")
    req(sum(len(SOURCE.trial_drop_rows(pid)) for pid in SOURCE.ordered_trial_dropbox_ids) == 3672, "Trial drop-row census drift")
    # Monday first-clear pool is two deterministic type24 rows.
    first = SOURCE.trial_drop_rows(9100001)
    req(len(first)==2 and all(int(r["increase_rate"])==10000 for r in first), "Monday first-clear pool drift")
    req(all(int(GAME.get(__import__('gxb_backend.content',fromlist=['ContentRef','CatalogNamespace']).ContentRef(__import__('gxb_backend.content',fromlist=['CatalogNamespace']).CatalogNamespace.ITEM,int(r['item_id'])))['type'])==24 for r in first), "Monday first-clear item type drift")
    with tempfile.TemporaryDirectory(prefix="pass170_catalog_") as td:
        out=Path(td)/"horcrux_source_catalog.json"
        subprocess.run([sys.executable,str(ROOT/"tools/build_horcrux_source_catalog.py"),"--src64",str(ROOT/"source_evidence/src_64"),"--output",str(out)],check=True,stdout=subprocess.DEVNULL)
        req(out.read_bytes()==(DATA/"horcrux_source_catalog.json").read_bytes(), "H5 source-evidence rebuild not byte-identical")


def test_source_day_boundary_and_campaign_projection() -> None:
    # Monday source day starts Sunday 21:00 UTC == Monday 05:00 GMT+8.
    boundary = int(datetime(2026,8,23,21,0,tzinfo=timezone.utc).timestamp())
    p,s,commits,entropy,clock = services(now=boundary-1,pid="170day")
    req(s.gods_trial.current_weekday()==7, "pre-boundary weekday should be Sunday")
    clock.value=boundary
    req(s.gods_trial.current_weekday()==1, "boundary weekday should roll to Monday")
    info=s.gods_trial.campaign_info()
    req(info["day"]==1 and info["day_info"]=={}, "MID3097 day projection drift")
    req(info["base_info"]=={"auto_campaign":0,"auto_times":0,"auto_start_time":0}, "base_info idle projection drift")
    req(set(info["campaign_infos"])=={str(1000+i) for i in range(1,7)}, "Monday stage projection drift")
    req(info["campaign_infos"]["1001"]=={"is_open":1,"win_count":0}, "first stage open drift")
    req(info["campaign_infos"]["1002"]=={"is_open":0,"win_count":0}, "second stage prerequisite drift")
    req(entropy.requests==[], "read-only info consumed Trial entropy")


def test_manual_first_clear_terminal_replay_and_next_unlock() -> None:
    p,s,commits,entropy,clock = services(pid="170manual")
    out=s.gods_trial.start_fight(1001,79,"10001",0)
    req(out=={} and commits==[1], "MID3092 stage/commit drift")
    snapshot=copy.deepcopy(vars(p))
    req(s.gods_trial.start_fight(1001,79,"10001",0)=={}, "identical MID3092 replay drift")
    req(vars(p)==snapshot and commits==[1], "identical MID3092 replay mutated")
    result=s.gods_trial.fight_result(1001,79,[10001],3,0)
    req(result["items"]==[] and len(result["spirit_items"])==2, f"first-clear reward projection drift: {result}")
    req(p.spirit_energy==160 and s.horcrux_repository.owned_count()==2, "manual win energy/reward settlement drift")
    req(s.gods_trial.campaign_info()["campaign_infos"]["1002"]["is_open"]==1, "next Trial stage did not unlock")
    draws=len(entropy.requests); commits_after=len(commits); state=copy.deepcopy(vars(p))
    replay=s.gods_trial.fight_result(1001,79,[10001],3,0)
    req(replay.get("error_code")==30005 and replay["spirit_items"]==result["spirit_items"], "terminal MID3093 replay drift")
    req(len(entropy.requests)==draws and len(commits)==commits_after and vars(p)==state, "terminal replay duplicated mutation/RNG")


def test_manual_loss_and_soft_capacity_entry_guard() -> None:
    p,s,commits,entropy,clock=services(pid="170loss")
    s.gods_trial.start_fight(1001,79,"10001")
    result=s.gods_trial.fight_result(1001,79,[10001],0)
    req(result=={"items":[],"spirit_items":[]} and p.spirit_energy==178, "manual loss settlement drift")
    req(s.gods_trial._progress(1001)==0 and s.horcrux_repository.owned_count()==0, "manual loss granted progress/rewards")
    p2,s2,c2,e2,_=services(spirits=minimal_spirits(2000),pid="170cap")
    before=copy.deepcopy(vars(p2))
    try: s2.gods_trial.start_fight(1001,79,"10001"); raise AssertionError("2000-cap manual entry succeeded")
    except GodsTrialServiceError: pass
    req(vars(p2)==before and c2==[] and e2.requests==[], "manual capacity rejection mutated")
    # Soft cap permits an authorized 1,999 -> 2,001 first-clear settlement.
    p3,s3,c3,e3,_=services(spirits=minimal_spirits(1999),pid="170cross")
    s3.gods_trial.start_fight(1001,79,"10001")
    win=s3.gods_trial.fight_result(1001,79,[10001],3)
    req(len(win["spirit_items"])==2 and s3.horcrux_repository.owned_count()==2001, "soft cap crossing drift")


def test_weekend_first_clear_ordinary_gift_wire() -> None:
    saturday = int(datetime(2026,8,29,0,0,tzinfo=timezone.utc).timestamp())
    p,s,commits,entropy,clock=services(now=saturday,pid="170weekend")
    req(s.gods_trial.current_weekday()==6, "Saturday source-day fixture drift")
    row=SOURCE.campaign(6001); req(row is not None, "Saturday stage missing")
    first_rows=SOURCE.trial_drop_rows(int(row["init_dropbox"]))
    req(len(first_rows)==1 and int(GAME.get(__import__('gxb_backend.content',fromlist=['ContentRef','CatalogNamespace']).ContentRef(__import__('gxb_backend.content',fromlist=['CatalogNamespace']).CatalogNamespace.ITEM,int(first_rows[0]['item_id'])))['type'])==4, "Saturday first-clear source is not ordinary Gift item")
    s.gods_trial.start_fight(6001,79,"10001")
    result=s.gods_trial.fight_result(6001,79,[10001],3)
    req(len(result["items"])==1 and result["items"][0]["item_num"]==1, f"weekend ordinary reward wire drift: {result}")
    req(result["spirit_items"]==[] and entropy.requests==[], "weekend deterministic first-clear should not draw/materialize Horcrux")


def test_repeat_sampler_stable_independent_rows() -> None:
    p,s,commits,entropy,clock=services(progress={1001:1},entropy_values=[0]*36,pid="170repeat")
    rows=SOURCE.trial_drop_rows(9000001)
    req(len(rows)==36 and all(int(r["increase_rate"])<10000 for r in rows), "repeat fixture/source drift")
    out=s.gods_trial_drops.repeat(9000001)
    req(len(out)==36, "zero rolls should pass every positive residual row")
    req([x.ordinal for x in out]==list(range(1,37)), "repeat row ordering drift")
    req([r.namespace for r in entropy.requests]==["horcrux.trial.repeat.residual"]*36, "repeat RNG namespace drift")
    req(all(r.upper_exclusive==10000 for r in entropy.requests), "repeat residual draw bound drift")


def test_auto_start_maturity_collection_and_replay() -> None:
    # 9999 misses every current residual row, making a deterministic no-drop auto run.
    p,s,commits,entropy,clock=services(progress={1001:1},entropy_values=[9999]*100,pid="170auto")
    start=s.gods_trial.start_auto(1001,2)
    req(start["auto_campaign"]==1001 and start["auto_times"]==2 and start["auto_start_time"]==clock.value, "MID3099 base_info drift")
    req(p.spirit_energy==140 and commits==[1], "auto upfront Spirit Energy debit drift")
    state=copy.deepcopy(vars(p)); draws=len(entropy.requests)
    req(s.gods_trial.start_auto(1001,2)==start and vars(p)==state and commits==[1], "same auto retry not idempotent")
    try: s.gods_trial.start_auto(1001,1); raise AssertionError("different auto request while running succeeded")
    except GodsTrialServiceError: pass
    try: s.gods_trial.collect_auto(); raise AssertionError("premature auto collection succeeded")
    except GodsTrialServiceError: pass
    req(vars(p)==state and len(entropy.requests)==draws, "premature auto collection mutated/consumed RNG")
    clock.value += 2*SOURCE.spirit_auto_minutes*60
    terminal=s.gods_trial.collect_auto()
    req(terminal=={"awards":[],"spirit_awards":[],"base_info":{"auto_campaign":0,"auto_times":0,"auto_start_time":0}}, f"auto terminal projection drift: {terminal}")
    req(s.gods_trial._progress(1001)==3 and len(entropy.requests)==72, "auto attempts/progress/RNG cardinality drift")
    commits_after=len(commits); state_after=copy.deepcopy(vars(p)); draws_after=len(entropy.requests)
    req(s.gods_trial.collect_auto()==terminal, "auto terminal replay drift")
    req(vars(p)==state_after and len(commits)==commits_after and len(entropy.requests)==draws_after, "auto replay duplicated settlement")


def test_auto_guards_and_capacity() -> None:
    p,s,c,e,_=services(pid="170autolocked")
    try: s.gods_trial.start_auto(1001,1); raise AssertionError("uncleared auto succeeded")
    except GodsTrialServiceError: pass
    for bad in (0,11):
        try: s.gods_trial.start_auto(1001,bad); raise AssertionError(f"auto times {bad} succeeded")
        except GodsTrialServiceError: pass
    req(c==[] and e.requests==[], "auto guard mutated/consumed RNG")
    p2,s2,c2,e2,_=services(progress={1001:1},energy=19,pid="170autoenergy")
    try: s2.gods_trial.start_auto(1001,1); raise AssertionError("insufficient auto energy succeeded")
    except GodsTrialServiceError: pass
    req(c2==[] and e2.requests==[], "insufficient auto energy mutated/consumed RNG")
    p3,s3,c3,e3,_=services(progress={1001:1},spirits=minimal_spirits(2000),pid="170autocap")
    try: s3.gods_trial.start_auto(1001,1); raise AssertionError("2000-cap auto succeeded")
    except GodsTrialServiceError: pass
    req(c3==[] and e3.requests==[], "auto capacity guard mutated/consumed RNG")


def test_manual_and_auto_settlement_failure_rollback() -> None:
    # Manual: fail on the second deterministic first-clear Horcrux after the
    # first one was inserted; energy, progress and partial rewards must roll back
    # while the previously committed STAGED session remains retryable.
    p,s,commits,entropy,clock=services(pid="170rollback-manual")
    s.gods_trial.start_fight(1001,79,"10001")
    staged=copy.deepcopy(vars(p)); original=s.horcrux_repository.add_instance; calls=[0]
    def fail_second(row):
        calls[0]+=1
        if calls[0]==2: raise RuntimeError("pass170 injected manual reward failure")
        return original(row)
    s.horcrux_repository.add_instance=fail_second
    try:
        try: s.gods_trial.fight_result(1001,79,[10001],3); raise AssertionError("manual fault injection succeeded")
        except RuntimeError as exc: req("injected" in str(exc), "wrong manual injected failure")
    finally:
        s.horcrux_repository.add_instance=original
    req(vars(p)==staged and commits==[1], "manual reward failure did not restore STAGED state/energy/rewards")

    # Auto collection is a later transaction than the upfront energy debit. A
    # collection failure must restore RUNNING/progress/rewards, but intentionally
    # retain the already committed start debit. Ephemeral Trial RNG is not rewound.
    p2,s2,c2,e2,clock2=services(progress={1001:1},entropy_values=[0]*36,pid="170rollback-auto")
    s2.gods_trial.start_auto(1001,1); clock2.value += 300
    running=copy.deepcopy(vars(p2)); original2=s2.horcrux_repository.add_instance; calls2=[0]
    def fail_second_auto(row):
        calls2[0]+=1
        if calls2[0]==2: raise RuntimeError("pass170 injected auto reward failure")
        return original2(row)
    s2.horcrux_repository.add_instance=fail_second_auto
    try:
        try: s2.gods_trial.collect_auto(); raise AssertionError("auto fault injection succeeded")
        except RuntimeError as exc: req("injected" in str(exc), "wrong auto injected failure")
    finally:
        s2.horcrux_repository.add_instance=original2
    req(vars(p2)==running and c2==[1] and p2.spirit_energy==160, "auto collection failure did not preserve committed start/RUNNING state")
    req(len(e2.requests)>=36 and [r.namespace for r in e2.requests[:36]]==["horcrux.trial.repeat.residual"]*36, "auto collection failure Trial entropy topology drift")


def test_dispatcher_bindings_and_fail_closed() -> None:
    fake=types.ModuleType("flask"); fake.Request=object; fake.jsonify=lambda data=None,**k:data; fake.make_response=lambda data=None,status=200,**k:data; fake.send_file=lambda *a,**k:None
    sys.modules.setdefault("flask",fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    with tempfile.TemporaryDirectory(prefix="pass170_dispatch_") as td:
        root=Path(td); state=StateRepository(DATA/"player_db.json",profile="established",legacy_path=ROOT/"state/gxb_state.json",multiuser_root=root/"server_state")
        d=EngineDispatcher(state,Settings(multiuser_root=root/"server_state",runtime_log_dir=root/"logs"))
        expected={
            MID.HUNQI_START_FIGHT:"start_fight", MID.HUNQI_FIGHT_RESULT:"fight_result",
            MID.HUNQI_GET_CAMPAIGN_INFO:"get_campaign_info", MID.HUNQI_AUTO_FIGHT:"start_auto",
            MID.HUNQI_GET_AUTO_AWRAD:"collect_auto",
        }
        for mid,name in expected.items():
            h=d.handlers.get(mid); req(h is not None and getattr(h,"__self__",None) is d.gods_trial and getattr(h,"__name__","")==name, f"MID {mid} route drift")
    p,s,c,e,_=services(pid="170transport")
    from gxb_backend.handlers.context import HandlerContext
    from gxb_backend.handlers.gods_trial import GodsTrialHandlers
    class St:
        def get_services(self): return s
    class Set: pass
    handler=GodsTrialHandlers(HandlerContext(state=St(),settings=Set(),resource_gateway=None))
    bad=handler.start_fight({"campaign_id":1001,"campaign_type":57,"formation":"10001"})
    req(isinstance(bad,EngineTransportResult) and bad.status_code==409 and bad.body.get("error_code")==1, "invalid campaign_type not fail-closed")
    stale=handler.fight_result({"campaign_id":1001,"campaign_type":79,"partner_ids":[10001],"star":3})
    req(isinstance(stale,dict) and stale.get("error_code")==30005, "unstaged result did not use client-tolerated terminal code")


def main() -> None:
    tests=[
        test_source_catalog_v4_and_wire_correction,
        test_source_day_boundary_and_campaign_projection,
        test_manual_first_clear_terminal_replay_and_next_unlock,
        test_manual_loss_and_soft_capacity_entry_guard,
        test_weekend_first_clear_ordinary_gift_wire,
        test_repeat_sampler_stable_independent_rows,
        test_auto_start_maturity_collection_and_replay,
        test_auto_guards_and_capacity,
        test_manual_and_auto_settlement_failure_rollback,
        test_dispatcher_bindings_and_fail_closed,
    ]
    for test in tests:
        test(); print("PASS",test.__name__,flush=True)
    print(f"PASS Pass170 H5 Gods Trial ({len(tests)}/{len(tests)})",flush=True)


if __name__=="__main__": main()
