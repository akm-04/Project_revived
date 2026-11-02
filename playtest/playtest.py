#!/usr/bin/env python3
"""Temporary v2 real-client playtest harness: build, reset, start and stop its own stack."""

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

WORKSPACE = Path(__file__).resolve().parents[3]
PLAYTEST_HOME = Path(os.environ.get("PLAYTEST_HOME", WORKSPACE / "tmp" / "playtest"))
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
ASSET_TREE = Path(
    os.environ.get(
        "PLAYTEST_ASSET_TREE", WORKSPACE / "tmp" / "virtualclient" / "update-tree"
    )
)

API_HOST = "127.0.0.1"
API_PORT = 18953
REALTIME_HOST = "0.0.0.0"
REALTIME_PORT = 18954
SDK_PORT = 18955
ASSET_FRONT_PORT = 18956
POSTGRES_PORT = 18957
API_ADDRESS = f"{API_HOST}:{API_PORT}"
REALTIME_ADDRESS = f"{REALTIME_HOST}:{REALTIME_PORT}"
DATABASE_NAME = "gxb_playtest"
BINARY_NAMES = ("gxb-api", "gxb-combat-worker", "gxb-worker", "gxb-realtime")
LOG_LINE_COUNT = 50
API_START_TIMEOUT_SECONDS = 60
STOP_TIMEOUT_SECONDS = 10

STATE_DIRECTORY = PLAYTEST_HOME / "state"
LOG_DIRECTORY = PLAYTEST_HOME / "logs"
RUN_DIRECTORY = PLAYTEST_HOME / "run"
BINARY_DIRECTORY = PLAYTEST_HOME / "bin"
NEW_BINARY_DIRECTORY = PLAYTEST_HOME / "bin.new"
OLD_BINARY_DIRECTORY = PLAYTEST_HOME / "bin.old"
MEDIA_DIRECTORY = PLAYTEST_HOME / "media"
POSTGRES_DATA_DIRECTORY = PLAYTEST_HOME / "pg"
POSTGRES_LOG = LOG_DIRECTORY / "postgres.log"
SECRETS_PATH = STATE_DIRECTORY / "secrets.json"
BACKEND_STATE_PATH = STATE_DIRECTORY / "backend.json"
ACCOUNTS_PATH = STATE_DIRECTORY / "accounts.json"

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
            "GXB_PUBLIC_ENGINE_URL": f"{ENGINE_ORIGIN}/engine",
            "GXB_CLIENT_LOG_URL": f"{ENGINE_ORIGIN}/client-log",
            "GXB_REALTIME_PUBLIC_HOST": LAN_HOST,
            "GXB_REALTIME_PUBLIC_PORT": str(REALTIME_PORT),
            "GXB_CREDENTIAL_DIGEST_SECRET": secrets_value["credential_digest_secret"],
            "GXB_GAMEPLAY_BEARER_SECRET": secrets_value["gameplay_bearer_secret"],
            "GXB_REDEEM_DIGEST_SECRET": secrets_value["redeem_digest_secret"],
            "GXB_DERIVATION_KEY_ID": secrets_value["derivation_key_id"],
            "GXB_PROFILE_MEDIA_ROOT": str(MEDIA_DIRECTORY),
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
            "GXB_REALTIME_PUBLIC_HOST": LAN_HOST,
            "GXB_REALTIME_PUBLIC_PORT": str(REALTIME_PORT),
            "GXB_CREDENTIAL_DIGEST_SECRET": secrets_value["credential_digest_secret"],
            "GXB_GAMEPLAY_BEARER_SECRET": secrets_value["gameplay_bearer_secret"],
            "GXB_DERIVATION_KEY_ID": secrets_value["derivation_key_id"],
        }
    )


def worker_environment():
    return child_environment({"GXB_POSTGRES_DSN": DATABASE_DSN})


