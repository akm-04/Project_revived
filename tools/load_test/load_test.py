#!/usr/bin/env python3
"""Repeatable load test for the v2 backend: many virtual players log in and start battles.

Players are created once (accounts in SQL, stock MID18/MID1 birth, production
level grant, stock MID59 summons). Every measured call goes through the real
HTTP edge on the private load stack. See README.md for the workflow.
"""

import argparse
import concurrent.futures
import fcntl
import hashlib
import hmac
import http.client
import json
import os
import re
import statistics
import subprocess
import sys
import threading
import time
import urllib.parse
import uuid
from pathlib import Path

WORKSPACE = Path("/home/akm/Chatgpt/EOL_Game")
WORKTREE = Path(__file__).resolve().parents[2]
TOOLS = WORKSPACE / "tmp" / "tools_r4_accept" / "gxb-e2e-self-contained" / "bin"
PSQL = TOOLS / "psql"
DB_HOST = WORKSPACE / "tmp" / "test-databases" / "i853_dev"
DB_PORT = 55853
SCRATCH = Path(os.environ.get("LOAD_SCRATCH", WORKSPACE / "tmp" / "load"))
BIN = Path(os.environ.get("LOAD_BIN", SCRATCH / "bin"))
LOCK_PATH = WORKSPACE / "tmp" / "vc.lock"
DIGEST_SECRET = "gxb-load-digest-key-000000000001"
API = "http://127.0.0.1:18970"
REGION = 1
PET_CAMPAIGN_FIRST_FLOOR = 30001
DEFAULT_HERO_TABLES = (10001001, 10001002, 10001003, 10001004, 10001005)
DEFAULT_LEVEL = 40
LOGIN_TIMEOUT_SECONDS = 20  # src_64/app/common/network/Backend.lua:645-647 (var_23_10 and 30 or 20)
SOCKET_TIMEOUT_SECONDS = 35  # gxb-api WriteTimeout: limits.StockMultipartHTTPTimeout + 5s
SAMPLE_INTERVAL_SECONDS = 1.0
threading.stack_size(512 * 1024)


def sql_literal(value):
    return "'" + str(value).replace("'", "''") + "'"


def rsync_psql(database, sql):
    result = subprocess.run(
        [str(PSQL), "-X", "-q", "-v", "ON_ERROR_STOP=1", "-h", str(DB_HOST),
         "-p", str(DB_PORT), "-U", "postgres", "-d", database, "-t", "-A", "-f", "-"],
        input=sql, text=True, capture_output=True, check=False,
    )
    if result.returncode != 0:
        raise RuntimeError(f"psql failed: {result.stderr.strip()[:600]}")
    return result.stdout.strip()


def credential_digest(label, raw):
    digest = hmac.new(DIGEST_SECRET.encode("utf-8"), digestmod=hashlib.sha256)
    digest.update(b"gxb-v2/credential/v1\x00")
    digest.update(label.encode("utf-8"))
    digest.update(b"\x00")
    digest.update(raw.encode("utf-8"))
    return digest.hexdigest()


def envelope(mid, session, token=None, extra=None):
    payload = {
        "mid": mid,
        "region": REGION,
        "v_": "1.631.0",
        "app_v": "1.631.0",
        "platform": 3,
    }
    if token is None:
        # Stock bootstrap MID18/MID1 authenticate the SID pair; gameplay calls carry only the token.
        payload["sid"] = session["sid"]
        payload["login_token"] = session["login_token"]
    else:
        payload["token"] = token
    payload.update(extra or {})
    return payload


class EdgeConnection:
    """One keep-alive connection to the edge, as a stock client would hold."""

    def __init__(self, origin=API):
        self.origin = urllib.parse.urlsplit(origin)
        self.connection = None

    def connect(self):
        self.connection = http.client.HTTPConnection(
            self.origin.hostname, self.origin.port or 80, timeout=SOCKET_TIMEOUT_SECONDS
        )

    def post(self, payload):
        body = urllib.parse.urlencode({"payload": json.dumps(payload)}).encode("utf-8")
        headers = {"Content-Type": "application/x-www-form-urlencoded"}
        if self.connection is None:
            self.connect()
        started = time.perf_counter()
        try:
            self.connection.request("POST", self.origin.path + "/engine", body=body, headers=headers)
            response = self.connection.getresponse()
            raw = response.read()
            status = response.status
        except Exception:
            self.close()
            raise
        latency_ms = (time.perf_counter() - started) * 1000.0
        try:
            decoded = json.loads(raw)
        except (json.JSONDecodeError, UnicodeDecodeError):
            decoded = {"raw": raw[:200].decode("utf-8", "replace")}
        return status, decoded, latency_ms

    def close(self):
        if self.connection is not None:
            try:
                self.connection.close()
            finally:
                self.connection = None


