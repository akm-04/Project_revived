#!/usr/bin/env python3
"""Build the Pass100 retry-safe MID97 preservation OTA override from canonical Lua."""
from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path

MARKER = "-- PASS100 PRESERVATION OTA MID97 BRIDGE"

OLD = '''function var_0_0.addEnergy(arg_5_0, arg_5_1)\n\txyd.Backend.get():request(xyd.mid.ADD_ENERGY, {}, function(arg_6_0)\n\t\tif arg_5_1 then\n\t\t\targ_5_1(arg_6_0)\n\t\tend\n\tend, {}, true, true)\nend'''

NEW = '''-- PASS100 PRESERVATION OTA MID97 BRIDGE
function var_0_0.addEnergy(arg_5_0, arg_5_1)
	local var_5_0 = tonumber(arg_5_0.selfPlayer.buyEnergyTimes) or 0
	local var_5_1 = math.floor((xyd.ServerTime.get():getServerTime() + 10800) / 86400)
	local var_5_2 = xyd.generateUUID()
	local var_5_3 = "p100-energy-" .. tostring(var_5_1) .. "-" .. tostring(var_5_0) .. "-" .. tostring(var_5_2)

	xyd.Backend.get():request(xyd.mid.ADD_ENERGY, {
		expected_buy_energy_times = var_5_0,
		energy_day_id = var_5_1,
		energy_op_id = var_5_3
	}, function(arg_6_0)
		if arg_5_1 then
			arg_5_1(arg_6_0)
		end
	end, {}, true, true)
end'''


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def patch_bytes(raw: bytes) -> bytes:
    bom = raw.startswith(b"\xef\xbb\xbf")
    text = raw.decode("utf-8-sig")
    newline = "\r\n" if "\r\n" in text else "\n"
    normalized = text.replace("\r\n", "\n")
    if MARKER in normalized:
        raise RuntimeError("canonical input already contains Pass100 marker")
    if normalized.count(OLD) != 1:
        raise RuntimeError(
            f"canonical AddEnergy.lua MID97 constructor did not match exactly once: "
            f"count={normalized.count(OLD)} sha={sha256_bytes(raw)}"
        )
    out_text = normalized.replace(OLD, NEW, 1)
    if newline == "\r\n":
        out_text = out_text.replace("\n", "\r\n")
    out = out_text.encode("utf-8")
    return (b"\xef\xbb\xbf" + out) if bom else out


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("asset_root", type=Path, help="effective assets root containing src_32 and src_64")
    ap.add_argument("--local-assets", type=Path, default=Path("local_assets"))
    ap.add_argument("--report", type=Path, default=Path("docs/PASS100_OTA_BRIDGE_BUILD.json"))
    args = ap.parse_args()

    rows=[]
    patched=[]
    for arch in ("src_32", "src_64"):
        source=args.asset_root/arch/"app/model/AddEnergy.lua"
        if not source.is_file():
            raise SystemExit(f"missing canonical {source}")
        raw=source.read_bytes()
        out=patch_bytes(raw)
        target=args.local_assets/arch/"app/model/AddEnergy.lua"
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(out)
        rows.append({
            "arch": arch,
            "source": f"{arch}/app/model/AddEnergy.lua",
            "source_sha256": sha256_bytes(raw),
            "override": f"{arch}/app/model/AddEnergy.lua",
            "override_sha256": sha256_bytes(out),
            "source_size": len(raw),
            "override_size": len(out),
        })
        patched.append(out)
    if patched[0] != patched[1]:
        raise RuntimeError("src_32/src_64 Pass100 overrides drifted despite identical source contract")

    report={
        "schema_version":1,
        "pass":"100.0",
        "status":"GENERATED_FROM_CANONICAL_SOURCE",
        "bridge":"MID97 source-day + expected purchase ordinal + source-native xyd.generateUUID operation id",
        "retry_invariant":"Backend.lua retries the same params table, preserving the exact operation identity after a lost response.",
        "source_day_formula":"floor((server_time + 10800) / 86400)",
        "operation_id_formula":"p100-energy-{energy_day_id}-{expected_buy_energy_times}-{xyd.generateUUID()}",
        "files":rows,
    }
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(report,indent=2)+"\n",encoding="utf-8")
    print(json.dumps(report,indent=2))
    return 0

if __name__=="__main__":
    raise SystemExit(main())
