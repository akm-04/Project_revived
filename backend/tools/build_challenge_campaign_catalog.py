#!/usr/bin/env python3
"""Build Pass122 Challenge catalog from effective src_64 without executing Lua."""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path

EXPECTED_ROOTS = [24111, 24211, 24311, 24411, 24511, 24611, 24711]


def decode(raw: str) -> str:
    out: list[str] = []
    i = 0
    mapping = {"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"'}
    while i < len(raw):
        ch = raw[i]
        if ch != "\\":
            out.append(ch); i += 1; continue
        i += 1
        if i >= len(raw):
            out.append("\\"); break
        out.append(mapping.get(raw[i], raw[i])); i += 1
    return "".join(out)


def strings(block: str) -> list[str]:
    return [decode(m.group(1)) for m in re.finditer(r'"((?:\\.|[^"\\])*)"', block)]


def brace(text: str, start: int) -> tuple[str, int]:
    depth = 0; in_string = False; escaped = False
    for idx in range(start, len(text)):
        ch = text[idx]
        if in_string:
            if escaped: escaped = False
            elif ch == "\\": escaped = True
            elif ch == '"': in_string = False
            continue
        if ch == '"': in_string = True
        elif ch == "{": depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0: return text[start:idx + 1], idx + 1
    raise ValueError("unclosed Lua brace block")


def table(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8-sig")
    kstart = text.index("{", text.index("keys ="))
    keys_block, kend = brace(text, kstart)
    keys = strings(keys_block)
    rstart = text.index("{", text.index("rows =", kend))
    rows_block, _ = brace(text, rstart)
    rows: list[dict[str, str]] = []
    idx = 1
    while idx < len(rows_block) - 1:
        if rows_block[idx] != "{": idx += 1; continue
        block, idx = brace(rows_block, idx)
        values = strings(block)
        if values:
            if len(values) != len(keys): raise ValueError(f"{path.name}: row/key length mismatch")
            rows.append(dict(zip(keys, values)))
    return rows


def sha(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def build(src64: Path) -> dict:
    tables = src64 / "data" / "tables"
    campaign_path = tables / "campaign.lua"
    chapter_path = tables / "chapter.lua"
    drop_path = tables / "campaign_dropbox.lua"
    campaigns = table(campaign_path)
    chapters = table(chapter_path)
    drops = table(drop_path)
    challenge = [row for row in campaigns if int(row.get("campaign_type") or 0) == 24]
    ids = {int(row["campaign_id"]) for row in challenge}

    order: list[int] = []
    for row in chapters:
        for raw in (row.get("challenge") or "").split("|"):
            if raw and int(raw) in ids: order.append(int(raw))
    if len(order) != len(ids) or set(order) != ids: raise ValueError("chapter.lua Challenge ordering does not cover exactly the Campaign Challenge rows")
    order_idx = {cid: idx for idx, cid in enumerate(order)}

    pools: dict[int, list[dict[str, str]]] = {}
    for row in drops:
        pools.setdefault(int(row.get("dropbox_id") or 0), []).append(row)

    parents = {cid: [] for cid in ids}
    raw_rows: list[dict] = []
    edge_count = 0
    for row in challenge:
        cid = int(row["campaign_id"])
        children = [int(v) for v in (row.get("next_campaign_id") or "").split("|") if v and int(v) > 0]
        for child in children:
            if child not in ids: raise ValueError(f"Challenge child outside graph: {cid}->{child}")
            parents[child].append(cid); edge_count += 1
        pool = int(row.get("init_dropbox") or 0)
        awards = []
        for drop in pools.get(pool, []):
            rate = int(drop.get("increase_rate") or 0)
            if rate <= 0: continue
            if rate % 10000: raise ValueError(f"non-deterministic Challenge init rate {cid}:{rate}")
            quantity = rate // 10000
            if quantity > 0:
                awards.append({"increase_rate": rate, "item_id": int(drop["item_id"]), "item_num": quantity})
        raw_rows.append({
            "campaign_id": cid,
            "chapter": int(row.get("chapter") or 0),
            "children": children,
            "daily_limit": int(row.get("daily_limit") or 0),
            "defeat_cost": int(row.get("defeat_cost") or 0),
            "deterministic_init_awards": awards,
            "dropbox_id": int(row.get("dropbox") or 0),
            "energy_cost": int(row.get("energy_cost") or 0),
            "init_dropbox_id": pool,
            "last_campaign_id_raw": row.get("last_campaign_id") or "",
            "mana_gain": int(row.get("mana_gain") or 0),
            "next_campaign_id_raw": row.get("next_campaign_id") or "",
            "partner_exp": int(row.get("partner_exp") or 0),
            "relate_normal_campaign_id": int(row.get("relate_campaign_id") or 0),
            "source_order": order_idx[cid],
            "sweep_reward": int(row.get("sweep_reward") or 0),
        })
    for row in raw_rows:
        cid = row["campaign_id"]
        row["parents"] = sorted(parents[cid], key=order_idx.__getitem__)
        row["is_root"] = not row["parents"]
    raw_rows.sort(key=lambda row: row["source_order"])
    roots = [row["campaign_id"] for row in raw_rows if row["is_root"]]
    fanout = sum(len(row["children"]) > 1 for row in raw_rows)
    award_count = sum(len(row["deterministic_init_awards"]) for row in raw_rows)
    if (len(raw_rows), edge_count, roots, fanout) != (144, 137, EXPECTED_ROOTS, 22):
        raise ValueError(f"Challenge topology invariant drift: rows={len(raw_rows)} edges={edge_count} roots={roots} fanout={fanout}")
    if any(row["daily_limit"] or row["dropbox_id"] or row["sweep_reward"] for row in raw_rows):
        raise ValueError("Challenge unexpectedly exposes sweep/repeat plane")
    return {
        "_meta": {
            "authority": "effective src_64 raw Challenge topology + campaign_dropbox.lua deterministic init pools",
            "campaign_type": 24,
            "deterministic_award_row_count": award_count,
            "edge_count": edge_count,
            "fanout_count": fanout,
            "pass": "122.0",
            "reward_formula": "quantity = increase_rate // 10000",
            "root_count": len(roots),
            "row_count": len(raw_rows),
            "schema_version": 1,
            "source_resolution": "effective_merged",
            "source_sha256": {
                "data/tables/campaign.lua": sha(campaign_path),
                "data/tables/chapter.lua": sha(chapter_path),
                "data/tables/campaign_dropbox.lua": sha(drop_path),
            },
        },
        "campaigns": {str(row["campaign_id"]): row for row in raw_rows},
        "ordered_campaign_ids": [row["campaign_id"] for row in raw_rows],
        "roots": roots,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("src64", type=Path)
    ap.add_argument("output", type=Path)
    args = ap.parse_args()
    payload = build(args.src64)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps(payload["_meta"], indent=2, sort_keys=True))
    return 0

if __name__ == "__main__": raise SystemExit(main())
