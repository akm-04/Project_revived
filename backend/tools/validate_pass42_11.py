#!/usr/bin/env python3
"""Pure/static Pass42.11 validation; does not start Flask or execute live gameplay."""
from __future__ import annotations

from datetime import datetime
import json
from pathlib import Path
import shutil
import tempfile
from zoneinfo import ZoneInfo

from gxb_backend.content.summon_featured_catalog import SummonFeaturedCatalog
from gxb_backend.state.summon_featured_rotation import SummonFeaturedRotationPolicy

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"


def write_policy(target: Path, policy: dict) -> None:
    (target / "summon_featured_rotation_policy.json").write_text(
        json.dumps(policy, indent=2) + "\n", encoding="utf-8"
    )


def temp_rotation(policy: dict) -> SummonFeaturedRotationPolicy:
    td = Path(tempfile.mkdtemp(prefix="gxb4211-rotation-"))
    shutil.copy2(DATA / "summon_featured_catalog.json", td / "summon_featured_catalog.json")
    write_policy(td, policy)
    catalog = SummonFeaturedCatalog(td)
    obj = SummonFeaturedRotationPolicy(td, catalog)
    obj._validation_tempdir = td  # keep alive/reference for diagnostic cleanup ownership
    return obj


def main() -> int:
    checks: dict[str, object] = {}
    fixed = datetime(2026, 8, 20, 12, 0, tzinfo=ZoneInfo("Asia/Dhaka"))
    base = json.loads((DATA / "summon_featured_rotation_policy.json").read_text(encoding="utf-8"))

    # Pass42.9 calendar behavior must remain byte-semantically equivalent for the
    # known Pass42.10 reconciliation date.
    calendar = temp_rotation(base)
    snap = calendar.snapshot(fixed)
    expected = {
        "sx_week_ids": [10001197, 10001248],
        "sx_day_ids": [10001100, 10001171, 10001167],
        "medium_featured_id": 10001089,
    }
    actual = {
        "sx_week_ids": list(snap.sx_week_ids),
        "sx_day_ids": list(snap.sx_day_ids),
        "medium_featured_id": snap.medium_featured_id,
    }
    assert actual == expected, (actual, expected)
    checks["calendar_pass42_10_known_snapshot"] = actual

    # Partial zero overrides preserve pinned slots and auto-fill only zeros.
    p = dict(base)
    p["sx"] = {"week_manual_ids": [10001045, 10001100], "day_manual_ids": [10001218, 10001228, 0]}
    p["medium"] = {"manual_hero_id": 10001144}
    r = temp_rotation(p)
    s = r.snapshot(fixed)
    assert list(s.sx_day_ids) == [10001218, 10001228, 10001167]
    checks["partial_zero_case_1"] = list(s.sx_day_ids)

    p2 = dict(base)
    p2["sx"] = {"week_manual_ids": [10001045, 10001100], "day_manual_ids": [0, 10001228, 0]}
    p2["medium"] = {"manual_hero_id": 10001144}
    r2 = temp_rotation(p2)
    s2 = r2.snapshot(fixed)
    assert list(s2.sx_day_ids) == [10001171, 10001228, 10001167]
    checks["partial_zero_case_2"] = list(s2.sx_day_ids)

    # Explicit debug seed is reproducible and frozen across calls/timestamps.
    debug_policy = dict(base)
    debug_policy["selection_mode"] = "startup_debug"
    debug_policy["debug_seed"] = "pass42.11-repro-seed"
    d1 = temp_rotation(debug_policy)
    d2 = temp_rotation(debug_policy)
    a = d1.snapshot(fixed)
    b = d1.snapshot(datetime(2035, 1, 1, 0, 0, tzinfo=ZoneInfo("UTC")))
    c = d2.snapshot()
    assert a == b == c
    five = list(a.sx_week_ids) + list(a.sx_day_ids)
    assert len(five) == 5 and len(set(five)) == 5
    assert set(five) <= d1.catalog.sx_ids()
    assert a.medium_featured_id in d1.catalog.medium_featured_ids()
    checks["startup_debug_reproducible"] = {
        "seed": d1.debug_seed,
        "run_id": d1.debug_run_id,
        "sx_week_ids": list(a.sx_week_ids),
        "sx_day_ids": list(a.sx_day_ids),
        "medium_featured_id": a.medium_featured_id,
    }

    # Manual overrides remain slot-scoped on top of the frozen debug baseline.
    debug_manual = dict(debug_policy)
    debug_manual["sx"] = {"week_manual_ids": [10001045, 0], "day_manual_ids": [0, 10001228, 0]}
    debug_manual["medium"] = {"manual_hero_id": 10001144}
    dm = temp_rotation(debug_manual)
    dms = dm.snapshot()
    assert dms.sx_week_ids[0] == 10001045
    assert dms.sx_day_ids[1] == 10001228
    assert dms.medium_featured_id == 10001144
    assert len(set(dms.sx_week_ids + dms.sx_day_ids)) == 5
    checks["startup_debug_manual_overlay"] = {
        "sx_week_ids": list(dms.sx_week_ids),
        "sx_day_ids": list(dms.sx_day_ids),
        "medium_featured_id": dms.medium_featured_id,
    }

    # Ineligible and duplicate overrides warn/fallback rather than crashing.
    invalid_manual = dict(debug_policy)
    invalid_manual["sx"] = {"week_manual_ids": [10001034, 10001045], "day_manual_ids": [10001045, 10001228, 10001228]}
    invalid_manual["medium"] = {"manual_hero_id": 10001032}
    im = temp_rotation(invalid_manual)
    ims = im.snapshot()
    assert len(set(ims.sx_week_ids + ims.sx_day_ids)) == 5
    assert set(ims.sx_week_ids + ims.sx_day_ids) <= im.catalog.sx_ids()
    assert ims.medium_featured_id in im.catalog.medium_featured_ids()
    assert im._warnings
    checks["invalid_manual_warn_fallback"] = {
        "warning_count": len(im._warnings),
        "sx_week_ids": list(ims.sx_week_ids),
        "sx_day_ids": list(ims.sx_day_ids),
        "medium_featured_id": ims.medium_featured_id,
    }

    # Zero debug seed generates fresh boot seeds; selection object remains frozen.
    fresh_policy = dict(base)
    fresh_policy["selection_mode"] = "startup_debug"
    fresh_policy["debug_seed"] = 0
    f1 = temp_rotation(fresh_policy)
    f2 = temp_rotation(fresh_policy)
    assert f1.debug_seed and f2.debug_seed and f1.debug_seed != f2.debug_seed
    assert f1.snapshot() == f1.snapshot()
    checks["startup_debug_fresh_seed"] = {
        "distinct_boot_seeds": True,
        "seed_lengths": [len(f1.debug_seed), len(f2.debug_seed)],
    }

    # Invalid mode fails soft to normal calendar mode.
    invalid = dict(base)
    invalid["selection_mode"] = "not-a-mode"
    inv = temp_rotation(invalid)
    assert inv.selection_mode == "calendar_deterministic"
    assert any("invalid selection_mode" in w for w in inv._warnings)
    checks["invalid_mode_fallback"] = True

    # Process composition: StateRepository injects the exact same policy into
    # request services and MultiUserDatabase maintenance plumbing.
    from gxb_backend.state.repository import StateRepository
    import gxb_backend.state.maintenance_services as maintenance_module

    with tempfile.TemporaryDirectory(prefix="gxb4211-state-") as td:
        t = Path(td)
        data_copy = t / "data"
        shutil.copytree(DATA, data_copy)
        state_policy = json.loads((data_copy / "summon_featured_rotation_policy.json").read_text())
        state_policy["selection_mode"] = "startup_debug"
        state_policy["debug_seed"] = "shared-process-seed"
        write_policy(data_copy, state_policy)
        repo = StateRepository(
            data_copy / "player_db.json",
            profile="established",
            legacy_path=data_copy / "state.json",
            multiuser_root=t / "server_state",
        )
        assert repo.store.featured_rotation is repo._featured_rotation
        services = repo.get_services()
        assert services.summon_featured_rotation is repo._featured_rotation

        original_ctor = maintenance_module.SummonFeaturedRotationPolicy
        class BombRotation:
            def __init__(self, *args, **kwargs):
                raise AssertionError("maintenance attempted independent featured rotation construction")
        maintenance_module.SummonFeaturedRotationPolicy = BombRotation
        try:
            player = repo.store.sandbox_player()
            repo.store.normalize_player(player, persist=False)
        finally:
            maintenance_module.SummonFeaturedRotationPolicy = original_ctor
        checks["shared_process_rotation_injection"] = True

    # Generated docs must match runtime cohort counts and all-Girl compact catalog.
    ref = json.loads((DATA / "girl_reference_catalog.json").read_text(encoding="utf-8"))
    featured = SummonFeaturedCatalog(DATA)
    assert len(ref["girls"]) == 291
    assert len(featured.sx()) == 73
    assert len(featured.medium_extension()) == 58
    assert len(featured.medium_featured()) == 56
    checks["catalog_counts"] = {"all": 291, "sx": 73, "medium_extended": 58, "medium_featured": 56}

    report = {
        "schema_version": 1,
        "pass": "42.11",
        "backend": "v0.8.32",
        "validation_type": "pure/static repository validation; no Flask/live gameplay",
        "status": "pass",
        "checks": checks,
    }
    out = ROOT / "docs" / "PASS42_11_BACKEND_STATIC_VALIDATION.json"
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(json.dumps(report, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
