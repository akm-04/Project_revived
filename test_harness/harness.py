#!/usr/bin/env python3
"""Temporary v2 real-client playtest harness: build, upgrade, reset, start and stop its own stack."""

import json
import os
import secrets
import shutil
import signal
import socket
import subprocess
import sys
import time
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[1]
PLAYTEST_HOME = Path(os.environ.get("PLAYTEST_HOME", Path(__file__).resolve().parent / "runtime"))
PLAYTEST_TOOLS = Path(
    os.environ.get(
        "PLAYTEST_TOOLS",
        WORKSPACE / "tmp" / "tools_r4_accept" / "gxb-e2e-self-contained" / "bin",
    )
)
PLAYTEST_BIND = os.environ.get("PLAYTEST_BIND", "127.0.0.1")
ENGINE_ORIGIN = os.environ.get(
    "PLAYTEST_ENGINE_ORIGIN", "https://gxbv2engine.shares.zrok.io"
).rstrip("/")

API_HOST = "127.0.0.1"
API_PORT = int(os.environ.get("PLAYTEST_API_PORT", "18953"))
REALTIME_HOST = "0.0.0.0"
REALTIME_PORT = int(os.environ.get("PLAYTEST_REALTIME_PORT", "18954"))
REALTIME_HTTP_PORT = int(os.environ.get("PLAYTEST_REALTIME_HTTP_PORT", "18958"))
SDK_PORT = int(os.environ.get("PLAYTEST_SDK_PORT", "18955"))
ASSET_FRONT_PORT = int(os.environ.get("PLAYTEST_FRONT_PORT", "18956"))
POSTGRES_PORT = int(os.environ.get("PLAYTEST_POSTGRES_PORT", "18957"))
API_ADDRESS = f"{API_HOST}:{API_PORT}"
REALTIME_ADDRESS = f"{REALTIME_HOST}:{REALTIME_PORT}"
DATABASE_NAME = os.environ.get("PLAYTEST_DATABASE_NAME", "gxb_playtest")
BINARY_NAMES = ("gxb-api", "gxb-operator", "gxb-combat-worker", "gxb-worker", "gxb-realtime", "gxb-player-data")
LOG_LINE_COUNT = 50
API_START_TIMEOUT_SECONDS = 60
ASSET_INDEX_TIMEOUT_SECONDS = 300
# The agent stops gxb-api (5 s shutdown) before it exits itself.
STOP_TIMEOUT_SECONDS = 20

STATE_DIRECTORY = PLAYTEST_HOME / "state"
LOG_DIRECTORY = PLAYTEST_HOME / "logs"
RUN_DIRECTORY = PLAYTEST_HOME / "run"
BINARY_DIRECTORY = PLAYTEST_HOME / "bin"
NEW_BINARY_DIRECTORY = PLAYTEST_HOME / "bin.new"
OLD_BINARY_DIRECTORY = PLAYTEST_HOME / "bin.old"
MEDIA_DIRECTORY = PLAYTEST_HOME / "media"
# The backend OTA root (GXB_OTA_ROOT); gxb-api serves /updates and /res from it and the asset front streams them.
OTA_ROOT_DIRECTORY = PLAYTEST_HOME / "ota_root"
# Pictures shipped inside the APK; up restores this setting when an older OTA root lacks it.
APK_RES_DIRECTORY = WORKSPACE / "tmp" / "virtualclient" / "apk" / "res"
# The operator agent owns gxb-api, as in production: it starts it with the per-start operator token.
AGENT_DIRECTORY = PLAYTEST_HOME / "agent"
AGENT_LISTEN = f"127.0.0.1:{os.environ.get('PLAYTEST_AGENT_PORT', '18960')}"
OPERATOR_ADDRESS = f"127.0.0.1:{os.environ.get('PLAYTEST_OPERATOR_PORT', '18961')}"
STOCK_BASELINE = WORKSPACE / "inputs" / "Recovered_assets" / "New_Client" / "APK_1.631.0"
# Decompiled stock Lua (read as data, never run): OTA patch pins hash this text, not the per-ABI APK bytecode.
STOCK_SOURCE = WORKSPACE / "inputs" / "Recovered_assets" / "New_Client" / "Decompiled_Lua" / "src_64"
POSTGRES_DATA_DIRECTORY = PLAYTEST_HOME / "pg"
POSTGRES_LOG = LOG_DIRECTORY / "postgres.log"
SECRETS_PATH = STATE_DIRECTORY / "secrets.json"
OPERATOR_PASSWORD_PATH = STATE_DIRECTORY / "operator_password"
BACKEND_STATE_PATH = STATE_DIRECTORY / "backend.json"
ACCOUNTS_PATH = STATE_DIRECTORY / "accounts.json"
# The retired Python SDK stand-in's logins, kept read-only and imported into the backend once (G51F F6).
STANDIN_ACCOUNTS_PATH = STATE_DIRECTORY / "accounts.standin-backup.json"
SDK_IMPORTED_MARKER = STATE_DIRECTORY / "sdk_import.done"
BASELINE_SNAPSHOT_MARKER = STATE_DIRECTORY / "baseline_snapshot.done"

