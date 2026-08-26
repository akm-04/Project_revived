#!/usr/bin/env python3
"""Build the immutable Horcrux/HUNQI source catalog from effective src_64.

Pass166 H1 foundation. This generator records client/table facts only; private-
server compatibility math lives separately in horcrux_policy_v1.json.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import re
from pathlib import Path
from typing import Any

EXPECTED_MODELS = 54
EXPECTED_TEMPLATES = 378
EXPECTED_STRENGTH_ROWS = 90
EXPECTED_TRIAL_STAGES = 42
EXPECTED_TRIAL_POOLS = 84
EXPECTED_TRIAL_DROP_ROWS = 3672
EXPECTED_POSITIONS = (1, 2, 3, 4, 5, 6)


def _sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def _decode(raw: str) -> str:
    out: list[str] = []
    i = 0
    mapping = {"n": "\n", "r": "\r", "t": "\t", "\\": "\\", '"': '"'}
    while i < len(raw):
        ch = raw[i]
        if ch != "\\":
            out.append(ch)
            i += 1
            continue
        i += 1
        if i >= len(raw):
            out.append("\\")
            break
        out.append(mapping.get(raw[i], raw[i]))
        i += 1
    return "".join(out)


def _strings(block: str) -> list[str]:
    return [_decode(m.group(1)) for m in re.finditer(r'"((?:\\.|[^"\\])*)"', block)]


def _brace(text: str, start: int) -> tuple[str, int]:
    depth = 0
    in_string = False
    escaped = False
    for idx in range(start, len(text)):
        ch = text[idx]
        if in_string:
            if escaped:
                escaped = False
            elif ch == "\\":
                escaped = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start:idx + 1], idx + 1
    raise ValueError("unclosed Lua brace block")


def _table(path: Path) -> list[dict[str, str]]:
    text = path.read_text(encoding="utf-8-sig")
    kstart = text.index("{", text.index("keys ="))
    keys_block, kend = _brace(text, kstart)
    keys = _strings(keys_block)
    rstart = text.index("{", text.index("rows =", kend))
    rows_block, _ = _brace(text, rstart)
    rows: list[dict[str, str]] = []
    idx = 1
    while idx < len(rows_block) - 1:
        if rows_block[idx] != "{":
            idx += 1
            continue
        block, idx = _brace(rows_block, idx)
        values = _strings(block)
        if not values:
            continue
        if len(values) != len(keys):
            raise ValueError(f"{path.name}: row/key length mismatch {len(values)} != {len(keys)}")
        rows.append(dict(zip(keys, values)))
    return rows


def _int(value: Any, default: int = 0) -> int:
    try:
        return int(str(value or "0"))
    except (TypeError, ValueError):
        return default


def _number(value: Any) -> int | float:
    text = str(value or "0").strip()
    if not text:
        return 0
    try:
        value_f = float(text)
    except ValueError:
        return 0
    if value_f.is_integer():
        return int(value_f)
    return value_f


def _pipe_ints(value: Any) -> list[int]:
    return [_int(part) for part in str(value or "").split("|") if str(part).strip()]


def _pipe_numbers(value: Any) -> list[int | float]:
    return [_number(part) for part in str(value or "").split("|") if str(part).strip()]


def build(src64: Path) -> dict[str, Any]:
    tables = src64 / "data" / "tables"
    paths = {
        "data/tables/spirit.lua": tables / "spirit.lua",
        "data/tables/spirit_equip.lua": tables / "spirit_equip.lua",
        "data/tables/spirit_strth.lua": tables / "spirit_strth.lua",
        "data/tables/spirit_suit.lua": tables / "spirit_suit.lua",
        "data/tables/spirit_campaign.lua": tables / "spirit_campaign.lua",
        "data/tables/campaign_dropbox.lua": tables / "campaign_dropbox.lua",
        "data/tables/misc.lua": tables / "misc.lua",
    }
    client_paths = {
        "app/common/tables/SpiritTable.lua": src64 / "app/common/tables/SpiritTable.lua",
        "app/common/tables/SpiritStrthTable.lua": src64 / "app/common/tables/SpiritStrthTable.lua",
        "app/common/tables/SpiritCampaignTable.lua": src64 / "app/common/tables/SpiritCampaignTable.lua",
        "app/common/enums.lua": src64 / "app/common/enums.lua",
        "app/windows/HunqiStrengthenWindow.lua": src64 / "app/windows/HunqiStrengthenWindow.lua",
        "app/windows/HunqiCampaignWindow.lua": src64 / "app/windows/HunqiCampaignWindow.lua",
        "app/windows/HunqiAutoFightWindow.lua": src64 / "app/windows/HunqiAutoFightWindow.lua",
        "app/windows/SelectTeamNewWindow.lua": src64 / "app/windows/SelectTeamNewWindow.lua",
        "app/scenes/BattleCreate.lua": src64 / "app/scenes/BattleCreate.lua",
        "app/common/network/mid.lua": src64 / "app/common/network/mid.lua",
        "app/model/Backpack.lua": src64 / "app/model/Backpack.lua",
        "app/model/NormalHero.lua": src64 / "app/model/NormalHero.lua",
        "app/model/SuperHero.lua": src64 / "app/model/SuperHero.lua",
    }
    for path in [*paths.values(), *client_paths.values()]:
        if not path.is_file():
            raise RuntimeError(f"required effective source missing: {path}")

    raw_models = _table(paths["data/tables/spirit.lua"])
    raw_templates = _table(paths["data/tables/spirit_equip.lua"])
    raw_strength = _table(paths["data/tables/spirit_strth.lua"])
    raw_suits = _table(paths["data/tables/spirit_suit.lua"])
    raw_campaigns = _table(paths["data/tables/spirit_campaign.lua"])
    raw_campaign_drops = _table(paths["data/tables/campaign_dropbox.lua"])
    raw_misc = _table(paths["data/tables/misc.lua"])
    misc_values = {str(row.get("key") or ""): row.get("value") for row in raw_misc}
    program_limit = _int(misc_values.get("spirit_program_limit"), 0)
    spirit_num_limit = _int(misc_values.get("spirit_num_limit"), 0)
    spirit_energy_minute = _int(misc_values.get("spirit_energy_minute"), 0)
    spirit_energy_up_limit = _int(misc_values.get("spirit_energy_up_limit"), 0)
    spirit_auto_limit = _int(misc_values.get("spirit_auto_limit"), 0)
    spirit_auto_time = _int(misc_values.get("spirit_auto_time"), 0)
    strengthen_exp_rate = _number(misc_values.get("spirit_strth_exp_rate"))
    strengthen_mana_rate = _int(misc_values.get("spirit_strth_gold_rate"), 0)
    if program_limit <= 0:
        raise ValueError("misc spirit_program_limit missing")
    if spirit_num_limit <= 0:
        raise ValueError("misc spirit_num_limit missing")
    if (spirit_energy_minute, spirit_energy_up_limit, spirit_auto_limit, spirit_auto_time) != (360, 180, 10, 5):
        raise ValueError("Gods Trial misc source values drift")
    if strengthen_exp_rate != 0.6:
        raise ValueError(f"misc spirit_strth_exp_rate drift: {strengthen_exp_rate}")
    if strengthen_mana_rate != 25:
        raise ValueError(f"misc spirit_strth_gold_rate drift: {strengthen_mana_rate}")

    enums_text = client_paths["app/common/enums.lua"].read_text(encoding="utf-8-sig")
    campaign_type_block = re.search(r"xyd\.CampaignType\s*=\s*\{(.*?)\n\}", enums_text, re.S)
    hunqi_match = re.search(r"\bHUNQI\s*=\s*(\d+)", campaign_type_block.group(1) if campaign_type_block else "")
    campaign_type = int(hunqi_match.group(1)) if hunqi_match else 0
    if campaign_type != 79:
        raise ValueError(f"xyd.CampaignType.HUNQI drift: {campaign_type}")
    max_match = re.search(r"xyd\.HunqiMaxLev\s*=\s*(\d+)", enums_text)
    max_level = int(max_match.group(1)) if max_match else 0
    if max_level != 15:
        raise ValueError(f"xyd.HunqiMaxLev drift: {max_level}")
    strengthen_window_text = client_paths["app/windows/HunqiStrengthenWindow.lua"].read_text(encoding="utf-8-sig")
    if "spirit_strth_exp_rate" not in strengthen_window_text or "spirit_strth_gold_rate" not in strengthen_window_text:
        raise ValueError("HunqiStrengthenWindow strengthening rate consumers missing")
    if "% 3 == 0" not in strengthen_window_text:
        raise ValueError("HunqiStrengthenWindow milestone cadence drift")

    models: dict[str, dict[str, Any]] = {}
    for row in raw_models:
        model_id = _int(row.get("id"))
        models[str(model_id)] = {
            "id": model_id,
            "star": _int(row.get("star")),
            "pos": _int(row.get("pos")),
            "main": _pipe_ints(row.get("main")),
            "main_is_p": _pipe_ints(row.get("main_is_p")),
            "main_value": _pipe_numbers(row.get("main_value")),
            "main_strth": _pipe_numbers(row.get("main_strth")),
            "sub_num": _int(row.get("sub_num")),
            "sub_num_rate": _pipe_ints(row.get("sub_num_rate")),
            "sub_is_p": _pipe_ints(row.get("sub_is_p")),
            "sub": _pipe_ints(row.get("sub")),
            "sub_strth": _pipe_numbers(row.get("sub_strth")),
            "sub_value": _pipe_numbers(row.get("sub_value")),
            "exp": _int(row.get("exp")),
        }

    templates: dict[str, dict[str, int]] = {}
    for row in raw_templates:
        item_id = _int(row.get("item_id"))
        templates[str(item_id)] = {
            "item_id": item_id,
            "family_id": _int(row.get("from")),
            "model_id": _int(row.get("model_id")),
        }

    strengthen: list[dict[str, int]] = [
        {"id": _int(row.get("id")), "star": _int(row.get("star")), "lv": _int(row.get("lv")), "exp": _int(row.get("exp"))}
        for row in raw_strength
    ]

    suits: dict[str, dict[str, Any]] = {}
    for row in raw_suits:
        suit_id = _int(row.get("id"))
        suits[str(suit_id)] = {
            "id": suit_id,
            "name": str(row.get("name") or ""),
            "attr_2": _int(row.get("attr_2")),
            "is_p": _int(row.get("is_p")),
            "attr_2_value": _number(row.get("attr_2_value")),
            "attr_4_desc": str(row.get("attr_4_desc") or ""),
            "campaign_desc": str(row.get("campain_desc") or ""),
        }

    campaigns: dict[str, dict[str, Any]] = {}
    ordered_campaign_ids: list[int] = []
    for row in raw_campaigns:
        cid = _int(row.get("id"))
        ordered_campaign_ids.append(cid)
        display_type = _int(row.get("display_type"))
        display_raw = str(row.get("display") or "")
        rule_raw = str(row.get("rule_display") or "")
        campaigns[str(cid)] = {
            "id": cid,
            "name": str(row.get("name") or ""),
            "desc": str(row.get("desc") or ""),
            "day": _int(row.get("day")),
            "last_campaign": _int(row.get("last_campaign")),
            "next_campaign": _int(row.get("next_campaign")),
            "level": _int(row.get("level")),
            "cost_type": _int(row.get("cost_type")),
            "win_cost_num": _int(row.get("win_cost_num")),
            "lose_cost_num": _int(row.get("lose_cost_num")),
            "model": _int(row.get("model")),
            "scale": _number(row.get("scale")),
            "battle": _int(row.get("battle")),
            "init_display": _pipe_ints(row.get("init_display")),
            "display_type": display_type,
            "display": _pipe_ints(display_raw) if display_type == 1 else display_raw,
            "rule_display": _pipe_ints(rule_raw) if display_type == 1 else rule_raw,
            "init_dropbox": _int(row.get("init_dropbox")),
            "dropbox": _int(row.get("dropbox")),
            "is_open": _int(row.get("is_open")),
            "title": str(row.get("title") or ""),
        }

    referenced_trial_pools: list[int] = []
    for cid in ordered_campaign_ids:
        campaign = campaigns[str(cid)]
        referenced_trial_pools.extend([int(campaign["init_dropbox"]), int(campaign["dropbox"])])
    if len(set(referenced_trial_pools)) != EXPECTED_TRIAL_POOLS:
        raise ValueError(f"Gods Trial referenced pool count drift: {len(set(referenced_trial_pools))}")

    trial_drop_pools: dict[str, list[dict[str, int]]] = {str(pool_id): [] for pool_id in referenced_trial_pools}
    ordinal_by_pool: dict[int, int] = {pool_id: 0 for pool_id in referenced_trial_pools}
    for row in raw_campaign_drops:
        pool_id = _int(row.get("dropbox_id"))
        if pool_id not in ordinal_by_pool:
            continue
        ordinal_by_pool[pool_id] += 1
        trial_drop_pools[str(pool_id)].append({
            "id": _int(row.get("id")),
            "dropbox_id": pool_id,
            "item_id": _int(row.get("item_id")),
            "increase_rate": _int(row.get("increase_rate")),
            "ordinal": ordinal_by_pool[pool_id],
        })
    trial_drop_row_count = sum(len(rows) for rows in trial_drop_pools.values())
    if trial_drop_row_count != EXPECTED_TRIAL_DROP_ROWS:
        raise ValueError(f"Gods Trial drop row count drift: {trial_drop_row_count}")
    if any(not rows for rows in trial_drop_pools.values()):
        raise ValueError("Gods Trial referenced drop pool has no rows")

    if len(models) != EXPECTED_MODELS:
        raise ValueError(f"Horcrux model count drift: {len(models)}")
    if len(templates) != EXPECTED_TEMPLATES:
        raise ValueError(f"Horcrux template count drift: {len(templates)}")
    if len(strengthen) != EXPECTED_STRENGTH_ROWS:
        raise ValueError(f"Horcrux strengthening count drift: {len(strengthen)}")
    if len(campaigns) != EXPECTED_TRIAL_STAGES:
        raise ValueError(f"Gods Trial stage count drift: {len(campaigns)}")
    positions = tuple(sorted({int(row["pos"]) for row in models.values()}))
    if positions != EXPECTED_POSITIONS:
        raise ValueError(f"Horcrux positions drift: {positions}")
    for template in templates.values():
        if template["model_id"] not in {int(k) for k in models}:
            raise ValueError(f"template references unknown model: {template}")
    days = sorted({row["day"] for row in campaigns.values()})
    if days != list(range(1, 8)):
        raise ValueError(f"Gods Trial days drift: {days}")

    return {
        "schema_version": 4,
        "_meta": {
            "pass": "170.0",
            "wave": "H5_GODS_TRIAL",
            "authority": "effective src_64 Horcrux tables and client consumers",
            "source_resolution": "effective_src64",
            "epistemic_class": "SOURCE_FACT_ONLY",
            "source_hashes": {name: _sha256(path) for name, path in {**paths, **client_paths}.items()},
            "expected_counts": {
                "models": EXPECTED_MODELS,
                "templates": EXPECTED_TEMPLATES,
                "strength_rows": EXPECTED_STRENGTH_ROWS,
                "trial_stages": EXPECTED_TRIAL_STAGES,
                "trial_pools": EXPECTED_TRIAL_POOLS,
                "trial_drop_rows": EXPECTED_TRIAL_DROP_ROWS,
            },
            "note": "Raw source only. Private-server RNG, capacity, anomaly overlays and unrecovered server policy are stored separately in horcrux_policy_v1.json.",
        },
        "limits": {
            "spirit_program_limit": program_limit,
            "spirit_num_limit": spirit_num_limit,
            "spirit_energy_minute": spirit_energy_minute,
            "spirit_energy_up_limit": spirit_energy_up_limit,
            "spirit_auto_limit": spirit_auto_limit,
            "spirit_auto_time": spirit_auto_time,
        },
        "trial_rules": {
            "campaign_type": campaign_type,
        },
        "trial_drop_pools": trial_drop_pools,
        "ordered_trial_dropbox_ids": referenced_trial_pools,
        "strengthening_rules": {
            "max_level": max_level,
            "fodder_exp_rate": strengthen_exp_rate,
            "mana_per_exp": strengthen_mana_rate,
            "milestones": list(range(3, max_level + 1, 3)),
        },
        "models": models,
        "templates": templates,
        "strengthening": strengthen,
        "suits": suits,
        "campaigns": campaigns,
        "ordered_campaign_ids": ordered_campaign_ids,
    }


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--src64", required=True, type=Path)
    ap.add_argument("--output", required=True, type=Path)
    args = ap.parse_args()
    payload = build(args.src64)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_text(json.dumps(payload, indent=2, ensure_ascii=False, sort_keys=True) + "\n", encoding="utf-8")
    print(json.dumps({
        "models": len(payload["models"]),
        "templates": len(payload["templates"]),
        "strengthening": len(payload["strengthening"]),
        "suits": len(payload["suits"]),
        "campaigns": len(payload["campaigns"]),
        "trial_pools": len(payload["trial_drop_pools"]),
        "trial_drop_rows": sum(len(v) for v in payload["trial_drop_pools"].values()),
    }, indent=2))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
