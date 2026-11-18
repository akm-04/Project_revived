"""I9-11C core-shop compiler.

Compiles shop_config, the stock tables of every served shop type, the dropbox
groups those tables reference and the refresh ladders into one immutable
catalog. A missing stock table fails the compile; a stock row whose group or
roll is not a qualified shop row fails the compile rather than being dropped,
except a drop column longer than its rate column, where the missing weight is
the source's implicit unreachable zero.
"""

SHOP_TYPES = (
    1, 2, 3, 4, 5, 6, 7, 8, 9, 12, 13, 14, 30, 35,
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 28, 31, 33, 36,
)

# config.lua FuncShopMap: the permanent merchant functions gate the types whose
# shop_config function_id is 0.
CONFIG_FUNCTION_BY_TYPE = {4: 12, 5: 13, 8: 35}

REFRESH_KEYS = (
    "shop_cost", "arena_shop_cost", "crusade_shop_cost", "goblin_shop_cost",
    "black_market_cost", "top_shop_cost", "guild_shop_cost",
    "space_trip_shop_cost", "region_shop_cost", "paradise_shop_cost",
    "library_shop_cost", "guild_friend_shop_cost", "vending_shop_cost",
    "team_shop_cost",
)

SELL_TYPES = (1, 2, 3, 4, 5, 6, 7, 10, 15, 16, 17, 22, 23, 24, 25, 32)

STONE_CURRENCY_ITEM = 50001427
CUBE_CURRENCY_ITEM = 50002072


def _int(raw, label, error, *, allow_zero=True, allow_negative=False):
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


def _pipe_ints(raw, label, error, *, allow_negative=False):
    text = (raw or "").strip()
    if text in ("", "0"):
        return []
    out = []
    for part in text.split("|"):
        part = part.strip()
        if part == "":
            continue
        out.append(_int(part, label, error, allow_negative=allow_negative))
    return out


def _slot_count(row):
    highest = 0
    for key in row:
        if not key.startswith("slot") or not key.endswith("_drop"):
            continue
        number = key[4:].split("_")[0]
        if number.isdigit():
            highest = max(highest, int(number))
    return highest


def _compile_stock(table, rows, dropbox_groups, error):
    compiled_rows = []
    referenced = set()
    for index, row in enumerate(rows, start=1):
        row_id = _int(row.get("id", ""), f"{table}[{index}].id", error, allow_zero=False)
        slots = []
        for slot in range(1, _slot_count(row) + 1):
            drops = _pipe_ints(row.get(f"slot{slot}_drop", ""), f"{table}[{row_id}].slot{slot}_drop", error)
            rates = _pipe_ints(row.get(f"slot{slot}_rate", ""), f"{table}[{row_id}].slot{slot}_rate", error)
            if len(rates) > len(drops):
                raise error(f"{table}[{row_id}].slot{slot}: more weights than groups")
            groups = []
            for position, dropbox_id in enumerate(drops):
                weight = rates[position] if position < len(rates) else 0
                if dropbox_id not in dropbox_groups:
                    raise error(f"{table}[{row_id}].slot{slot}: unknown dropbox {dropbox_id}")
                if weight > 0:
                    groups.append({"dropbox_id": dropbox_id, "weight": weight})
                    referenced.add(dropbox_id)
            if not groups:
                raise error(f"{table}[{row_id}].slot{slot}: no reachable group")
            slots.append({"groups": groups})
        compiled_rows.append({"id": row_id, "slots": slots})
    return compiled_rows, referenced