def call(connection, mid, session, token=None, extra=None):
    return connection.post(envelope(mid, session, token, extra))


def error_code_of(body):
    if not isinstance(body, dict):
        return None
    value = body.get("error_code")
    return int(value) if isinstance(value, (int, float)) else None


# ---------------------------------------------------------------- setup


def create_account_rows(database, count, start_index, batch=200):
    rows = []
    for index in range(start_index, start_index + count):
        account_id = str(uuid.uuid4())
        session_id = str(uuid.uuid4())
        sid = "load-sid-" + uuid.uuid4().hex
        login_token = "load-login-" + uuid.uuid4().hex
        rows.append({
            "account_id": account_id,
            "session_id": session_id,
            "sid": sid,
            "login_token": login_token,
            "login": f"load-{index:05d}-{account_id[:8]}",
            "index": index,
        })
    for offset in range(0, len(rows), batch):
        statements = ["BEGIN;"]
        for row in rows[offset:offset + batch]:
            account = sql_literal(row["account_id"]) + "::uuid"
            session = sql_literal(row["session_id"]) + "::uuid"
            statements.append(
                "INSERT INTO accounts(account_id,account_uid,status,created_at)"
                f" VALUES ({account},{sql_literal(row['account_id'])},'ACTIVE',clock_timestamp());"
            )
            statements.append(
                "INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)"
                f" VALUES ({session},{account},'SID_LOGIN_TOKEN_PAIR',clock_timestamp(),clock_timestamp());"
            )
            for kind, raw in (("SID", row["sid"]), ("LOGIN_TOKEN", row["login_token"])):
                statements.append(
                    "INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)"
                    f" VALUES ({sql_literal(str(uuid.uuid4()))}::uuid,{session},{sql_literal(kind)},"
                    f"decode({sql_literal(credential_digest(kind.lower(), raw))},'hex'),clock_timestamp());"
                )
        statements.append("COMMIT;")
        rsync_psql(database, "\n".join(statements) + "\n")
    return rows


def birth_player(row):
    # MID1 birth takes the logical-server directory lock (I4_BOOTSTRAP LockTimeout 2s),
    # so concurrent births contend and must retry rather than fail the setup.
    connection = EdgeConnection()
    failure = None
    try:
        for attempt in range(8):
            status, listing, _ = call(connection, 18, row)
            if status != 200:
                failure = f"MID18 http {status}: {listing}"
            else:
                status, reply, _ = call(connection, 1, row, extra=None)
                if status == 200 and reply.get("token"):
                    return {**row, "token": reply["token"], "is_new": reply.get("is_new")}
                failure = f"MID1 http {status}: {reply}"
            time.sleep(0.15 * (attempt + 1) + 0.05 * (row["index"] % 7))
        return {**row, "error": failure}
    except Exception as error:
        return {**row, "error": f"birth: {error}"}
    finally:
        connection.close()


def run_provisioner(database, players, level, hero_tables):
    accounts_path = SCRATCH / "accounts.json"
    accounts_path.write_text(json.dumps([{"account_id": p["account_id"]} for p in players]))
    result_path = SCRATCH / "provision.json"
    dsn = f"postgres://postgres@/{database}?host={DB_HOST}&port={DB_PORT}"
    command = [
        str(BIN / "gxb-load-provision"), "-dsn", dsn, "-accounts", str(accounts_path),
        "-level", str(level), "-tables", ",".join(str(t) for t in hero_tables),
        "-parallel", "4", "-out", str(result_path),
    ]
    subprocess.run(command, check=True)
    outcomes = json.loads(result_path.read_text())
    by_account = {row["account_id"]: row for row in outcomes}
    for player in players:
        outcome = by_account.get(player["account_id"], {})
        if outcome.get("error"):
            player["error"] = f"provision: {outcome['error']}"
        player["summons"] = outcome.get("summons") or []


