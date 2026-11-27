#!/usr/bin/env python3
"""Re-import the preserved v1 saves onto the harness's product SDK accounts.

After a harness reset the product identity tables are rebuilt from the stand-in
accounts file, but the legacy player rows are not: the import tool has to be run
again. This wrapper resolves each seed login to its product account id (the
product SDK login row), forces a fresh session for that account, then runs the
existing seed import. It never creates an identity.

Run with the harness up; read the report in work/i11/HARNESS_ACCOUNT_FINDINGS.md.
"""

import argparse
import json
import sys
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[1]
HARNESS_DIRECTORY = WORKSPACE / "test_harness"
sys.path.insert(0, str(HARNESS_DIRECTORY))

import import_legacy  # noqa: E402  (path set above)

PIN_COMMANDS = (
    "export PW=$(head -1 test_harness/runtime/state/operator_password)",
    "test_harness/runtime/bin/gxb-operator --root test_harness/runtime/agent login <<<\"$PW\"",
    'test_harness/runtime/bin/gxb-operator --root test_harness/runtime/agent backup snapshot '
    '--name "legacy v1 import" --pin --reason "level-100 legacy accounts restored"',
    "test_harness/runtime/bin/gxb-operator --root test_harness/runtime/agent logout",
)


def product_account(login):
    normalized = import_legacy.normalize_login(login)
    row = import_legacy.query_text(
        "SELECT l.account_id FROM sdk_logins l JOIN accounts a ON a.account_id=l.account_id"
        f" WHERE l.login_normalized={import_legacy.quote(normalized)} AND a.status='ACTIVE'"
        " AND a.account_kind='normal'"
    )
    rows = [line for line in row.splitlines() if line]
    if len(rows) != 1:
        fail(f"{login}: expected one active product SDK login, found {len(rows)}")
    return rows[0]


def existing_player(account_uid):
    row = import_legacy.query_text(
        "SELECT player_id FROM players WHERE account_id="
        f"{import_legacy.quote(account_uid)}::uuid AND logical_server_id={import_legacy.REGION}"
    )
    rows = [line for line in row.splitlines() if line]
    if len(rows) > 1:
        fail(f"account {account_uid} has {len(rows)} players on server {import_legacy.REGION}")
    return int(rows[0]) if rows else None


def verify(seed_login, account_uid, save):
    player = import_legacy.player_state(save)
    expected_level = max(1, int((player.get("progression") or {}).get("lev", 1)))
    expected_heroes = len((player.get("heroes") or {}).get("heroes") or {})
    player_id = existing_player(account_uid)
    if player_id is None:
        fail(f"{seed_login}: import wrote no player")
    row = import_legacy.query_text(
        "SELECT level FROM player_progression WHERE player_id=" + str(player_id)
    )
    heroes = import_legacy.query_text(
        "SELECT count(*) FROM player_heroes WHERE player_id=" + str(player_id)
    )
    level = int(row.strip() or 0)
    hero_count = int(heroes.strip() or 0)
    if level != expected_level or hero_count != expected_heroes:
        fail(
            f"{seed_login}: player {player_id} is level {level} with {hero_count} heroes,"
            f" expected level {expected_level} with {expected_heroes}"
        )
    print(f"verified {seed_login}: player {player_id} level {level}, {hero_count} heroes")


def fail(message):
    raise SystemExit(f"reimport_legacy_players: {message}")


def main(arguments):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--dry-run", action="store_true", help="resolve accounts without importing")
    options = parser.parse_args(arguments)

    seeds = import_legacy.SEEDS
    accounts = import_legacy.load_accounts()
    resolved = {}
    for seed in seeds:
        login = seed["login"]
        account_uid = product_account(login)
        save_path = import_legacy.PRESERVE_PLAYERS / seed["directory"] / "player.json"
        save = json.loads(save_path.read_text(encoding="utf-8"))
        resolved[login] = (account_uid, save_path, save)
        player_id = existing_player(account_uid)
        print(f"{login}: product account {account_uid}, current player {player_id or 'none'}")

    if options.dry_run:
        return 0

    for login, (account_uid, _save_path, _save) in resolved.items():
        normalized = import_legacy.normalize_login(login)
        previous = accounts["logins"].get(normalized)
        if previous and previous != account_uid:
            accounts["accounts"].pop(previous, None)
        accounts["logins"][normalized] = account_uid
        accounts["accounts"][account_uid] = {
            "uid": account_uid,
            "login": login,
            "username": login,
            "account_type": "normal",
            "created_at": 0,
            "password": None,
            "session": None,
        }
    import_legacy.save_accounts(accounts)

    import_legacy.seed()

    for login, (account_uid, _save_path, save) in resolved.items():
        verify(login, account_uid, save)

    print("next: relogin on the phone, then pin the state with:")
    for command in PIN_COMMANDS:
        print(f"  {command}")
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