def build_shop_catalog(shop_config_rows, stock_rows_by_table, dropbox_rows, refresh_rows, error):
    shops_by_id = {}
    for index, row in enumerate(shop_config_rows, start=1):
        shop_id = _int(row.get("id", ""), f"shop_config[{index}].id", error, allow_zero=False)
        if shop_id in shops_by_id:
            raise error(f"duplicate shop type {shop_id}")
        shops_by_id[shop_id] = row
    missing = [shop_type for shop_type in SHOP_TYPES if shop_type not in shops_by_id]
    if missing:
        raise error(f"shop_config is missing types {missing}")

    raw_dropbox_groups = {}
    for index, row in enumerate(dropbox_rows, start=1):
        dropbox_id = _int(row.get("dropbox_id", ""), f"dropbox[{index}].dropbox_id", error, allow_zero=False)
        raw_dropbox_groups.setdefault(dropbox_id, []).append((index, row))

    shops = []
    stock_tables = {}
    referenced_groups = set()
    seen_tables = set()
    total_rows = 0
    for shop_type in SHOP_TYPES:
        row = shops_by_id[shop_type]
        table = (row.get("shop_table") or "").strip()
        if table not in stock_rows_by_table:
            raise error(f"shop type {shop_type} names missing stock table {table!r}")
        function_id = _int(row.get("function_id", ""), f"shop_config[{shop_type}].function_id", error)
        if function_id == 0:
            function_id = CONFIG_FUNCTION_BY_TYPE.get(shop_type, 0)
        refresh_times = [value for value in _pipe_ints(row.get("refresh_time", ""), f"shop_config[{shop_type}].refresh_time", error) if value > 0]
        shops.append({
            "type": shop_type,
            "function_id": function_id,
            "is_team_shop": _int(row.get("is_team_shop", ""), f"shop_config[{shop_type}].is_team_shop", error),
            "slot_num": _int(row.get("slot_num", ""), f"shop_config[{shop_type}].slot_num", error, allow_zero=False),
            "refresh_type": _int(row.get("refresh_type", ""), f"shop_config[{shop_type}].refresh_type", error),
            "refresh_key": (row.get("refresh_key") or "").strip(),
            "refresh_times": refresh_times,
            "shop_table": table,
            "is_alone": _int(row.get("is_alone", ""), f"shop_config[{shop_type}].is_alone", error),
            "is_unlimit": _int(row.get("is_unlimit", ""), f"shop_config[{shop_type}].is_unlimit", error),
            "auto_refresh": _int(row.get("auto_refresh", ""), f"shop_config[{shop_type}].auto_refresh", error),
            "team_dungeon_homologous_id": _int(row.get("team_dungeon_homologous_id", ""), f"shop_config[{shop_type}].team_dungeon_homologous_id", error),
        })
        if table in seen_tables:
            continue
        seen_tables.add(table)
        compiled, referenced = _compile_stock(table, stock_rows_by_table[table], raw_dropbox_groups, error)
        if not compiled:
            raise error(f"stock table {table} is empty")
        stock_tables[table] = {"rows": compiled}
        referenced_groups |= referenced
        total_rows += len(compiled)

    referenced_ids = sorted(referenced_groups)
    groups = {}
    for dropbox_id in referenced_ids:
        rolls = []
        for index, row in raw_dropbox_groups[dropbox_id]:
            roll = {
                "item_id": _int(row.get("item_id", ""), f"dropbox[{index}].item_id", error, allow_zero=False),
                "item_num": _int(row.get("item_num", ""), f"dropbox[{index}].item_num", error, allow_zero=False),
                "sell_type": _int(row.get("sell_type", ""), f"dropbox[{index}].sell_type", error, allow_zero=False),
                "sell_price": _int(row.get("sell_price", ""), f"dropbox[{index}].sell_price", error, allow_zero=False),
                "discount": _int(row.get("discount", ""), f"dropbox[{index}].discount", error),
                "rate": _int(row.get("drop_rate", ""), f"dropbox[{index}].drop_rate", error),
            }
            if roll["sell_type"] not in SELL_TYPES:
                raise error(f"dropbox[{index}] unqualified sell_type {roll['sell_type']}")
            if roll["discount"] not in (0, 1):
                raise error(f"dropbox[{index}] unqualified discount {roll['discount']}")
            if roll["rate"] < 0:
                raise error(f"dropbox[{index}] negative drop_rate")
            rolls.append(roll)
        rolls.sort(key=lambda roll: (roll["rate"], roll["item_id"], roll["item_num"], roll["sell_price"]))
        if not any(roll["rate"] > 0 for roll in rolls):
            raise error(f"dropbox {dropbox_id} has no positive rate")
        groups[str(dropbox_id)] = rolls

    refresh = {}
    for key in REFRESH_KEYS:
        ladder = []
        for index, row in enumerate(refresh_rows, start=1):
            row_id = _int(row.get("id", ""), f"refresh_cost[{index}].id", error, allow_zero=False)
            ladder.append(_int(row.get(key, ""), f"refresh_cost[{row_id}].{key}", error))
        refresh[key] = ladder

    return {
        "schema_version": 1,
        "policy_id": "I9_11C_CORE_SHOPS_V2",
        "source_row_counts": {
            "shop_config": len(shops_by_id),
            "shops": len(shops),
            "stock_tables": len(stock_tables),
            "stock_rows": total_rows,
            "dropbox_groups_referenced": len(groups),
            "dropbox_rows_referenced": sum(len(rolls) for rolls in groups.values()),
            "refresh_cost_rows": len(refresh_rows),
        },
        "shops": shops,
        "stock_tables": stock_tables,
        "groups": groups,
        "refresh_cost": refresh,
        "tunables": {
            "stone_currency_item": STONE_CURRENCY_ITEM,
            "cube_currency_item": CUBE_CURRENCY_ITEM,
            "discount_millionths": 600000,
            "month_card_millionths": 550000,
            "level_pool_rows": 100,
        },
    }