def summon_heroes(player):
    summons = player.get("summons") or []
    if not summons:
        player["error"] = "provision granted no summons"
        return
    connection = EdgeConnection()
    partners = []
    try:
        for summon in summons:
            partner = None
            for attempt in range(8):
                status, reply, _ = call(connection, 59, player, player["token"], {
                    "table_id": summon["table_id"],
                    "stone": summon["stone"],
                    "stone_num": summon["stone_num"],
                })
                if status == 200:
                    partner = reply.get("partner_id") or (reply.get("partner_info") or {}).get("partner_id")
                    if partner:
                        break
                time.sleep(0.15 * (attempt + 1) + 0.05 * (summon["table_id"] % 7))
            if not partner:
                player["error"] = f"MID59 table {summon['table_id']} failed"
                return
            partners.append(int(partner))
        player["partners"] = partners
    finally:
        connection.close()


def command_setup(arguments):
    players_path = Path(arguments.players_file)
    players = []
    if players_path.exists():
        players = json.loads(players_path.read_text())[:arguments.players]
    hero_tables = tuple(int(t) for t in arguments.hero_tables.split(","))
    for _ in range(4):
        needed = arguments.players - len(players)
        if needed <= 0:
            break
        rows = create_account_rows(arguments.database, needed, len(players))
        print(f"setup: accounts +{needed}, target {arguments.players}")

        born = []
        with concurrent.futures.ThreadPoolExecutor(max_workers=6) as executor:
            for result in executor.map(birth_player, rows):
                born.append(result)
        failures = [p for p in born if p.get("error")]
        print(f"setup: birth ok={len(born) - len(failures)} failed={len(failures)}")
        if failures:
            print(f"setup: first failure: {failures[0]['error']}", file=sys.stderr)

        run_provisioner(arguments.database, born, arguments.level, hero_tables)
        with concurrent.futures.ThreadPoolExecutor(max_workers=12) as executor:
            list(executor.map(summon_heroes, born))
        for player in born:
            player.pop("summons", None)

        summon_failures = [p for p in born if not p.get("partners")]
        if summon_failures:
            print(f"setup: provision/summon failures: "
                  f"{[(p['login'], p.get('error')) for p in summon_failures[:3]]}", file=sys.stderr)
        players += [p for p in born if p.get("partners")]
        players_path.write_text(json.dumps(players, indent=1))
        print(f"setup: players ready={len(players)}/{arguments.players}")

    players_path.write_text(json.dumps(players, indent=1))
    return 0 if len(players) >= arguments.players else 1


# ---------------------------------------------------------------- samplers


def process_tree_ticks(root_pid):
    ticks = 0
    parents = {}
    own = {}
    for entry in os.listdir("/proc"):
        if not entry.isdigit():
            continue
        try:
            raw = Path(f"/proc/{entry}/stat").read_text()
        except OSError:
            continue
        close = raw.rfind(")")
        fields = raw[close + 2:].split()
        parents[int(entry)] = int(fields[1])
        own[int(entry)] = int(fields[11]) + int(fields[12])
    descendants = {root_pid}
    changed = True
    while changed:
        changed = False
        for pid, parent in parents.items():
            if parent in descendants and pid not in descendants:
                descendants.add(pid)
                changed = True
    return sum(own.get(pid, 0) for pid in descendants)