DATABASE_DSN = (
    f"postgres://postgres@/{DATABASE_NAME}"
    f"?host={POSTGRES_DATA_DIRECTORY}&port={POSTGRES_PORT}"
)

TOOL_BUNDLE = PLAYTEST_TOOLS.parent
GO_ROOT = TOOL_BUNDLE / "opt" / "go-1.27.3"
GO_MODULE_CACHE = WORKSPACE / "tmp" / "cache" / "tools_r4" / "go-mod"
GO_BUILD_CACHE = WORKSPACE / "tmp" / "cache" / "tools_r4" / "go-build"
GO_PROXY = f"file://{TOOL_BUNDLE}/cache/go-mod/cache/download"


def detect_lan_host():
    result = subprocess.run(
        ["ip", "-4", "route", "get", "1.1.1.1"],
        capture_output=True,
        text=True,
        check=False,
    )
    fields = result.stdout.split()
    if "src" in fields and fields.index("src") + 1 < len(fields):
        return fields[fields.index("src") + 1]
    return "127.0.0.1"


LAN_HOST = os.environ.get("PLAYTEST_LAN_HOST") or detect_lan_host()


def tool_path(name):
    return str(PLAYTEST_TOOLS / name)


def go_environment():
    environment = os.environ.copy()
    environment.update(
        {
            "GOROOT": str(GO_ROOT),
            "GOMODCACHE": str(GO_MODULE_CACHE),
            "GOCACHE": str(GO_BUILD_CACHE),
            "GOTOOLCHAIN": "local",
            "GOPROXY": GO_PROXY,
            "GOSUMDB": "off",
            "CC": tool_path("zig-cc"),
            "GOFLAGS": "-mod=mod",
            "PATH": f"{PLAYTEST_TOOLS}:{GO_ROOT / 'bin'}:{environment.get('PATH', '')}",
        }
    )
    return environment


def ensure_layout():
    for directory in (
        STATE_DIRECTORY,
        LOG_DIRECTORY,
        RUN_DIRECTORY,
        MEDIA_DIRECTORY,
        OTA_ROOT_DIRECTORY,
        AGENT_DIRECTORY,
    ):
        directory.mkdir(parents=True, exist_ok=True)
    os.chmod(STATE_DIRECTORY, 0o700)
    os.chmod(MEDIA_DIRECTORY, 0o700)


def read_json(path, fallback):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return fallback


def write_json_atomic(path, value, mode=None):
    path.parent.mkdir(parents=True, exist_ok=True)
    temporary = path.with_name(f"{path.name}.{os.getpid()}.tmp")
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        json.dump(value, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, path)
    if mode is not None:
        os.chmod(path, mode)


def load_secrets():
    existing = read_json(SECRETS_PATH, None)
    if existing is not None:
        return existing
    combat_key = secrets.token_hex(32)
    secrets_value = {
        "credential_digest_secret": secrets.token_hex(32),
        "gameplay_bearer_secret": secrets.token_hex(32),
        "redeem_digest_secret": secrets.token_hex(32),
        "derivation_key_id": "playtest-" + secrets.token_hex(8),
        "combat_entropy_keys": f"playtest1={combat_key}",
        "combat_entropy_key_current": "playtest1",
    }
    write_json_atomic(SECRETS_PATH, secrets_value, 0o600)
    return secrets_value


