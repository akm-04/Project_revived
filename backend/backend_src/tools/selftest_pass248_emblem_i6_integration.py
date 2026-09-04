#!/usr/bin/env python3
from __future__ import annotations

import copy
import json
import tempfile
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.config import Settings
from gxb_backend.content import EmblemSourceCatalog, GameDataCatalog
from gxb_backend.observability.runtime_logger import RuntimeLogger, infer_domain
from gxb_backend.state.emblem_state_repository import EmblemStateRepository
from gxb_backend.state.multiuser_database import MultiUserDatabase
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")


def req(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def hero(*, pid: int = 10001, lev: int = 100, stage: int = 3, inscripts=None) -> dict:
    return {
        "partner_id": pid, "table_id": 11001001, "star": 6,
        "lev": lev, "twice_awake_stage": stage,
        "inscript_items": [] if inscripts is None else inscripts,
    }


def player(name: str = "248001", *, eligible: bool = True) -> PlayerState:
    p = PlayerState(player_id=name, account_uid=name, player_name="Pass248-I6")
    p.heroes = {"10001": hero()} if eligible else {}
    p.backpack_items = []
    p.emblem_state = EmblemStateRepository.default_state("emblem-v1")
    return p


def seed(p: PlayerState, *pairs: tuple[int, int]) -> None:
    p.backpack_items = [
        {"table_id": int(i), "item_num": int(n), "time": 0}
        for i, n in pairs if int(n) > 0
    ]


def services(p: PlayerState, draws=()) -> tuple[RequestServices, ScriptedEntropyProvider]:
    provider = ScriptedEntropyProvider(list(draws))
    s = RequestServices(p, DATA, lambda: None, catalog=CATALOG, entropy_provider=provider)
    return s, provider


def test_global_operational_gate_is_pre_entropy_and_function45_not_auth() -> None:
    p = player("248010", eligible=False)
    p.degree_cer = 999999
    p.function_ids = [45]
    seed(p, (160100101, 1))
    p.mana = 9999999
    s, provider = services(p)
    before = copy.deepcopy(vars(p))
    req(s.emblem.make({"inscript_id": 10001, "make_num": 1}).get("error_code") == 1,
        "Forge bypassed global eligible-Hero gate")
    req(s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 2}).get("error_code") == 1,
        "Reforge bypassed global eligible-Hero gate")
    req(provider.consumed == (), "operational gate consumed entropy")
    req(p.degree_cer == before["degree_cer"] and p.mana == before["mana"], "operational gate consumed economy")
    req(p.emblem_state == before["emblem_state"], "operational gate mutated pity/proposal state")
    req(s.stack_inventory.quantity(160100101) == 1, "operational gate mutated inventory")


def test_operational_gate_accepts_blood3_level100_without_function45_authorization() -> None:
    p = player("248020", eligible=True)
    p.function_ids = []
    p.degree_cer = 90
    s, provider = services(p, [ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 0)])
    out = s.emblem.make({"inscript_id": 10001, "make_num": 1})
    req(out == {"inscript_items": [160100101]}, "eligible Forge failed without Function45 authorization")
    req(s.stack_inventory.quantity(160100101) == 1 and p.degree_cer == 0, "eligible Forge settlement drift")
    provider.assert_exhausted()


def test_star_exchange_forge_equip_remove_resolve_loop() -> None:
    p = player("248030")
    p.crystal = 20
    seed(p, (50001343, 18))
    s, provider = services(p, [ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 0)])
    ex = s.emblem.exchange_materials({})
    req(ex == {"currency_change": [{"currency": 19, "change": 90}]}, "Star exchange wire drift")
    req(p.degree_cer == 90 and s.stack_inventory.quantity(50001343) == 0, "Star exchange state drift")
    made = s.emblem.make({"inscript_id": 10001, "make_num": 1})
    req(made == {"inscript_items": [160100101]}, "exchange->Forge output drift")
    inserted = s.emblem.insert({"partner_id": 10001, "item_id": 160100101, "replace_item_id": 0})
    req(inserted == {"inscript_items": [160100101]}, "Forge->equip drift")
    req(s.stack_inventory.quantity(160100101) == 0, "equipped medal remained in backpack")
    removed = s.emblem.remove({"partner_id": 10001, "item_id": 160100101})
    req(removed == {"inscript_items": []}, "remove response drift")
    req(p.crystal == 0 and s.stack_inventory.quantity(160100101) == 1, "remove settlement drift")
    resolved = s.emblem.resolve({"item_id": 160100101, "resolve_num": 1})
    req(resolved == {} and p.degree_cer == 90, "resolve certificate loop drift")
    req(s.stack_inventory.quantity(160100101) == 0, "resolved medal survived")
    provider.assert_exhausted()


