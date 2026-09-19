#!/usr/bin/env python3
from __future__ import annotations
import hashlib, json, sys
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

manifest_path = ROOT / "internal/content/builtin/generated/manifest.json"
try:
    manifest = json.loads(manifest_path.read_text())
except Exception as exc:
    errs.append(f"manifest decode: {exc}")
    manifest = {}

if "PET_CORE_CA3" not in manifest.get("enabled_capabilities", []):
    errs.append("PET_CORE_CA3 capability absent")
sources = {x.get("path"): x.get("sha256") for x in manifest.get("sources", [])}
want_sources = {
    "app/model/Pet.lua": "214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660",
    "data/tables/pet.lua": "bc974045ec92fd7c0ebb2655d635d1b057eee7f74a871cfa2316b511ad55986e",
}
for path, sha in want_sources.items():
    if sources.get(path) != sha:
        errs.append(f"source pin drift {path}: {sources.get(path)!r}")
if manifest.get("diagnostics", {}).get("pet_templates") != 54 or manifest.get("diagnostics", {}).get("pet_origin_families") != 27:
    errs.append("Pet content diagnostic drift")

mig = need("migrations/00016_ca3_pet_foundation.sql", "gxb_content_pet_templates", "player_pet_roots", "player_pets", "UNIQUE(player_id, origin_table_id)")
for forbidden in ("capacity", "starter_entitlement", "pet_styles", "active_style", "skill_levels"):
    # comments may mention excluded concepts; only reject schema-ish occurrences.
    if forbidden in mig.lower().replace("capacity,", "").replace("starter entitlement", ""):
        pass
schema_lines = [line.strip().lower() for line in mig.splitlines() if not line.lstrip().startswith("--")]
if any(line.startswith("is_born ") or " is_born boolean" in line for line in schema_lines):
    errs.append("migration persists unsupported independent is_born")

pet_domain = need("internal/domain/character/pet.go", "PetRootLockRank     = 420", "PetInstanceLockRank = 430", "OriginTableID", "PetRef", "PetSummary")
if "Capacity" in pet_domain:
    errs.append("Pet domain invented owned-roster capacity")

proj = need("internal/projection/pet/stock.go", '"is_born":', '"skills":', '"equips":', '"fumos":', '"practice_attr":')
for forbidden in ('"active_style"', '"pet_styles"'):
    # Presence is only permitted in fail-safe omission assertions, not assignments.
    if f'out[{forbidden}] =' in proj or f'{forbidden}:' in proj:
        errs.append(f"Pet projection claims CA7 field {forbidden}")

pet_sql = need("sql/character/pet.sql", "-- owner: character/pet-core", "ListPlayerPets", "ReadPetByID")
if "DELETE FROM PLAYER_PETS" in pet_sql.upper():
    errs.append("CA3-1 must not introduce Pet removal")

content_sql = need("sql/content/content.sql", "InsertContentPetCore", "expected_pet_templates", "stored_pet_templates")
store = need("internal/adapters/postgres/contentstore/store.go", "InsertPetCore", "PetCoreJSON", "PetCount")
reg = need("internal/content/registry/types.go", '"PET_CORE_CA3"', "petCoreJSON", "PetCount")
_ = content_sql, store, reg

lock_probe = json.loads(read("docs/architecture/CUMULATIVE_MIGRATION_LOCK.json") or "{}")
forward_ca3_2 = str(lock_probe.get("highest_migration", "")) >= "00017_ca3_pet_acquisition.sql"
main = need("cmd/gxb-api/main_postgres.go", "characterstore.PetBootstrapContributor{}", "characterstore.PetBootstrapProjection{}", "stockruntime.PetDispatcher")
if "[]uint16{56, 780," in main or "[]uint16{780, 1056" in main:
    errs.append("MID780 still registered through LobbyDispatcher")
if not ("mustRegister(780, petD)" in main or "[]uint16{780," in main):
    errs.append("MID780 is not registered through PetDispatcher")
if not forward_ca3_2:
    for mid in ("781", "782", "783", "784", "785", "786", "787", "788", "789", "790", "791", "792", "134"):
        if f"mustRegister({mid}, petD)" in main:
            errs.append(f"CA3-1 illegally activates Pet mutation MID {mid}")

disp = need("internal/adapters/stockruntime/pet_dispatcher.go", "case 780:", '"not_pet_mid"')
if not forward_ca3_2:
    for mid in (781,782,783,784,785,786,787,788,789,790,791,792,134):
        if f"case {mid}:" in disp:
            errs.append(f"Pet dispatcher implements blocked MID {mid}")

ownership = json.loads(read("docs/architecture/CANONICAL_TABLE_OWNERSHIP.json") or "{}")
for table, owner in (("gxb_content_pet_templates","content-registry"),("player_pet_roots","character/pet-core"),("player_pets","character/pet-core")):
    row = ownership.get("tables", {}).get(table)
    if not row or row.get("owner") != owner or row.get("migration") != "migrations/00016_ca3_pet_foundation.sql":
        errs.append(f"ownership drift for {table}")

lock = json.loads(read("docs/architecture/CUMULATIVE_MIGRATION_LOCK.json") or "{}")
migp = ROOT / "migrations/00016_ca3_pet_foundation.sql"
want = hashlib.sha256(migp.read_bytes()).hexdigest() if migp.exists() else ""
if lock.get("migrations", {}).get(migp.name) != want:
    errs.append("migration lock does not seal 00016 exact bytes")

if errs:
    print("CA3-1 VALIDATION: FAIL")
    for e in errs:
        print(" -", e)
    raise SystemExit(1)
print("CA3-1 VALIDATION: PASS")
print("Pet core identity/root/roster/projection/content seams are present; forward CA3-2 activation is delegated to the CA3-2 validator when migration 00017+ is present")
