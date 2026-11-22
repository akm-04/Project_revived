"""I9-11B daily-buy input compiler.

Compiles the stock item/gift/dropbox rows and the golden-hand, energy-buy and
tenfold tunables from the verified source archive into one immutable bundle.
Only gift rows an item can reference and the dropbox groups those gifts draw
are emitted; absent gift rows or dropbox groups stay absent so the runtime
refuses those boxes fail-closed.
"""
from decimal import Decimal, InvalidOperation


def _int(raw, label, error, *, allow_zero=True, allow_negative=True):
    text = (raw or "").strip()
    if text == "":
        raise error(f"{label} is empty")
    try:
        value = int(text)
    except ValueError:
        raise error(f"{label} is not an integer: {text!r}")
    if not allow_zero and value == 0:
        raise error(f"{label} must be non-zero")
    if not allow_negative and value < 0:
        raise error(f"{label} must be non-negative")
    return value


def _maybe_int(raw, default, label, error, *, allow_negative=False):
    """A source cell that is blank counts as the table's implicit zero."""
    text = (raw or "").strip()
    if text == "":
        return default
    return _int(text, label, error, allow_negative=allow_negative)


def _ids(raw, label, error):
    text = (raw or "").strip()
    if text in ("", "0"):
        return []
    out = []
    for part in text.split("|"):
        part = part.strip()
        if part == "":
            # item 50001188 carries one empty gift slot in the stock table.
            continue
        out.append(_int(part, label, error, allow_negative=False))
    return out


def _millionths(raw, label, error):
    text = (raw or "").strip()
    if text == "":
        raise error(f"{label} is empty")
    try:
        value = Decimal(text) * 1000000
    except InvalidOperation:
        raise error(f"{label} is not a decimal: {text!r}")
    if value != value.to_integral_value():
        raise error(f"{label} is not exact to six decimals: {text!r}")
    return int(value)


GIFT_SCALARS = (
    "crystal", "mana", "energy", "vip_exp", "arena_coin", "march_coin",
    "lucky_coin", "friendship_coin", "skin_fragment", "exp", "badge", "soul",
    "vip", "ex_badge", "tutor_coin", "skin_coin", "spirit_energy",
)