def test_heart_compose_exchange_lv7_forge_loop() -> None:
    p = player("248040")
    seed(p, (50001343, 426), (50001347, 60))
    draws = [
        ScriptedEntropyDraw("emblem.forge.scholarship_gate", 0, 10000, 9999),
        ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 0),
    ]
    s, provider = services(p, draws)
    req(s.item_composition.compose({"item_id": 50001346, "item_num": 1}) == {}, "Heart compose failed")
    req(s.stack_inventory.quantity(50001347) == 0 and s.stack_inventory.quantity(50001346) == 1, "Heart recipe settlement drift")
    ex = s.emblem.exchange_materials({})
    req(ex == {"currency_change": [{"currency": 19, "change": 2130}]}, "Lv7 Star exchange drift")
    out = s.emblem.make({"inscript_id": 10007, "make_num": 1})
    req(out == {"inscript_items": [160100701]}, "Lv7 Heart-backed Forge drift")
    req(p.degree_cer == 0 and s.stack_inventory.quantity(50001346) == 0, "Lv7 costs not consumed")
    req(s.emblem_state.misses_since_special("forge") == 1, "Lv7 miss pity drift")
    provider.assert_exhausted()


def test_scholarship_sets_and_nonforge_artifacts_are_equip_compatible_but_not_generated() -> None:
    source = EmblemSourceCatalog(DATA)
    orphans = [i for i in source.concrete_item_ids() if source.require_concrete_item(i)["classification"] == "SOURCE_PRESENT_NON_FORGE_ORPHAN"]
    req(len(orphans) == 14 and all(not source.is_generation_candidate(i) for i in orphans), "14 Honor artifacts generation fence drift")
    generated = set()
    for iid in source.inscription_ids():
        row = source.require_inscription(iid)
        generated.update(int(v) for v in row.get("candidate_item_ids") or ())
    req(not generated.intersection(orphans), "Honor artifacts leaked into generation pools")

    p = player("248050")
    seed(p, (160500101, 1), (160500102, 1), (160500103, 1), (orphans[0], 1))
    s, provider = services(p)
    for item_id in (160500101, 160500102, 160500103):
        req(s.emblem.insert({"partner_id": 10001, "item_id": item_id, "replace_item_id": 0}).get("error_code", 0) == 0,
            f"3-piece Scholarship insert failed {item_id}")
    equipped = p.heroes["10001"]["inscript_items"]
    req(equipped == [160500101, 160500102, 160500103], "3-piece dense Scholarship layout drift")
    req(set(equipped) == set(source.set_row(2001)["item_ids"]), "3-piece source set membership drift")
    # Remove the Honor set piece, then prove source-present non-forge artifact can occupy the Honor slot.
    p.crystal = 20
    req(s.emblem.remove({"partner_id": 10001, "item_id": 160500102}).get("error_code", 0) == 0, "Scholarship Honor remove failed")
    req(s.emblem.insert({"partner_id": 10001, "item_id": orphans[0], "replace_item_id": 0}).get("error_code", 0) == 0,
        "source-present Honor artifact could not equip")
    req(orphans[0] in p.heroes["10001"]["inscript_items"], "Honor artifact missing after insert")
    provider.assert_exhausted()


def test_dense_equipment_migration_and_malformed_layout_fail_closed_on_insert() -> None:
    p = player("248060")
    p.heroes["10001"]["inscript_items"] = {"2": 160200101, "1": 160100101}
    s, provider = services(p)
    normalized = s.heroes.get(10001)
    req(normalized["inscript_items"] == [160100101, 160200101], "position-map migration did not become dense list")

    # A duplicate physical Honor position is retained as evidence/recovery state,
    # but new insertions must fail closed rather than making the layout worse.
    p.heroes["10001"]["inscript_items"] = [160200101, 160200102]
    seed(p, (160300101, 1))
    before = copy.deepcopy(p.heroes["10001"]["inscript_items"])
    out = s.emblem.insert({"partner_id": 10001, "item_id": 160300101, "replace_item_id": 0})
    req(out.get("error_code") == 1 and p.heroes["10001"]["inscript_items"] == before,
        "malformed layout accepted a new insertion")
    provider.assert_exhausted()


def test_load_maintenance_durably_normalizes_emblem_state_and_dense_hero_shape() -> None:
    p = player("248070")
    p.emblem_state = {
        "schema_version": 0,
        "proposal_generation": -8,
        "pending_rebuild": {"garbage": True},
        "scholarship_rng": {"forge": {"misses_since_special": -2}},
    }
    p.heroes["10001"]["inscript_items"] = {"1": 160100101, "3": 160300101}
    with tempfile.TemporaryDirectory() as td:
        db = MultiUserDatabase(Path(td), DATA)
        req(db.normalize_player(p, persist=True), "maintenance reported no normalization")
        loaded = db.load_player(str(p.player_id))
        req(loaded is not None, "normalized player did not persist")
        req(loaded.emblem_state == EmblemStateRepository.default_state("emblem-v1"), "Emblem state load normalization drift")
        req(loaded.heroes["10001"]["inscript_items"] == [160100101, 160300101], "dense Hero Emblem shape did not persist")