def backend_state():
    return read_json(BACKEND_STATE_PATH, {})


def child_environment(overrides):
    environment = os.environ.copy()
    environment.update(overrides)
    return environment


def media_public_origin():
    # The backend's profile-media URL parser accepts only literal http:// origins.
    if ENGINE_ORIGIN.startswith("http://"):
        return ENGINE_ORIGIN
    return f"http://{LAN_HOST}:{ASSET_FRONT_PORT}"


def api_environment(secrets_value):
    return child_environment(
        {
            "GXB_POSTGRES_DSN": DATABASE_DSN,
            "GXB_HTTP_ADDR": API_ADDRESS,
            "GXB_SDK_LISTEN": f"{PLAYTEST_BIND}:{SDK_PORT}",
            "GXB_PUBLIC_ENGINE_URL": f"{ENGINE_ORIGIN}/engine",
            "GXB_CLIENT_LOG_URL": f"{ENGINE_ORIGIN}/client-log",
            "GXB_REALTIME_PUBLIC_HOST": LAN_HOST,
            "GXB_REALTIME_PUBLIC_PORT": str(REALTIME_PORT),
            "GXB_CREDENTIAL_DIGEST_SECRET": secrets_value["credential_digest_secret"],
            "GXB_GAMEPLAY_BEARER_SECRET": secrets_value["gameplay_bearer_secret"],
            "GXB_REDEEM_DIGEST_SECRET": secrets_value["redeem_digest_secret"],
            "GXB_DERIVATION_KEY_ID": secrets_value["derivation_key_id"],
            "GXB_PROFILE_MEDIA_ROOT": str(MEDIA_DIRECTORY),
            "GXB_OTA_ROOT": str(OTA_ROOT_DIRECTORY),
            "GXB_PROFILE_MEDIA_PUBLIC_ORIGIN": media_public_origin(),
            "GXB_COMBAT_ENTROPY_KEYS": secrets_value["combat_entropy_keys"],
            "GXB_COMBAT_ENTROPY_KEY_CURRENT": secrets_value[
                "combat_entropy_key_current"
            ],
        }
    )


def realtime_environment(secrets_value):
    return child_environment(
        {
            "GXB_POSTGRES_DSN": DATABASE_DSN,
            "GXB_REALTIME_ADDR": REALTIME_ADDRESS,
            "GXB_REALTIME_HTTP_ADDR": f"127.0.0.1:{REALTIME_HTTP_PORT}",
            "GXB_REALTIME_PUBLIC_HOST": LAN_HOST,
            "GXB_REALTIME_PUBLIC_PORT": str(REALTIME_PORT),
            "GXB_CREDENTIAL_DIGEST_SECRET": secrets_value["credential_digest_secret"],
            "GXB_GAMEPLAY_BEARER_SECRET": secrets_value["gameplay_bearer_secret"],
            "GXB_DERIVATION_KEY_ID": secrets_value["derivation_key_id"],
        }
    )


def worker_environment():
    return child_environment({"GXB_POSTGRES_DSN": DATABASE_DSN})


def asset_front_environment():
    return child_environment(
        {
            "PLAYTEST_HOME": str(PLAYTEST_HOME),
            "PLAYTEST_BIND": PLAYTEST_BIND,
            "PLAYTEST_ENGINE_ORIGIN": ENGINE_ORIGIN,
            "PLAYTEST_REALTIME_HTTP_PORT": str(REALTIME_HTTP_PORT),
        }
    )


def service_command(service):
    if service["kind"] == "tunnel":
        share = [
            "zrok2",
            "share",
            "public",
            f"localhost:{service['target_port']}",
            "-n",
            f"public:{service['share']}",
            "--headless",
        ]
        return share, str(RUN_DIRECTORY)
    if service["kind"] == "binary":
        return [str(BINARY_DIRECTORY / service["name"])], str(BINARY_DIRECTORY)
    if service["kind"] == "agent":
        command = [str(BINARY_DIRECTORY / "gxb-operator"), "--root", str(AGENT_DIRECTORY), "agent"]
        return command, str(BINARY_DIRECTORY)
    script = Path(__file__).resolve().parent / service["script"]
    return [sys.executable, "-I", "-B", "-u", str(script)], str(script.parent)


