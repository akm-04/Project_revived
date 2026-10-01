#!/usr/bin/env python3
from pathlib import Path
import fnmatch
import hashlib
import json
import os
import sys
import zipfile

ROOT = Path(__file__).resolve().parents[1]
errs = []


def req(ok: bool, msg: str) -> None:
    if not ok:
        errs.append(msg)


def file_sha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()


def sha(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def resolve(env_name: str, oracle_id: str) -> Path:
    explicit = os.environ.get(env_name, "")
    if explicit:
        return Path(explicit)
    root = Path(sys.argv[1] if len(sys.argv) > 1 else os.environ.get("GXB_ORACLE_ROOT", "/mnt/data"))
    lock = json.loads((ROOT / "oracles.lock.json").read_text())
    ent = next(x for x in lock["oracles"] if x["id"] == oracle_id)
    if root.is_dir():
        for path in sorted(root.rglob("*.zip")):
            try:
                if any(fnmatch.fnmatch(path.name, pat) for pat in ent["filename_patterns"]) and file_sha(path) == ent["sha256"]:
                    return path
            except OSError:
                pass
    return Path("")


current = resolve("GXB_CA8_8_CURRENT_ARCHIVE", "current_src64")
old = resolve("GXB_CA8_8_OLD_ARCHIVE", "old_client")
current_sha = "c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf"
old_sha = "d0a4815507fd4626ac5749f2f6efae554d3a4bef717793f155f58c8bed7170b1"
for label, path, want in [("current", current, current_sha), ("old", old, old_sha)]:
    req(path.is_file(), f"exact {label} CA8-8 oracle archive missing")
    if path.is_file():
        req(file_sha(path) == want, f"{label} CA8-8 archive identity drift")

current_members = {
    "app/windows/SelectTeamNewWindow.lua": "0fabc7b70c2acf48765c41b414e3cae7504f567cb6fbe344b0f98456ed18667a",
    "app/model/Tutor.lua": "bb424fa849ce791148bf1ee35c8147caf8ecedf4cbb0ad6eca95c81aafaa439b",
    "app/model/SelfGuild.lua": "c744e6f256a796a98613911372c1821b3e02f21d38480184df9c095373bd64f9",
}
old_members = {
    "app/windows/SelectTeamWindow.lua": "7c51a321ea15014e329aa372761c3d76946e1cb72535c62d2985b515f6d59b0f",
}


def read_members(path: Path, prefix: str, expected: dict[str, str], label: str) -> dict[str, str]:
    out: dict[str, str] = {}
    if not path.is_file():
        return out
    with zipfile.ZipFile(path) as zf:
        names = set(zf.namelist())
        for rel, want in expected.items():
            member = prefix + rel
            req(member in names, f"{label} CA8-8 source member missing {rel}")
            if member in names:
                data = zf.read(member)
                req(sha(data) == want, f"{label} CA8-8 member hash drift {rel}")
                out[rel] = data.decode("utf-8", "replace")
    return out


cur = read_members(current, "app-assets/output/assets/src_64/", current_members, "current")
oldtxt = read_members(old, "src/", old_members, "old")

select = cur.get("app/windows/SelectTeamNewWindow.lua", "")
for token in [
    "tutor_rent_hero",
    "rent_hero_player",
    "rent_hero_id",
    "rent_player_id",
    "rent_formation",
    "rent_pet_player_id",
    "rent_pet_id",
]:
    req(token in select, f"current rental request-family marker missing {token!r}")
req("handleRentParams" in select and "fourthAnni" in select, "current Hero rental-family branch markers drifted")

tutor = cur.get("app/model/Tutor.lua", "")
for token in ["getRentHeros", "getHeroIgnoreAwaken", ":toParams()", ".can_rent = true", ".tutorInfo ="]:
    req(token in tutor, f"current Tutor construction marker missing {token!r}")

self_guild = cur.get("app/model/SelfGuild.lua", "")
for token in ["guild_rent_heroes", "tutor_rent_heroes", "setUseRent", ".tutorInfo"]:
    req(token in self_guild, f"current Guild/Tutor separation marker missing {token!r}")

old_select = oldtxt.get("app/windows/SelectTeamWindow.lua", "")
for token in ["rent_player_id", "rent_formation", "rent_pet_player_id", "rent_pet_id"]:
    req(token in old_select, f"V1.164 lender/actor request marker missing {token!r}")

product_path = ROOT / "internal/application/characterasset/mode_guild.go"
req(product_path.is_file(), "CA8-8 product file missing")
product = product_path.read_text() if product_path.is_file() else ""
for token in [
    "type ModeGuildCharacterReader struct",
    "SavedPresetReferencesTx",
    "BorrowedHeroTx",
    "BorrowedPetTx",
    "QualifiedBorrowedHeroReference",
    "QualifiedBorrowedPetReference",
]:
    req(token in product, f"candidate CA8-8 product marker missing {token!r}")
for bad in [
    "tutor_rent_hero",
    "rent_player_id",
    "rent_formation",
    "rent_hero_player",
    "rent_hero_id",
    "rent_pet_player_id",
    "rent_pet_id",
    "fourthAnni",
    "getRentHeros",
]:
    req(bad not in product, f"candidate CA8-8 leaked raw client rental marker {bad!r}")

if errs:
    print("CA8-8 SOURCE ORACLE CHECK: FAIL")
    for err in errs:
        print(" -", err)
    sys.exit(1)

print("CA8-8 SOURCE ORACLE CHECK: PASS")
print(
    "current source keeps Tutor, anniversary and ordinary lender/actor rental request families distinct; "
    "V1.164 corroborates lender+actor identity; CA8-8 consumes only typed qualified references. "
    "These are client/source facts and do not establish original-server rental business rules."
)
