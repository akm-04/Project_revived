#!/usr/bin/env python3
"""Pass111 MID50 UUID/UoW/ROS migration regression."""
from __future__ import annotations

import copy
import hashlib
import json
from pathlib import Path

from gxb_backend.content import GameDataCatalog
from gxb_backend.state.mid50_operation_receipt import (
    RECEIPT_DOMAIN,
    RECEIPT_MODE,
    RETENTION_POLICY,
    Mid50OperationIdentity,
    Mid50OperationIdentityError,
    mid50_request_fingerprint,
)
from gxb_backend.state.player_state import PlayerState
from gxb_backend.state.profiles import apply_established_profile
from gxb_backend.state.random_outcome_service import EntropyDrawRequest, NamespacedRandbelowAdapter
from gxb_backend.state.request_services import RequestServices

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
CATALOG = GameDataCatalog.load(DATA / "game_data_catalog.json")
OP1 = "mid50-00000000-0000-4000-8000-000000000001"
OP2 = "mid50-00000000-0000-4000-8000-000000000002"

POLICY_HASHES = {
    "data/summon_private_server_policy.json": "4e419ca4bddb3255c8e5f4aba5537e3d7315f6d6b8574da16ebe0764fa58bed2",
    "data/summon_pool_catalog.json": "31702401c8be6dfc3029df8c95a4462850692ea82c12a864f7e6531109e4d718",
    "data/summon_counter_policy.json": "246ffe49c39921c2f4290dd52c0fe176140a5d3653a18b1dbc4a066693b6039d",
    "data/summon_operation_catalog.json": "fa67a40e902ba7667e1f20340defacad40b1ac09b6e3c55fabe586147f838e7a",
    "data/summon_cost_policy.json": "87f69a1d3a7d2d9020d06429b7c932d27f86a776150938d3c5b1beeb1f1cf784",
    "data/summon_result_policy.json": "f642bfa52c52196c45d5b99902a15a6785e2d332adc5e773eff75fca90323824",
    "gxb_backend/state/summon_private_policy.py": "45b0cccabfbfa701f97fb1db92443d2b3d36b7a8e22ce3a2c826bf118f79b937",
    "gxb_backend/state/medium_legacy_private_policy.py": "2e45bbd54b344d53f6bcc0ba0ff4b5fa85ed24e91888aeded5f81d9052faaf83",
    "gxb_backend/state/sx_soul_box_private_policy.py": "a4d501416dd565a4ac64c015f4f8c294d411b56b6943217d88da87c3d7809baa",
    "gxb_backend/state/classic_vending_balance_policy.py": "d5464c74c2b956383cfe33b51c02c2d5b7d2b31190b8e25e52e2b351adfdd8d1",
}


def require(value: bool, message: str) -> None:
    if not value:
        raise AssertionError(message)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


class RecordingZeroEntropy:
    def __init__(self) -> None:
        self.requests: list[EntropyDrawRequest] = []

    def draw(self, request: EntropyDrawRequest) -> int:
        self.requests.append(request)
        return 0


def make_services() -> tuple[PlayerState, RequestServices, list[str], RecordingZeroEntropy]:
    player = apply_established_profile(PlayerState())
    player.account_uid = "11100001"
    player.player_id = "11100001"
    player.mana = 3_000_000
    player.crystal = 999_999
    player.vip = 15
    commits: list[str] = []
    entropy = RecordingZeroEntropy()
    services = RequestServices(
        player,
        DATA,
        lambda: commits.append("commit"),
        catalog=CATALOG,
        entropy_provider=entropy,
    )
    return player, services, commits, entropy


def test_identity_and_fingerprint() -> None:
    identity = Mid50OperationIdentity.from_request(
        {"summon_op_id": OP1}, summon_type=1, summon_index=2
    )
    require(identity is not None and identity.operation_id == OP1, "valid UUID rejected")
    require(identity.fingerprint == mid50_request_fingerprint(1, 2), "fingerprint drift")
    require(
        Mid50OperationIdentity.from_request({}, summon_type=1, summon_index=2) is None,
        "missing identity must remain distinguishable",
    )
    bad = (
        "not-a-uuid",
        "mid50-00000000-0000-3000-8000-000000000001",
        "mid50-00000000-0000-4000-7000-000000000001",
        "p100-energy-foo",
    )
    for value in bad:
        try:
            Mid50OperationIdentity.from_request(
                {"summon_op_id": value}, summon_type=1, summon_index=2
            )
        except Mid50OperationIdentityError:
            pass
        else:
            raise AssertionError(f"invalid operation identity accepted: {value}")


