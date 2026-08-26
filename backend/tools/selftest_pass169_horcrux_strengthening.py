#!/usr/bin/env python3
"""Pass169 H4 MID3089 strengthening + deterministic policy regression gate."""
from __future__ import annotations

import copy
import hashlib
import json
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
from gxb_backend.state.horcrux_service import HorcruxServiceError
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.random_outcome_service import EntropyDrawRequest
from gxb_backend.state.request_services import RequestServices
from gxb_backend.transport.result import EngineTransportResult

GAME = GameDataCatalog.load(DATA / "game_data_catalog.json")
SOURCE = HorcruxSourceCatalog(DATA, game_data=GAME)

TARGET_TABLE = 250000111  # model1, star1, pos1, sub_num2
OATH_TABLE = 250001151    # model49, star5, pos1, base fodder EXP 20000
BASIC_FODDER_TABLE = 250000112  # star1 model2, base EXP 500


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


class ScriptedEntropy:
    def __init__(self, values=()) -> None:
        self.values = list(values)
        self.requests: list[EntropyDrawRequest] = []

    def draw(self, request: EntropyDrawRequest) -> int:
        self.requests.append(request)
        value = self.values.pop(0) if self.values else 0
        if value < 0 or value >= request.upper_exclusive:
            raise AssertionError(f"scripted entropy {value} invalid for {request}")
        return value


def instance(spirit_id: int, table_id: int, *, exp: int = 0, lev: int = 0,
             sub=(), sub_values=(), is_lock=0, is_equip=0, collo_count=0) -> dict:
    template = SOURCE.template(table_id); req(template is not None, f"unknown template {table_id}")
    model = SOURCE.model(template["model_id"]); req(model is not None, "unknown model")
    main_selector = 1
    selectors = list(sub)
    attrs = [int(model["sub"][sel - 1]) for sel in selectors]
    values = list(sub_values) if sub_values else [model["sub_value"][sel - 1] for sel in selectors]
    return {
        "spirit_id": spirit_id,
        "table_id": table_id,
        "star": int(model["star"]),
        "lev": lev,
        "exp": exp,
        "main": main_selector,
        "main_attr": int(model["main"][0]),
        "main_attr_value": model["main_value"][0] + lev * model["main_strth"][0],
        "sub": selectors,
        "sub_attr": attrs,
        "sub_attr_value": values,
        "is_equip": is_equip,
        "is_lock": is_lock,
        "collo_count": collo_count,
    }


def services(spirits: list[dict], *, mana=10_000_000, values=(), pid="169001", hero_slots=None, collocation_refs=None):
    player = apply_established_profile(PlayerState())
    player.player_id = player.account_uid = pid
    player.player_name = "Pass169 H4"
    player.mana = mana
    player.spirit_list = copy.deepcopy(spirits)
    player.heroes = {
        "10001": {"partner_id":10001,"table_id":10001001,"star":5,"spirit_equip":list(hero_slots or [0]*6)}
    }
    player.horcrux_state = {}
    if collocation_refs is not None:
        player.horcrux_state = {
            "collocations": {"1": {"id":1,"name":"Guard","spirit_ids":list(collocation_refs)}}
        }
    commits: list[int] = []
    entropy = ScriptedEntropy(values)
    svc = RequestServices(player, DATA, lambda: commits.append(1), catalog=GAME, entropy_provider=entropy)
    svc.heroes.normalize(); svc.horcrux_repository.normalize()
    return player, svc, commits, entropy


def by_id(player):
    return {int(row["spirit_id"]): row for row in player.spirit_list}


def test_source_catalog_v3_and_rebuild() -> None:
    req(SOURCE.max_strength_level == 15, "max strengthening level drift")
    req(SOURCE.fodder_exp_rate == 0.6, "fodder EXP rate drift")
    req(SOURCE.mana_per_strength_exp == 25, "Mana multiplier drift")
    req(SOURCE.strengthening_milestones == (3, 6, 9, 12, 15), "milestone source drift")
    req(SOURCE.spirit_num_limit == 2000 and SOURCE.program_limit == 20, "source limits drift")
    req(SOURCE.strengthening_max_exp(1) == 67500 and SOURCE.strengthening_max_exp(6) == 236250, "strengthening cumulative table drift")
    with tempfile.TemporaryDirectory(prefix="pass169_catalog_") as td:
        out = Path(td) / "horcrux_source_catalog.json"
        subprocess.run([
            sys.executable, str(ROOT / "tools/build_horcrux_source_catalog.py"),
            "--src64", str(ROOT / "source_evidence/src_64"), "--output", str(out),
        ], check=True, stdout=subprocess.DEVNULL)
        req(out.read_bytes() == (DATA / "horcrux_source_catalog.json").read_bytes(), "source-evidence catalog rebuild not byte-identical")