class Sampler(threading.Thread):
    def __init__(self, database, api_pid):
        super().__init__(daemon=True)
        self.database = database
        self.api_pid = api_pid
        self.stop_event = threading.Event()
        self.samples = []

    def query(self, sql):
        result = subprocess.run(
            [str(PSQL), "-X", "-q", "-t", "-A", "-h", str(DB_HOST), "-p", str(DB_PORT),
             "-U", "postgres", "-d", self.database, "-c", sql],
            text=True, capture_output=True, check=False,
        )
        return result.stdout if result.returncode == 0 else ""

    def run(self):
        clock_ticks = os.sysconf("SC_CLK_TCK")
        previous_ticks = process_tree_ticks(self.api_pid)
        previous_at = time.monotonic()
        while not self.stop_event.wait(SAMPLE_INTERVAL_SECONDS):
            at = time.monotonic()
            ticks = process_tree_ticks(self.api_pid)
            cores = max(0.0, (ticks - previous_ticks) / clock_ticks / (at - previous_at))
            previous_ticks, previous_at = ticks, at
            counts = self.query(
                "SELECT count(*), count(*) FILTER (WHERE state='active'), "
                "count(*) FILTER (WHERE wait_event_type='Lock'), "
                "count(*) FILTER (WHERE wait_event_type='Client'), "
                "count(*) FILTER (WHERE wait_event_type='IO') "
                f"FROM pg_stat_activity WHERE datname={sql_literal(self.database)}"
            ).strip()
            waits = self.query(
                "SELECT COALESCE(wait_event_type,'-')||'/'||COALESCE(wait_event,'-'), count(*) "
                "FROM pg_stat_activity "
                f"WHERE datname={sql_literal(self.database)} AND state='active' GROUP BY 1 ORDER BY 2 DESC"
            )
            self.samples.append({"at": round(at, 3), "cpu_cores": cores,
                                 "connections": counts, "waits": waits})

    def summary(self):
        if not self.samples:
            return {}
        connections = []
        active = []
        lock_waiters = []
        cores = []
        waits = {}
        for sample in self.samples:
            parts = sample["connections"].split("|")
            if len(parts) == 5:
                connections.append(int(parts[0]))
                active.append(int(parts[1]))
                lock_waiters.append(int(parts[2]))
            cores.append(sample["cpu_cores"])
            for line in sample["waits"].splitlines():
                name, _, count = line.rpartition("|")
                if name:
                    waits[name] = waits.get(name, 0) + int(count)
        return {
            "samples": len(self.samples),
            "connections_max": max(connections) if connections else 0,
            "connections_mean": round(statistics.fmean(connections), 1) if connections else 0,
            "active_max": max(active) if active else 0,
            "lock_waiters_max": max(lock_waiters) if lock_waiters else 0,
            "api_cpu_cores_max": round(max(cores), 2) if cores else 0,
            "api_cpu_cores_mean": round(statistics.fmean(cores), 2) if cores else 0,
            "wait_event_samples": dict(sorted(waits.items(), key=lambda item: -item[1])[:12]),
        }


# ---------------------------------------------------------------- load


def percentile(values, fraction):
    if not values:
        return None
    ordered = sorted(values)
    index = min(len(ordered) - 1, max(0, int(round(fraction * (len(ordered) - 1)))))
    return round(ordered[index], 1)


def login_player(player):
    connection = EdgeConnection()
    latency = None
    try:
        for attempt in range(4):
            status, reply, latency = call(connection, 1, player)
            if status == 200 and reply.get("token"):
                player["token"] = reply["token"]
                return {"mid": 1, "status": status, "latency_ms": round(latency, 1),
                        "error_code": error_code_of(reply)}
            time.sleep(0.3 * (attempt + 1))
        return {"mid": 1, "status": status, "latency_ms": round(latency, 1),
                "error_code": error_code_of(reply)}
    finally:
        connection.close()


def run_client(player, start_at, records, scenarios, login_mode):
    connection = EdgeConnection()
    try:
        wait = start_at - time.monotonic()
        if wait > 0:
            time.sleep(wait)
        client = {"player": player["login"], "started_at": start_at, "calls": [], "skipped": []}

        def perform(mid, token, extra=None):
            status, body, latency = call(connection, mid, player, token, extra)
            record = {"mid": mid, "status": status, "latency_ms": round(latency, 1),
                      "error_code": error_code_of(body),
                      "error": (body.get("error") if isinstance(body, dict) else None)}
            client["calls"].append(record)
            records.append(record)
            return status, body

        token = player.get("token")
        if login_mode == "burst":
            status, login = perform(1, None)
            token = login.get("token") if status == 200 else None
        if not token:
            client["skipped"].append("all: login failed")
            return client

        if "top_floor" in scenarios:
            status, arena = perform(272, token)
            enemies = arena.get("enemies") if status == 200 else None
            if not enemies:
                client["skipped"].append("280: no enemy list")
            else:
                enemy_id = int(enemies[0]["table_id"])
                formation = "|".join(str(p) for p in player["partners"])
                request = {"formation": formation, "pet_id": 0, "enemy_id": enemy_id,
                           "is_avenge": 0, "campaign_id": 0, "campaign_type": 0}
                status, body = perform(280, token, request)
                if status == 200 and isinstance(body, dict) and not body.get("battle_report"):
                    perform(280, token, request)

        if "pet_campaign" in scenarios:
            formation = "|".join(str(p) for p in player["partners"])
            status, _ = perform(819, token, {"campaign_id": PET_CAMPAIGN_FIRST_FLOOR,
                                             "formation": formation, "pet_id": 0})
            if status == 200:
                perform(820, token, {"is_win": True, "floor": 1, "floor_type": 1, "pet_id": 0})
            else:
                client["skipped"].append("820: pet campaign START failed")
        return client
    except Exception as error:
        return {"player": player["login"], "error": str(error), "calls": [], "skipped": []}
    finally:
        connection.close()


