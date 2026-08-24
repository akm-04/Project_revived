#!/usr/bin/env python3
from __future__ import annotations

import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))
DATA = ROOT / "data"

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.campaign_drop_planner import CAMPAIGN_FIRST_CLEAR_NAMESPACE
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.request_services import RequestServices
from gxb_backend.testing.scripted_entropy import ScriptedEntropyDraw, ScriptedEntropyProvider

CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
DROP_SOURCE = json.loads((DATA / "campaign_drop_source_catalog.json").read_text(encoding="utf-8"))["campaigns"]
STAGE_RECEIPT_DOMAIN = "mid113_campaign_battle_stage"
RESULT_RECEIPT_DOMAIN = "mid114_campaign_battle_result"

LEGACY_UUID_A = "mid113-123e4567-e89b-42d3-a456-426614174000"
LEGACY_UUID_B = "mid113-123e4567-e89b-42d3-a456-426614174001"


def require(condition: bool, message: str) -> None:
    if not condition:
        raise AssertionError(message)


def make_player(campaign_id: int = 100001, *, star: int = 0, energy: int = 100) -> PlayerState:
    p = PlayerState(player_id="991230", account_uid="991230", player_name="Pass123", vip=15)
    p.lev = 100
    p.max_lev = 100
    p.energy = energy
    p.max_energy = 160
    p.energy_time = 0
    p.crystal = 1000
    p.world_map = {
        "normal": [
            {"campaign_id": campaign_id, "star": star, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}
        ],
        "super": [],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 1,
            "normal_campaign_id": campaign_id,
            "super_chapter_id": 0,
            "super_campaign_id": 0,
            "normal_stars": star,
            "normal_bonus_id": 0,
            "super_stars": 0,
            "super_bonus_id": 0,
        },
    }
    return p


def make_super_player(campaign_id: int = 1600022, *, star: int = 1, daily_limit: int = 3, energy: int = 100) -> PlayerState:
    p = PlayerState(player_id="991231", account_uid="991231", player_name="Pass123Super", vip=15)
    p.lev = 100
    p.max_lev = 100
    p.energy = energy
    p.max_energy = 160
    p.energy_time = 0
    p.crystal = 1000
    # Pass128 canonical unlocked-Elite fixture.  Historical tests previously
    # treated a preexisting Super row as sufficient authority; production now
    # also requires the server-announced Function31 state.
    p.func_ids = [31]
    p.world_map = {
        "normal": [{"campaign_id": 1600016, "star": 3, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0}],
        "super": [{"campaign_id": campaign_id, "star": star, "daily_limit": daily_limit, "reset_count": 0, "is_partner_drop": 0}],
        "challenge": [],
        "chapter_events": {},
        "chapter_info": {
            "normal_chapter_id": 16, "normal_campaign_id": 1600016,
            "super_chapter_id": 16, "super_campaign_id": campaign_id,
            "normal_stars": 3, "normal_bonus_id": 0,
            "super_stars": star, "super_bonus_id": 0,
        },
    }
    return p


def service(player: PlayerState, draws: list[ScriptedEntropyDraw] | None = None, commits: list[int] | None = None):
    commits = commits if commits is not None else []
    provider = ScriptedEntropyProvider(draws or [])
    svc = RequestServices(player, DATA, lambda: commits.append(1), catalog=CATALOG, entropy_provider=provider)
    return svc, provider, commits


def first_clear_draws(campaign_id: int, value: int) -> list[ScriptedEntropyDraw]:
    rows = DROP_SOURCE[str(campaign_id)]["init_dropbox_rows"]
    intermediate = [row for row in rows if 0 < int(row["increase_rate"]) < 10000]
    return [
        ScriptedEntropyDraw(CAMPAIGN_FIRST_CLEAR_NAMESPACE, idx, 10000, value)
        for idx in range(len(intermediate))
    ]


def backpack_qty(player: PlayerState, item_id: int) -> int:
    return sum(
        int(row.get("item_num", 0) or 0)
        for row in player.backpack_items
        if int(row.get("table_id", 0) or 0) == int(item_id)
    )


