#!/usr/bin/env python3
"""Generate and check the R8 player restore plan.

The plan is built from docs/data/PLAYER_DATA_MANIFEST.json (the player table
list, owner, via, kind, backup and restore order), CANONICAL_TABLE_OWNERSHIP.json
(the classes the catalog must agree with) and the live PostgreSQL catalog
(foreign keys, column types, version columns). For every table with
scope "player" and backup true it records:

  action     restore (state, report, cache, journal), keep (ledger, U7) or
             skip (shared, P2);
  select     SQL selecting the player's rows: owner columns, owner_where, the
             via parent, or the shared row's player references;
  inbound    foreign keys from rows the restore does not delete that point at
             this table's rows;
  versioned  whether the table has state_version and whether it has updated_at
             (the design bumps every state_version and sets every updated_at).

--check exits 1 with one line per problem: the plan differs from the generated
one, or a player-scoped backup table has no plan entry.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

import player_data_manifest as manifest_tool

ROOT = Path(__file__).resolve().parents[1]
PLAN_PATH = ROOT / "docs/data/PLAYER_RESTORE_PLAN.json"
AUTHORITY = ("R8 player restore plan (generated from PLAYER_DATA_MANIFEST.json, "
             "CANONICAL_TABLE_OWNERSHIP.json and the PostgreSQL catalog)")

COLUMN_TYPES_SQL = ("SELECT table_name, column_name, data_type FROM information_schema.columns "
                    "WHERE table_schema = 'public' ORDER BY table_name, ordinal_position")
FOREIGN_KEYS_SQL = """
    SELECT c.conrelid::regclass::text AS child,
           string_agg(a.attname, ',' ORDER BY s.ord) AS child_columns,
           c.confrelid::regclass::text AS parent,
           string_agg(fa.attname, ',' ORDER BY s.ord) AS parent_columns,
           c.conname
    FROM pg_constraint c
    JOIN LATERAL generate_subscripts(c.conkey, 1) s(ord) ON true
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = c.conkey[s.ord]
    JOIN pg_attribute fa ON fa.attrelid = c.confrelid AND fa.attnum = c.confkey[s.ord]
    WHERE c.contype = 'f'
    GROUP BY c.conrelid, c.conname, c.confrelid, c.conkey, c.confkey
    ORDER BY 1, 5"""

KEEP_KINDS = ("ledger",)
SKIP_KINDS = ("shared",)
RESTORE_KINDS = ("state", "report", "cache", "journal")


class Catalog:
    def __init__(self, tables, column_types, foreign_keys):
        self.tables = tables
        self.column_types = column_types
        self.foreign_keys = foreign_keys

    def has_columns(self, table, columns):
        return all((table, column) in self.column_types for column in columns)

    def column_type(self, table, column):
        try:
            return self.column_types[(table, column)]
        except KeyError:
            raise SystemExit(f"catalog has no column {table}.{column}")


def query(database, sql):
    result = subprocess.run(["psql", database, "-AtF", "\t", "-c", sql], capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit("restore plan catalog query failed: " + result.stderr.strip())
    return [line.split("\t") for line in result.stdout.splitlines() if line]


def load_catalog(database):
    base = manifest_tool.load_catalog(database)
    column_types = {(table, column): kind for table, column, kind in query(database, COLUMN_TYPES_SQL)}
    foreign_keys = []
    for child, child_columns, parent, parent_columns, name in query(database, FOREIGN_KEYS_SQL):
        foreign_keys.append({
            "constraint": name,
            "table": child,
            "columns": child_columns.split(","),
            "target": parent,
            "target_columns": parent_columns.split(","),
        })
    return Catalog(base.tables, column_types, foreign_keys)


def load_classes():
    return manifest_tool.load_classes()


def load_manifest():
    return json.loads(manifest_tool.MANIFEST_PATH.read_text())


def quote(identifier):
    return '"' + identifier.replace('"', '""') + '"'


def action_for(kind):
    if kind in KEEP_KINDS:
        return "keep"
    if kind in SKIP_KINDS:
        return "skip"
    if kind in RESTORE_KINDS:
        return "restore"
    raise SystemExit(f"unknown table kind {kind!r} has no restore action")


def player_condition(table, column, catalog, alias=""):
    prefix = alias + "." if alias else ""
    return f"{prefix}{quote(column)} = $1::{catalog.column_type(table, column)}"


def owner_select(entry, catalog):
    conditions = [player_condition(entry["table"], column, catalog) for column in entry["owner"]]
    if entry.get("owner_where"):
        conditions.append(f"({entry['owner_where']})")
    return f"SELECT * FROM {quote(entry['table'])} WHERE " + " AND ".join(conditions)


def via_select(entry, catalog, entries_by_table):
    table, via = entry["table"], entry["via"]
    parent = entries_by_table.get(via)
    if parent is None:
        raise SystemExit(f"{table}: via table {via} is not a player table")
    paths = sorted((key for key in catalog.foreign_keys if key["table"] == table and key["target"] == via),
                   key=lambda key: (key["columns"], key["constraint"]))
    if not paths:
        raise SystemExit(f"{table}: no foreign key reaches via table {via}")
    exists = []
    for path in paths:
        conditions = [player_condition(via, column, catalog, alias="p") for column in parent["owner"]]
        if parent.get("owner_where"):
            conditions.append(f"({parent['owner_where']})")
        conditions.extend(f'c.{quote(column)} = p.{quote(target_column)}'
                          for column, target_column in zip(path["columns"], path["target_columns"]))
        exists.append(f"EXISTS (SELECT 1 FROM {quote(via)} p WHERE " + " AND ".join(conditions) + ")")
    return f"SELECT * FROM {quote(table)} c WHERE " + " OR ".join(exists)


def reference_select(entry, catalog):
    table = entry["table"]
    targets = {key["columns"][0] for key in catalog.foreign_keys
               if key["table"] == table and key["target"] == "players" and len(key["columns"]) == 1}
    columns = [column for column in entry["references"] if column in targets]
    if not columns:
        raise SystemExit(f"{table}: no owner, via or player reference selects its rows")
    return (f"SELECT * FROM {quote(table)} WHERE "
            + " OR ".join(player_condition(table, column, catalog) for column in columns))


def select_sql(entry, catalog, entries_by_table):
    if entry["owner"]:
        return owner_select(entry, catalog)
    if entry.get("via"):
        return via_select(entry, catalog, entries_by_table)
    return reference_select(entry, catalog)


def row_is_deleted(foreign_key, classes):
    """Rows the restore deletes cannot leave an inbound reference behind."""
    child = classes.get(foreign_key["table"]) or {}
    if child.get("scope") != "player" or not child.get("backup"):
        return False
    if action_for(child.get("kind")) != "restore":
        return False
    owner = set(child.get("owner") or [])
    if not owner:
        return foreign_key["target"] == child.get("via")
    return any(column in owner for column in foreign_key["columns"])


def inbound_for(table, catalog, classes):
    entries = []
    for foreign_key in catalog.foreign_keys:
        if foreign_key["target"] != table or row_is_deleted(foreign_key, classes):
            continue
        entries.append({
            "constraint": foreign_key["constraint"],
            "table": foreign_key["table"],
            "columns": foreign_key["columns"],
            "references": foreign_key["target_columns"],
        })
    return sorted(entries, key=lambda entry: entry["constraint"])


def plan_entries(manifest):
    entries = [entry for entry in manifest["tables"] if entry.get("scope") == "player" and entry.get("backup")]
    return sorted(entries, key=lambda entry: (entry["restore_order"], entry["table"]))


def build_plan(manifest, classes, catalog):
    entries_by_table = {entry["table"]: entry for entry in manifest["tables"]}
    tables = []
    for entry in plan_entries(manifest):
        table = entry["table"]
        tables.append({
            "table": table,
            "action": action_for(entry["kind"]),
            "select": select_sql(entry, catalog, entries_by_table),
            "versioned": {column: catalog.has_columns(table, (column,))
                          for column in ("state_version", "updated_at")},
            "inbound": inbound_for(table, catalog, classes),
        })
    return {"authority": AUTHORITY, "schema_version": 1, "tables": tables}


def missing_plan_entries(plan, classes, catalog):
    planned = {entry["table"] for entry in plan["tables"]}
    problems = []
    for table in catalog.tables:
        data = classes.get(table) or {}
        if data.get("scope") == "player" and data.get("backup") and table not in planned:
            problems.append(f"{table}: player-scoped table has no plan entry")
    return problems


def check(manifest, classes, catalog, plan):
    expected = build_plan(manifest, classes, catalog)
    problems = []
    if plan != expected:
        problems.append(f"plan {PLAN_PATH.relative_to(ROOT)} differs from the generated plan")
    problems.extend(missing_plan_entries(plan, classes, catalog))
    return problems


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", required=True, help="DSN of a database migrated to the tree's head")
    parser.add_argument("--check", action="store_true", help="report problems instead of writing the plan")
    return parser.parse_args()


def main():
    arguments = parse_arguments()
    catalog = load_catalog(arguments.database)
    classes = load_classes()
    manifest = load_manifest()
    if not arguments.check:
        PLAN_PATH.parent.mkdir(parents=True, exist_ok=True)
        PLAN_PATH.write_text(json.dumps(build_plan(manifest, classes, catalog), indent=1, ensure_ascii=False) + "\n")
        print(f"wrote {PLAN_PATH.relative_to(ROOT)}")
        return 0
    if not PLAN_PATH.is_file():
        print(f"missing {PLAN_PATH.relative_to(ROOT)}", file=sys.stderr)
        return 1
    plan = json.loads(PLAN_PATH.read_text())
    problems = check(manifest, classes, catalog, plan)
    for problem in problems:
        print(problem, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