def test_paid_proposal_remains_recoverable_if_eligibility_is_lost_after_rebuild() -> None:
    p = player("248080")
    p.mana = 100000
    seed(p, (160100101, 1))
    s, provider = services(p, [ScriptedEntropyDraw("emblem.reforge.ordinary", 0, 76, 0)])
    proposal = s.emblem.rebuild({"item_id": 160100101, "rebuild_num": 1, "cost_type": 2})
    req(proposal == {"inscript_items": [160100102]}, "paid proposal setup drift")
    p.heroes["10001"]["twice_awake_stage"] = 2
    # New Forge/Reforge must now be gated, but already-paid Save remains usable.
    req(s.emblem.make({"inscript_id": 10001, "make_num": 1}).get("error_code") == 1, "eligibility loss did not gate new Forge")
    saved = s.emblem.save_rebuild({"item_id": 160100102})
    req(saved == {"rebuild_items": [{"table_id": 160100102, "item_num": 1}]}, "paid proposal stranded after eligibility loss")
    req(s.emblem_state.pending_rebuild() is None and s.stack_inventory.quantity(160100102) == 1, "Save recovery settlement drift")
    provider.assert_exhausted()


def test_campaign_catalog_contains_all_core_emblem_acquisition_items() -> None:
    raw = json.loads((DATA / "campaign_drop_source_catalog.json").read_text(encoding="utf-8"))
    seen: dict[int, set[int]] = {50001343: set(), 50001344: set(), 50001345: set(), 50001347: set()}
    for key, row in (raw.get("campaigns") or {}).items():
        cid = int(row.get("campaign_id", key) or 0)
        for branch in ("init_dropbox_rows", "repeat_dropbox_rows"):
            for drop in row.get(branch) or ():
                iid = int(drop.get("item_id", 0) or 0)
                if iid in seen:
                    seen[iid].add(cid)
    req(all(seen.values()), f"Campaign core Emblem acquisition gap: {seen}")
    req(1700003 in seen[50001343] and 1700006 in seen[50001344] and 1700009 in seen[50001345], "chapter17 Star acquisition source anchors drift")
    req(1800003 in seen[50001347], "chapter18 Heart-fragment source anchor drift")


def test_integrated_mutations_advance_state_version_once_per_committed_action() -> None:
    p = player("248090")
    p.crystal = 20
    seed(p, (50001343, 18))
    s, provider = services(p, [ScriptedEntropyDraw("emblem.forge.ordinary", 0, 84, 0)])
    versions = [int(p.persistence_state.get("state_version", 0))]
    req(s.emblem.exchange_materials({}).get("error_code", 0) == 0, "exchange failed")
    versions.append(int(p.persistence_state.get("state_version", 0)))
    made = s.emblem.make({"inscript_id": 10001, "make_num": 1})
    versions.append(int(p.persistence_state.get("state_version", 0)))
    item_id = int(made["inscript_items"][0])
    req(s.emblem.insert({"partner_id": 10001, "item_id": item_id, "replace_item_id": 0}).get("error_code", 0) == 0, "insert failed")
    versions.append(int(p.persistence_state.get("state_version", 0)))
    req(s.emblem.remove({"partner_id": 10001, "item_id": item_id}).get("error_code", 0) == 0, "remove failed")
    versions.append(int(p.persistence_state.get("state_version", 0)))
    req(s.emblem.resolve({"item_id": item_id, "resolve_num": 1}).get("error_code", 0) == 0, "resolve failed")
    versions.append(int(p.persistence_state.get("state_version", 0)))
    req(versions == list(range(versions[0], versions[0] + 6)), f"state_version commit topology drift: {versions}")
    provider.assert_exhausted()


def test_runtime_logger_emblem_event_is_wire_separate_and_bounded() -> None:
    req(infer_domain(1400) == "emblem" and infer_domain(1407) == "emblem", "Emblem runtime domain classification drift")
    with tempfile.TemporaryDirectory() as td:
        logger = RuntimeLogger(Settings(runtime_log_dir=Path(td), log_all_requests=False))
        snapshot = {
            "policy_version": "emblem-v1", "state_policy_version": "emblem-v1",
            "proposal_generation": 4, "pending_generation": 4,
            "pending_candidate_count": 10, "forge_misses_since_special": 7,
            "reforge_misses_since_special": 9,
        }
        response = {"inscript_items": [160100101]}
        logger.emblem_event(mid=1401, name="INSCRIPTION_REBUILD", response=response, snapshot=snapshot)
        row = json.loads((Path(td) / "emblem_events.jsonl").read_text(encoding="utf-8").splitlines()[-1])
        req(row["policy_version"] == "emblem-v1" and row["proposal_generation"] == 4 and row["pending_candidate_count"] == 10,
            "Emblem runtime audit fields drift")
        text = json.dumps(row, sort_keys=True)
        req("160100101" not in text and "inscript_items" not in text, "Emblem runtime audit leaked candidate/wire payload")
        req(response == {"inscript_items": [160100101]}, "runtime logging mutated wire response")


def main() -> int:
    tests = [value for name, value in sorted(globals().items()) if name.startswith("test_") and callable(value)]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS248_I6 {len(tests)}/{len(tests)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