def load_average():
    return [round(value, 2) for value in os.getloadavg()]


def command_run(arguments):
    players = json.loads(Path(arguments.players_file).read_text())
    ready = [p for p in players if p.get("partners")][:arguments.players]
    if len(ready) < arguments.players:
        print(f"run: only {len(ready)} ready players", file=sys.stderr)
        return 2
    scenarios = set(name for name in arguments.scenarios.split(",") if name)
    records = []
    login_records = []
    clients = []
    sampler = None
    api_pid = int((SCRATCH / "api.pid").read_text()) if (SCRATCH / "api.pid").exists() else None

    lock_handle = open(LOCK_PATH, "w")
    fcntl.flock(lock_handle, fcntl.LOCK_EX)
    load_start = load_average()
    print(f"run: vc.lock held; load average before={load_start}")
    try:
        if api_pid:
            sampler = Sampler(arguments.database, api_pid)
            sampler.start()
        if arguments.login_mode == "prelogin":
            started = time.monotonic()
            with concurrent.futures.ThreadPoolExecutor(max_workers=arguments.login_concurrency) as executor:
                login_records = list(executor.map(login_player, ready))
            Path(arguments.players_file).write_text(json.dumps(players, indent=1))
            print(f"prelogin: {sum(1 for r in login_records if r['status'] == 200)}/{len(ready)} ok "
                  f"in {time.monotonic() - started:.1f}s")
        began = time.monotonic()
        with concurrent.futures.ThreadPoolExecutor(max_workers=arguments.players) as executor:
            futures = []
            for index, player in enumerate(ready):
                start_at = began + (arguments.ramp_seconds * index / max(1, arguments.players - 1))
                futures.append(executor.submit(run_client, player, start_at, records, scenarios,
                                               arguments.login_mode))
            for future in concurrent.futures.as_completed(futures):
                clients.append(future.result())
        duration = time.monotonic() - began
    finally:
        if sampler:
            sampler.stop_event.set()
            sampler.join()
        fcntl.flock(lock_handle, fcntl.LOCK_UN)
        lock_handle.close()

    metrics = summarize(records)
    result = {
        "players": arguments.players,
        "ramp_seconds": arguments.ramp_seconds,
        "login_mode": arguments.login_mode,
        "login_concurrency": arguments.login_concurrency if arguments.login_mode == "prelogin" else None,
        "prelogin_mids": summarize(login_records) if login_records else {},
        "scenarios": sorted(scenarios),
        "database": arguments.database,
        "load_average_start": load_start,
        "load_average_end": load_average(),
        "duration_seconds": round(duration, 2),
        "client_timeout_seconds": LOGIN_TIMEOUT_SECONDS,
        "mids": metrics,
        "sampler": sampler.summary() if sampler else {},
        "failed_clients": [c for c in clients if c.get("error")][:10],
        "skipped": [s for c in clients for s in c.get("skipped", [])],
    }
    out = Path(arguments.out_file)
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(result, indent=1))
    print(json.dumps({"players": result["players"], "ramp_seconds": result["ramp_seconds"],
                      "duration_seconds": result["duration_seconds"],
                      "mids": metrics, "sampler": result["sampler"]}, indent=1))
    return 0


