import re
from decimal import Decimal, InvalidOperation

SOURCE_COLUMNS = {"gold": 1, "diamond": 2, "dust": 11, "liquor": 12, "power": 13}
DESTINATIONS = (11, 12, 13)
ORDINAL_LIMIT = 60
EXPECTED_COLUMNS = frozenset(("id", "c_resource", *SOURCE_COLUMNS))


def _amount(value, label, error):
    try:
        amount = Decimal(value)
    except (InvalidOperation, TypeError):
        raise error(f"{label} is not numeric: {value!r}") from None
    if not amount.is_finite() or amount != amount.to_integral_value():
        raise error(f"{label} is not a finite whole amount: {value!r}")
    return int(amount)


ADMINISTRATOR_COLUMNS = frozenset((
    "id", "name", "type", "desc", "resources_id", "resources_num", "time",
    "type_request", "function_request_level", "unlock",
))


def build_administrator(blobs, parse_table, error):
    rows = parse_table(blobs["data/tables/event_centre_conversion.lua"].data)
    columns_by_currency = {currency: column for column, currency in SOURCE_COLUMNS.items()}
    rules = {}
    for index, row in enumerate(rows, start=1):
        if set(row) != EXPECTED_COLUMNS:
            raise error(f"administrator conversion row {index} has an unexpected column set")
        if not row["id"].isdigit():
            raise error(f"administrator conversion row {index} id is not a positive integer")
        identifier = int(row["id"])
        destination = identifier // 100
        ordinal = identifier % 100
        if destination not in DESTINATIONS:
            raise error(f"administrator conversion row {index} has unknown destination {destination}")
        if not 1 <= ordinal <= ORDINAL_LIMIT:
            raise error(f"administrator conversion row {index} has ordinal {ordinal} outside 1..{ORDINAL_LIMIT}")
        if identifier in rules:
            raise error(f"duplicate administrator conversion id {identifier}")
        self_column = columns_by_currency[destination]
        if _amount(row[self_column], f"row {index} {self_column}", error) != 0:
            raise error(f"administrator conversion row {index} has a nonzero self-currency cost")
        credit = _amount(row["c_resource"], f"row {index} c_resource", error)
        if credit <= 0:
            raise error(f"administrator conversion row {index} has nonpositive credit")
        costs = {}
        for column, currency in SOURCE_COLUMNS.items():
            if currency == destination:
                continue
            cost = _amount(row[column], f"row {index} {column}", error)
            if cost <= 0:
                raise error(f"administrator conversion row {index} has nonpositive {column} cost")
            costs[str(currency)] = cost
        rules[identifier] = {
            "destination": destination,
            "ordinal": ordinal,
            "credit": credit,
            "costs": costs,
        }
    expected_ids = {destination * 100 + ordinal for destination in DESTINATIONS for ordinal in range(1, ORDINAL_LIMIT + 1)}
    missing = sorted(expected_ids - set(rules))
    if missing:
        raise error(f"missing administrator conversion ids: {missing}")
    ordered = [rules[identifier] for identifier in sorted(rules)]

    level_rows = parse_table(blobs["data/tables/event_centre_administrator.lua"].data)
    if len(level_rows) != 5:
        raise error(f"administrator level table has {len(level_rows)} rows, want 5")
    level_unlocks = []
    known_currencies = set(SOURCE_COLUMNS.values())
    for level, row in enumerate(level_rows, start=1):
        if set(row) != ADMINISTRATOR_COLUMNS:
            raise error(f"administrator level row {level} has an unexpected column set")
        if _amount(row["id"], f"administrator level {level} id", error) != level:
            raise error(f"administrator level {level} is not the expected source level")
        unlock = [
            _amount(part, f"administrator level {level} unlock", error)
            for part in row["unlock"].split("|")
            if part != ""
        ]
        if not unlock or len(unlock) != len(set(unlock)) or any(currency not in known_currencies for currency in unlock):
            raise error(f"administrator level {level} has an invalid unlock set")
        level_unlocks.append({"level": level, "unlock": unlock})
    if set(level_unlocks[-1]["unlock"]) != known_currencies:
        raise error("administrator level 5 does not unlock every source currency")
    return {"schema_version": 1, "rules": ordered, "level_unlocks": level_unlocks}