def service_environment(name, secrets_value):
    if name.startswith("zrok-"):
        return child_environment({})
    if name == "gxb-agent":
        return api_environment(secrets_value)
    if name == "gxb-realtime":
        return realtime_environment(secrets_value)
    if name == "gxb-worker":
        return worker_environment()
    return asset_front_environment()


SERVICES = (
    {
        "name": "gxb-agent",
        "kind": "agent",
        "port": API_PORT,
        "listen_host": API_HOST,
    },
    {
        "name": "gxb-worker",
        "kind": "binary",
        "port": None,
        "listen_host": None,
    },
    {
        "name": "gxb-realtime",
        "kind": "binary",
        "port": REALTIME_PORT,
        "listen_host": "127.0.0.1",
    },
    {
        "name": "gxb-asset-front",
        "kind": "python",
        "script": "asset_front.py",
        "port": ASSET_FRONT_PORT,
        "listen_host": PLAYTEST_BIND,
    },
    {
        "name": "zrok-gxbv2sdk",
        "kind": "tunnel",
        "share": "gxbv2sdk",
        "target_port": SDK_PORT,
        "port": None,
        "listen_host": None,
    },
    {
        "name": "zrok-gxbv2engine",
        "kind": "tunnel",
        "share": "gxbv2engine",
        "target_port": ASSET_FRONT_PORT,
        "port": None,
        "listen_host": None,
    },
)
SERVICE_NAMES = tuple(service["name"] for service in SERVICES)

EXPECTED_COMMANDLINE = {
    "gxb-agent": "gxb-operator",
    "gxb-worker": "gxb-worker",
    "gxb-realtime": "gxb-realtime",
    "gxb-asset-front": "asset_front.py",
    "zrok-gxbv2sdk": "public:gxbv2sdk",
    "zrok-gxbv2engine": "public:gxbv2engine",
}


def pid_path(name):
    return RUN_DIRECTORY / f"{name}.pid"


def log_path(name):
    return LOG_DIRECTORY / f"{name}.log"


def read_pid(name):
    try:
        return int(pid_path(name).read_text(encoding="utf-8").strip())
    except (FileNotFoundError, ValueError):
        return None


def commandline_matches(pid, name):
    try:
        raw = Path(f"/proc/{pid}/cmdline").read_bytes()
    except OSError:
        return False
    return EXPECTED_COMMANDLINE[name].encode() in raw


def process_alive(name):
    pid = read_pid(name)
    if pid is None:
        return False
    try:
        os.kill(pid, 0)
    except ProcessLookupError:
        return False
    except PermissionError:
        return True
    return commandline_matches(pid, name)


def port_open(host, port):
    if port is None:
        return False
    with socket.socket(socket.AF_INET, socket.SOCK_STREAM) as probe:
        probe.settimeout(0.5)
        return probe.connect_ex((host, port)) == 0


def start_service(service, secrets_value):
    name = service["name"]
    pid_path(name).parent.mkdir(parents=True, exist_ok=True)
    log_path(name).parent.mkdir(parents=True, exist_ok=True)
    command, working_directory = service_command(service)
    handle = open(log_path(name), "ab")
    process = subprocess.Popen(
        command,
        env=service_environment(name, secrets_value),
        cwd=working_directory,
        stdin=subprocess.DEVNULL,
        stdout=handle,
        stderr=subprocess.STDOUT,
        start_new_session=True,
    )
    handle.close()
    pid_path(name).write_text(f"{process.pid}\n", encoding="utf-8")


def stop_service(name):
    pid = read_pid(name)
    if pid is None:
        return "not running"
    if not process_alive(name):
        pid_path(name).unlink(missing_ok=True)
        return "stale pid removed"
    try:
        os.kill(pid, signal.SIGTERM)
    except ProcessLookupError:
        pid_path(name).unlink(missing_ok=True)
        return "stopped"
    deadline = time.monotonic() + STOP_TIMEOUT_SECONDS
    while time.monotonic() < deadline:
        if not Path(f"/proc/{pid}").exists():
            break
        time.sleep(0.1)
    if Path(f"/proc/{pid}").exists():
        os.kill(pid, signal.SIGKILL)
    pid_path(name).unlink(missing_ok=True)
    return "stopped"


