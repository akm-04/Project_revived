#!/usr/bin/env python3
"""Verify the narrow client-source facts that bound the I6A kernel.

This deliberately checks hashes and lexical/source-shape facts only. It does not
promote source presence to reachability/server behavior and does not assert that
client +8/05:00/+1-second logic is a universal server reset policy.
"""
from __future__ import annotations
import fnmatch, hashlib, json, sys, zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OROOT = Path(sys.argv[1] if len(sys.argv) > 1 else "/mnt/data")
lock = json.loads((ROOT / "oracles.lock.json").read_text())
fixture = json.loads((ROOT / "testdata/sourcefacts/pass493_i6a_generation_scheduler.json").read_text())

def fsha(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for block in iter(lambda: f.read(1 << 20), b""):
            h.update(block)
    return h.hexdigest()

def locate(oracle_id: str) -> Path:
    oracle = next(x for x in lock["oracles"] if x["id"] == oracle_id)
    for path in sorted(OROOT.iterdir()):
        if (path.is_file() and
            any(fnmatch.fnmatch(path.name, pat) for pat in oracle["filename_patterns"]) and
            fsha(path) == oracle["sha256"]):
            return path
    raise SystemExit(f"{oracle_id}: verified oracle not found")

def shab(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()

current = locate("current_src64")
old = locate("old_client")
current_paths = {
    "ServerTime.lua": "app-assets/output/assets/src_64/app/common/ServerTime.lua",
    "Activities.lua": "app-assets/output/assets/src_64/app/model/Activities.lua",
    "RegionArena.lua": "app-assets/output/assets/src_64/app/model/RegionArena.lua",
    "Playoffs.lua": "app-assets/output/assets/src_64/app/model/Playoffs.lua",
    "mid.lua": "app-assets/output/assets/src_64/app/common/network/mid.lua",
}
old_paths = {
    "ServerTime.lua": "src/app/common/ServerTime.lua",
    "Activities.lua": "src/app/model/Activities.lua",
    "RegionArena.lua": "src/app/model/RegionArena.lua",
    "Playoffs.lua": "src/app/model/Playoffs.lua",
}
errs: list[str] = []
cur_txt: dict[str, str] = {}
old_txt: dict[str, str] = {}

with zipfile.ZipFile(current) as z:
    for name, path in current_paths.items():
        data = z.read(path)
        if name in fixture["current_src64"]:
            got = shab(data)
            exp = fixture["current_src64"][name]
            if got != exp:
                errs.append(f"current source hash drift {name}: {got}")
        cur_txt[name] = data.decode("utf-8-sig", errors="replace")

with zipfile.ZipFile(old) as z:
    for name, path in old_paths.items():
        data = z.read(path)
        got = shab(data)
        exp = fixture["old_client"][name]
        if got != exp:
            errs.append(f"old-client source hash drift {name}: {got}")
        old_txt[name] = data.decode("utf-8-sig", errors="replace")

checks = [
    ("MID229 activities", "xyd.mid.ACTIVITIES = 229" in cur_txt["mid.lua"]),
    ("server time is received/projected and advanced client-side",
        "function var_0_0.resetServerTime" in cur_txt["ServerTime.lua"] and
        "arg_7_0.serverTime_ = arg_7_1" in cur_txt["ServerTime.lua"] and
        "return math.floor(arg_6_0.serverTime_)" in cur_txt["ServerTime.lua"]),
    ("client seconds-of-day helper contains +8 presentation logic",
        "local var_8_0 = 8" in cur_txt["ServerTime.lua"] and
        "serverTime_ % 86400 + var_8_0 * 3600" in cur_txt["ServerTime.lua"]),
    ("05:00:01 client event reload trigger",
        "if var_9_0 == 18001 then" in cur_txt["ServerTime.lua"] and
        "name = xyd.event.UPDATE_ACTIVITIES_ONTIME" in cur_txt["ServerTime.lua"]),
    ("activity timer and foreground route reload through MID229",
        "UPDATE_ACTIVITIES_ONTIME" in cur_txt["Activities.lua"] and
        "APP_ENTER_FOREGROUND_EVENT" in cur_txt["Activities.lua"] and
        "arg_12_0:loadActivities()" in cur_txt["Activities.lua"] and
        "request(xyd.mid.ACTIVITIES, {}" in cur_txt["Activities.lua"]),
    ("server-projected activity row fields are consumed",
        all(x in cur_txt["Activities.lua"] for x in ["table_id", "is_open", "start_time", "end_time"])),
    ("client boundary conventions are not lexically uniform",
        "var_38_0 <= var_38_2 and var_38_2 < var_38_1" in cur_txt["Activities.lua"] and
        "var_59_1 >= iter_59_1.start_time and var_59_1 <= iter_59_1.end_time" in cur_txt["Activities.lua"] and
        "getServerTime() >= iter_61_1.start_time and xyd.ServerTime.get():getServerTime() < iter_61_1.end_time" in cur_txt["Activities.lua"]),
    ("activity openness consumes server is_open",
        "iter_60_1.table_id == arg_60_1 and iter_60_1.is_open == 1" in cur_txt["Activities.lua"]),
    ("historical client corroborates timer/reload shape",
        "UPDATE_ACTIVITIES_ONTIME" in old_txt["ServerTime.lua"] and
        "UPDATE_ACTIVITIES_ONTIME" in old_txt["Activities.lua"] and
        "request(xyd.mid.ACTIVITIES" in old_txt["Activities.lua"]),
    ("RegionArena/Playoffs source remains independently version-bound",
        bool(cur_txt["RegionArena.lua"]) and bool(cur_txt["Playoffs.lua"])),
]
for label, ok in checks:
    if not ok:
        errs.append("source fact missing: " + label)

# Exact equality is corroborative only; do not interpret it as server truth.
for name in ("RegionArena.lua", "Playoffs.lua"):
    if shab(cur_txt[name].encode()) == shab(old_txt[name].encode()):
        # Encoding roundtrip is not the authority; fixture hashes above are. This
        # branch is intentionally informational only and not used as a proof.
        pass

if errs:
    print("I6A SOURCE ORACLE CHECK: FAIL")
    for err in errs:
        print(" -", err)
    raise SystemExit(1)

print("I6A SOURCE ORACLE CHECK: PASS")
print("verified candidate-bound current/historical client hashes and reload/time source shape; no server reachability/reset semantics inferred")
