#!/usr/bin/env python3
"""Generate and check the R8 retention reference lists.

The lists come from the live PostgreSQL catalog (a database migrated to the
tree's head): every attempt-id, receipt-id and operation-id column a retention
rule can be asked to keep alive. docs/data/RETENTION_REFERENCES.json records
them; --check fails when it differs from the catalog, or when a listed column
is not cited as table.column by the committed rule table
internal/adapters/postgres/retentionstore/references.go.

Tables a migration renamed to *_retired_* (R5D's old mode-local attempts) are
kept only for a rollback and are not listed.

A non-uuid attempt-id column outside the lead's text list stops the tool: the
sweep rule would have to compare text and no foreign key can be added.
"""
import argparse
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
REFERENCES_PATH = ROOT / "docs/data/RETENTION_REFERENCES.json"
RULE_TABLE_PATH = ROOT / "internal/adapters/postgres/retentionstore/references.go"
AUTHORITY = "R8 retention reference lists (generated from the PostgreSQL catalog)"

# The combat chain's own key columns carry the attempt id of the row they belong
# to; they are not references that keep an attempt alive.
COMBAT_CHAIN_TABLES = (
    "combat_attempts",
    "combat_attestations",
    "combat_attempt_members",
    "combat_member_settlements",
    "combat_resolutions",
    "combat_start_packages",
)

# Text attempt ids the lead approved (R8_4_RETENTION_TASKS.md, text-typed attempt ids).
TEXT_ATTEMPT_ID_TABLES = frozenset((
    "adventure_single_attempts",
    "conquer_school_reports",
    "illusion_attempts",
    "worldboss_attempts",
))

# The receipts table's own operation id is the command id it was written with,
# not a row key another owner holds.
EXCLUDED_OPERATION_ID_COLUMNS = {("gxb_operation_receipts", "operation_id")}

COLUMNS_SQL = (
    "SELECT table_name, column_name, data_type FROM information_schema.columns "
    "WHERE table_schema = 'public' AND table_name NOT LIKE 'river\\_%' AND table_name NOT LIKE '%\\_retired\\_%' "
    "AND table_name <> 'goose_db_version' ORDER BY table_name, ordinal_position"
)
FOREIGN_KEYS_SQL = """
    SELECT c.conrelid::regclass::text, a.attname
    FROM pg_constraint c JOIN LATERAL unnest(c.conkey) WITH ORDINALITY k(attnum, n) ON true
    JOIN pg_attribute a ON a.attrelid = c.conrelid AND a.attnum = k.attnum
    WHERE c.contype = 'f' ORDER BY 1, 2"""


class CatalogProblem(Exception):
    """The catalog holds a reference the lead's rules do not settle."""


class Catalog:
    def __init__(self, columns, foreign_keys):
        self.columns = columns
        self.foreign_keys = foreign_keys


def query(database, sql):
    result = subprocess.run(["psql", database, "-AtF", "\t", "-c", sql], capture_output=True, text=True)
    if result.returncode != 0:
        raise SystemExit("retention reference catalog query failed: " + result.stderr.strip())
    return [line.split("\t") for line in result.stdout.splitlines() if line]


def load_catalog(database):
    columns = {(table, column): kind for table, column, kind in query(database, COLUMNS_SQL)}
    foreign_keys = {tuple(row) for row in query(database, FOREIGN_KEYS_SQL)}
    return Catalog(columns, foreign_keys)


def is_attempt_id(column):
    return column == "attempt_id" or column.endswith("_attempt_id")


def is_receipt_id(column):
    return column == "receipt_id" or column.endswith("_receipt_id")


def is_operation_id(column):
    return column == "operation_id" or column.endswith("_operation_id")


def entry(catalog, table, column):
    return {
        "table": table,
        "column": column,
        "type": catalog.columns[(table, column)],
        "foreign_key": (table, column) in catalog.foreign_keys,
    }


def attempt_entries(catalog):
    entries = []
    for table, column in sorted(catalog.columns):
        if not is_attempt_id(column) or (table in COMBAT_CHAIN_TABLES and column == "attempt_id"):
            continue
        kind = catalog.columns[(table, column)]
        if kind != "uuid" and table not in TEXT_ATTEMPT_ID_TABLES:
            raise CatalogProblem(
                f"{table}.{column}: {kind} attempt-id column is not in the lead's text list "
                f"({', '.join(sorted(TEXT_ATTEMPT_ID_TABLES))}); stop and report")
        entries.append(entry(catalog, table, column))
    return entries


def receipt_entries(catalog):
    return [entry(catalog, table, column)
            for table, column in sorted(catalog.columns) if is_receipt_id(column)]


def operation_entries(catalog):
    return [entry(catalog, table, column)
            for table, column in sorted(catalog.columns)
            if is_operation_id(column) and (table, column) not in EXCLUDED_OPERATION_ID_COLUMNS]


def build_document(catalog):
    return {
        "authority": AUTHORITY,
        "schema_version": 1,
        "attempt_ids": attempt_entries(catalog),
        "receipt_ids": receipt_entries(catalog),
        "operation_ids": operation_entries(catalog),
    }


def listed_columns(document):
    for key in ("attempt_ids", "receipt_ids", "operation_ids"):
        for item in document.get(key) or []:
            yield f"{item['table']}.{item['column']}"


def citation_problems(document, rule_table):
    return [f"{name}: listed reference column is not cited by a retention rule"
            for name in listed_columns(document) if name not in rule_table]


def check(catalog, document, rule_table):
    problems = []
    if document != build_document(catalog):
        problems.append(f"{REFERENCES_PATH.relative_to(ROOT)} differs from the generated reference lists")
    if rule_table is not None:
        problems.extend(citation_problems(document, rule_table))
    return problems


def parse_arguments():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--database", required=True, help="DSN of a database migrated to the tree's head")
    parser.add_argument("--check", action="store_true", help="report problems instead of writing the reference lists")
    return parser.parse_args()


def main():
    arguments = parse_arguments()
    try:
        catalog = load_catalog(arguments.database)
        document = build_document(catalog)
    except CatalogProblem as problem:
        print(f"STOP: {problem}", file=sys.stderr)
        return 2
    if not arguments.check:
        REFERENCES_PATH.parent.mkdir(parents=True, exist_ok=True)
        REFERENCES_PATH.write_text(json.dumps(document, indent=1, ensure_ascii=False) + "\n")
        print(f"wrote {REFERENCES_PATH.relative_to(ROOT)}")
        return 0
    if not REFERENCES_PATH.is_file():
        print(f"missing {REFERENCES_PATH.relative_to(ROOT)}", file=sys.stderr)
        return 1
    rule_table = RULE_TABLE_PATH.read_text() if RULE_TABLE_PATH.is_file() else None
    if rule_table is None:
        print(f"notice: {RULE_TABLE_PATH.relative_to(ROOT)} is absent; not-cited check skipped (R8-4c adds it)")
    problems = check(catalog, json.loads(REFERENCES_PATH.read_text()), rule_table)
    for problem in problems:
        print(problem, file=sys.stderr)
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