def cluster_running():
    if not (POSTGRES_DATA_DIRECTORY / "PG_VERSION").exists():
        return False
    result = subprocess.run(
        [tool_path("pg_ctl"), "-D", str(POSTGRES_DATA_DIRECTORY), "status"],
        capture_output=True,
        check=False,
    )
    return result.returncode == 0


# C1 Tier 0 (work/i9/stages/I9-11/contract_recovery/C1_CAPACITY_DESIGN.md F3): the defaults escalate roster-sized
# SERIALIZABLE reads to relation locks, so unrelated players abort each other with 40001.
SERIALIZABLE_LOCK_BUDGET = "-c max_pred_locks_per_transaction=1024 -c max_pred_locks_per_relation=512 -c max_pred_locks_per_page=8"


def initialize_cluster():
    if (POSTGRES_DATA_DIRECTORY / "PG_VERSION").exists():
        return
    POSTGRES_DATA_DIRECTORY.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            tool_path("initdb"),
            "-D",
            str(POSTGRES_DATA_DIRECTORY),
            "-U",
            "postgres",
            "-A",
            "trust",
            "--no-sync",
        ],
        check=True,
    )
    with open(POSTGRES_DATA_DIRECTORY / "postgresql.conf", "a", encoding="utf-8") as conf:
        conf.write(
            "\nlisten_addresses = ''\n"
            f"port = {POSTGRES_PORT}\n"
            f"unix_socket_directories = '{POSTGRES_DATA_DIRECTORY}'\n"
        )


def start_cluster():
    initialize_cluster()
    LOG_DIRECTORY.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        [
            tool_path("pg_ctl"),
            "-D",
            str(POSTGRES_DATA_DIRECTORY),
            "-l",
            str(POSTGRES_LOG),
            "-o",
            SERIALIZABLE_LOCK_BUDGET,
            "-w",
            "start",
        ],
        check=True,
    )


def stop_cluster():
    if not cluster_running():
        return "not running"
    subprocess.run(
        [
            tool_path("pg_ctl"),
            "-D",
            str(POSTGRES_DATA_DIRECTORY),
            "-m",
            "fast",
            "-w",
            "stop",
        ],
        check=True,
    )
    return "stopped"


def run_checked(command, working_directory, environment=None):
    result = subprocess.run(
        command,
        cwd=working_directory,
        env=environment,
        stdin=subprocess.DEVNULL,
        check=False,
    )
    if result.returncode != 0:
        raise SystemExit(f"failed ({result.returncode}): {' '.join(command)}")


def build_binaries(tree):
    shutil.rmtree(NEW_BINARY_DIRECTORY, ignore_errors=True)
    NEW_BINARY_DIRECTORY.mkdir(parents=True)
    environment = go_environment()
    go_binary = str(GO_ROOT / "bin" / "go")
    for name in BINARY_NAMES:
        run_checked(
            [
                go_binary,
                "build",
                "-tags",
                "postgres,river",
                "-o",
                str(NEW_BINARY_DIRECTORY / name),
                f"./cmd/{name}",
            ],
            tree,
            environment,
        )
    shutil.rmtree(OLD_BINARY_DIRECTORY, ignore_errors=True)
    if BINARY_DIRECTORY.exists():
        BINARY_DIRECTORY.rename(OLD_BINARY_DIRECTORY)
    NEW_BINARY_DIRECTORY.rename(BINARY_DIRECTORY)
    shutil.rmtree(OLD_BINARY_DIRECTORY, ignore_errors=True)


def migrate_database(tree):
    """Migrate forward and run the deploy steps that are idempotent on a populated database."""
    environment = go_environment()
    run_checked(
        [
            tool_path("goose"),
            "-dir",
            "migrations",
            "postgres",
            DATABASE_DSN,
            "up",
        ],
        tree,
        environment,
    )
    deploy_environment = dict(environment)
    deploy_environment["GXB_POSTGRES_DSN"] = DATABASE_DSN
    run_checked(
        [
            str(GO_ROOT / "bin" / "go"),
            "run",
            "-tags",
            "postgres,river",
            "./cmd/gxb-content-broadcast-deploy",
        ],
        tree,
        deploy_environment,
    )
    publication_environment = dict(environment)
    publication_environment["GXB_I7A9_DSN"] = DATABASE_DSN
    publication_environment["GXB_I7A9_PREPARE_PROCESS"] = "1"
    run_checked(
        [
            str(GO_ROOT / "bin" / "go"),
            "test",
            "-count=1",
            "-tags",
            "postgres,river",
            "-run",
            "^(TestPreparePublicationProcess|TestPreparePublicationRiver)$",
            "./internal/integration/publication",
            "./internal/adapters/river",
        ],
        tree,
        publication_environment,
    )


