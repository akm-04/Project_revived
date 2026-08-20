#!/usr/bin/env python3
"""Pure/static Pass42.12 validation; no Flask/client gameplay."""
from __future__ import annotations

from collections import Counter
from datetime import datetime
import importlib.util
import json
from pathlib import Path
import shutil
import tempfile
from zoneinfo import ZoneInfo

from gxb_backend.content.game_data_catalog import GameDataCatalog
from gxb_backend.content.summon_featured_catalog import SummonFeaturedCatalog
from gxb_backend.content.summon_pool_catalog import SummonPoolCatalog
from gxb_backend.state.classic_vending_balance_policy import (
    ClassicVendingBalancePlanner,
    ClassicVendingBalancePolicy,
)
from gxb_backend.state.medium_legacy_private_policy import MediumLegacyPrivatePlanner, MediumLegacyPrivatePolicy
from gxb_backend.state.summon_featured_rotation import SummonFeaturedRotationPolicy
from gxb_backend.state.summon_private_policy import ClassicVendingPrivatePlanner, SummonPrivateServerPolicy

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


class ZeroRandom:
    def randbelow(self, upper: int) -> int:
        if upper <= 0:
            raise ValueError
        return 0


def load_tool_module():
    spec = importlib.util.spec_from_file_location("gxb_pass4212_gacha_control", ROOT / "gacha_control.py")
    mod = importlib.util.module_from_spec(spec)
    assert spec and spec.loader
    spec.loader.exec_module(mod)
    return mod


def temp_rotation(policy: dict) -> SummonFeaturedRotationPolicy:
    td = Path(tempfile.mkdtemp(prefix="gxb4212-rotation-"))
    shutil.copy2(DATA / "summon_featured_catalog.json", td / "summon_featured_catalog.json")
    (td / "summon_featured_rotation_policy.json").write_text(json.dumps(policy, indent=2) + "\n")
    obj = SummonFeaturedRotationPolicy(td, SummonFeaturedCatalog(td), emit_startup_log=False)
    obj._validation_tempdir = td
    return obj


