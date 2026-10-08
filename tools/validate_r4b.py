#!/usr/bin/env python3
from __future__ import annotations

import json
import re
import subprocess
import sys
from pathlib import Path
from content_generation_policy import qualified_social_gift_scalar_delta

ROOT = Path(__file__).resolve().parents[1]
MIG = ROOT / "migrations/00009_r4_immutable_content_revisions.sql"
OWN = ROOT / "docs/architecture/CANONICAL_TABLE_OWNERSHIP.json"
GEN = ROOT / "internal/content/builtin/generated"
NEW_TABLES = [
    "gxb_content_revisions",
    "gxb_content_activation",
    "gxb_content_resource_definitions",
    "gxb_content_player_progression",
    "gxb_content_objective_definitions",
]
CLASSES = {"SCALAR_CURRENCY", "TEMPORAL", "STACK_ITEM", "PLAYER_EXP", "SPECIALIZED_DOMAIN"}
CATALOG = {"QUALIFIED", "SOURCE_KNOWN", "PARTIAL"}
ACTIVATION = {"ENABLED_R4", "OWNER_REQUIRED", "R5_REQUIRED", "ENABLED_R5", "FAIL_CLOSED"}
CAP_RULES = {"STATIC", "PLAYER_LEVEL_ENERGY", "VIP_PLUS_MONTHLY_PRIVILEGE", "UNRESOLVED"}


def resource_shape_errors(row: dict) -> list[str]:
    e: list[str] = []
    cls = row.get("class")
    if cls not in CLASSES:
        return [f"unknown class {cls!r}"]
    if row.get("catalog_status") not in CATALOG:
        e.append("invalid catalog_status")
    if row.get("settlement_activation") not in ACTIVATION:
        e.append("invalid settlement_activation")
    if not str(row.get("definition_key", "")).strip():
        e.append("blank definition_key")
    resource = row.get("resource_key")
    item = row.get("item_id")
    item_type = row.get("item_type")
    partner = row.get("partner_id")
    stack = row.get("stack_cap")
    overflow_present = "overflow_to_mail" in row
    regen_s = row.get("regen_seconds")
    regen_a = row.get("regen_amount")
    cap = row.get("cap_rule")
    static = row.get("static_cap")
    specialized = row.get("specialized_owner")
    if cls in {"SCALAR_CURRENCY", "PLAYER_EXP"}:
        if not resource or any(v is not None for v in (item, item_type, partner, stack, regen_s, regen_a, cap, static, specialized)) or overflow_present:
            e.append("scalar/player-exp relational shape")
    elif cls == "TEMPORAL":
        if not resource or any(v is not None for v in (item, item_type, partner, stack, specialized)) or overflow_present:
            e.append("temporal non-temporal columns")
        if not isinstance(regen_s, int) or regen_s <= 0 or not isinstance(regen_a, int) or regen_a <= 0 or cap not in CAP_RULES:
            e.append("temporal rule shape")
        if (cap == "STATIC") != isinstance(static, int):
            e.append("temporal static-cap shape")
        if isinstance(static, int) and static < 0:
            e.append("negative static cap")
    elif cls == "STACK_ITEM":
        if resource is not None or not isinstance(item, int) or item <= 0 or not isinstance(item_type, int) or item_type < 0 or not isinstance(stack, int) or stack <= 0 or not overflow_present:
            e.append("stack relational shape")
        if any(v is not None for v in (regen_s, regen_a, cap, static, specialized)):
            e.append("stack temporal/specialized leakage")
        if partner is not None and (not isinstance(partner, int) or partner <= 0):
            e.append("invalid partner_id")
    else:
        if resource is not None or partner is not None or not isinstance(item, int) or item <= 0 or not isinstance(item_type, int) or item_type < 0 or not isinstance(stack, int) or stack <= 0 or not overflow_present or not str(specialized or "").strip():
            e.append("specialized relational shape")
        if any(v is not None for v in (regen_s, regen_a, cap, static)):
            e.append("specialized temporal leakage")
    return e