WORKSHOP_SCHEMA_VERSION = 1
WORKSHOP_RESOURCE_KEYS = {1: "mana", 11: "magic_dust", 12: "magic_liquid", 13: "magic_energy", 14: "magic_exp"}
WORKSHOP_MISC_KEYS = (
    "event_centre_crit_param",
    "event_centre_crit_proportion",
    "event_centre_saturation_init",
    "event_centre_saturation_time",
    "event_centre_accelerate_item",
    "event_centre_accelerate_time",
    "event_centre_pet_cost_item",
    "event_centre_pet_color_accelerate_time",
)
WORKSHOP_DESK_COLUMNS = frozenset((
    "id", "name", "type", "desc", "resources_id", "resources_num", "time",
    "type_request", "function_request_level", "cut_maketime", "item_id",
))
WORKSHOP_RECYCLE_COLUMNS = frozenset((
    "id", "name", "type", "desc", "resources_id", "resources_num", "time",
    "function_request", "function_request_level", "recount_item",
    "energy_limit", "cut_cost_energy", "crit_up",
))
WORKSHOP_BOARD_COLUMNS = frozenset((
    "id", "name", "type", "desc", "resources_id", "resources_num", "time",
    "type_request", "function_request_level", "task_limit", "gold_task",
))
WORKSHOP_MISSION_COLUMNS = frozenset((
    "id", "hero", "hero_id", "name", "desc", "enemy", "monster_star",
    "monster_quality", "monster_level", "fight_id", "fighting", "time", "deposit",
))
WORKSHOP_HERO_COLUMNS = frozenset(("hero_id", "partner", "upper_limit_fighting", "mission_id"))
WORKSHOP_AWARD_COLUMNS = frozenset((
    "id", "grade", "item_id", "item_number", "reward_id", "reward_resource", "reward_gold",
))
WORKSHOP_EXACT_DECIMAL = re.compile(r"(0|[1-9][0-9]*)(\.[0-9]+)?")


def _workshop_integer(value, label, error, *, allow_zero=True):
    try:
        number = int(value)
    except (TypeError, ValueError):
        raise error(f"{label} is not an integer: {value!r}") from None
    if number < 0 or (number == 0 and not allow_zero):
        raise error(f"{label} is out of range: {value!r}")
    return number


def _workshop_vector(value, label, error, *, positive):
    if value == "":
        return []
    numbers = []
    for part in value.split("|"):
        numbers.append(_workshop_integer(part, label, error, allow_zero=not positive))
    return numbers


def _workshop_exact_decimal(value, label, error):
    if not isinstance(value, str) or WORKSHOP_EXACT_DECIMAL.fullmatch(value) is None:
        raise error(f"{label} is not an exact nonnegative decimal: {value!r}")
    try:
        coefficient = Decimal(value)
    except InvalidOperation:
        raise error(f"{label} is not an exact nonnegative decimal: {value!r}") from None
    if not coefficient.is_finite() or coefficient < 0:
        raise error(f"{label} is not an exact nonnegative decimal: {value!r}")
    return value


def _workshop_rows(blobs, parse_table, path, columns, label, error):
    rows = parse_table(blobs[path].data)
    for index, row in enumerate(rows, start=1):
        if set(row) != columns:
            raise error(f"{label} row {index} has an unexpected column set")
    return rows


def _workshop_indexed_value(keys, values, name, row_id, error):
    index = keys.get(name)
    if index is None:
        raise error(f"indexed source table is missing required key {name}")
    if index < 1 or index > len(values):
        raise error(f"indexed source row {row_id} is missing {name}")
    return values[index - 1]


def _workshop_material_identity(identifier, items, label, error):
    if identifier <= 0:
        raise error(f"{label} has a nonpositive resource identity")
    if identifier in WORKSHOP_RESOURCE_KEYS or identifier in items:
        return
    raise error(f"{label} has an unknown resource identity {identifier}")