def main() -> int:
    checks: dict[str, object] = {}
    tool = load_tool_module()
    store = tool.Store(ROOT)
    store.validate()
    checks["operator_tool_validation"] = "pass"
    summary = store.summary()
    assert "Small Vending" not in summary  # summary is data, not menu decoration
    assert "Rotation mode: startup_debug" in summary
    checks["operator_summary"] = summary.splitlines()[:6]

    rotation = json.loads((DATA / "summon_featured_rotation_policy.json").read_text())
    assert rotation["selection_mode"] == "startup_debug"
    assert rotation["debug_seed"] == 0
    checks["development_default"] = {"selection_mode": "startup_debug", "debug_seed": 0}

    # Calendar behavior remains available and preserves the Pass42.10 known snapshot.
    calendar_policy = dict(rotation)
    calendar_policy["selection_mode"] = "calendar_deterministic"
    cal = temp_rotation(calendar_policy)
    fixed = datetime(2026, 8, 20, 12, 0, tzinfo=ZoneInfo("Asia/Dhaka"))
    snap = cal.snapshot(fixed)
    actual = {
        "sx_week_ids": list(snap.sx_week_ids),
        "sx_day_ids": list(snap.sx_day_ids),
        "medium_featured_id": snap.medium_featured_id,
    }
    expected = {
        "sx_week_ids": [10001197, 10001248],
        "sx_day_ids": [10001100, 10001171, 10001167],
        "medium_featured_id": 10001089,
    }
    assert actual == expected, (actual, expected)
    checks["calendar_compatibility"] = actual

    # Explicit startup debug seed is still reproducible after default-mode change.
    seeded = dict(rotation)
    seeded["selection_mode"] = "startup_debug"
    seeded["debug_seed"] = "pass42.12-seed"
    a = temp_rotation(seeded)
    b = temp_rotation(seeded)
    assert a.snapshot() == b.snapshot()
    checks["startup_debug_reproducible"] = {
        "sx_week_ids": list(a.snapshot().sx_week_ids),
        "sx_day_ids": list(a.snapshot().sx_day_ids),
        "medium_featured_id": a.snapshot().medium_featured_id,
    }

    game = GameDataCatalog.load(DATA / "game_data_catalog.json")
    pools = SummonPoolCatalog(DATA)
    classic = SummonPrivateServerPolicy(DATA)
    balance = ClassicVendingBalancePolicy(DATA)
    bp = ClassicVendingBalancePlanner(balance, game, random_source=ZeroRandom())
    planner = ClassicVendingPrivatePlanner(pools, classic, random_source=ZeroRandom(), balance_planner=bp)
    assert not planner.category_override_enabled("small")
    assert not planner.category_override_enabled("medium")
    base = pools.require(200003)
    scroll = planner.partition_item_pool(base, "scroll")
    items = planner.partition_item_pool(base, "item")
    assert len(scroll.rows) == 83 and len(items.rows) == 288
    assert {r.drop_rate for r in scroll.rows} == {1}
    checks["classic_scroll_partition"] = {"scroll_rows": 83, "non_scroll_item_rows": 288, "explicit_scroll_mode": "flat_equal"}

    featured = SummonFeaturedCatalog(DATA)
    medium_policy = MediumLegacyPrivatePolicy(DATA, featured)
    medium_planner = MediumLegacyPrivatePlanner(featured, medium_policy, random_source=ZeroRandom())
    augmented = medium_planner.augmented_ordinary_hero_pool(pools.require(200004))
    assert len(augmented.rows) == 143
    star_counts = Counter(bp.native_star(r.item_id) for r in augmented.rows)
    assert star_counts == Counter({1: 13, 2: 33, 3: 97}), star_counts
    checks["medium_ordinary_143_native_stars"] = {str(k): v for k, v in sorted(star_counts.items())}

    # Opt-in explicit tuning is isolated to the new overlay and supports native-star routing.
    with tempfile.TemporaryDirectory(prefix="gxb4212-balance-") as td:
        td = Path(td)
        raw = json.loads((DATA / "classic_vending_balance_policy.json").read_text())
        raw["families"]["medium"]["category_override"]["enabled"] = True
        raw["families"]["medium"]["category_override"]["weights_per_10000"] = {"item": 0, "scroll": 0, "girl": 10000}
        raw["families"]["medium"]["girl_star_override"]["enabled"] = True
        raw["families"]["medium"]["girl_star_override"]["weights_per_10000"] = {"1": 0, "2": 0, "3": 10000}
        (td / "classic_vending_balance_policy.json").write_text(json.dumps(raw, indent=2) + "\n")
        p2 = ClassicVendingBalancePolicy(td)
        b2 = ClassicVendingBalancePlanner(p2, game, random_source=ZeroRandom())
        assert b2.pick_category("medium") == "girl"
        star3 = b2.partition_hero_pool_by_star("medium", augmented)
        assert len(star3.rows) == 97 and {b2.native_star(r.item_id) for r in star3.rows} == {3}
        checks["explicit_medium_tuning"] = {"category": "girl", "native_star": 3, "candidate_rows": 97}

    # Tool writes are atomic and backed up; exercise only a temporary data copy.
    with tempfile.TemporaryDirectory(prefix="gxb4212-tool-") as td:
        root = Path(td)
        (root / "data").mkdir()
        for name in tool.FILES.values():
            shutil.copy2(DATA / name, root / "data" / name)
        temp_store = tool.Store(root)
        temp_store.docs["rotation"]["debug_seed"] = "backup-test"
        backup = temp_store.backup_and_write(["rotation"])
        assert backup.is_dir()
        saved = json.loads((root / "data" / tool.FILES["rotation"]).read_text())
        assert saved["debug_seed"] == "backup-test"
        assert (backup / tool.FILES["rotation"]).is_file()
        checks["operator_atomic_backup_write"] = True

    sx = json.loads((DATA / "sx_soul_box_private_policy.json").read_text())
    medium = json.loads((DATA / "medium_legacy_private_policy.json").read_text())
    classic_raw = json.loads((DATA / "summon_private_server_policy.json").read_text())
    assert sx["hotspot_policy"]["guarantee_purchases"] == 25
    assert classic_raw["medium"]["ten_pull_guarantee"]["mode"] == "at_least_one_hero"
    assert classic_raw["small"]["ten_pull_guarantee"]["mode"] == "at_least_one_item"
    assert medium["featured_daily_overlay"]["pity_eligible_slots"] == 20
    checks["fixed_guarantees"] = {
        "small_x10": "at_least_one_item",
        "medium_x10": "at_least_one_hero",
        "sx_selected_hotspot_purchases": 25,
        "medium_new_add_pity_slots": 20,
    }

    report = {
        "schema_version": 1,
        "pass": "42.12",
        "backend": "v0.8.33",
        "validation_type": "pure/static repository/tool validation; no Flask/client gameplay",
        "status": "pass",
        "checks": checks,
    }
    out = ROOT / "docs" / "PASS42_12_BACKEND_STATIC_VALIDATION.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
