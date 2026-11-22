"""Does the cluster's SSI lock budget keep unrelated players apart? (C1 Tier 0, C1_CAPACITY_DESIGN.md F3)

Two SERIALIZABLE transactions for two different players each read their own N scattered rows of a multi-page
table, then each update one of their own rows. Nothing is shared, so any 40001 is predicate-lock escalation
(tuple -> page -> relation). With the PostgreSQL defaults N=200 fails every trial; with the Tier 0 budget it
must not. Exits 1 when the largest N still fails.

usage: ssi_escalation_probe.py [--database c1_ssi_probe] [--rows 5,30,200] [--trials 10]
"""
import argparse
import sys

import psycopg
from psycopg import errors

SOCKET = "/home/akm/Chatgpt/EOL_Game/tmp/test-databases/i853_dev"
PORT = 55853
PLAYERS = 50
ROWS_PER_PLAYER = 200


def connect(database, autocommit=False):
    return psycopg.connect(host=SOCKET, port=PORT, user="postgres", dbname=database, autocommit=autocommit)


def build(database):
    with connect("postgres", autocommit=True) as admin:
        admin.execute(f'DROP DATABASE IF EXISTS "{database}" WITH (FORCE)')
        admin.execute(f'CREATE DATABASE "{database}"')
    with connect(database) as conn:
        conn.execute("CREATE TABLE probe (id bigserial PRIMARY KEY, player int NOT NULL, slot int NOT NULL, value int NOT NULL, "
                     "padding text NOT NULL) WITH (fillfactor = 50)")
        # Interleaved by slot, so each player's rows are spread over every page, as a hero roster is in a shared table.
        # fillfactor leaves room for HOT updates: a non-HOT update inserts into an index leaf the other player read, a
        # conflict the lock budget cannot remove (the probe measures escalation only).
        conn.execute("INSERT INTO probe (player, slot, value, padding) SELECT p, h, 0, repeat('x', 300) "
                     "FROM generate_series(1, %s) h, generate_series(1, %s) p ORDER BY h, p", (ROWS_PER_PLAYER, PLAYERS))
        conn.execute("ANALYZE probe")
        budget = {name: conn.execute(f"SHOW {name}").fetchone()[0] for name in
                  ("max_pred_locks_per_transaction", "max_pred_locks_per_relation", "max_pred_locks_per_page")}
        pages = conn.execute("SELECT relpages FROM pg_class WHERE relname = 'probe'").fetchone()[0]
    return budget, pages


def row_ids(player, rows):
    """Primary keys of the player's first rows: the insert order is (slot, player). Reading by key keeps the locks on
    tuples; a filter on player would scan the table and lock the whole relation at any N."""
    return [(slot - 1) * PLAYERS + player for slot in range(1, rows + 1)]


def trial(database, rows):
    first, second = connect(database), connect(database)
    try:
        for conn in (first, second):
            conn.execute("BEGIN ISOLATION LEVEL SERIALIZABLE")
        for conn, player in ((first, 3), (second, 47)):
            conn.execute("SELECT sum(value) FROM probe WHERE id = ANY(%s)", (row_ids(player, rows),)).fetchone()
        for conn, player in ((first, 3), (second, 47)):
            conn.execute("UPDATE probe SET value = value + 1 WHERE id = %s", (row_ids(player, 1)[0],))
        first.commit()
        second.commit()
        return False
    except errors.SerializationFailure:
        return True
    finally:
        first.close()
        second.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--database", default="c1_ssi_probe")
    parser.add_argument("--rows", default="5,30,200")
    parser.add_argument("--trials", type=int, default=10)
    arguments = parser.parse_args()
    sizes = [int(size) for size in arguments.rows.split(",")]
    budget, pages = build(arguments.database)
    print(f"budget {budget}; table pages {pages}")
    failed_at_largest = 0
    try:
        for rows in sizes:
            failures = sum(trial(arguments.database, rows) for _ in range(arguments.trials))
            print(f"N={rows}: {failures}/{arguments.trials} serialization failures")
            failed_at_largest = failures
    finally:
        with connect("postgres", autocommit=True) as admin:
            admin.execute(f'DROP DATABASE IF EXISTS "{arguments.database}" WITH (FORCE)')
    print("ESCALATION" if failed_at_largest else "OK")
    return 1 if failed_at_largest else 0


if __name__ == "__main__":
    sys.exit(main())
