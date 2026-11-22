#!/usr/bin/env python3
"""Inventory every jsonb column in the PostgreSQL catalog for the R8 payload-version work.

The tool reads the live catalog (River and goose tables excluded) and joins
docs/architecture/CANONICAL_TABLE_OWNERSHIP.json for each table's "data" scope.
The hand-filled fields (decode, writers, sql_paths, digest, batch) are kept from
docs/data/PAYLOAD_COLUMNS.json; a column new to the catalog is added as "UNKNOWN"
and a column gone from the catalog is dropped.

--check exits 1 with one line per problem: a catalog column missing from the
file, a file column missing from the catalog, or an entry still "UNKNOWN".
"""
import argparse
import json
import subprocess
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT_PATH = ROOT / "docs/architecture/CANONICAL_TABLE_OWNERSHIP.json"
INVENTORY_PATH = ROOT / "docs/data/PAYLOAD_COLUMNS.json"
AUTHORITY = "R8 payload column inventory (generated from the PostgreSQL catalog and CANONICAL_TABLE_OWNERSHIP.json)"
UNSET = "UNKNOWN"
DECODE_KINDS = ("struct", "map", "raw", "none")

COLUMNS_SQL = ("SELECT table_name, column_name FROM information_schema.columns "
               "WHERE table_schema = 'public' AND data_type = 'jsonb' "
               "AND table_name NOT LIKE 'river\\_%' AND table_name <> 'goose_db_version' "
               "ORDER BY table_name, column_name")


def query(database, sql):
    result = subprocess.run(["psql", database, "-AtF", "\t", "-c", sql], capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit("payload inventory catalog query failed: " + result.stderr.strip())
    return [line.split("\t") for line in result.stdout.splitlines() if line]


def load_scopes():
    document = json.loads(CONTRACT_PATH.read_text())
    scopes = {}
    for table, entry in document["tables"].items():
        data = entry.get("data")
        if isinstance(data, dict):
            scopes[table] = data.get("scope", UNSET)
    return scopes


def catalog_columns(database):
    return [(table, column) for table, column in query(database, COLUMNS_SQL)]


def empty_entry(table, column, scope):
    return {
        "table": table,
        "column": column,
        "scope": scope,
        "decode": UNSET,
        "decode_type": "",
        "decode_sites": [],
        "writers": [],
        "sql_paths": [],
        "digest": UNSET,
        "digest_sites": [],
        "batch": UNSET,
    }


def merge(columns, scopes, inventory):
    """Keep every hand-filled field; add new columns as UNSET and drop vanished ones."""
    existing = {(entry["table"], entry["column"]): entry for entry in inventory.get("columns", [])}
    merged = []
    for table, column in columns:
        entry = existing.get((table, column))
        if entry is None:
            entry = empty_entry(table, column, scopes.get(table, UNSET))
        else:
            entry = dict(entry)
            entry["scope"] = scopes.get(table, UNSET)
            for field in ("decode_type", "decode_sites", "writers", "sql_paths", "digest_sites"):
                entry.setdefault(field, [] if field != "decode_type" else "")
            for field in ("decode", "digest", "batch"):
                entry.setdefault(field, UNSET)
        merged.append(entry)
    return {"authority": AUTHORITY, "schema_version": 1, "columns": merged}


def check(columns, inventory):
    problems = []
    catalog = set(columns)
    listed = {(entry.get("table"), entry.get("column")) for entry in inventory.get("columns", [])}
    for table, column in columns:
        if (table, column) not in listed:
            problems.append(f"{table}.{column}: catalog column missing from the inventory")
    for table, column in sorted(listed):
        if (table, column) not in catalog:
            problems.append(f"{table}.{column}: inventory column missing from the catalog")
    for entry in inventory.get("columns", []):
        name = f"{entry.get('table')}.{entry.get('column')}"
        for field in ("decode", "digest", "batch"):
            if entry.get(field) == UNSET:
                problems.append(f"{name}: {field} is still {UNSET}")
        if entry.get("decode") not in DECODE_KINDS and entry.get("decode") != UNSET:
            problems.append(f"{name}: decode {entry.get('decode')!r} is not one of {', '.join(DECODE_KINDS)}")
        if entry.get("scope") in (UNSET, None, ""):
            problems.append(f"{name}: scope is unknown")
    return problems


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", required=True, help="DSN of a database migrated to the tree's head")
    parser.add_argument("--check", action="store_true", help="report problems instead of writing the inventory")
    return parser.parse_args()


def main():
    arguments = parse_arguments()
    columns = catalog_columns(arguments.database)
    scopes = load_scopes()
    if arguments.check:
        if not INVENTORY_PATH.exists():
            raise SystemExit(f"{INVENTORY_PATH.relative_to(ROOT)} is missing")
        problems = check(columns, json.loads(INVENTORY_PATH.read_text()))
        if problems:
            print("\n".join(problems))
            raise SystemExit(1)
        print(f"PAYLOAD_COLUMNS OK: {len(columns)} jsonb columns")
        return
    inventory = merge(columns, scopes, json.loads(INVENTORY_PATH.read_text()) if INVENTORY_PATH.exists() else {})
    INVENTORY_PATH.write_text(json.dumps(inventory, indent=1, sort_keys=False) + "\n")
    print(f"wrote {INVENTORY_PATH.relative_to(ROOT)}: {len(columns)} jsonb columns")


if __name__ == "__main__":
    main()
