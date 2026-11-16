#!/usr/bin/env python3
"""Generate and check the R8 player data manifest.

The table classes live in docs/architecture/CANONICAL_TABLE_OWNERSHIP.json under
each table's "data" object. This tool joins them with the live PostgreSQL catalog,
computes restore order from the foreign keys and writes
docs/data/PLAYER_DATA_MANIFEST.json (player tables only, in restore order).
"owner_where" narrows a shared table to its player rows (receipts: owner_kind = 'player').

--check exits 1 with one line per problem.
"""
import argparse
import heapq
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "docs/architecture/CANONICAL_TABLE_OWNERSHIP.json"
MANIFEST_PATH = ROOT / "docs/data/PLAYER_DATA_MANIFEST.json"
AUTHORITY = "R8 player data manifest (generated from CANONICAL_TABLE_OWNERSHIP.json and the PostgreSQL catalog)"

PLAYER_NAMED = re.compile(r"(^|_)player_id$|^(challenger|attacker|defender|student|lender|holder|mentor|apprentice|owner|"
                          r"inviter|invitee|sender|recipient|viewer|author|subject|actor|member|leader|target|blocked)_id$")
RENAME_TABLE_RE = re.compile(r"\bALTER\s+TABLE\s+(?:IF\s+EXISTS\s+)?([A-Za-z_][A-Za-z0-9_]*)\s+RENAME\s+TO\s+([A-Za-z_][A-Za-z0-9_]*)", re.IGNORECASE)

# References that intentionally have no key to players: journals, allocators, polymorphic text.
UNKEYED_PLAYER_REFERENCES = {
    ("client_log_capabilities", "player_id"),
    ("logical_servers", "max_player_id"),
    ("logical_servers", "next_player_id"),
    ("redeem_redemptions", "subject_id"),
}

TABLES_SQL = ("SELECT tablename FROM pg_tables WHERE schemaname = 'public' AND tablename NOT LIKE 'river_%' "
              "AND tablename <> 'goose_db_version' ORDER BY 1")
COLUMNS_SQL = ("SELECT table_name, column_name, data_type FROM information_schema.columns "
               "WHERE table_schema = 'public' ORDER BY table_name, ordinal_position")
FOREIGN_KEYS_SQL = """
    SELECT c.conrelid::regclass::text, a.attname, c.confrelid::regclass::text
    FROM pg_constraint c JOIN LATERAL unnest(c.conkey) WITH ORDINALITY k(attnum, n) ON true
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = k.attnum
    WHERE c.contype = 'f' ORDER BY 1, 3"""
PRIMARY_KEYS_SQL = """
    SELECT c.conrelid::regclass::text, array_agg(a.attname ORDER BY k.n)
    FROM pg_constraint c JOIN LATERAL unnest(c.conkey) WITH ORDINALITY k(attnum, n) ON true
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = k.attnum
    WHERE c.contype = 'p' GROUP BY 1"""


class Catalog:
    def __init__(self, tables, columns, foreign_keys, primary_keys, json_columns):
        self.tables = sorted(tables)
        self.columns = columns
        self.foreign_keys = foreign_keys
        self.primary_keys = primary_keys
        self.json_columns = json_columns