def summarize(records):
    by_mid = {}
    for record in records:
        by_mid.setdefault(str(record["mid"]), []).append(record)
    metrics = {}
    for mid, rows in sorted(by_mid.items(), key=lambda item: int(item[0])):
        latencies = [row["latency_ms"] for row in rows]
        statuses = {}
        refused = 0
        slow = 0
        causes = {}
        for row in rows:
            statuses[str(row["status"])] = statuses.get(str(row["status"]), 0) + 1
            if row["status"] != 200 or row.get("error_code") not in (None, 0):
                refused += 1
                cause = row.get("error") or f"http {row['status']}"
                causes[cause] = causes.get(cause, 0) + 1
            if row["latency_ms"] > LOGIN_TIMEOUT_SECONDS * 1000:
                slow += 1
        metrics[mid] = {
            "count": len(rows),
            "errors_by_status": statuses,
            "errors_by_cause": dict(sorted(causes.items(), key=lambda item: -item[1])),
            "errors": refused,
            "over_client_timeout": slow,
            "p50_ms": percentile(latencies, 0.50),
            "p95_ms": percentile(latencies, 0.95),
            "p99_ms": percentile(latencies, 0.99),
            "max_ms": round(max(latencies), 1),
            "mean_ms": round(statistics.fmean(latencies), 1),
        }
    return metrics


MID_NAMES = {"1": "MID 1 login", "272": "MID 272 top floor load", "280": "MID 280 top floor START",
             "819": "MID 819 sky tower START", "820": "MID 820 sky tower result"}


def command_report(arguments):
    rows = ["| players | ramp (s) | MID | calls | errors | p50 ms | p95 ms | p99 ms | max ms | over 20 s |",
            "|---|---|---|---|---|---|---|---|---|---|"]
    for path in arguments.results:
        data = json.loads(Path(path).read_text())
        stages = [("prelogin", data.get("prelogin_mids") or {}), ("burst", data.get("mids") or {})]
        for stage, mids in stages:
            for mid, metric in mids.items():
                label = MID_NAMES.get(mid, f"MID {mid}")
                if stage == "prelogin":
                    label += " (prelogin)"
                rows.append(
                    f"| {data['players']} | {data['ramp_seconds']:g} | {label} | {metric['count']} | "
                    f"{metric['errors']} | {metric['p50_ms']} | {metric['p95_ms']} | {metric['p99_ms']} | "
                    f"{metric['max_ms']} | {metric['over_client_timeout']} |"
                )
    table = "\n".join(rows)
    if arguments.out_file:
        Path(arguments.out_file).write_text(table + "\n")
    print(table)
    return 0


def main(arguments):
    parser = argparse.ArgumentParser(description=__doc__)
    subparsers = parser.add_subparsers(dest="command", required=True)

    setup = subparsers.add_parser("setup", help="create accounts, birth, provision and summon players")
    setup.add_argument("--database", required=True)
    setup.add_argument("--players", type=int, required=True)
    setup.add_argument("--players-file", default=str(SCRATCH / "players.json"))
    setup.add_argument("--level", type=int, default=DEFAULT_LEVEL)
    setup.add_argument("--hero-tables", default=",".join(str(t) for t in DEFAULT_HERO_TABLES))
    setup.set_defaults(handler=command_setup)

    run = subparsers.add_parser("run", help="run one measured load burst")
    run.add_argument("--database", required=True)
    run.add_argument("--players", type=int, required=True)
    run.add_argument("--players-file", default=str(SCRATCH / "players.json"))
    run.add_argument("--ramp-seconds", type=float, default=0)
    run.add_argument("--scenarios", default="top_floor,pet_campaign")
    run.add_argument("--login-mode", choices=("burst", "prelogin"), default="prelogin",
                     help="burst: MID1 inside the measured burst; prelogin: log in at controlled concurrency first")
    run.add_argument("--login-concurrency", type=int, default=4)
    run.add_argument("--out-file", required=True)
    run.set_defaults(handler=command_run)

    report = subparsers.add_parser("report", help="build the markdown table from result JSON files")
    report.add_argument("results", nargs="+")
    report.add_argument("--out-file")
    report.set_defaults(handler=command_report)

    parsed = parser.parse_args(arguments)
    SCRATCH.mkdir(parents=True, exist_ok=True)
    return parsed.handler(parsed)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
