#!/usr/bin/env python3
"""CA1 narrow source/oracle drift check.

This is hash + lexical corroboration only. It proves that CA1's deliberately
narrow PartnerEntity/material-debit seams still align with the exact current
src_64 and historical v1.164 client evidence used by the research checkpoint.
It does not prove original-server behavior or authorize CA2+ mechanics.
"""
from __future__ import annotations

import fnmatch
import hashlib
import json
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "/mnt/data")
LOCK = json.loads((ROOT / "oracles.lock.json").read_text())


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def locate(oracle_id: str) -> Path:
    entry = next(x for x in LOCK["oracles"] if x["id"] == oracle_id)
    for path in sorted(OROOT.iterdir()):
        if not path.is_file():
            continue
        if not any(fnmatch.fnmatch(path.name, pat) for pat in entry["filename_patterns"]):
            continue
        if sha256_file(path) == entry["sha256"]:
            return path
    raise SystemExit(f"{oracle_id}: verified oracle not found under {OROOT}")


def read(z: zipfile.ZipFile, name: str) -> str:
    return z.read(name).decode("utf-8-sig", errors="replace")


current = locate("current_src64")
old = locate("old_client")
errs: list[str] = []

with zipfile.ZipFile(current) as z:
    item = read(z, "app-assets/output/assets/src_64/app/common/tables/ItemTable.lua")
    pet = read(z, "app-assets/output/assets/src_64/app/model/Pet.lua")
    mid = read(z, "app-assets/output/assets/src_64/app/common/network/mid.lua")

with zipfile.ZipFile(old) as z:
    old_item = read(z, "src/app/common/tables/ItemTable.lua")
    old_pet = read(z, "src/app/model/Pet.lua")
    old_mid = read(z, "src/app/common/network/mid.lua")

checks = [
    ("current ItemTable keeps hero/pet/style mappings distinct", all(x in item for x in [
        "heroIDs_", "partner_id", "petIDs_", "pet_id", "stylePet_", "style_pet",
    ])),
    ("historical ItemTable corroborates distinct hero/pet/style mappings", all(x in old_item for x in [
        "heroIDs_", "partner_id", "petIDs_", "pet_id", "stylePet_", "style_pet",
    ])),
    ("current Pet style state is explicit", "active_style" in pet and "pet_styles" in pet),
    ("historical Pet style state is explicit", "active_style" in old_pet and "pet_styles" in old_pet),
    ("current Pet advance/style MIDs are distinct", all(x in mid for x in [
        "xyd.mid.PET_ADVANCE = 785",
        "xyd.mid.GET_PET_STYLE_FORM_ITEM = 1893",
        "xyd.mid.USE_PET_STYLE = 1894",
        "xyd.mid.CANCEL_PET_STYLE = 1895",
    ])),
    ("historical Pet advance/style MIDs corroborate current split", all(x in old_mid for x in [
        "xyd.mid.PET_ADVANCE = 785",
        "xyd.mid.GET_PET_STYLE_FORM_ITEM = 1893",
        "xyd.mid.USE_PET_STYLE = 1894",
        "xyd.mid.CANCEL_PET_STYLE = 1895",
    ])),
]
for label, ok in checks:
    if not ok:
        errs.append(label)

if errs:
    print("CA1 SOURCE ORACLE CHECK: FAIL")
    for err in errs:
        print(" -", err)
    raise SystemExit(1)

print("CA1 SOURCE ORACLE CHECK: PASS")
print("verified exact current+historical corpora; lexical evidence keeps partner/pet/style identities distinct; no CA2+ mechanics inferred")
