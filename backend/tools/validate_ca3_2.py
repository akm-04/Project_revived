#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errs: list[str] = []

def read(rel: str) -> str:
    p = ROOT / rel
    if not p.exists():
        errs.append(f"missing {rel}")
        return ""
    return p.read_text()

def need(rel: str, *tokens: str) -> str:
    s = read(rel)
    for tok in tokens:
        if tok not in s:
            errs.append(f"{rel}: missing {tok!r}")
    return s

# Deterministic source/content boundary.
try:
    manifest = json.loads(read("internal/content/builtin/generated/manifest.json") or "{}")
except Exception as exc:
    errs.append(f"manifest decode: {exc}")
    manifest = {}
if manifest.get("compiler_version") != "ca3-2" or manifest.get("parser_version") != "lua-generated-v4-pet-acquisition":
    errs.append("CA3-2 compiler/parser identity drift")
for cap in ("PET_CORE_CA3", "PET_ACQUISITION_CA3"):
    if cap not in manifest.get("enabled_capabilities", []):
        errs.append(f"missing content capability {cap}")
if manifest.get("diagnostics", {}).get("pet_acquisition_templates") != 27:
    errs.append("Pet acquisition template count drift")
sources = {x.get("path"): x.get("sha256") for x in manifest.get("sources", [])}
for path, sha in {
    "app/model/Pet.lua": "214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660",
    "data/tables/pet.lua": "bc974045ec92fd7c0ebb2655d635d1b057eee7f74a871cfa2316b511ad55986e",
    "data/tables/misc.lua": "058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a",
    "app/common/enums.lua": "15340bd89fe7c6f150ccfd4a5cd2a2f0e8e73c89dfae9ac3388376a4799901f3",
}.items():
    if sources.get(path) != sha:
        errs.append(f"source pin drift {path}: {sources.get(path)!r}")

acq = json.loads(read("internal/content/builtin/generated/pet_acquisition_catalog.json") or "{}")
rows = acq.get("templates", [])
if len(rows) != 27:
    errs.append(f"pet acquisition catalog expected 27 rows, got {len(rows)}")
if any(int(x.get("table_id", 0)) != int(x.get("origin_table_id", -1)) for x in rows):
    errs.append("pet acquisition catalog includes non-base/awakened row")
pol = acq.get("policy", {})
if pol.get("starter_egg_item_id") != 50001050 or pol.get("hatch_cost_param") != 12960000:
    errs.append("Pet acquisition policy drift")
want_frag = {1:10, 2:30, 3:80, 4:180, 5:330}
for x in rows:
    if int(x.get("fragment_count", -1)) != want_frag.get(int(x.get("initial_star", -1)), -2):
        errs.append(f"fragment cost drift for table {x.get('table_id')}")
    if int(x.get("hatch_seconds", 0)) != 86400 or int(x.get("summon_type", 0)) != 4:
        errs.append(f"hatch/summon drift for table {x.get('table_id')}")

funcs = json.loads(read("internal/content/builtin/generated/function_gates.json") or "{}")
flist = funcs.get("gates", funcs.get("functions", funcs if isinstance(funcs, list) else []))
cap38 = None
for row in flist:
    if int(row.get("function_id", row.get("id", 0))) == 38:
        cap38 = row.get("announcement_capability")
    elif row.get("announcement_capability") not in (None, "", "NONE"):
        errs.append(f"unexpected announcement capability on function {row.get('function_id', row.get('id'))}")
if cap38 != "PET_STARTER_CA3":
    errs.append(f"Function 38 starter capability drift: {cap38!r}")

# Schema/owner boundary.
mig = need("migrations/00017_ca3_pet_acquisition.sql", "first_free_hatch_used", "gxb_content_pet_acquisition", "gxb_content_pet_acquisition_policy")
for forbidden in ("INSERT INTO player_function_unlocks", "INSERT INTO player_stack_items", "INSERT INTO player_pets"):
    if forbidden.lower() in mig.lower():
        errs.append(f"migration 00017 illegally performs gameplay backfill: {forbidden}")
petdom = need("internal/domain/character/pet.go", "FirstFreeHatchUsed bool", "PetRootLockRank", "PetInstanceLockRank")
if "Capacity" in petdom:
    errs.append("Pet domain invented owned-roster capacity")

