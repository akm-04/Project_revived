#!/usr/bin/env python3
"""Generate operator Girl-ID sheets from compact/runtime authority catalogs."""
from __future__ import annotations

import json
from pathlib import Path
from typing import Iterable

ROOT = Path(__file__).resolve().parents[1]
DATA = ROOT / "data"
DOCS = ROOT / "docs"


def load_json(name: str):
    return json.loads((DATA / name).read_text(encoding="utf-8"))


def table(title: str, intro: list[str], rows: Iterable[dict], evidence) -> str:
    rows = list(rows)
    lines = [title, "=" * len(title), "", *intro, "", f"Count: {len(rows)}", ""]
    lines += [
        "HeroID     | Name                              | Native★ | StoneID    | Group/Evidence",
        "-----------+-----------------------------------+---------+------------+----------------------------------------------",
    ]
    for row in rows:
        lines.append(
            f"{int(row['hero_id']):<10} | {str(row.get('name') or '')[:33]:<33} | "
            f"{int(row.get('native_star') or 0):^7} | {int(row.get('stone_id') or 0):<10} | {evidence(row)}"
        )
    return "\n".join(lines) + "\n"


def main() -> None:
    featured = load_json("summon_featured_catalog.json")
    all_ref = load_json("girl_reference_catalog.json")
    pools = load_json("summon_pool_catalog.json")
    DOCS.mkdir(parents=True, exist_ok=True)

    sx = sorted(featured["sx_eligible"], key=lambda r: int(r["hero_id"]))
    featured56 = sorted(featured["medium_legacy_featured_only"], key=lambda r: int(r["hero_id"]))
    extension58 = sorted(featured["medium_legacy_ordinary_extension"], key=lambda r: int(r["hero_id"]))

    (DOCS / "GIRLS_SX_73.txt").write_text(
        table(
            "SX Girl Hero IDs (73)",
            [
                "Canonical SX feature-selection cohort. Runtime authority: data/summon_featured_catalog.json -> sx_eligible.",
                "Every automatic/manual SX Current or Daily featured slot must resolve inside this set.",
                "Non-SX event/Legacy Girls are never injected into SX.",
            ],
            sx,
            lambda _r: "SX / partner.is_sx",
        ), encoding="utf-8"
    )

    (DOCS / "GIRLS_MEDIUM_FEATURED_56.txt").write_text(
        table(
            "Medium New Add Featured-Only Girl IDs (56)",
            [
                "Exact cohort eligible for Medium SUMMON_LIST_NEW_ADD / rate-up target selection.",
                "These limited/unmapped non-SX Girls have no positive Soul-Casket type2/type5 acquisition route under the Pass42 classifier.",
                "Only IDs in this list are valid nonzero medium.manual_hero_id overrides.",
            ],
            featured56,
            lambda _r: "Medium featured-only Legacy / no positive type2/type5 route",
        ), encoding="utf-8"
    )

    def ext_evidence(r: dict) -> str:
        types = ",".join(str(v) for v in r.get("soul_casket_fragment_types") or [])
        return f"Medium ordinary extension / Soul-Casket type {types}"

    (DOCS / "GIRLS_MEDIUM_EXTENDED_58.txt").write_text(
        table(
            "Medium Soul-Casket-Backed Extension Girl IDs (58)",
            [
                "Limited/unmapped non-SX Girls with positive Soul-Casket type2/type5 fragment-route evidence.",
                "They extend only the ordinary Medium full-Hero candidate pool after that Hero result class is selected.",
                "This 58-Girl extension does not change Medium's top-level ordinary Hero-vs-item probability.",
            ],
            extension58,
            ext_evidence,
        ), encoding="utf-8"
    )

    pool200004 = next(p for p in pools["pools"] if int(p["dropbox_id"]) == 200004)
    all_by_id = {int(r["hero_id"]): r for r in all_ref["girls"]}
    recovered_ids = []
    for row in pool200004["rows"]:
        hid = int(row["item_id"])
        if hid not in recovered_ids:
            recovered_ids.append(hid)
    merged_ids = sorted(set(recovered_ids) | {int(r["hero_id"]) for r in extension58})
    merged_rows = [all_by_id[hid] for hid in merged_ids]
    extension_ids = {int(r["hero_id"]) for r in extension58}
    (DOCS / "GIRLS_MEDIUM_ORDINARY_143.txt").write_text(
        table(
            "Medium Effective Ordinary Full-Hero Candidate IDs (143)",
            [
                "Effective private-server ordinary Medium Hero set: 85 recovered pool200004 Girls + 58 Soul-Casket-backed Legacy extensions.",
                "This is separate from the 56-Girl New Add featured overlay.",
            ],
            merged_rows,
            lambda r: "Legacy extension (58)" if int(r["hero_id"]) in extension_ids else "Recovered Medium pool200004 (85)",
        ), encoding="utf-8"
    )

    all_rows = sorted(all_ref["girls"], key=lambda r: (0 if r["source_family"] == "super_partner" else 1, int(r["hero_id"])))
    title = "All Canonical Girl Hero IDs (291)"
    lines = [
        title,
        "=" * len(title),
        "",
        "Merged operator reference: 277 normal Partner Girls + 14 Vow/super-partner Girls.",
        "Generated from data/girl_reference_catalog.json, which is a compact projection of the canonical Pass42.10 GIRL_CATALOG.jsonl.",
        "Runtime summon eligibility is NOT inferred from this file; use data/summon_featured_catalog.json and the cohort sheets above.",
        "",
        f"Count: {len(all_rows)}",
        "",
        "HeroID     | Name                              | Native★ | StoneID    | SX | Vow | Acquisition              | Legacy group",
        "-----------+-----------------------------------+---------+------------+----+-----+--------------------------+---------------------------",
    ]
    for r in all_rows:
        lines.append(
            f"{int(r['hero_id']):<10} | {str(r.get('name') or '')[:33]:<33} | {int(r.get('native_star') or 0):^7} | "
            f"{int(r.get('stone_id') or 0):<10} | {1 if r.get('is_sx') else 0:^2} | {1 if r.get('is_vow') else 0:^3} | "
            f"{str(r.get('acquisition_class') or '')[:24]:<24} | {str(r.get('legacy_group') or '')}"
        )
    all_text = "\n".join(lines) + "\n"
    (DOCS / "ALL_GIRLS_ID.txt").write_text(all_text, encoding="utf-8")
    # Compatibility/master alias retained because earlier releases/documentation refer to this path.
    (DOCS / "GIRL_IDS.txt").write_text(all_text, encoding="utf-8")

    print("Generated:")
    for name in [
        "GIRLS_SX_73.txt",
        "GIRLS_MEDIUM_FEATURED_56.txt",
        "GIRLS_MEDIUM_EXTENDED_58.txt",
        "GIRLS_MEDIUM_ORDINARY_143.txt",
        "ALL_GIRLS_ID.txt",
        "GIRL_IDS.txt",
    ]:
        print(f"  docs/{name}")


if __name__ == "__main__":
    main()
