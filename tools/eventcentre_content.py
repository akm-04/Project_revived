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
    return {"schema_version": 1, "rules": ordered}