def test_fodder_guards_and_insufficient_mana_are_read_only() -> None:
    base_target = instance(1, TARGET_TABLE)
    cases = [
        ("locked", instance(2, BASIC_FODDER_TABLE, is_lock=1), {}, [2]),
        ("equipped", instance(2, BASIC_FODDER_TABLE), {"hero_slots":[0,2,0,0,0,0]}, [2]),
        ("collocated", instance(2, BASIC_FODDER_TABLE), {"collocation_refs":[0,2,0,0,0,0]}, [2]),
    ]
    for label, fodder, opts, request_ids in cases:
        p, s, commits, entropy = services([base_target, fodder], pid=f"169guard-{label}", **opts)
        before = copy.deepcopy(vars(p))
        try: s.horcrux.strengthen(1, request_ids); raise AssertionError(f"{label} fodder succeeded")
        except HorcruxServiceError: pass
        req(vars(p) == before and commits == [] and entropy.requests == [], f"{label} rejection mutated/consumed entropy")

    p, s, commits, entropy = services([base_target, instance(2, BASIC_FODDER_TABLE)], mana=0, pid="169guard-mana")
    before = copy.deepcopy(vars(p))
    try: s.horcrux.strengthen(1, [2]); raise AssertionError("insufficient Mana succeeded")
    except HorcruxServiceError: pass
    req(vars(p) == before and commits == [] and entropy.requests == [], "insufficient Mana mutated/consumed entropy")

    for bad in ([2,2], [1], [999]):
        p, s, commits, entropy = services([base_target, instance(2, BASIC_FODDER_TABLE)], pid=f"169bad-{len(bad)}-{bad[0]}")
        before = copy.deepcopy(vars(p))
        try: s.horcrux.strengthen(1, bad); raise AssertionError(f"bad fodder request succeeded: {bad}")
        except HorcruxServiceError: pass
        req(vars(p) == before and commits == [] and entropy.requests == [], f"bad fodder request mutated: {bad}")


def test_cost_exp_overshoot_and_full_response() -> None:
    # 67,400/67,500 target EXP; 500-EXP fodder. Full 500 EXP costs 12,500 Mana,
    # stored EXP clamps at 67,500 and the level-15 milestone is still processed.
    target = instance(1, TARGET_TABLE, exp=67400, lev=14, sub=[1], sub_values=[40])
    fodder = instance(2, BASIC_FODDER_TABLE)
    p, s, commits, entropy = services([target, fodder], mana=20_000, values=[1], pid="169overshoot")
    out = s.horcrux.strengthen(1, [2])
    req(out["spirit_id"] == 1 and out["table_id"] == TARGET_TABLE, "full target identity response drift")
    req(out["exp"] == 67500 and out["lev"] == 15, f"level cap/EXP clamp drift: {out}")
    req(p.mana == 7_500, f"full gained-EXP Mana cost not charged: {p.mana}")
    req(len(p.spirit_list) == 1 and by_id(p)[1] == out, "fodder/target settlement drift")
    req(out["main_attr_value"] == 99.0, f"main stat level recompute drift: {out['main_attr_value']}")
    req([r.namespace for r in entropy.requests] == ["horcrux.enhance.action"], f"overshoot milestone topology drift: {entropy.requests}")
    req(commits == [1], "overshoot did not commit exactly once")


def test_milestone_rng_topology_forced_and_sequential() -> None:
    # Oath fodder base 20,000 + 60% of 12,000 = 27,200 EXP. Star1 target rises
    # 0->9, crossing 3/6/9. Policy: milestone3 forced ADD; milestone6 action=ADD;
    # milestone9 forced IMPROVE once sub_num2 is reached.
    target = instance(1, TARGET_TABLE)
    fodder = instance(2, OATH_TABLE, exp=12000)
    p, s, commits, entropy = services([target, fodder], values=[0, 0, 0, 0], pid="169topology")
    out = s.horcrux.strengthen(1, [2])
    req(out["exp"] == 27200 and out["lev"] == 9, "gained EXP/level topology setup drift")
    req(out["sub"] == [1,2] and out["sub_attr"] == [4,5], f"ADD selector order drift: {out}")
    req(out["sub_attr_value"] == [60,4], f"IMPROVE aligned increment drift: {out['sub_attr_value']}")
    req([r.namespace for r in entropy.requests] == [
        "horcrux.enhance.new_sub",
        "horcrux.enhance.action",
        "horcrux.enhance.new_sub",
        "horcrux.enhance.improve_target",
    ], f"milestone namespace order drift: {entropy.requests}")
    req([r.upper_exclusive for r in entropy.requests] == [12,2,11,2], "milestone draw bounds drift")
    req(p.mana == 10_000_000 - 27200*25 and commits == [1], "milestone settlement cost/commit drift")