# I5 owns starter activation and acquisition debits; Character never writes I5 SQL.
need("internal/application/i5/r5_policy.go", "PetStarterFunctionAnnouncements", '"PET_STARTER_CA3"')
need("internal/application/i5/pet_starter_reconcile.go", "PetStarterLoginReconciler", "LockStackTx", "LockFunctionStateTx", "InsertFunctionUnlockTx", "StarterEggItemID")
need("internal/application/i5/pet_acquisition.go", "PetAcquisitionDebiter", "DebitPetAcquisitionTx", "LockStackTx", "essenceItemID", "UsedEgg")
need("internal/application/i5/grant_lock_plan.go", 'gate.AnnouncementCapability == "PET_STARTER_CA3"', "PetStarterPolicy", "grantLockRankStack")
settle = need("internal/application/i5/settlement_projection.go", "ExtraDrops", "NewFunctionIDs")
i5disp = need("internal/adapters/stockruntime/i5_dispatcher.go", 'body["extra_drops_"]', 'body["new_funcs_"]')
_ = settle, i5disp

# Pet owner commands/replay/hatch boundary.
need("internal/application/characterpet/acquisition.go", "FindPetByOriginTx", "Recovered: true", "DebitPetAcquisitionTx", "Birthday: bound.StartedAt.UTC().Unix()")
need("internal/application/characterpet/hatch.go", "FirstFreeHatchUsed", "HatchCostParam", "ErrPetStillIncubating", "SavePetShowStateTx")
petdisp = need("internal/adapters/stockruntime/pet_dispatcher.go", "case 780:", "case 781:", "case 782:", "case 789:")
for mid in (783,784,785,786,787,788,790,791,792,134):
    if f"case {mid}:" in petdisp:
        errs.append(f"CA3-2 illegally implements deferred Pet MID {mid}")
main = need("cmd/gxb-api/main_postgres.go", "PetStarterFunctionAnnouncements{}", "PetStarterLoginReconciler", "PetAcquisitionDebiter", "[]uint16{780, 781, 782, 789}")
for mid in (783,784,785,786,787,788,790,791,792,134):
    if f"mustRegister({mid}, petD)" in main:
        errs.append(f"CA3-2 illegally registers deferred Pet MID {mid}")

# Content registry exact persistence/verification, not write-only payloads.
need("sql/content/content.sql", "InsertContentPetAcquisition", "ReadPetAcquisition", "ReadPetAcquisitionPolicy", "expected_pet_acquisition", "stored_pet_acquisition")
need("internal/adapters/postgres/contentstore/store.go", "InsertPetAcquisition", "PetAcquisitionCount")
need("internal/adapters/postgres/contentstore/pet_acquisition.go", "PetAcquisitionActive", "PetAcquisitionRevision", "PetAcquisitionTx", "PetAcquisitionPolicyTx")
need("internal/content/registry/types.go", '"PET_ACQUISITION_CA3"', "petAcquisitionJSON", "PetAcquisitionCount")

# Canonical table ownership and immutable migration lock.
try:
    ownership = json.loads(read("docs/architecture/CANONICAL_TABLE_OWNERSHIP.json") or "{}")
    for table in ("gxb_content_pet_acquisition", "gxb_content_pet_acquisition_policy"):
        row = ownership.get("tables", {}).get(table)
        if not row or row.get("owner") != "content-registry" or row.get("migration") != "migrations/00017_ca3_pet_acquisition.sql":
            errs.append(f"ownership drift for {table}")
    for table in ("player_pet_roots", "player_pets"):
        row = ownership.get("tables", {}).get(table)
        if not row or row.get("owner") != "character/pet-core":
            errs.append(f"Pet owner drift for {table}")
except Exception as exc:
    errs.append(f"ownership decode: {exc}")
try:
    lock = json.loads(read("docs/architecture/CUMULATIVE_MIGRATION_LOCK.json") or "{}")
    p = ROOT / "migrations/00017_ca3_pet_acquisition.sql"
    sha = hashlib.sha256(p.read_bytes()).hexdigest() if p.exists() else ""
    if lock.get("highest_migration") != p.name or lock.get("migrations", {}).get(p.name) != sha:
        errs.append("migration lock does not seal 00017 exact bytes/high-water")
except Exception as exc:
    errs.append(f"migration lock decode: {exc}")

if errs:
    print("CA3-2 VALIDATION: FAIL")
    for e in errs:
        print(" -", e)
    raise SystemExit(1)
print("CA3-2 VALIDATION: PASS")
print("Pet acquisition/starter/hatch seams are present; deferred CA3-3/CA4 Pet surfaces remain unregistered")
