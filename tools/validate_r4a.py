#!/usr/bin/env python3
from __future__ import annotations

import argparse
import hashlib
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
GENERATED = ROOT / "internal/content/builtin/generated"
EXPECTED_SOURCE = "c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf"


def canonical(value: object) -> bytes:
    return json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode()


def check_static() -> list[str]:
    errors: list[str] = []
    required = ["manifest.json", "resource_catalog.json", "player_progression.json", "objective_catalog.json"]
    for name in required:
        if not (GENERATED / name).is_file():
            errors.append(f"missing generated artifact {name}")
    if errors:
        return errors
    try:
        manifest = json.loads((GENERATED / "manifest.json").read_text())
        resources = json.loads((GENERATED / "resource_catalog.json").read_text())
        players = json.loads((GENERATED / "player_progression.json").read_text())
        objectives = json.loads((GENERATED / "objective_catalog.json").read_text())
    except Exception as exc:
        return [f"generated JSON decode failed: {exc}"]

    if manifest.get("source_archive_sha256") != EXPECTED_SOURCE:
        errors.append("source archive SHA-256 drift")
    if manifest.get("schema_version") != 1:
        errors.append("manifest schema drift")
    basis = dict(manifest)
    basis.pop("revision_id", None)
    got_revision = hashlib.sha256(canonical(basis)).hexdigest()
    if got_revision != manifest.get("revision_id"):
        errors.append("manifest basis revision digest mismatch")
    for name, want in manifest.get("artifact_sha256s", {}).items():
        path = GENERATED / name
        if not path.is_file():
            errors.append(f"manifest names missing artifact {name}")
            continue
        got = hashlib.sha256(path.read_bytes()).hexdigest()
        if got != want:
            errors.append(f"artifact hash drift for {name}")

    rows = resources.get("resources") or []
    keys = [r.get("definition_key") for r in rows]
    if keys != sorted(keys) or len(keys) != len(set(keys)):
        errors.append("resource keys are not strictly deterministic/unique")
    by_key = {r.get("definition_key"): r for r in rows}
    required_resources = {
        "scalar_currency:mana": ("SCALAR_CURRENCY", "ENABLED_R4"),
        "scalar_currency:crystal": ("SCALAR_CURRENCY", "ENABLED_R4"),
        "temporal:energy": ("TEMPORAL", {"R5_REQUIRED", "ENABLED_R5"}),
        "temporal:spirit_energy": ("TEMPORAL", {"R5_REQUIRED", "ENABLED_R5"}),
        "temporal:skill_point": ("TEMPORAL", {"R5_REQUIRED", "ENABLED_R5"}),
        "temporal:invitation": ("TEMPORAL", "FAIL_CLOSED"),
        "player_exp:exp": ("PLAYER_EXP", {"R5_REQUIRED", "ENABLED_R5"}),
    }
    for key, (cls, activation) in required_resources.items():
        row = by_key.get(key)
        allowed = activation if isinstance(activation, set) else {activation}
        if not row or row.get("class") != cls or row.get("settlement_activation") not in allowed:
            errors.append(f"required resource boundary drift: {key}")

    diagnostics = manifest.get("diagnostics") or {}
    expected_counts = {
        "item_rows": 5838,
        "positive_stack_items": 5540,
        "enabled_stack_items": 5159,
        "specialized_type24_items": 378,
        "type3_partner_scrolls": 291,
        "unqualified_type0_stack_items": 3,
        "player_rows": 100,
        "objective_builtin_rows": 0,
    }
    for key, want in expected_counts.items():
        if diagnostics.get(key) != want:
            errors.append(f"diagnostic {key}={diagnostics.get(key)!r}, want {want}")

    prow = players.get("rows") or []
    if [r.get("lev") for r in prow] != list(range(1, 101)):
        errors.append("player progression levels drift/non-contiguous")
    if any(prow[i]["total_exp"] > prow[i + 1]["total_exp"] for i in range(max(0, len(prow) - 1))):
        errors.append("player total_exp is non-monotonic")
    if objectives.get("definitions") != [] or objectives.get("status") != "BUILTIN_ACTIVATION_EMPTY_UNQUALIFIED_MAPPING":
        errors.append("built-in Objective activation is not empty/fail-closed")

    go = (ROOT / "internal/content/builtin/catalog.go").read_text()
    for needle in (
        "//go:embed generated/*.json",
        "ExpectedSourceArchiveSHA256",
        "canonical_manifest_without_revision_id",
        "BUILTIN_ACTIVATION_EMPTY_UNQUALIFIED_MAPPING",
        "PLAYER_LEVEL_ENERGY",
        "VIP_PLUS_MONTHLY_PRIVILEGE",
    ):
        if needle not in go:
            errors.append(f"typed builtin reader missing {needle}")
    return errors


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--source-archive", type=Path)
    args = p.parse_args()
    errors = check_static()
    test_env = None
    if args.source_archive:
        test_env = dict(__import__("os").environ)
        test_env["GXB_R4A_SOURCE_ARCHIVE"] = str(args.source_archive)
        proc = subprocess.run(
            [sys.executable, str(ROOT / "tools/test_generate_builtin_content.py")],
            cwd=ROOT,
            env=test_env,
            text=True,
        )
        if proc.returncode:
            errors.append("R4A compiler tests failed")
        proc = subprocess.run(
            [sys.executable, str(ROOT / "tools/generate_builtin_content.py"), "--source-archive", str(args.source_archive), "--check"],
            cwd=ROOT,
            text=True,
        )
        if proc.returncode:
            errors.append("R4A exact-source regeneration check failed")
    else:
        proc = subprocess.run([sys.executable, str(ROOT / "tools/test_generate_builtin_content.py")], cwd=ROOT, text=True)
        if proc.returncode:
            errors.append("R4A compiler fixture tests failed")
    if errors:
        for error in errors:
            print("R4A VALIDATION ERROR:", error)
        return 1
    print("R4A VALIDATION: PASS")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