def receipt_domains(player: PlayerState) -> set[str]:
    root = player.persistence_state if isinstance(player.persistence_state, dict) else {}
    receipts = root.get("receipts") if isinstance(root.get("receipts"), dict) else {}
    return set(str(key) for key in receipts.keys())


def test_stock_shape_sticky_stage_and_legacy_uuid_ignored() -> None:
    p = make_player(1900019, star=0)
    svc1, entropy1, commits = service(p, first_clear_draws(1900019, 0))
    first = svc1.world.begin_fight({
        "campaign_id": 1900019,
        "campaign_type": 1,
        "formation": "10001|10002",
    })
    require(first.get("error_code", 0) == 0, f"stock-shape MID113 failed: {first}")
    entropy1.assert_exhausted()
    active = p.active_campaign_battle
    require(active.get("schema_version") == 2 and active.get("status") == "STAGED", f"v2 session not staged: {active}")
    require(active.get("formation_snapshot") == "10001|10002", f"formation audit snapshot missing: {active}")
    require("operation_id" not in active and "stage_fingerprint" not in active and "committed" not in active, f"Pass117 identity leaked into v2 session: {active}")
    require(STAGE_RECEIPT_DOMAIN not in receipt_domains(p), "new MID113 wrote retired stage receipt")

    svc2, entropy2, _ = service(p, [], commits)
    replay = svc2.world.begin_fight({
        "campaign_battle_op_id": LEGACY_UUID_A,
        "campaign_id": 1900019,
        "campaign_type": 1,
        "formation": "DIFFERENT_FORMATION",
    })
    require(replay == first, "same Campaign/type STAGED replay changed frozen MID113 response")
    require(entropy2.consumed == (), "same-stage replay consumed RNG")
    require(p.active_campaign_battle.get("formation_snapshot") == "10001|10002", "replay rewrote audit formation")
    require(STAGE_RECEIPT_DOMAIN not in receipt_domains(p), "legacy UUID resurrected MID113 receipt writes")


def test_invalid_supersede_preserves_stage_and_valid_other_campaign_replaces() -> None:
    p = make_player(100001, star=1)
    p.world_map["normal"].append({"campaign_id": 100002, "star": 1, "daily_limit": 0, "reset_count": 0, "is_partner_drop": 0})
    svc, entropy, _ = service(p)
    first = svc.world.begin_fight({"campaign_id": 100001, "campaign_type": 1, "formation": "A"})
    require(first.get("error_code", 0) == 0, f"initial repeat stage failed: {first}")
    require(entropy.consumed == (), "repeat stage unexpectedly consumed RNG")
    prior = json.loads(json.dumps(p.active_campaign_battle))

    bad = svc.world.begin_fight({"campaign_id": 99999999, "campaign_type": 1, "formation": "B"})
    require(bad.get("error_code") == 1, f"invalid different stage did not fail closed: {bad}")
    require(p.active_campaign_battle == prior, "invalid different MID113 destroyed/superseded live stage")

    second = svc.world.begin_fight({"campaign_id": 100002, "campaign_type": 1, "formation": "B"})
    require(second.get("error_code", 0) == 0, f"valid different stage did not supersede: {second}")
    require(int(p.active_campaign_battle.get("campaign_id", 0)) == 100002, f"valid different stage did not become active: {p.active_campaign_battle}")
    require(p.active_campaign_battle.get("formation_snapshot") == "B", "superseding stage audit formation wrong")