def build_daily_buy_inputs(items, gift_rows, dropbox_rows, vip_rows, monthly_rows, refresh_rows, misc_by_key, daily_consume_rows, error):
    items_by_id = {}
    for index, row in enumerate(items, start=1):
        item_id = _int(row.get("id", ""), f"item[{index}].id", error, allow_zero=False)
        if item_id in items_by_id:
            raise error(f"duplicate item id {item_id}")
        gifts = _ids(row.get("gifts"), f"item[{item_id}].gifts", error)
        one_in_more = _ids(row.get("one_in_more"), f"item[{item_id}].one_in_more", error)
        items_by_id[item_id] = {
            "id": item_id,
            "type": _maybe_int(row.get("type", "0"), 0, f"item[{item_id}].type", error, allow_negative=True),
            "sub_type": _maybe_int(row.get("sub_type", "0"), 0, f"item[{item_id}].sub_type", error),
            "stack": _maybe_int(row.get("stack", "0"), 0, f"item[{item_id}].stack", error),
            "energy": _maybe_int(row.get("energy", "0"), 0, f"item[{item_id}].energy", error),
            "skill_point": _maybe_int(row.get("skill_point", "0"), 0, f"item[{item_id}].skill_point", error),
            "mana": _maybe_int(row.get("mana", "0"), 0, f"item[{item_id}].mana", error),
            "crystal": _maybe_int(row.get("crystal", "0"), 0, f"item[{item_id}].crystal", error),
            "magic_energy": _maybe_int(row.get("magic_energy", "0"), 0, f"item[{item_id}].magic_energy", error),
            "magic_dust": _maybe_int(row.get("magic_dust", "0"), 0, f"item[{item_id}].magic_dust", error),
            "magic_liquid": _maybe_int(row.get("magic_liquid", "0"), 0, f"item[{item_id}].magic_liquid", error),
            "level": _maybe_int(row.get("level", "0"), 0, f"item[{item_id}].level", error),
            "gifts": gifts,
            "one_in_more": one_in_more,
        }

    referenced_gifts = set()
    for item in items_by_id.values():
        referenced_gifts.update(item["gifts"])
        referenced_gifts.update(item["one_in_more"])

    gifts_by_id = {}
    malformed_gifts = 0
    for index, row in enumerate(gift_rows, start=1):
        gift_id = _int(row.get("id", ""), f"gift[{index}].id", error, allow_zero=False)
        if gift_id in gifts_by_id or gift_id not in referenced_gifts:
            continue
        gift_items = _ids(row.get("items"), f"gift[{gift_id}].items", error)
        gift_item_nums = _ids(row.get("item_nums"), f"gift[{gift_id}].item_nums", error)
        if len(gift_items) != len(gift_item_nums):
            # The stock row cannot be granted as written; the box refuses it fail-closed.
            malformed_gifts += 1
            continue
        drops = _ids(row.get("drops"), f"gift[{gift_id}].drops", error)
        record = {
            "id": gift_id,
            "items": gift_items,
            "item_nums": gift_item_nums,
            "drops": drops,
            "equip": (row.get("equip") or "0").strip(),
            "summon_id": _maybe_int(row.get("summon_id", "0"), 0, f"gift[{gift_id}].summon_id", error),
        }
        for scalar in GIFT_SCALARS:
            record[scalar] = _maybe_int(row.get(scalar, "0"), 0, f"gift[{gift_id}].{scalar}", error)
        gifts_by_id[gift_id] = record

    referenced_dropboxes = set()
    for gift in gifts_by_id.values():
        referenced_dropboxes.update(gift["drops"])

    dropboxes = {}
    for index, row in enumerate(dropbox_rows, start=1):
        dropbox_id = _int(row.get("dropbox_id", ""), f"dropbox[{index}].dropbox_id", error, allow_zero=False)
        if dropbox_id not in referenced_dropboxes:
            continue
        roll = {
            "id": _int(row.get("id", ""), f"dropbox[{index}].id", error, allow_zero=False),
            "item_id": _int(row.get("item_id", ""), f"dropbox[{index}].item_id", error, allow_zero=False),
            "item_num": _int(row.get("item_num", ""), f"dropbox[{index}].item_num", error, allow_zero=False),
            "rate": _int(row.get("drop_rate", ""), f"dropbox[{index}].drop_rate", error, allow_negative=False),
            "roll_type": _int(row.get("roll_type", ""), f"dropbox[{index}].roll_type", error, allow_zero=False),
        }
        dropboxes.setdefault(dropbox_id, []).append(roll)
    dropbox_rows_out = [{"id": key, "rolls": dropboxes[key]} for key in sorted(dropboxes)]

    vip = []
    for index, row in enumerate(vip_rows, start=1):
        level = _int(row.get("id", ""), f"vip[{index}].id", error, allow_negative=False)
        vip.append({
            "level": level,
            "num_energy": _int(row.get("num_energy", ""), f"vip[{level}].num_energy", error, allow_negative=False),
            "num_midas": _int(row.get("num_midas", ""), f"vip[{level}].num_midas", error, allow_negative=False),
            "skill_buy": _int(row.get("skill_buy", ""), f"vip[{level}].skill_buy", error, allow_negative=False),
            "skill_max": _int(row.get("skill_max", ""), f"vip[{level}].skill_max", error, allow_negative=False),
        })
    vip.sort(key=lambda row: row["level"])
    if [row["level"] for row in vip] != list(range(16)):
        raise error("vip levels are not 0..15")

    monthly = next((row for row in monthly_rows if (row.get("id") or "").strip() == "1"), None)
    if monthly is None:
        raise error("monthly_privilege row 1 is missing")
    monthly_out = {
        "num_energy": _int(monthly.get("num_energy", ""), "monthly_privilege.num_energy", error, allow_negative=False),
        "num_midas": _int(monthly.get("num_midas", ""), "monthly_privilege.num_midas", error, allow_negative=False),
    }

    refresh = []
    for index, row in enumerate(refresh_rows, start=1):
        row_id = _int(row.get("id", ""), f"refresh_cost[{index}].id", error, allow_zero=False)
        refresh.append({
            "id": row_id,
            "buy_energy_cost": _int(row.get("buy_energy_cost", ""), f"refresh_cost[{row_id}].buy_energy_cost", error, allow_zero=False),
            "buy_mana_cost": _int(row.get("buy_mana_cost", ""), f"refresh_cost[{row_id}].buy_mana_cost", error, allow_zero=False),
            "buy_skill_cost": _int(row.get("buy_skill_cost", ""), f"refresh_cost[{row_id}].buy_skill_cost", error, allow_zero=False),
            "buy_mana_ratio_millionths": _millionths(row.get("buy_mana_ratio", ""), f"refresh_cost[{row_id}].buy_mana_ratio", error),
        })
    refresh.sort(key=lambda row: row["id"])
    if [row["id"] for row in refresh] != list(range(1, len(refresh) + 1)):
        raise error("refresh_cost ids are not contiguous from 1")

    misc_keys = (
        "buy_energy_num", "energy_max_limit", "midas_base", "midas_lv_increase",
        "midas_float_up", "midas_float_down", "midas_crit_type", "midas_crit_rate",
    )
    for key in misc_keys:
        if key not in misc_by_key:
            raise error(f"misc.lua missing required key {key}")

    def misc_positive(key):
        value = _int(misc_by_key[key], f"misc.{key}", error, allow_negative=False)
        if value <= 0:
            raise error(f"misc.{key} must be positive")
        return value

    crit_types = _ids(misc_by_key["midas_crit_type"], "misc.midas_crit_type", error)
    crit_rates = _ids(misc_by_key["midas_crit_rate"], "misc.midas_crit_rate", error)
    if len(crit_types) != len(crit_rates) or not crit_types:
        raise error("misc midas crit type/rate length differ")
    misc_out = {
        "buy_energy_num": misc_positive("buy_energy_num"),
        "energy_max_limit": misc_positive("energy_max_limit"),
        "midas_base": misc_positive("midas_base"),
        "midas_level_increase": misc_positive("midas_lv_increase"),
        "midas_float_up_basis_points": _millionths(misc_by_key["midas_float_up"], "misc.midas_float_up", error) // 100,
        "midas_float_down_basis_points": _millionths(misc_by_key["midas_float_down"], "misc.midas_float_down", error) // 100,
        "midas_crit_types": crit_types,
        "midas_crit_rates": crit_rates,
    }

    daily_consume = []
    for index, row in enumerate(daily_consume_rows, start=1):
        row_id = _int(row.get("id", ""), f"daily_consume[{index}].id", error, allow_zero=False)
        daily_consume.append({
            "id": row_id,
            "cost": _int(row.get("cost", ""), f"daily_consume[{row_id}].cost", error, allow_negative=False),
            "num": _int(row.get("num", ""), f"daily_consume[{row_id}].num", error, allow_negative=False),
            "value": _int(row.get("value", ""), f"daily_consume[{row_id}].value", error, allow_negative=False),
        })
    daily_consume.sort(key=lambda row: row["id"])

    return {
        "schema_version": 1,
        "policy_id": "I9_11B_DAILY_BUY_INPUTS_V1",
        "source_row_counts": {
            "items": len(items_by_id),
            "gift_rows_referenced": len(gifts_by_id),
            "gift_rows_malformed": malformed_gifts,
            "dropboxes_referenced": len(dropbox_rows_out),
            "vip": len(vip),
            "refresh_cost": len(refresh),
            "daily_consume": len(daily_consume),
        },
        "items": [items_by_id[key] for key in sorted(items_by_id)],
        "gifts": [gifts_by_id[key] for key in sorted(gifts_by_id)],
        "dropboxes": dropbox_rows_out,
        "vip": vip,
        "monthly_privilege": monthly_out,
        "refresh_cost": refresh,
        "misc": misc_out,
        "daily_consume": daily_consume,
    }