def prepare_database(tree):
    subprocess.run(
        [
            tool_path("dropdb"),
            "--force",
            "-h",
            str(POSTGRES_DATA_DIRECTORY),
            "-p",
            str(POSTGRES_PORT),
            "-U",
            "postgres",
            "--if-exists",
            DATABASE_NAME,
        ],
        stdin=subprocess.DEVNULL,
        check=True,
    )
    subprocess.run(
        [
            tool_path("createdb"),
            "-h",
            str(POSTGRES_DATA_DIRECTORY),
            "-p",
            str(POSTGRES_PORT),
            "-U",
            "postgres",
            DATABASE_NAME,
        ],
        check=True,
    )
    migrate_database(tree)


def command_reset(arguments):
    if len(arguments) != 1:
        raise SystemExit("usage: harness.py reset <backend tree>")
    tree = Path(arguments[0]).resolve()
    if not (tree / "go.mod").is_file() or not (tree / "BACKEND_COMMIT").is_file():
        raise SystemExit(f"not a deployed backend tree (go.mod and BACKEND_COMMIT): {tree}")
    ensure_layout()
    command_down()
    build_binaries(tree)
    start_cluster()
    prepare_database(tree)
    preserve_standin_accounts()
    SDK_IMPORTED_MARKER.unlink(missing_ok=True)
    BASELINE_SNAPSHOT_MARKER.unlink(missing_ok=True)
    head = (tree / "BACKEND_COMMIT").read_text(encoding="utf-8").strip()
    write_json_atomic(
        BACKEND_STATE_PATH,
        {"tree": str(tree), "commit": head, "database": DATABASE_NAME},
    )
    print(f"reset: built {', '.join(BINARY_NAMES)} into {BINARY_DIRECTORY}")
    print(f"reset: database {DATABASE_NAME} migrated, deployed and prepared")
    print(f"reset: backend {head} at {tree}")


def command_upgrade(arguments):
    if len(arguments) != 1:
        raise SystemExit("usage: harness.py upgrade <backend tree>")
    tree = Path(arguments[0]).resolve()
    if not (tree / "go.mod").is_file() or not (tree / "BACKEND_COMMIT").is_file():
        raise SystemExit(f"not a deployed backend tree (go.mod and BACKEND_COMMIT): {tree}")
    ensure_layout()
    command_down()
    build_binaries(tree)
    start_cluster()
    migrate_database(tree)
    head = (tree / "BACKEND_COMMIT").read_text(encoding="utf-8").strip()
    write_json_atomic(
        BACKEND_STATE_PATH,
        {"tree": str(tree), "commit": head, "database": DATABASE_NAME},
    )
    print(f"upgrade: built {', '.join(BINARY_NAMES)} into {BINARY_DIRECTORY}")
    print(f"upgrade: database {DATABASE_NAME} migrated forward and deployed, existing rows kept")
    print(f"upgrade: backend {head} at {tree}")


def write_agent_config():
    tree = backend_state().get("tree")
    if not tree:
        raise SystemExit("up: no deployed backend tree; run reset or upgrade first")
    config = {
        "listen": AGENT_LISTEN,
        "ota_root": str(OTA_ROOT_DIRECTORY),
        "stock_baseline": str(STOCK_BASELINE),
        "stock_source": str(STOCK_SOURCE),
        "client_tree": str(Path(tree) / "client" / "ota"),
        # PATH resolves the system pg_dump 16, which refuses the bundled PostgreSQL 18 server.
        "toolchain_path": str(PLAYTEST_TOOLS),
        "origins": {},
        "backend": {
            "binary": str(BINARY_DIRECTORY / "gxb-api"),
            "env_file": "",
            "operator_addr": OPERATOR_ADDRESS,
            "migrations_dir": str(Path(tree) / "migrations"),
        },
    }
    write_json_atomic(AGENT_DIRECTORY / "agent.json", config, 0o600)