def sdk_environment(secrets_value):
    return child_environment(
        {
            "PLAYTEST_HOME": str(PLAYTEST_HOME),
            "PLAYTEST_TOOLS": str(PLAYTEST_TOOLS),
            "PLAYTEST_BIND": PLAYTEST_BIND,
            "GXB_POSTGRES_DSN": DATABASE_DSN,
            "GXB_CREDENTIAL_DIGEST_SECRET": secrets_value["credential_digest_secret"],
        }
    )


def asset_front_environment():
    return child_environment(
        {
            "PLAYTEST_HOME": str(PLAYTEST_HOME),
            "PLAYTEST_ASSET_TREE": str(ASSET_TREE),
            "PLAYTEST_BIND": PLAYTEST_BIND,
            "PLAYTEST_ENGINE_ORIGIN": ENGINE_ORIGIN,
        }
    )


def service_command(service):
    if service["kind"] == "binary":
        return [str(BINARY_DIRECTORY / service["name"])], str(BINARY_DIRECTORY)
    script = Path(__file__).resolve().parent / service["script"]
    return [sys.executable, "-I", "-B", "-u", str(script)], str(script.parent)


def service_environment(name, secrets_value):
    if name == "gxb-api":
        return api_environment(secrets_value)
    if name == "gxb-realtime":
        return realtime_environment(secrets_value)
    if name == "gxb-worker":
        return worker_environment()
    if name == "gxb-sdk":
        return sdk_environment(secrets_value)
    return asset_front_environment()


SERVICES = (
    {
        "name": "gxb-api",
        "kind": "binary",
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
        "name": "gxb-sdk",
        "kind": "python",
        "script": "sdk.py",
        "port": SDK_PORT,
        "listen_host": PLAYTEST_BIND,
    },
    {
        "name": "gxb-asset-front",
        "kind": "python",
        "script": "asset_front.py",
        "port": ASSET_FRONT_PORT,
        "listen_host": PLAYTEST_BIND,
    },
)
SERVICE_NAMES = tuple(service["name"] for service in SERVICES)

EXPECTED_COMMANDLINE = {
    "gxb-api": "gxb-api",
    "gxb-worker": "gxb-worker",
    "gxb-realtime": "gxb-realtime",
    "gxb-sdk": "sdk.py",
    "gxb-asset-front": "asset_front.py",
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


def command_reset(arguments):
    if len(arguments) != 1:
        raise SystemExit("usage: playtest.py reset <backend tree>")
    tree = Path(arguments[0]).resolve()
    if not (tree / "go.mod").is_file():
        raise SystemExit(f"not a backend tree: {tree}")
    ensure_layout()
    command_down()
    build_binaries(tree)
    start_cluster()
    prepare_database(tree)
    ACCOUNTS_PATH.unlink(missing_ok=True)
    head = subprocess.run(
        ["git", "-C", str(tree), "rev-parse", "HEAD"],
        capture_output=True,
        text=True,
        check=True,
    ).stdout.strip()
    write_json_atomic(
        BACKEND_STATE_PATH,
        {"tree": str(tree), "commit": head, "database": DATABASE_NAME},
    )
    print(f"reset: built {', '.join(BINARY_NAMES)} into {BINARY_DIRECTORY}")
    print(f"reset: database {DATABASE_NAME} migrated, deployed and prepared")
    print(f"reset: backend {head} at {tree}")


def wait_for_api():
    deadline = time.monotonic() + API_START_TIMEOUT_SECONDS
    url = "http://127.0.0.1:18953/"
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
        start_service(service, secrets_value)
        print(f"up: {name} started")
    if not wait_for_api():
        raise SystemExit("up: gxb-api did not answer /health/live")
    print(f"up: gxb-api answering on {API_ADDRESS}, lan host {LAN_HOST}")


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
        raise SystemExit("usage: playtest.py logs <service> [-f]")
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


def main(arguments):
    if len(arguments) < 1:
        raise SystemExit(
            "usage: playtest.py reset <backend tree> | up | down | status | logs <service> [-f]"
        )
    command = arguments[0]
    if command == "reset":
        command_reset(arguments[1:])
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
    raise SystemExit(f"unknown command {command}")


if __name__ == "__main__":
    main(sys.argv[1:])
