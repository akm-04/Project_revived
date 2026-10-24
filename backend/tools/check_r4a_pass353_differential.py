#!/usr/bin/env python3
"""R4A corroborative differential against frozen Pass353.

The oracle never becomes V2 content authority. This check only reports whether
current-src_64-derived classifications contradict the frozen V1 reconstruction
on the bounded facts R4A deliberately used as corroboration.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EXPECTED_ORACLE_SHA256 = "31729d5c5e4509c2c89eaa1e8203cf1570afe87e18ed2610b944e457a9946b15"
EXPECTED_ITEM_SOURCE_SHA256 = "59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc"


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--oracle-archive", type=Path, required=True)
    p.add_argument("--output", type=Path)
    args = p.parse_args()

    oracle_sha = sha256_file(args.oracle_archive)
    if oracle_sha != EXPECTED_ORACLE_SHA256:
        print(f"R4A PASS353 DIFFERENTIAL ERROR: oracle SHA mismatch {oracle_sha}", file=sys.stderr)
        return 1

    current = json.loads((ROOT / "internal/content/builtin/generated/resource_catalog.json").read_text())
    manifest = json.loads((ROOT / "internal/content/builtin/generated/manifest.json").read_text())
    with zipfile.ZipFile(args.oracle_archive) as zf:
        stack = json.loads(zf.read("data/item_stack_limit_meta.json"))
        registry = json.loads(zf.read("data/resource_registry.json"))
        horcrux = json.loads(zf.read("data/horcrux_source_catalog.json"))

    errors: list[str] = []
    if stack.get("_meta", {}).get("source_sha256") != EXPECTED_ITEM_SOURCE_SHA256:
        errors.append("Pass353 stack metadata is not tied to the expected current item.lua hash")

    stack_rows = {
        int(k): {"stack": int(v.get("stack") or 0), "overflow_to_mail": int(v.get("stack_exceed_mail") or 0) == 1}
        for k, v in stack.get("items", {}).items()
    }
    current_items = {
        int(r["item_id"]): r
        for r in current.get("resources", [])
        if int(r.get("item_id") or 0) > 0
    }
    mismatches: list[dict[str, object]] = []
    for item_id, row in current_items.items():
        oracle = stack_rows.get(item_id)
        if oracle is None:
            mismatches.append({"item_id": item_id, "reason": "missing_in_pass353_stack_meta"})
            continue
        if int(row.get("stack_cap") or 0) != oracle["stack"]:
            mismatches.append({"item_id": item_id, "reason": "stack_cap", "r4a": row.get("stack_cap"), "pass353": oracle["stack"]})
        if bool(row.get("overflow_to_mail", False)) != oracle["overflow_to_mail"]:
            mismatches.append({"item_id": item_id, "reason": "overflow_to_mail", "r4a": row.get("overflow_to_mail", False), "pass353": oracle["overflow_to_mail"]})
    if mismatches:
        errors.append(f"{len(mismatches)} item stack/overflow mismatches")

    desc = {d.get("wire_key"): d for d in registry.get("descriptors", [])}
    corroborative_resources = {}
    for key in ("mana", "crystal", "exp", "energy", "spirit_energy", "skill_point", "invitation"):
        d = desc.get(key)
        if d:
            corroborative_resources[key] = {
                "owner_service": d.get("owner_service"),
                "migration_readiness": d.get("migration_readiness"),
                "semantic_class": d.get("semantic_class"),
            }
    if corroborative_resources.get("mana", {}).get("migration_readiness") != "FOUNDATION_READY":
        errors.append("Pass353 does not corroborate Mana as foundation-ready")
    if corroborative_resources.get("crystal", {}).get("migration_readiness") != "FOUNDATION_READY":
        errors.append("Pass353 does not corroborate Crystal as foundation-ready")

    current_type24 = [r for r in current.get("resources", []) if r.get("class") == "SPECIALIZED_DOMAIN" and r.get("specialized_owner") == "HORCRUX_GENERATED_OWNER_REQUIRED"]
    pass353_templates = horcrux.get("templates", {})
    if len(current_type24) != 378 or len(pass353_templates) != 378:
        errors.append(f"Horcrux template count drift R4A={len(current_type24)} Pass353={len(pass353_templates)}")

    report = {
        "schema_version": 1,
        "evidence_class": "CORROBORATIVE_DIFFERENTIAL_ONLY_NOT_V2_AUTHORITY",
        "r4a_content_revision": manifest.get("revision_id"),
        "pass353_archive_sha256": oracle_sha,
        "item_source_sha256": EXPECTED_ITEM_SOURCE_SHA256,
        "item_stack": {
            "source_row_count": stack.get("_meta", {}).get("row_count"),
            "source_positive_stack_rows": stack.get("_meta", {}).get("positive_stack_rows"),
            "r4a_catalog_item_rows": len(current_items),
            "mismatch_count": len(mismatches),
            "mismatches": mismatches[:20],
        },
        "horcrux": {
            "r4a_type24_specialized_rows": len(current_type24),
            "pass353_type24_templates": len(pass353_templates),
            "interpretation": "count agreement corroborates R4A fail-closed specialized-owner boundary; V1 materialization policy is not imported",
        },
        "resource_owner_corroboration": corroborative_resources,
        "conclusion": "PASS_NO_BOUNDED_CONTRADICTION" if not errors else "FAIL_CONTRADICTION_OR_DRIFT",
        "limitations": [
            "Pass353 is a frozen reconstruction/oracle, not original-server truth.",
            "This differential does not authorize V1 persistence, formulas, handlers, temporal transitions, or specialized-owner implementation in V2.",
            "Current src_64 hashes and the Pass467 implementation contract remain R4A authority.",
        ],
    }
    if args.output:
        args.output.parent.mkdir(parents=True, exist_ok=True)
        args.output.write_text(json.dumps(report, indent=2, sort_keys=True) + "\n")
    if errors:
        for e in errors:
            print("R4A PASS353 DIFFERENTIAL ERROR:", e, file=sys.stderr)
        return 1
    print(
        "R4A PASS353 DIFFERENTIAL: PASS "
        f"items={len(current_items)} mismatches=0 type24={len(current_type24)}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
