#!/usr/bin/env python3
"""Small operator helpers for the v2 real-client playtest.

Temporary test tool, not product code. The mail and give commands write the
production owner rows directly because this backend exposes no admin transport
(cmd/gxb-admin is a stub); the shape and invariants follow I5 createMailTx and
the importer's economy transaction.
"""

import argparse
import json
import sys
import uuid
from pathlib import Path

HARNESS_DIRECTORY = Path(__file__).resolve().parent
sys.path.insert(0, str(HARNESS_DIRECTORY))

import import_legacy

REGION = import_legacy.REGION
MAIL_POLICY_VERSION = "gxb.i5.admin-mail.v1"
MAIL_SOURCE_KIND = "ADMIN"


def fail(message):
    raise SystemExit(f"helpers: {message}")


def accounts():
    return import_legacy.load_accounts()


def resolve_player(login):
    account_map = accounts()
    uid = account_map["logins"].get(login.casefold())
    if uid is None:
        fail(f"{login}: no harness account")
    row = import_legacy.query_text(
        "SELECT player_id FROM players WHERE account_id="
        f"{import_legacy.quote(uid)}::uuid AND logical_server_id={REGION}"
    )
    if not row:
        fail(f"{login}: no player on logical server {REGION}")
    return int(row.splitlines()[0])


def parse_pairs(values, name):
    pairs = []
    for value in values or []:
        key, separator, amount = value.partition(":")
        if not separator or not key:
            fail(f"--{name} expects key:amount, got {value!r}")
        try:
            number = int(amount)
        except ValueError:
            fail(f"--{name} amount is not an integer: {value!r}")
        if number <= 0:
            fail(f"--{name} amount must be positive: {value!r}")
        pairs.append((key, number))
    return pairs


def parse_items(values):
    items = []
    for item_id, count in parse_pairs(values, "item"):
        try:
            identifier = int(item_id)
        except ValueError:
            fail(f"--item id is not an integer: {item_id!r}")
        if identifier <= 0:
            fail(f"--item id must be positive: {item_id!r}")
        items.append((identifier, count))
    return items


def command_mail(arguments):
    player_id = resolve_player(arguments.login)
    mail_uuid = str(uuid.uuid4())
    source_key = "admin:helpers:" + str(uuid.uuid4())
    attachments = parse_items(arguments.item)
    values = ",".join(
        f"({ordinal},{item_id},{count})"
        for ordinal, (item_id, count) in enumerate(attachments)
    )
    attachment_select = (
        "SELECT record.mail_uuid, v.ordinal, 'STACK_ITEM', NULL, v.item_id, v.count, '{}'::jsonb"
        f" FROM record, (VALUES {values}) AS v(ordinal,item_id,count)"
        if attachments
        else "SELECT record.mail_uuid, 0, 'STACK_ITEM', NULL, 0, 0, '{}'::jsonb WHERE FALSE"
    )
    sql = (
        "WITH counter AS ("
        " INSERT INTO mail_namespace_counters(recipient_player_id,namespace,next_wire_id,state_version)"
        " VALUES(" + str(player_id) + ",'NORMAL',2,1)"
        " ON CONFLICT(recipient_player_id,namespace) DO UPDATE"
        " SET next_wire_id=mail_namespace_counters.next_wire_id+1,"
        " state_version=mail_namespace_counters.state_version+1"
        " RETURNING next_wire_id-1 AS wire_id),"
        " record AS ("
        " INSERT INTO mail_records(mail_uuid,recipient_player_id,namespace,wire_id,source_kind,source_key,"
        " category,title,sender,body,created_at,expires_at,read_at,shown,claimed_at,platform_eligibility,"
        " compatibility_policy_version,state_version)"
        " SELECT " + import_legacy.quote(mail_uuid) + "::uuid," + str(player_id) + ",'NORMAL',wire_id,"
        + import_legacy.quote(MAIL_SOURCE_KIND) + "," + import_legacy.quote(source_key) + ",0,"
        + import_legacy.quote(arguments.title) + "," + import_legacy.quote(arguments.sender) + ","
        + import_legacy.quote(arguments.body)
        + ",now(),NULL,NULL,TRUE,NULL,'ANY'," + import_legacy.quote(MAIL_POLICY_VERSION) + ",1"
        " FROM counter RETURNING mail_uuid),"
        " attachments AS ("
        " INSERT INTO mail_attachments(mail_uuid,ordinal,grant_line_kind,resource_key,item_id,amount,metadata)"
        f" {attachment_select} RETURNING 1)"
        " SELECT wire_id FROM counter"
    )
    wire_id = import_legacy.query_text(sql)
    print(f"mail {arguments.login} pid={player_id} id={wire_id} attachments={len(attachments)}")
    return 0