def test_mid114_terminal_30005_live_projection_and_no_receipts() -> None:
    p = make_player(100001, star=0, energy=100)
    svc1, entropy1, commits = service(p)
    stage = svc1.world.begin_fight({
        "campaign_battle_op_id": LEGACY_UUID_A,
        "campaign_id": 100001,
        "campaign_type": 1,
        "formation": "10083|10059",
    })
    require(stage.get("items") == [{"item_id": 20001001, "item_num": 1}], f"first-clear stage drift: {stage}")
    require(entropy1.consumed == (), "guaranteed first-clear consumed RNG")
    before_item = backpack_qty(p, 20001001)

    svc2, entropy2, _ = service(p, [], commits)
    win = svc2.world.commit_fight_result({
        "campaign_battle_op_id": LEGACY_UUID_B,
        "campaign_id": 100001,
        "campaign_type": 1,
        "formation": "CHANGED_FORMATION",
        "star": 1,
    })
    require(win.get("error_code", 0) == 0 and win.get("is_win") == 1, f"source-shaped MID114 failed: {win}")
    require(backpack_qty(p, 20001001) == before_item + 1, "MID114 did not commit frozen first-clear item once")
    require(entropy2.consumed == (), "MID114 rerolled Campaign entropy")
    require(p.active_campaign_battle.get("status") == "SETTLED_WIN", f"terminal state missing: {p.active_campaign_battle}")
    require("operation_id" not in p.active_campaign_battle, "terminal session retained Pass117 operation authority")
    require(STAGE_RECEIPT_DOMAIN not in receipt_domains(p) and RESULT_RECEIPT_DOMAIN not in receipt_domains(p), "Pass123 wrote retired Campaign battle receipts")
    committed_item = backpack_qty(p, 20001001)
    committed_energy = p.energy

    # Live mutable projections must refresh while static terminal fields remain frozen.
    p.energy = max(0, committed_energy - 3)
    svc3, entropy3, _ = service(p, [], commits)
    duplicate = svc3.world.commit_fight_result({
        "campaign_id": 100001,
        "campaign_type": 1,
        "formation": "ANY_FORMATION",
        "star": 3,
    })
    require(duplicate.get("error_code") == 30005, f"terminal duplicate did not use source 30005: {duplicate}")
    require(duplicate.get("is_win") == 1 and duplicate.get("items") == [], f"terminal static response drift: {duplicate}")
    require(duplicate.get("economy_", {}).get("energy") == p.energy, f"terminal duplicate did not render live economy projection: {duplicate.get('economy_')}")
    require(backpack_qty(p, 20001001) == committed_item, "terminal duplicate double-granted reward")
    require(entropy3.consumed == (), "terminal duplicate consumed RNG")
    require(RESULT_RECEIPT_DOMAIN not in receipt_domains(p), "terminal duplicate resurrected result receipt")


def test_unmatched_mid114_is_family_bounded_terminal_drain() -> None:
    p = make_player(100001, star=0, energy=100)
    svc, entropy, commits = service(p)
    before = json.dumps(vars(p), sort_keys=True, default=str)
    drain = svc.world.commit_fight_result({
        "campaign_id": 100001,
        "campaign_type": 1,
        "formation": "",
        "star": 3,
        "campaign_battle_op_id": LEGACY_UUID_A,
    })
    require(drain.get("error_code") == 30005, f"unmatched Campaign MID114 was not drained with 30005: {drain}")
    require(drain.get("campaigns") == [] and drain.get("items") == [], f"unmatched drain minted projection/reward: {drain}")
    require(p.energy == 100 and backpack_qty(p, 20001001) == 0, "unmatched drain mutated economy/inventory")
    require(not p.active_campaign_battle, "unmatched drain fabricated active session")
    require(entropy.consumed == (), "unmatched drain consumed RNG")
    require(RESULT_RECEIPT_DOMAIN not in receipt_domains(p), "unmatched drain wrote result receipt")
    # RequestServices initialization may normalize persistence metadata, so avoid
    # requiring byte-identical whole-player JSON; mutation-sensitive fields above
    # are the source-backed invariant.