def build_workshop(blobs, parse_table, parse_indexed_table, parse_items, error):
    """Compile the supplementary Workshop source facts without upgrade costs.

    Book owns building upgrade costs and durations. This compiler emits only the
    per-level desk, recycle and board facts, the mission/hero/award source tables,
    the item make/resolve recipes those callers read, and the exact misc keys.
    """
    items = {}
    for row in parse_items(blobs["data/tables/item.lua"].data):
        identifier = _workshop_integer(row.get("id", ""), "item id", error, allow_zero=False)
        if identifier in items:
            raise error(f"duplicate item id {identifier}")
        items[identifier] = row

    desk_rows = _workshop_rows(
        blobs, parse_table, "data/tables/event_centre_table.lua",
        WORKSHOP_DESK_COLUMNS, "desk", error,
    )
    recycle_rows = _workshop_rows(
        blobs, parse_table, "data/tables/event_centre_recycle.lua",
        WORKSHOP_RECYCLE_COLUMNS, "recycle", error,
    )
    board_rows = _workshop_rows(
        blobs, parse_table, "data/tables/event_centre_notice_board.lua",
        WORKSHOP_BOARD_COLUMNS, "notice board", error,
    )
    mission_rows = _workshop_rows(
        blobs, parse_table, "data/tables/event_centre_mission.lua",
        WORKSHOP_MISSION_COLUMNS, "mission", error,
    )
    hero_rows = _workshop_rows(
        blobs, parse_table, "data/tables/event_centre_hero.lua",
        WORKSHOP_HERO_COLUMNS, "hero profile", error,
    )
    award_rows = _workshop_rows(
        blobs, parse_table, "data/tables/event_centre_mission_award.lua",
        WORKSHOP_AWARD_COLUMNS, "mission award", error,
    )
    if (len(desk_rows), len(recycle_rows), len(board_rows), len(mission_rows), len(hero_rows), len(award_rows)) != (8, 6, 5, 273, 91, 29):
        raise error("workshop source table counts differ from 8 desks, 6 recycle levels, 5 board levels, 273 missions, 91 hero profiles and 29 awards")

    desk_craftable_ids = set()
    desk = []
    for level, row in enumerate(desk_rows, start=1):
        if _workshop_integer(row["id"], f"desk row {level} id", error, allow_zero=False) != level:
            raise error(f"desk level {level} is not the expected source level")
        craftable_ids = _workshop_vector(row["item_id"], f"desk level {level} item_id", error, positive=True)
        if not craftable_ids or len(craftable_ids) != len(set(craftable_ids)):
            raise error(f"desk level {level} has an empty or duplicate craftable item list")
        for identifier in craftable_ids:
            if identifier not in items:
                raise error(f"desk level {level} references unknown item {identifier}")
            if identifier in desk_craftable_ids:
                raise error(f"desk level {level} repeats craftable item {identifier}")
            desk_craftable_ids.add(identifier)
            if not _workshop_vector(items[identifier]["make_res_type"], f"desk item {identifier} make resource", error, positive=True):
                raise error(f"desk item {identifier} has no make recipe")
        desk.append({
            "level": level,
            "cut_maketime": _workshop_integer(row["cut_maketime"], f"desk level {level} cut_maketime", error),
            "craftable_item_ids": craftable_ids,
        })

    recycle_recount_ids = set()
    recycle = []
    for level, row in enumerate(recycle_rows, start=1):
        if _workshop_integer(row["id"], f"recycle row {level} id", error, allow_zero=False) != level:
            raise error(f"recycle level {level} is not the expected source level")
        recount_ids = _workshop_vector(row["recount_item"], f"recycle level {level} recount_item", error, positive=True)
        if not recount_ids or len(recount_ids) != len(set(recount_ids)):
            raise error(f"recycle level {level} has an empty or duplicate recount item list")
        for identifier in recount_ids:
            if identifier not in items:
                raise error(f"recycle level {level} references unknown item {identifier}")
            if identifier in recycle_recount_ids:
                raise error(f"recycle level {level} repeats recount item {identifier}")
            recycle_recount_ids.add(identifier)
            if not _workshop_vector(items[identifier]["resolve_res_type"], f"recycle item {identifier} resolve resource", error, positive=True):
                raise error(f"recycle item {identifier} has no resolve recipe")
        recycle.append({
            "level": level,
            "recount_item_ids": recount_ids,
            "energy_limit": _workshop_integer(row["energy_limit"], f"recycle level {level} energy_limit", error),
            "cut_cost_energy": _workshop_exact_decimal(row["cut_cost_energy"], f"recycle level {level} cut_cost_energy", error),
            "crit_up": _workshop_exact_decimal(row["crit_up"], f"recycle level {level} crit_up", error),
        })

    board = []
    for level, row in enumerate(board_rows, start=1):
        if _workshop_integer(row["id"], f"notice board row {level} id", error, allow_zero=False) != level:
            raise error(f"notice board level {level} is not the expected source level")
        board.append({
            "level": level,
            "task_limit": _workshop_integer(row["task_limit"], f"notice board level {level} task_limit", error, allow_zero=False),
            "gold_task": _workshop_integer(row["gold_task"], f"notice board level {level} gold_task", error),
        })

    missions = []
    mission_by_id = {}
    fight_ids = set()
    for index, row in enumerate(mission_rows, start=1):
        identifier = _workshop_integer(row["id"], f"mission row {index} id", error, allow_zero=False)
        if identifier in mission_by_id:
            raise error(f"duplicate mission id {identifier}")
        fight_id = _workshop_integer(row["fight_id"], f"mission {identifier} fight_id", error, allow_zero=False)
        if fight_id in fight_ids:
            raise error(f"duplicate mission fight id {fight_id}")
        fight_ids.add(fight_id)
        enemy_ids = _workshop_vector(row["enemy"], f"mission {identifier} enemy", error, positive=True)
        monster_stars = _workshop_vector(row["monster_star"], f"mission {identifier} monster_star", error, positive=True)
        monster_qualities = _workshop_vector(row["monster_quality"], f"mission {identifier} monster_quality", error, positive=True)
        monster_levels = _workshop_vector(row["monster_level"], f"mission {identifier} monster_level", error, positive=True)
        if not enemy_ids or len({len(enemy_ids), len(monster_stars), len(monster_qualities), len(monster_levels)}) != 1:
            raise error(f"mission {identifier} has unaligned enemy display vectors")
        if not row["hero"] or not row["name"]:
            raise error(f"mission {identifier} has an empty hero or mission name")
        mission = {
            "id": identifier,
            "hero_name": row["hero"],
            "hero_id": _workshop_integer(row["hero_id"], f"mission {identifier} hero_id", error, allow_zero=False),
            "name": row["name"],
            "enemy_ids": enemy_ids,
            "monster_stars": monster_stars,
            "monster_qualities": monster_qualities,
            "monster_levels": monster_levels,
            "fight_id": fight_id,
            "fighting": _workshop_integer(row["fighting"], f"mission {identifier} fighting", error),
            "duration": _workshop_integer(row["time"], f"mission {identifier} time", error),
            "deposit": _workshop_integer(row["deposit"], f"mission {identifier} deposit", error),
        }
        mission_by_id[identifier] = mission
        missions.append(mission)

    hero_profiles = []
    profile_by_hero_id = {}
    profile_mission_ids = set()
    for index, row in enumerate(hero_rows, start=1):
        hero_id = _workshop_integer(row["hero_id"], f"hero profile row {index} hero_id", error, allow_zero=False)
        if hero_id in profile_by_hero_id:
            raise error(f"duplicate hero profile {hero_id}")
        mission_ids = _workshop_vector(row["mission_id"], f"hero profile {hero_id} mission_id", error, positive=True)
        thresholds = _workshop_vector(row["upper_limit_fighting"], f"hero profile {hero_id} upper_limit_fighting", error, positive=True)
        if len(mission_ids) != 3 or len(thresholds) != 3 or len(mission_ids) != len(set(mission_ids)):
            raise error(f"hero profile {hero_id} does not have three distinct missions and force thresholds")
        for mission_id in mission_ids:
            mission = mission_by_id.get(mission_id)
            if mission is None:
                raise error(f"hero profile {hero_id} references unknown mission {mission_id}")
            if mission["hero_id"] != hero_id:
                raise error(f"hero profile {hero_id} references mission {mission_id} of another hero")
            if mission_id in profile_mission_ids:
                raise error(f"mission {mission_id} belongs to more than one hero profile")
            profile_mission_ids.add(mission_id)
        profile = {
            "hero_id": hero_id,
            "partner_name": row["partner"],
            "mission_ids": mission_ids,
            "force_thresholds": thresholds,
        }
        profile_by_hero_id[hero_id] = profile
        hero_profiles.append(profile)
    if profile_mission_ids != set(mission_by_id):
        raise error("hero profiles do not cover every mission exactly once")

    awards = []
    award_ids = set()
    grade_counts = {1: 0, 2: 0, 3: 0}
    for index, row in enumerate(award_rows, start=1):
        identifier = _workshop_integer(row["id"], f"award row {index} id", error, allow_zero=False)
        if identifier in award_ids:
            raise error(f"duplicate award id {identifier}")
        award_ids.add(identifier)
        grade = _workshop_integer(row["grade"], f"award {identifier} grade", error, allow_zero=False)
        if grade not in grade_counts:
            raise error(f"award {identifier} has an unknown grade {grade}")
        grade_counts[grade] += 1
        item_id = _workshop_integer(row["item_id"], f"award {identifier} item_id", error)
        item_count = _workshop_integer(row["item_number"], f"award {identifier} item_number", error)
        material_ids = _workshop_vector(row["reward_id"], f"award {identifier} reward_id", error, positive=False)
        material_amounts = _workshop_vector(row["reward_resource"], f"award {identifier} reward_resource", error, positive=False)
        if len(material_ids) != len(material_amounts):
            raise error(f"award {identifier} has unaligned material vectors")
        if item_id == 0:
            if item_count != 0:
                raise error(f"award {identifier} has an item count without an item")
        elif item_count <= 0 or item_id not in items:
            raise error(f"award {identifier} has an invalid item reward")
        if material_ids == [0] and material_amounts == [0]:
            material_ids = []
            material_amounts = []
        else:
            if not material_ids or 0 in material_ids:
                raise error(f"award {identifier} has an invalid material vector")
            for material_id, amount in zip(material_ids, material_amounts):
                if material_id not in WORKSHOP_RESOURCE_KEYS or amount <= 0:
                    raise error(f"award {identifier} has an invalid material reward")
        if item_id == 0 and not material_ids:
            raise error(f"award {identifier} carries no reward")
        awards.append({
            "id": identifier,
            "grade": grade,
            "item_id": item_id,
            "item_count": item_count,
            "material_ids": material_ids,
            "material_amounts": material_amounts,
            "gold": _workshop_integer(row["reward_gold"], f"award {identifier} reward_gold", error),
        })
    if grade_counts != {1: 10, 2: 10, 3: 9}:
        raise error(f"award grade distribution differs from source: {grade_counts}")

    pet_keys, pet_rows = parse_indexed_table(blobs["data/tables/pet.lua"].data)
    pet_crafting = []
    pet_item_ids = set()
    for row_id in sorted(pet_rows):
        raw = _workshop_indexed_value(pet_keys, pet_rows[row_id], "table_item_id", row_id, error)
        levels = []
        for level_items in raw.split("@"):
            identifiers = _workshop_vector(level_items, f"pet {row_id} table_item_id", error, positive=True)
            if not identifiers or len(identifiers) != len(set(identifiers)):
                raise error(f"pet {row_id} has an empty or duplicate level item list")
            levels.append(identifiers)
            pet_item_ids.update(identifiers)
        pet_crafting.append({"table_id": row_id, "levels": levels})
    for identifier in pet_item_ids:
        if identifier not in items:
            raise error(f"pet selection references unknown item {identifier}")
        if not _workshop_vector(items[identifier]["make_res_type"], f"pet item {identifier} make resource", error, positive=True):
            raise error(f"pet item {identifier} has no make recipe")

    recipe_item_ids = sorted(desk_craftable_ids | recycle_recount_ids | pet_item_ids)
    item_recipes = []
    for identifier in recipe_item_ids:
        row = items[identifier]
        make_resource_ids = _workshop_vector(row["make_res_type"], f"item {identifier} make_res_type", error, positive=True)
        make_quantities = _workshop_vector(row["make_res_num"], f"item {identifier} make_res_num", error, positive=True)
        resolve_resource_ids = _workshop_vector(row["resolve_res_type"], f"item {identifier} resolve_res_type", error, positive=True)
        resolve_quantities = _workshop_vector(row["resolve_res_num"], f"item {identifier} resolve_res_num", error, positive=True)
        if len(make_resource_ids) != len(make_quantities) or len(resolve_resource_ids) != len(resolve_quantities):
            raise error(f"item {identifier} has unaligned recipe vectors")
        if not make_resource_ids and not resolve_resource_ids:
            raise error(f"item {identifier} has no make or resolve recipe")
        for material_id in make_resource_ids + resolve_resource_ids:
            _workshop_material_identity(material_id, items, f"item {identifier}", error)
        make_time = _workshop_integer(row["make_time"] or "0", f"item {identifier} make_time", error)
        resolve_energy = _workshop_integer(row["resolve_energy"] or "0", f"item {identifier} resolve_energy", error)
        if bool(make_resource_ids) != (make_time > 0):
            raise error(f"item {identifier} make recipe and make_time disagree")
        if bool(resolve_resource_ids) != (resolve_energy > 0):
            raise error(f"item {identifier} resolve recipe and resolve_energy disagree")
        item_recipes.append({
            "item_id": identifier,
            "make_resource_ids": make_resource_ids,
            "make_quantities": make_quantities,
            "make_time": make_time,
            "resolve_resource_ids": resolve_resource_ids,
            "resolve_quantities": resolve_quantities,
            "resolve_energy": resolve_energy,
        })
    if len(item_recipes) != 268:
        raise error(f"workshop recipe count differs from 268: {len(item_recipes)}")

    misc_rows = parse_table(blobs["data/tables/misc.lua"].data)
    misc_by_key = {}
    for index, row in enumerate(misc_rows, start=1):
        key = row.get("key", "")
        if key not in WORKSHOP_MISC_KEYS:
            continue
        if key in misc_by_key:
            raise error(f"duplicate misc key {key} at row {index}")
        misc_by_key[key] = row.get("value", "")
    missing = [key for key in WORKSHOP_MISC_KEYS if key not in misc_by_key]
    if missing:
        raise error(f"misc source is missing required keys: {missing}")
    pet_cost_item_ids = _workshop_vector(misc_by_key["event_centre_pet_cost_item"], "misc.event_centre_pet_cost_item", error, positive=True)
    if len(pet_cost_item_ids) != 2 or len(set(pet_cost_item_ids)) != 2:
        raise error("misc.event_centre_pet_cost_item does not hold two distinct items")
    for identifier in pet_cost_item_ids:
        if identifier not in items:
            raise error(f"misc.event_centre_pet_cost_item references unknown item {identifier}")
    misc = {
        "event_centre_crit_param": _workshop_exact_decimal(misc_by_key["event_centre_crit_param"], "misc.event_centre_crit_param", error),
        "event_centre_crit_proportion": _workshop_exact_decimal(misc_by_key["event_centre_crit_proportion"], "misc.event_centre_crit_proportion", error),
        "event_centre_saturation_init": _workshop_integer(misc_by_key["event_centre_saturation_init"], "misc.event_centre_saturation_init", error, allow_zero=False),
        "event_centre_saturation_time": _workshop_integer(misc_by_key["event_centre_saturation_time"], "misc.event_centre_saturation_time", error, allow_zero=False),
        "event_centre_accelerate_item": _workshop_integer(misc_by_key["event_centre_accelerate_item"], "misc.event_centre_accelerate_item", error, allow_zero=False),
        "event_centre_accelerate_time": _workshop_integer(misc_by_key["event_centre_accelerate_time"], "misc.event_centre_accelerate_time", error, allow_zero=False),
        "event_centre_pet_cost_item": pet_cost_item_ids,
        "event_centre_pet_color_accelerate_time": _workshop_integer(misc_by_key["event_centre_pet_color_accelerate_time"], "misc.event_centre_pet_color_accelerate_time", error),
    }

    return {
        "schema_version": WORKSHOP_SCHEMA_VERSION,
        "desk": desk,
        "recycle": recycle,
        "board": board,
        "missions": missions,
        "hero_profiles": hero_profiles,
        "awards": awards,
        "item_recipes": item_recipes,
        "pet_crafting": pet_crafting,
        "misc": misc,
    }