def command_players(arguments):
    account_map = accounts()
    uids = []
    for login in account_map["logins"]:
        uids.append(account_map["logins"][login])
    if not uids:
        print("no accounts")
        return 0
    quoted = ",".join(import_legacy.quote(uid) + "::uuid" for uid in uids)
    sql = (
        "SELECT COALESCE(json_agg(json_build_object("
        "'account_id',p.account_id::text,'player_id',p.player_id,"
        "'name',profile.display_name,'level',directory.lev,'vip',directory.vip)),'[]'::json)::text"
        " FROM players p"
        " JOIN player_profiles profile ON profile.player_id=p.player_id"
        " JOIN player_directory_profiles directory ON directory.player_id=p.player_id"
        f" WHERE p.logical_server_id={REGION} AND p.account_id IN ({quoted})"
    )
    rows = json.loads(import_legacy.query_text(sql) or "[]")
    by_account = {row["account_id"]: row for row in rows}
    for login in sorted(account_map["logins"]):
        row = by_account.get(account_map["logins"][login])
        if row is None:
            print(f"{login}\tno player")
            continue
        print(f"{login}\t{row['player_id']}\t{row['name']}\t{row['level']}\t{row['vip']}")
    return 0


def command_give(arguments):
    player_id = resolve_player(arguments.login)
    currencies = parse_pairs(arguments.currency, "currency")
    items = parse_items(arguments.item)
    if not currencies and not items:
        fail("give needs at least one --currency or --item")
    statements = ["BEGIN;", "SET LOCAL lock_timeout='5s';"]
    for key, amount in currencies:
        statements.append(
            "INSERT INTO player_currency_balances(player_id,resource_key,amount,state_version,updated_at)"
            f" VALUES({player_id},{import_legacy.quote(key)},{amount},1,now())"
            " ON CONFLICT(player_id,resource_key) DO UPDATE SET"
            " amount=player_currency_balances.amount+EXCLUDED.amount,"
            " state_version=player_currency_balances.state_version+1,updated_at=now();"
        )
    for item_id, count in items:
        statements.append(
            "INSERT INTO player_item_stacks(player_id,item_id,quantity,state_version,acquired_at,updated_at)"
            f" VALUES({player_id},{item_id},{count},1,now(),now())"
            " ON CONFLICT(player_id,item_id) DO UPDATE SET"
            " quantity=LEAST(player_item_stacks.quantity+EXCLUDED.quantity,"
            " COALESCE((SELECT stack_cap FROM gxb_content_resource_definitions"
            " WHERE revision_id=(SELECT revision_id FROM gxb_content_activation WHERE slot='content')"
            " AND item_id=EXCLUDED.item_id),9223372036854775807)),"
            " state_version=player_item_stacks.state_version+1,updated_at=now();"
        )
    statements.append("COMMIT;")
    import_legacy.run_psql("\n".join(statements) + "\n")
    print(
        f"give {arguments.login} pid={player_id} "
        f"currencies={len(currencies)} items={len(items)}"
    )
    return 0


def command_fight_report(arguments):
    player_id = resolve_player(arguments.login)
    sql = (
        "SELECT COALESCE(json_agg(row_to_json(t)),'[]'::json)::text FROM ("
        " SELECT journal_id,to_char(received_at AT TIME ZONE 'UTC','YYYY-MM-DD HH24:MI:SS') AS at,"
        " mid,outcome,error_code,http_status,error_class,cause"
        " FROM request_journal WHERE player_id=" + str(player_id)
        + " ORDER BY journal_id DESC LIMIT 20) t"
    )
    rows = json.loads(import_legacy.query_text(sql) or "[]")
    if not rows:
        print(f"{arguments.login}: no journal rows")
        return 0
    for row in rows:
        cause = str(row.get("cause") or "")
        if len(cause) > 120:
            cause = cause[:120] + "..."
        print(
            f"#{row['journal_id']} {row['at']} mid={row['mid']} outcome={row['outcome']} "
            f"http={row['http_status']} error_class={row.get('error_class') or '-'} cause={cause or '-'}"
        )
    return 0


def main(arguments):
    parser = argparse.ArgumentParser(description=__doc__)
    subcommands = parser.add_subparsers(dest="command", required=True)

    mail = subcommands.add_parser("mail", help="send one system mail with attachments")
    mail.add_argument("login")
    mail.add_argument("--title", required=True)
    mail.add_argument("--body", required=True)
    mail.add_argument("--sender", default="System")
    mail.add_argument("--item", action="append", default=[], metavar="ID:COUNT")
    mail.set_defaults(handler=command_mail)

    players = subcommands.add_parser("players", help="list accounts and players")
    players.set_defaults(handler=command_players)

    give = subcommands.add_parser("give", help="add currency or items")
    give.add_argument("login")
    give.add_argument("--currency", action="append", default=[], metavar="KEY:AMOUNT")
    give.add_argument("--item", action="append", default=[], metavar="ID:COUNT")
    give.set_defaults(handler=command_give)

    report = subcommands.add_parser("fight-report", help="last 20 journal rows")
    report.add_argument("login")
    report.set_defaults(handler=command_fight_report)

    parsed = parser.parse_args(arguments)
    return parsed.handler(parsed)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