def query(database, sql):
    result = subprocess.run(["psql", database, "-AtF", "\t", "-c", sql], capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit("manifest catalog query failed: " + result.stderr.strip())
    return [line.split("\t") for line in result.stdout.splitlines() if line]


def load_catalog(database):
    tables = [row[0] for row in query(database, TABLES_SQL)]
    columns, json_columns = {}, {}
    for table, column, kind in query(database, COLUMNS_SQL):
        columns.setdefault(table, []).append(column)
        if kind == "jsonb":
            json_columns.setdefault(table, []).append(column)
    foreign_keys = {}
    for table, column, target in query(database, FOREIGN_KEYS_SQL):
        foreign_keys.setdefault(table, []).append((column, target))
    primary_keys = {table: keys.split(",") for table, keys in query(database, PRIMARY_KEYS_SQL)}
    return Catalog(tables, columns, foreign_keys, primary_keys, json_columns)


def load_classes():
    document = json.loads(CONTRACT_PATH.read_text())
    classes = {}
    for table, entry in document["tables"].items():
        if isinstance(entry.get("data"), dict):
            classes[table] = entry["data"]
    return classes


def retired_tables():
    """Old and kept names of tables a migration renamed to *_retired_*.

    Such tables are pre-migration leftovers awaiting a later drop, not canonical
    player data, so neither the catalog check nor the restore manifest covers them.
    """
    retired = set()
    for path in sorted((ROOT / "migrations").glob("*.sql")):
        for old, new in RENAME_TABLE_RE.findall(path.read_text(errors="replace")):
            if "_retired_" in new:
                retired.update((old, new))
    return retired


def player_columns(catalog, table):
    direct = [column for column, target in catalog.foreign_keys.get(table, []) if target == "players"]
    named = [column for column in catalog.columns.get(table, []) if PLAYER_NAMED.search(column)]
    return sorted(set(named) | set(direct))


def reference_problems(catalog, classes):
    """A classified reference must key players directly or through player-scoped tables."""
    player_scoped = {table for table in classes if classes[table].get("scope") == "player"}
    problems = []
    for table in catalog.tables:
        for column in (classes.get(table) or {}).get("references") or []:
            if (table, column) in UNKEYED_PLAYER_REFERENCES:
                continue
            targets = {target for keyed, target in catalog.foreign_keys.get(table, []) if keyed == column}
            if targets & (player_scoped | {"players"}):
                continue
            problems.append(f"{table}.{column}: player reference has no key to players")
    return problems


def parent_tables(catalog, classes=None):
    parents = {}
    for table in catalog.tables:
        targets = {target for _, target in catalog.foreign_keys.get(table, [])
                   if target in catalog.tables and target != table}
        data = (classes or {}).get(table) or {}
        via = data.get("via")
        if via in catalog.tables and via != table:
            targets.add(via)
        parents[table] = sorted(targets)
    return parents


def components_of(catalog, parents):
    index, low, stack, on_stack, counter = {}, {}, [], set(), [0]
    found = []

    def visit(node):
        index[node] = low[node] = counter[0]
        counter[0] += 1
        stack.append(node)
        on_stack.add(node)
        for parent in parents[node]:
            if parent not in index:
                visit(parent)
                low[node] = min(low[node], low[parent])
            elif parent in on_stack:
                low[node] = min(low[node], index[parent])
        if low[node] == index[node]:
            component = set()
            while True:
                member = stack.pop()
                on_stack.discard(member)
                component.add(member)
                if member == node:
                    break
            found.append(component)

    for table in catalog.tables:
        if table not in index:
            visit(table)
    return found


def restore_positions(catalog, classes):
    parents = parent_tables(catalog, classes)
    components = components_of(catalog, parents)
    component_of = {}
    for number, component in enumerate(components):
        for member in component:
            component_of[member] = number
    component_parents = {number: set() for number in range(len(components))}
    for child, targets in parents.items():
        for parent in targets:
            if component_of[child] != component_of[parent]:
                component_parents[component_of[child]].add(component_of[parent])
    waiting = {number: len(targets) for number, targets in component_parents.items()}
    children = {number: [] for number in range(len(components))}
    for number, targets in component_parents.items():
        for parent in targets:
            children[parent].append(number)
    ready = [number for number in waiting if waiting[number] == 0]
    heapq.heapify(ready)
    order, position = [], {}
    while len(position) < len(catalog.tables):
        if not ready:
            raise SystemExit("restore order component graph is not acyclic")
        number = heapq.heappop(ready)
        for table in sorted(components[number]):
            position[table] = len(position)
            order.append(table)
        for child in children[number]:
            waiting[child] -= 1
            if waiting[child] == 0:
                heapq.heappush(ready, child)
    return position


def strong_components(catalog):
    """Pairs that share an FK cycle; the order check skips those edges."""
    pairs = set()
    for component in components_of(catalog, parent_tables(catalog)):
        if len(component) > 1:
            for member in component:
                for other in component:
                    if member != other:
                        pairs.add((member, other))
    return pairs


def build_manifest(catalog, classes):
    position = restore_positions(catalog, classes)
    entries = []
    for table in sorted(catalog.tables, key=lambda name: position[name]):
        data = classes.get(table)
        if data is None or data.get("scope") != "player":
            continue
        entries.append({
            "table": table,
            "scope": data["scope"],
            "owner": data.get("owner") or [],
            "via": data.get("via"),
            "kind": data.get("kind"),
            "backup": bool(data.get("backup")),
            "references": data.get("references") or [],
            "retention": data.get("retention"),
            "restore_order": position[table],
            "payload_columns": catalog.json_columns.get(table, []),
        })
        if data.get("owner_where"):
            entries[-1]["owner_where"] = data["owner_where"]
    return {"authority": AUTHORITY, "schema_version": 1, "tables": entries}


def order_problems(catalog, entries, cyclic):
    position = {}
    for entry in entries:
        position[entry["table"]] = entry["restore_order"]
    problems = []
    for child in catalog.tables:
        for parent in parent_tables(catalog)[child]:
            if child not in position or parent not in position:
                continue
            if (child, parent) in cyclic:
                continue
            if position[child] <= position[parent]:
                problems.append(f"{child}: restore order puts child before parent {parent}")
    for entry in entries:
        via = entry.get("via")
        if via in position and entry["restore_order"] <= position[via]:
            problems.append(f"{entry['table']}: restore order puts row before its via table {via}")
    return problems


def check(catalog, classes, manifest):
    problems = []
    for table in catalog.tables:
        if table not in classes:
            problems.append(f"{table}: catalog table has no data class")
    for table in sorted(classes):
        if table not in catalog.tables:
            problems.append(f"{table}: data class for a table missing from the catalog")
    for table in catalog.tables:
        if table not in classes:
            continue
        owned = set(classes[table].get("owner") or [])
        if classes[table].get("owner_where") and not owned:
            problems.append(f"{table}: owner_where without an owner column")
        referenced = set(classes[table].get("references") or [])
        for column in player_columns(catalog, table):
            if column not in owned and column not in referenced:
                problems.append(f"{table}.{column}: player column is in neither owner nor references")
    problems.extend(reference_problems(catalog, classes))
    cyclic = strong_components(catalog)
    problems.extend(order_problems(catalog, manifest.get("tables") or [], cyclic))
    expected = build_manifest(catalog, classes)
    if manifest != expected:
        problems.append(f"manifest {MANIFEST_PATH.relative_to(ROOT)} differs from the generated manifest")
    return problems


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", required=True, help="DSN of a database migrated to the tree's head")
    parser.add_argument("--check", action="store_true", help="report problems instead of writing the manifest")
    return parser.parse_args()


def main():
    arguments = parse_arguments()
    catalog = load_catalog(arguments.database)
    classes = load_classes()
    retired = retired_tables()
    catalog.tables = [table for table in catalog.tables if table not in retired]
    for table in retired:
        classes.pop(table, None)
    if not arguments.check:
        MANIFEST_PATH.parent.mkdir(parents=True, exist_ok=True)
        MANIFEST_PATH.write_text(json.dumps(build_manifest(catalog, classes), indent=1, ensure_ascii=False) + "\n")
        print(f"wrote {MANIFEST_PATH.relative_to(ROOT)}")
        return 0
    if not MANIFEST_PATH.is_file():
        print(f"missing {MANIFEST_PATH.relative_to(ROOT)}", file=sys.stderr)
        return 1
    manifest = json.loads(MANIFEST_PATH.read_text())
    problems = check(catalog, classes, manifest)
    for problem in problems:
        print(problem, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