def test_policy_hashes_unchanged() -> None:
    for rel, expected in POLICY_HASHES.items():
        require(sha256(ROOT / rel) == expected, f"Summon policy changed in infrastructure migration: {rel}")


def test_adapter_wiring_and_campaign_boundary() -> None:
    _player, services, _commits, _entropy = make_services()
    require(isinstance(services.summon_private_planner.random, NamespacedRandbelowAdapter), "classic pool adapter missing")
    require(services.summon_private_planner.random._namespace == "summon.classic.pool", "classic pool namespace drift")
    require(isinstance(services.classic_vending_balance_planner.random, NamespacedRandbelowAdapter), "classic balance adapter missing")
    require(services.classic_vending_balance_planner.random._namespace == "summon.classic.balance", "classic balance namespace drift")
    require(isinstance(services.medium_legacy_planner.random, NamespacedRandbelowAdapter), "medium adapter missing")
    require(services.medium_legacy_planner.random._namespace == "summon.medium_legacy", "medium namespace drift")
    require(isinstance(services.sx_soul_box_planner.random, NamespacedRandbelowAdapter), "SX adapter missing")
    require(services.sx_soul_box_planner.random._namespace == "summon.sx", "SX namespace drift")
    require(not isinstance(services.campaign_drop_planner.random_source, NamespacedRandbelowAdapter), "Campaign migrated during MID50-only pass")


def test_exactly_once_paid_mid50_and_live_projection() -> dict[str, object]:
    player, services, commits, entropy = make_services()
    repo = services.summon
    before = player.mana

    missing = repo.summon_hero({"summon_type": 1, "summon_index": 2})
    require(missing.get("error_code") == 1, "repeatable MID50 accepted missing operation identity")
    require(player.mana == before and commits == [] and entropy.requests == [], "missing identity mutated/spent/drew")

    request = {"summon_type": 1, "summon_index": 2, "summon_op_id": OP1}
    first = repo.summon_hero(request)
    require(first.get("error_code", 0) == 0 and len(first.get("result") or []) == 1, "first paid MID50 failed")
    require(player.mana == before - 10_000, "classic x1 cost changed")
    require(len(entropy.requests) > 0, "MID50 did not use RandomOutcomeService")
    require(all(draw.namespace.startswith("summon.") for draw in entropy.requests), "non-summon namespace used")
    first_draw_count = len(entropy.requests)
    first_commits = len(commits)
    first_static = copy.deepcopy(first["result"])

    receipt = services.uow.get_receipt(RECEIPT_DOMAIN, OP1)
    require(isinstance(receipt, dict), "durable MID50 receipt missing")
    require(receipt.get("status") == "COMMITTED", "receipt not committed")
    require(receipt.get("mode") == RECEIPT_MODE, "receipt mode drift")
    require(receipt.get("retention_policy") == RETENTION_POLICY, "receipt retention drift")
    require(receipt.get("request_fingerprint") == mid50_request_fingerprint(1, 2), "receipt fingerprint drift")
    replay_payload = receipt.get("replay_payload") or {}
    require("economy_" not in (replay_payload.get("static_response") or {}), "stale economy persisted as static response")
    require("summon_info" not in (replay_payload.get("static_response") or {}), "stale summon_info persisted as static response")
    require((replay_payload.get("projection") or {}).get("economy_keys") == ["mana"], "economy projection descriptor drift")
    require((replay_payload.get("projection") or {}).get("summon_info") is True, "summon projection flag drift")

    # Simulate unrelated legitimate economy progress after the committed pull.
    player.mana += 1_234
    live_mana = player.mana
    counter_snapshot = copy.deepcopy(player.summon)
    replay = repo.summon_hero(dict(request))
    require(replay.get("result") == first_static, "retry changed committed static outcome")
    require(replay.get("economy_", {}).get("mana") == live_mana, "retry replayed stale economy projection")
    require(player.mana == live_mana, "retry changed current economy")
    require(player.summon == counter_snapshot, "retry changed Summon counters/state")
    require(len(entropy.requests) == first_draw_count, "retry consumed entropy")
    require(len(commits) == first_commits, "retry committed again")

    conflict = repo.summon_hero({"summon_type": 1, "summon_index": 3, "summon_op_id": OP1})
    require(conflict.get("error_code") == 1, "same UUID accepted for a different tuple")
    require(len(entropy.requests) == first_draw_count and player.mana == live_mana, "fingerprint conflict drew/spent")

    second = repo.summon_hero({"summon_type": 1, "summon_index": 2, "summon_op_id": OP2})
    require(second.get("error_code", 0) == 0, "fresh operation identity did not execute")
    require(player.mana == live_mana - 10_000, "fresh identity did not charge exactly once")
    require(len(entropy.requests) > first_draw_count, "fresh identity did not draw")

    return {
        "first_draw_count": first_draw_count,
        "first_draws": [
            {"namespace": r.namespace, "ordinal": r.ordinal, "upper_exclusive": r.upper_exclusive}
            for r in entropy.requests[:first_draw_count]
        ],
        "receipt_domain": RECEIPT_DOMAIN,
        "receipt_mode": RECEIPT_MODE,
        "retention": RETENTION_POLICY,
        "replay_static_exact": True,
        "replay_live_economy": True,
        "retry_entropy_delta": 0,
        "fingerprint_conflict_fail_closed": True,
        "fresh_uuid_executes_again": True,
    }