def test_super_attempt_consumed_once_terminal_duplicate_zero_extra() -> None:
    p = make_super_player(star=1, daily_limit=3, energy=100)
    svc1, entropy1, commits = service(p)
    stage = svc1.world.begin_fight({
        "campaign_id": 1600022,
        "campaign_type": 2,
        "formation": "A",
    })
    require(stage.get("error_code", 0) == 0, f"Super MID113 failed: {stage}")
    require(entropy1.consumed == (), "Super repeat MID113 consumed RNG")
    require(int(p.world_map["super"][0]["daily_limit"]) == 3, "Super MID113 consumed an attempt")

    svc2, entropy2, _ = service(p, [], commits)
    result = svc2.world.commit_fight_result({
        "campaign_id": 1600022,
        "campaign_type": 2,
        "formation": "B",
        "star": 1,
    })
    require(result.get("error_code", 0) == 0 and result.get("is_win") == 1, f"Super MID114 failed: {result}")
    require(int(p.world_map["super"][0]["daily_limit"]) == 2, "Super MID114 did not consume exactly one attempt")
    require(entropy2.consumed == (), "Super MID114 consumed RNG")

    svc3, entropy3, _ = service(p, [], commits)
    duplicate = svc3.world.commit_fight_result({
        "campaign_battle_op_id": LEGACY_UUID_A,
        "campaign_id": 1600022,
        "campaign_type": 2,
        "formation": "C",
        "star": 3,
    })
    require(duplicate.get("error_code") == 30005, f"Super duplicate did not return 30005: {duplicate}")
    require(int(p.world_map["super"][0]["daily_limit"]) == 2, "Super terminal duplicate consumed another attempt")
    require(entropy3.consumed == (), "Super terminal duplicate consumed RNG")


def test_ota_16318_stock_rollback_shape() -> None:
    manifest = json.loads((ROOT / "local_assets/update_manifest.json").read_text(encoding="utf-8"))
    require(manifest.get("version") == "1.631.8", f"OTA version drift: {manifest.get('version')}")
    require(manifest.get("package") == "gxb-local-1.631.8.zip", f"OTA package drift: {manifest.get('package')}")
    files = manifest.get("files") or []
    require(len(files) == 138, f"cumulative OTA file count expected 138 got {len(files)}")
    six = {
        f"{arch}/{rel}"
        for arch in ("src_32", "src_64")
        for rel in (
            "app/windows/SelectTeamNewWindow.lua",
            "app/windows/SelectTeamWindow.lua",
            "app/scenes/BattleCreate.lua",
        )
    }
    require(six.issubset(set(files)), "OTA 1.631.8 omitted one or more explicit rollback files")

    for rel in sorted(six):
        text = (ROOT / "local_assets" / rel).read_text(encoding="utf-8")
        require("campaign_battle_op_id" not in text, f"{rel} still injects/carries Pass117 Campaign UUID")
        require("campaignBattleOpID" not in text, f"{rel} still retains hidden Campaign identity")
    # Cumulative bridges outside the six rollback files must remain present.
    for arch in ("src_32", "src_64"):
        self_player = (ROOT / "local_assets" / arch / "app/model/SelfPlayer.lua").read_text(encoding="utf-8")
        sweep = (ROOT / "local_assets" / arch / "app/windows/SweepWindow.lua").read_text(encoding="utf-8")
        require("generateUUID" in self_player, f"{arch} MID50 UUID bridge missing")
        require("generateUUID" in sweep, f"{arch} MID117 UUID bridge missing")

    volume = ROOT / "local_assets/updates/gxb-local-1.631.8.zip.001"
    require(volume.exists(), "OTA 1.631.8 cumulative volume missing")
    with zipfile.ZipFile(volume) as zf:
        require(len(zf.namelist()) == 138, f"OTA volume entry count expected 138 got {len(zf.namelist())}")
        require(set(zf.namelist()) == set(files), "OTA volume entries do not match manifest")
        for rel in six:
            require(zf.read(rel) == (ROOT / "local_assets" / rel).read_bytes(), f"OTA rollback entry differs from sparse source: {rel}")


def main() -> None:
    tests = [
        test_stock_shape_sticky_stage_and_legacy_uuid_ignored,
        test_invalid_supersede_preserves_stage_and_valid_other_campaign_replaces,
        test_mid114_terminal_30005_live_projection_and_no_receipts,
        test_unmatched_mid114_is_family_bounded_terminal_drain,
        test_super_attempt_consumed_once_terminal_duplicate_zero_extra,
        test_ota_16318_stock_rollback_shape,
    ]
    for test in tests:
        test()
        print(f"PASS {test.__name__}")
    print(f"PASS Pass123 manual battle session/OTA ({len(tests)} tests)")


if __name__ == "__main__":
    main()
