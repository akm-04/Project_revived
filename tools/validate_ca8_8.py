#!/usr/bin/env python3
from pathlib import Path
import hashlib
import os
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
errs = []


def req(ok: bool, msg: str) -> None:
    if not ok:
        errs.append(msg)


def file_sha(rel: str) -> str:
    return hashlib.sha256((ROOT / rel).read_bytes()).hexdigest()


product_path = ROOT / "internal/application/characterasset/mode_guild.go"
test_path = ROOT / "internal/application/characterasset/mode_guild_test.go"
arch_path = ROOT / "internal/archguard/ca8_8_contract_test.go"
source_path = ROOT / "tools/check_ca8_8_source_oracle.py"
for path in [product_path, test_path, arch_path, source_path]:
    req(path.is_file(), f"CA8-8 required file missing {path.relative_to(ROOT)}")

product = product_path.read_text() if product_path.is_file() else ""
tests = test_path.read_text() if test_path.is_file() else ""
arch = arch_path.read_text() if arch_path.is_file() else ""
check = (ROOT / "tools/check.sh").read_text()

for token in [
    "type ModeGuildCharacterReader struct",
    "Owned    *OwnedCompositeBuilder",
    "Borrowed *BorrowedCompositeBuilder",
    "func (r ModeGuildCharacterReader) SavedPresetReferencesTx(ctx context.Context, scope CoherentReadScope, pid identity.PlayerID) (SavedPresetReferenceState, error)",
    "func (r ModeGuildCharacterReader) BorrowedHeroTx(ctx context.Context, scope CoherentReadScope, ref QualifiedBorrowedHeroReference) (BorrowedHeroComposite, error)",
    "func (r ModeGuildCharacterReader) BorrowedPetTx(ctx context.Context, scope CoherentReadScope, ref QualifiedBorrowedPetReference) (BorrowedPetComposite, error)",
    "r.Owned.SavedPresetReferencesTx(ctx, scope, pid)",
    "r.Borrowed.BorrowedHeroTx(ctx, scope, ref)",
    "r.Borrowed.BorrowedPetTx(ctx, scope, ref)",
    "state.Clone()",
    "borrowed.Origin != ActorOriginBorrowed",
    "borrowed.QualifiedReference != ref",
    "borrowed.Base.Ref != ref.ActorRef",
    "borrowed.clone()",
]:
    req(token in product, f"CA8-8 product marker missing {token!r}")

methods = sorted(re.findall(r"func \(r ModeGuildCharacterReader\) ([A-Za-z0-9_]+)\(", product))
req(methods == ["BorrowedHeroTx", "BorrowedPetTx", "SavedPresetReferencesTx"], f"CA8-8 method surface drifted: {methods}")

for bad, label in [
    ("database/sql", "database/sql"),
    ("foundation/tx", "transaction ownership"),
    ("time.Now(", "fresh clock"),
    ("NewCoherentReadScope(", "scope rediscovery"),
    ("ActiveRevision(", "content discovery"),
    ("CombatSnapshot", "battle snapshot authority"),
    ("ProviderRequiredButUnavailable", "consumer requiredness"),
    ("OwnedHeroTx(ctx", "speculative owned Hero wrapper"),
    ("OwnedPetTx(ctx", "speculative owned Pet wrapper"),
    ("tutor_rent_hero", "Tutor wire parsing"),
    ("rent_player_id", "Guild wire parsing"),
    ("rent_formation", "Guild actor wire parsing"),
    ("rent_hero_player", "anniversary wire parsing"),
    ("rent_hero_id", "anniversary actor wire parsing"),
    ("rent_pet_player_id", "Pet lender wire parsing"),
    ("rent_pet_id", "Pet actor wire parsing"),
]:
    req(bad not in product, f"CA8-8 product gained forbidden {label} marker {bad!r}")

for token in [
    "TestModeGuildSavedPresetReferencesPreserveCA5StateAndDefensiveCopy",
    "TestModeGuildBorrowedHeroAndPetPreserveExactQualifiedProjection",
    "TestModeGuildRejectsInvalidDependenciesScopeAndTypedInputsBeforeRead",
    "TestModeGuildPropagatesOwnerErrorsAndFailsClosedOnOwnerMismatch",
]:
    req(token in tests, f"CA8-8 focused proof missing {token}")
for token in ["TestCA88ModeGuildCharacterProviderBoundary", "TestCA88IntroducesNoPersistenceWireOrForeignOwnerArtifact"]:
    req(token in arch, f"CA8-8 archguard proof missing {token}")

req('run python3 tools/check_ca8_8_source_oracle.py "${GXB_ORACLE_ROOT:-/mnt/data}"' in check, "CA8-8 source-oracle not wired into tools/check.sh")
req("run python3 tools/validate_ca8_8.py" in check, "CA8-8 static validator not wired into tools/check.sh")

if os.environ.get("GXB_COMPAT_SCRATCH") != "1":
    req(file_sha("go.mod") == "27868c2a7c77c82970cc5142dd9c54fc779794267ec1dd5b827db28a595a4dac", "canonical go.mod pin drift")
    req(file_sha("go.sum") == "d95362310e0526f9c47774f473f1919bb3900f43019328e339cd17fd2bc56c94", "canonical go.sum pin drift")
    req(file_sha(".go-version") == "55a45ba2851dc159876cb8854f80bf67b9eae781e67ce179708ea2e4f990fcd8", "canonical .go-version pin drift")

for directory in [ROOT / "migrations", ROOT / "internal/adapters/stockruntime", ROOT / "internal/protocol"]:
    if directory.exists():
        for path in directory.rglob("*"):
            if path.is_file():
                name = path.name.lower()
                req("ca8_8" not in name and "mode_guild" not in name, f"CA8-8 unexpected persistence/wire artifact {path.relative_to(ROOT)}")

if errs:
    print("CA8-8 VALIDATION: FAIL")
    for err in errs:
        print(" -", err)
    sys.exit(1)

print("CA8-8 VALIDATION: PASS")
print("three-method mode/Guild Character boundary, CA5/CA8-4 reuse, caller-owned coherent scope, no wire/business/persistence ownership and canonical pins preserved")