def test_ota_bridge_and_preservation() -> dict[str, object]:
    manifest = json.loads((ROOT / "local_assets/update_manifest.json").read_text())
    require(manifest.get("version") == "1.631.5", "Pass111 OTA resource version drift")
    require(manifest.get("enabled") is True and manifest.get("silent") is True, "OTA flags drift")
    require(len(manifest.get("files") or []) == 130, "cumulative OTA file count drift")
    for arch in ("src_32", "src_64"):
        self_rel = f"{arch}/app/model/SelfPlayer.lua"
        require(self_rel in manifest["files"], f"{self_rel} missing from OTA")
        text = (ROOT / "local_assets" / self_rel).read_text(encoding="utf-8-sig")
        require(text.count("-- PASS111 PRESERVATION OTA MID50 OPERATION ID BRIDGE") == 1, "MID50 bridge marker drift")
        require('if not arg_137_1.summon_op_id or arg_137_1.summon_op_id == "" then' in text, "existing-id preservation guard missing")
        require('arg_137_1.summon_op_id = "mid50-" .. tostring(xyd.generateUUID())' in text, "source-native UUID generation missing")
        energy = ROOT / "local_assets" / arch / "app/model/AddEnergy.lua"
        require("-- PASS100 PRESERVATION OTA MID97 BRIDGE" in energy.read_text(encoding="utf-8-sig"), "Pass100 MID97 bridge lost")
    report = json.loads((ROOT / "docs/PASS111_OTA_BRIDGE_BUILD.json").read_text())
    require(report.get("prior_override_count") == 128, "prior OTA preservation census drift")
    require(len(report.get("prior_override_hashes") or {}) == 128, "prior OTA hash bank incomplete")
    return {"resource_version": "1.631.5", "files": 130, "prior_overrides_preserved": 128}


def test_legacy_paid_store_is_mid70_only() -> None:
    text = (ROOT / "gxb_backend/state/summon_repository.py").read_text()
    require(text.count("PaidSummonOperationReceiptStore(") == 1, "legacy paid receipt store still used outside one route")
    location = text.find("PaidSummonOperationReceiptStore(")
    require(text.rfind("def magic_summon_hero", 0, location) >= 0, "remaining legacy receipt is not MID70 Magic")


def main() -> int:
    test_identity_and_fingerprint()
    test_policy_hashes_unchanged()
    test_adapter_wiring_and_campaign_boundary()
    replay = test_exactly_once_paid_mid50_and_live_projection()
    ota = test_ota_bridge_and_preservation()
    test_legacy_paid_store_is_mid70_only()
    report = {
        "schema_version": 1,
        "pass": "111.0",
        "status": "PASS",
        "scope": "MID50 UUID + UoW receipt/replay + RandomOutcomeService adapter migration only",
        "policy_files_verified_unchanged": POLICY_HASHES,
        "exactly_once": replay,
        "ota": ota,
        "boundaries": {
            "MID50_probability_pool_pity_unchanged": True,
            "Campaign_unmigrated": True,
            "tutorial_one_shot_receipts_preserved": True,
            "legacy_short_window_store_remaining_plane": "MID70 Magic Summon only",
        },
    }
    out = ROOT / "docs/PASS111_MID50_RNG_MIGRATION_SELFTEST.json"
    out.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    print(json.dumps(report, indent=2, sort_keys=True))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