def test_receipt_replay_is_exactly_once() -> None:
    target = instance(1, TARGET_TABLE)
    f2 = instance(2, OATH_TABLE, exp=12000)
    f3 = instance(3, BASIC_FODDER_TABLE)
    p, s, commits, entropy = services([target, f2, f3], values=[0,0,0,0], pid="169receipt")
    out1 = s.horcrux.strengthen(1, [3,2])
    mana_after = p.mana; draws_after = len(entropy.requests); state_after = copy.deepcopy(vars(p))
    out2 = s.horcrux.strengthen(1, [2,3])  # same canonical consumed-ID set
    req(out2 == out1, "enhancement receipt did not replay full target")
    req(p.mana == mana_after and len(entropy.requests) == draws_after and commits == [1], "receipt replay duplicated cost/RNG/commit")
    req(vars(p) == state_after, "receipt replay mutated state")
    receipts = p.persistence_state.get("receipts", {}).get("horcrux.enhance", {})
    req(len(receipts) == 1 and next(iter(receipts.values()))["replay_payload"] == out1, "durable enhancement receipt drift")


def test_failure_after_debit_and_fodder_removal_rolls_back() -> None:
    target = instance(1, TARGET_TABLE)
    fodder = instance(2, OATH_TABLE, exp=12000)
    p, s, commits, entropy = services([target, fodder], values=[0,0,0,0], pid="169rollback")
    before = copy.deepcopy(vars(p))
    original = s.horcrux_repository.replace_instance
    def boom(*args, **kwargs):
        raise RuntimeError("pass169 injected replace failure")
    s.horcrux_repository.replace_instance = boom
    try:
        try: s.horcrux.strengthen(1, [2]); raise AssertionError("fault injection unexpectedly succeeded")
        except RuntimeError as exc: req("injected" in str(exc), "wrong injected failure")
    finally:
        s.horcrux_repository.replace_instance = original
    req(vars(p) == before and commits == [], "UoW did not restore Mana/fodder/target/receipt after failure")
    req(len(entropy.requests) == 4, "expected ephemeral policy entropy to be consumed before injected failure")


def test_dispatcher_binding_and_transport_failure() -> None:
    fake = types.ModuleType("flask"); fake.Request=object; fake.jsonify=lambda data=None,**k:data; fake.make_response=lambda data=None,status=200,**k:data; fake.send_file=lambda *a,**k:None
    sys.modules.setdefault("flask", fake)
    from gxb_backend.config import Settings
    from gxb_backend.dispatch.engine_dispatcher import EngineDispatcher
    from gxb_backend.state.repository import StateRepository
    with tempfile.TemporaryDirectory(prefix="pass169_dispatch_") as td:
        root=Path(td); state=StateRepository(DATA/'player_db.json',profile='established',legacy_path=ROOT/'state/gxb_state.json',multiuser_root=root/'server_state')
        d=EngineDispatcher(state,Settings(multiuser_root=root/'server_state',runtime_log_dir=root/'logs'))
        h=d.handlers.get(MID.HUNQI_ENHANCE)
        req(h is not None and getattr(h,'__self__',None) is d.horcrux and getattr(h,'__name__','')=='strengthen', 'MID3089 route drift')
    p, s, _commits, _entropy = services([instance(1,TARGET_TABLE), instance(2,BASIC_FODDER_TABLE)], mana=0, pid="169transport")
    from gxb_backend.handlers.context import HandlerContext
    from gxb_backend.handlers.horcrux import HorcruxHandlers
    class St:
        def get_services(self): return s
    class Set: pass
    result=HorcruxHandlers(HandlerContext(state=St(),settings=Set(),resource_gateway=None)).strengthen({'spirit_id':1,'spirit_ids':[2]})
    req(isinstance(result,EngineTransportResult) and result.status_code==409 and result.body.get('error_code')==1, 'MID3089 failure not fail-closed HTTP409')


def main() -> None:
    tests = [
        test_source_catalog_v3_and_rebuild,
        test_fodder_guards_and_insufficient_mana_are_read_only,
        test_cost_exp_overshoot_and_full_response,
        test_milestone_rng_topology_forced_and_sequential,
        test_receipt_replay_is_exactly_once,
        test_failure_after_debit_and_fodder_removal_rolls_back,
        test_dispatcher_binding_and_transport_failure,
    ]
    for test in tests:
        test(); print("PASS", test.__name__, flush=True)
    print(f"PASS Pass169 H4 Horcrux strengthening ({len(tests)}/{len(tests)})", flush=True)


if __name__ == "__main__":
    main()