def main() -> int:
    errors: list[str] = []
    if not MIG.is_file():
        return print("R4B VALIDATION ERROR: missing migration 00009") or 1
    sql = MIG.read_text()
    repair = ROOT / "migrations/00010_r4_manifest_identity_not_null.sql"
    if not repair.is_file() or "IS TRUE" not in repair.read_text() or "manifest_identity_strict_chk" not in repair.read_text():
        errors.append("R4B manifest JSON-null forward repair missing")
    if "-- +goose Down" in sql:
        errors.append("migration contains forbidden DOWN section")
    if "wire_table_id" in sql or "source_provenance" in sql:
        errors.append("migration contains forbidden R4B fields")
    for table in NEW_TABLES:
        if len(re.findall(rf"(?i)CREATE\s+TABLE\s+{re.escape(table)}\b", sql)) != 1:
            errors.append(f"{table} not created exactly once")
    required_prefix = list(range(1, 11))
    actual_numbers = sorted(int(p.name[:5]) for p in (ROOT / "migrations").glob("[0-9][0-9][0-9][0-9][0-9]_*.sql"))
    if actual_numbers[:10] != required_prefix or actual_numbers != list(range(1, max(actual_numbers)+1)):
        errors.append(f"migration sequence={actual_numbers} must preserve contiguous historical 1..10 prefix")
    if "ON DELETE CASCADE" in sql:
        errors.append("immutable content migration must not cascade-delete revision history")
    for needle in (
        "operation_policy_refs jsonb NOT NULL DEFAULT '[]'::jsonb",
        "jsonb_typeof(operation_policy_refs)='array'",
        "player_temporal_resources",
        "player_mission_instances",
        "content_revision text NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT",
        "manifest ? 'revision_id'",
        "manifest ? 'schema_version'",
        "manifest ? 'compiler_version'",
        "manifest ? 'parser_version'",
    ):
        if needle not in sql:
            errors.append(f"migration missing {needle}")
    if re.search(r"gxb_content_objective_definitions[\s\S]*?\bactive\b", sql.split("ALTER TABLE gxb_operation_receipts", 1)[0]):
        errors.append("immutable objective table contains active/currentness field")
    for needle in (
        "ON gxb_content_resource_definitions(revision_id,class,resource_key)",
        "ON gxb_content_resource_definitions(revision_id,item_id)",
        "revision_id text NOT NULL REFERENCES gxb_content_revisions(revision_id) ON DELETE RESTRICT",
    ):
        if needle not in sql:
            errors.append(f"revision-scoped/restrictive schema missing {needle}")
    # Historical R4B-only boundary: later R4C is permitted only with its own gate.
    if (ROOT / "sql/content").exists() or (ROOT / "internal/adapters/postgres/contentstore").exists():
        gate = ROOT / "tools/validate_r4c.py"
        if not gate.is_file() or subprocess.run([sys.executable, str(gate)], cwd=ROOT).returncode:
            errors.append("later R4C content paths lack a passing dedicated gate")

    own = json.loads(OWN.read_text())
    for table in NEW_TABLES:
        entry = own.get("tables", {}).get(table)
        if not entry:
            errors.append(f"ownership missing {table}")
            continue
        if entry.get("owner") != "content-registry" or entry.get("migration") != "migrations/00009_r4_immutable_content_revisions.sql":
            errors.append(f"ownership mismatch {table}")

    resource_payload=json.loads((GEN / "resource_catalog.json").read_text())
    resources = resource_payload.get("resources") or []
    progression = json.loads((GEN / "player_progression.json").read_text()).get("rows") or []
    objectives = json.loads((GEN / "objective_catalog.json").read_text()).get("definitions") or []
    expected_resource_count=5556
    manifest=json.loads((GEN/"manifest.json").read_text())
    if manifest.get("compiler_version")=="i7a7a-social-gift":
        if qualified_social_gift_scalar_delta(ROOT,resource_payload):expected_resource_count=5557
        else:errors.append("unqualified SocialGift scalar delta; historical catalog identity must remain exact")
    if len(resources)!=expected_resource_count:
        errors.append(f"resource count={len(resources)} want {expected_resource_count}")
    if len(progression) != 100:
        errors.append(f"progression count={len(progression)} want 100")
    if objectives != []:
        errors.append("built-in objective closure must remain empty")
    seen_resource: set[tuple[str, str]] = set()
    seen_item: set[int] = set()
    for row in resources:
        for err in resource_shape_errors(row):
            errors.append(f"{row.get('definition_key')}: {err}")
        if row.get("resource_key") is not None:
            key = (row["class"], row["resource_key"])
            if key in seen_resource:
                errors.append(f"duplicate revision-scoped resource identity {key}")
            seen_resource.add(key)
        if row.get("item_id") is not None:
            iid = row["item_id"]
            if iid in seen_item:
                errors.append(f"duplicate revision-scoped item identity {iid}")
            seen_item.add(iid)
    if [r.get("lev") for r in progression] != list(range(1, 101)):
        errors.append("progression source levels drift")
    for r in progression:
        if any(not isinstance(r.get(k), int) or r[k] < 0 for k in ("energy", "exp", "award_energy", "total_exp", "hero_lev", "power", "expedition_mana")):
            errors.append(f"invalid progression row level {r.get('lev')}")
        if r.get("hero_lev", 0) <= 0:
            errors.append(f"nonpositive hero level at {r.get('lev')}")

    receipt_go = (ROOT / "internal/foundation/receipt/receipt.go").read_text()
    store_go = (ROOT / "internal/adapters/postgres/kernelstore/store.go").read_text()
    query_sql = (ROOT / "sql/kernel/receipts.sql").read_text()
    policy_go = (ROOT / "internal/foundation/policy/refs.go").read_text()
    for needle, text in (
        ("OperationPolicyRefs policy.Set", receipt_go),
        ("OperationPolicyRefs: op.Policies", receipt_go),
        ("policy.MarshalCanonicalJSON", store_go),
        ("policy.ParseCanonicalJSON", store_go),
        ("operation_policy_refs", query_sql),
        ('json:"name"', policy_go),
        ('json:"version"', policy_go),
        ("DisallowUnknownFields", policy_go),
    ):
        if needle not in text:
            errors.append(f"receipt/policy implementation missing {needle}")
    if "stored.OperationPolicyRefs" in store_go or "OperationPolicyRefs.Equal" in store_go:
        errors.append("kernel store incorrectly treats execution-policy evidence as replay conflict identity")

    for cmd in (
        [sys.executable, str(ROOT / "tools/generate_kernel_querytext.py"), "--check"],
        [sys.executable, str(ROOT / "tools/check_schema_query_ownership.py")],
    ):
        if subprocess.run(cmd, cwd=ROOT).returncode:
            errors.append("sub-validator failed: " + " ".join(cmd[1:]))

    if errors:
        for e in errors[:100]:
            print("R4B VALIDATION ERROR:", e)
        if len(errors) > 100:
            print("R4B VALIDATION ERROR: ...", len(errors) - 100, "more")
        return 1
    print("R4B VALIDATION: PASS")
    print("resource_rows", len(resources), "progression_rows", len(progression), "objective_rows", len(objectives))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