def operator_password():
    if not OPERATOR_PASSWORD_PATH.exists():
        descriptor = os.open(OPERATOR_PASSWORD_PATH, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
            handle.write(secrets.token_urlsafe(24) + "\n")
    return OPERATOR_PASSWORD_PATH.read_text(encoding="utf-8").strip()


def run_operator(arguments, typed_lines=(), environment=None):
    command = [str(BINARY_DIRECTORY / "gxb-operator"), "--root", str(AGENT_DIRECTORY), *arguments]
    result = subprocess.run(
        command,
        input="".join(f"{line}\n" for line in typed_lines),
        capture_output=True,
        text=True,
        check=False,
        env=environment,
    )
    if result.returncode != 0:
        raise SystemExit(f"up: gxb-operator {arguments[0]} failed: {result.stderr.strip() or result.stdout.strip()}")


def start_backend_through_agent():
    """Root setup once, a fresh CLI session, then backend start unless gxb-api already listens."""
    host, port = AGENT_LISTEN.rsplit(":", 1)
    wait_for_port(host, int(port), API_START_TIMEOUT_SECONDS)
    password = operator_password()
    if not (AGENT_DIRECTORY / "root.passwd").exists():
        run_operator(["setup"], (password, password))
    run_operator(["login"], (password,))
    if not port_open(API_HOST, API_PORT):
        run_operator(["backend", "start"])


def preserve_standin_accounts():
    """Keep the stand-in's login file as the read-only import source; never overwrite an earlier copy."""
    if ACCOUNTS_PATH.exists() and not STANDIN_ACCOUNTS_PATH.exists():
        ACCOUNTS_PATH.rename(STANDIN_ACCOUNTS_PATH)
        STANDIN_ACCOUNTS_PATH.chmod(0o400)
    ACCOUNTS_PATH.unlink(missing_ok=True)


def import_logins_and_pin_baseline():
    """Once per reset: import the stand-in logins into the backend, then pin the v1 import baseline snapshot."""
    if STANDIN_ACCOUNTS_PATH.exists() and not SDK_IMPORTED_MARKER.exists():
        run_operator(["sdk-import", str(STANDIN_ACCOUNTS_PATH)], environment=worker_environment())
        SDK_IMPORTED_MARKER.touch()
        print("up: stand-in SDK logins imported")
    if not BASELINE_SNAPSHOT_MARKER.exists():
        run_operator(["backup", "snapshot", "--name", "v1 import baseline", "--pin", "--reason", "harness reset baseline"])
        BASELINE_SNAPSHOT_MARKER.touch()
        print("up: pinned snapshot 'v1 import baseline' taken")


def wait_for_api():
    deadline = time.monotonic() + API_START_TIMEOUT_SECONDS
    url = f"http://{API_ADDRESS}/"
    body = urllib.parse.urlencode({"payload": '{"mid":20480}'}).encode("utf-8")
    while time.monotonic() < deadline:
        request = urllib.request.Request(
            url,
            data=body,
            headers={"Content-Type": "application/x-www-form-urlencoded"},
            method="POST",
        )
        try:
            with urllib.request.urlopen(request, timeout=2) as reply:
                if reply.status == 200:
                    return True
        except (urllib.error.URLError, OSError):
            pass
        time.sleep(0.2)
    return False


def wait_for_port(host, port, timeout_seconds):
    deadline = time.monotonic() + timeout_seconds
    while time.monotonic() < deadline:
        if port_open(host, port):
            return
        time.sleep(0.2)
    raise SystemExit(f"up: nothing listening on {host}:{port}")


def command_up():
    ensure_layout()
    secrets_value = load_secrets()
    if not cluster_running():
        start_cluster()
        print("up: postgres cluster started")
    for service in SERVICES:
        name = service["name"]
        if process_alive(name):
            print(f"up: {name} already running")
            continue
        if port_open(service["listen_host"] or "127.0.0.1", service["port"]):
            raise SystemExit(
                f"up: port {service['port']} for {name} is held by another process"
            )
        if service["kind"] == "agent":
            write_agent_config()
        start_service(service, secrets_value)
        print(f"up: {name} started")
    start_backend_through_agent()
    restore_apk_res_path()
    if not wait_for_api():
        raise SystemExit("up: gxb-api did not answer MID 20480")
    import_logins_and_pin_baseline()
    wait_for_port(PLAYTEST_BIND, ASSET_FRONT_PORT, ASSET_INDEX_TIMEOUT_SECONDS)
    wait_for_port(PLAYTEST_BIND, SDK_PORT, API_START_TIMEOUT_SECONDS)
    print(f"up: gxb-api answering on {API_ADDRESS}, lan host {LAN_HOST}")


def restore_apk_res_path():
    settings_path = OTA_ROOT_DIRECTORY / "settings.json"
    if not settings_path.exists() or not APK_RES_DIRECTORY.is_dir():
        return
    settings = json.loads(settings_path.read_text(encoding="utf-8"))
    if settings.get("apk_res_path"):
        return
    settings["apk_res_path"] = str(APK_RES_DIRECTORY)
    write_json_atomic(settings_path, settings)
    print(f"up: apk_res_path set to {APK_RES_DIRECTORY}")


def command_down():
    ensure_layout()
    results = []
    for name in reversed(SERVICE_NAMES):
        results.append(f"{name} {stop_service(name)}")
    results.append(f"postgres {stop_cluster()}")
    print("down: " + ", ".join(results))


def command_status():
    ensure_layout()
    backend = backend_state()
    for service in SERVICES:
        state = "alive" if process_alive(service["name"]) else "dead"
        port = service["port"] if service["port"] is not None else "-"
        print(f"{service['name']} {state} port={port}")
    postgres_state = "alive" if cluster_running() else "dead"
    print(f"postgres {postgres_state} port={POSTGRES_PORT}")
    print(
        f"backend commit={backend.get('commit', 'unknown')} "
        f"tree={backend.get('tree', 'unknown')}"
    )
    print(f"lan_host={LAN_HOST}")


def command_logs(arguments):
    if not arguments:
        raise SystemExit("usage: harness.py logs <service> [-f]")
    name = arguments[0]
    if name not in SERVICE_NAMES:
        raise SystemExit(f"unknown service {name}; services: {', '.join(SERVICE_NAMES)}")
    path = log_path(name)
    if not path.exists():
        raise SystemExit(f"no log for {name}")
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    for line in lines[-LOG_LINE_COUNT:]:
        print(line)
    if "-f" in arguments[1:]:
        with open(path, "r", encoding="utf-8", errors="replace") as handle:
            handle.seek(0, os.SEEK_END)
            try:
                while True:
                    line = handle.readline()
                    if line:
                        print(line, end="", flush=True)
                    else:
                        time.sleep(0.2)
            except KeyboardInterrupt:
                return


def command_snapshot(arguments):
    """Unpinned snapshot of the live database before a planned wipe; skipped when the agent is not running."""
    reason = " ".join(arguments) or "harness redeploy"
    host, port = AGENT_LISTEN.rsplit(":", 1)
    if not port_open(host, int(port)):
        print("snapshot: agent not running, nothing taken", file=sys.stderr)
        return
    run_operator(["login"], (operator_password(),))
    run_operator(["backup", "snapshot", "--name", "pre-redeploy", "--reason", reason])
    print("snapshot: pre-redeploy snapshot taken")


def main(arguments):
    if len(arguments) < 1:
        raise SystemExit(
            "usage: harness.py reset <backend tree> | upgrade <backend tree> | up | down | status | snapshot [reason] | logs <service> [-f]"
        )
    command = arguments[0]
    if command == "reset":
        command_reset(arguments[1:])
        return
    if command == "upgrade":
        command_upgrade(arguments[1:])
        return
    if command == "up":
        command_up()
        return
    if command == "down":
        command_down()
        return
    if command == "status":
        command_status()
        return
    if command == "logs":
        command_logs(arguments[1:])
        return
    if command == "snapshot":
        command_snapshot(arguments[1:])
        return
    raise SystemExit(f"unknown command {command}")


if __name__ == "__main__":
    main(sys.argv[1:])
