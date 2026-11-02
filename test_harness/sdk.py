#!/usr/bin/env python3
"""Playtest SDK: v1-compatible register/login/anonymous replies with real v2 account sessions."""

import hashlib
import hmac
import json
import os
import secrets
import subprocess
import sys
import threading
import time
import urllib.parse
import uuid
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path

WORKSPACE = Path(__file__).resolve().parents[1]
PLAYTEST_HOME = Path(os.environ.get("PLAYTEST_HOME", Path(__file__).resolve().parent / "runtime"))
PLAYTEST_TOOLS = Path(
    os.environ.get(
        "PLAYTEST_TOOLS",
        WORKSPACE / "tmp" / "tools_r4_accept" / "gxb-e2e-self-contained" / "bin",
    )
)
DIGEST_SECRET = os.environ.get("GXB_CREDENTIAL_DIGEST_SECRET", "")
BIND_ADDRESS = os.environ.get("PLAYTEST_BIND", "127.0.0.1")
LISTEN_PORT = 18955
DATABASE_NAME = "gxb_playtest"
POSTGRES_PORT = 18957
PBKDF2_ITERATIONS = 200_000
PASSWORD_ALGORITHM = "pbkdf2-sha256"
AUTH_PROFILE = "SID_LOGIN_TOKEN_PAIR"

STATE_DIRECTORY = PLAYTEST_HOME / "state"
ACCOUNTS_PATH = STATE_DIRECTORY / "accounts.json"

REGISTER_MID = "65282"
LOGIN_MID = "65281"
ANONYMOUS_MID = "65284"
PACKAGE_INFO_MID = "65305"
SESSION_COOKIE = "QQWSID"

STATE_LOCK = threading.Lock()


def log(message):
    print(message, file=sys.stderr, flush=True)


def empty_accounts():
    return {"version": 1, "accounts": {}, "logins": {}, "devices": {}}


def load_accounts():
    try:
        value = json.loads(ACCOUNTS_PATH.read_text(encoding="utf-8"))
    except (FileNotFoundError, json.JSONDecodeError):
        return empty_accounts()
    if not isinstance(value, dict):
        return empty_accounts()
    for key, fallback in (
        ("accounts", {}),
        ("logins", {}),
        ("devices", {}),
    ):
        if not isinstance(value.get(key), dict):
            value[key] = fallback
    return value


def save_accounts(accounts):
    STATE_DIRECTORY.mkdir(parents=True, exist_ok=True)
    temporary = ACCOUNTS_PATH.with_name(f"{ACCOUNTS_PATH.name}.{os.getpid()}.tmp")
    descriptor = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(descriptor, "w", encoding="utf-8") as handle:
        json.dump(accounts, handle, indent=2, sort_keys=True)
        handle.write("\n")
        handle.flush()
        os.fsync(handle.fileno())
    os.replace(temporary, ACCOUNTS_PATH)
    os.chmod(ACCOUNTS_PATH, 0o600)


def normalize_login(login):
    return str(login or "").strip().casefold()


def password_record(password):
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt, PBKDF2_ITERATIONS
    )
    return {
        "algorithm": PASSWORD_ALGORITHM,
        "iterations": PBKDF2_ITERATIONS,
        "salt": salt.hex(),
        "hash": digest.hex(),
    }


def verify_password(record, password):
    try:
        if record.get("algorithm") != PASSWORD_ALGORITHM:
            return False
        iterations = int(record.get("iterations", PBKDF2_ITERATIONS))
        salt = bytes.fromhex(str(record["salt"]))
        expected = bytes.fromhex(str(record["hash"]))
    except (KeyError, TypeError, ValueError):
        return False
    actual = hashlib.pbkdf2_hmac(
        "sha256", password.encode("utf-8"), salt, iterations
    )
    return hmac.compare_digest(actual, expected)


def credential_digest(secret, label, raw):
    if len(secret) < 16 or not label or not raw:
        raise ValueError("credential digest input invalid")
    digest = hmac.new(secret.encode("utf-8"), digestmod=hashlib.sha256)
    digest.update(b"gxb-v2/credential/v1\x00")
    digest.update(label.encode("utf-8"))
    digest.update(b"\x00")
    digest.update(raw.encode("utf-8"))
    return digest.hexdigest()


def sql_literal(value):
    return "'" + str(value).replace("'", "''") + "'"


def issue_database_session(account_uid, session_id, sid, token):
    sid_digest = credential_digest(DIGEST_SECRET, "sid", sid)
    token_digest = credential_digest(DIGEST_SECRET, "login_token", token)
    statements = [
        "BEGIN;",
        "INSERT INTO accounts(account_id,account_uid,status,created_at)"
        f" VALUES ({sql_literal(account_uid)}::uuid,{sql_literal(account_uid)},'ACTIVE',clock_timestamp())"
        " ON CONFLICT (account_id) DO NOTHING;",
        "INSERT INTO account_sessions(session_id,account_id,auth_profile,issued_at,last_activity_at)"
        f" VALUES ({sql_literal(session_id)}::uuid,{sql_literal(account_uid)}::uuid,"
        f"{sql_literal(AUTH_PROFILE)},clock_timestamp(),clock_timestamp());",
    ]
    for kind, digest in (("SID", sid_digest), ("LOGIN_TOKEN", token_digest)):
        credential_id = str(uuid.uuid4())
        statements.append(
            "INSERT INTO account_session_credentials(credential_id,session_id,kind,digest,issued_at)"
            f" VALUES ({sql_literal(credential_id)}::uuid,{sql_literal(session_id)}::uuid,"
            f"{sql_literal(kind)},decode({sql_literal(digest)},'hex'),clock_timestamp());"
        )
    statements.append("COMMIT;")
    command = [
        str(PLAYTEST_TOOLS / "psql"),
        "-X",
        "-q",
        "-v",
        "ON_ERROR_STOP=1",
        "-h",
        str(PLAYTEST_HOME / "pg"),
        "-p",
        str(POSTGRES_PORT),
        "-U",
        "postgres",
        "-d",
        DATABASE_NAME,
        "-f",
        "-",
    ]
    result = subprocess.run(
        command,
        input="\n".join(statements) + "\n",
        text=True,
        capture_output=True,
        check=False,
    )
    if result.returncode != 0:
        log(f"sdk session insert failed: {result.stderr.strip()[:300]}")
        return False
    return True


def ensure_session(accounts, account):
    if account.get("session"):
        return True
    session_id = str(uuid.uuid4())
    sid = "pl-sid-" + uuid.uuid4().hex
    token = "pl-login-" + uuid.uuid4().hex
    if not issue_database_session(account["uid"], session_id, sid, token):
        return False
    account["session"] = {"session_id": session_id, "sid": sid, "token": token}
    save_accounts(accounts)
    log(f"sdk session issued uid={account['uid']}")
    return True


def create_guest(accounts, device):
    uid = str(uuid.uuid4())
    account = {
        "uid": uid,
        "login": None,
        "username": "guest-" + uid[:8],
        "account_type": "guest",
        "created_at": int(time.time()),
        "password": None,
        "session": None,
    }
    accounts["accounts"][uid] = account
    if device:
        accounts["devices"][device] = uid
    return account


def find_account_for_request(accounts, payload):
    device = payload.get("device_id")
    if isinstance(device, str) and device:
        uid = accounts["devices"].get(device)
        if uid in accounts["accounts"]:
            return accounts["accounts"][uid]
    return create_guest(accounts, device if isinstance(device, str) else "")


def find_account_by_cookie(accounts, cookie_header):
    for part in (cookie_header or "").split(";"):
        name, separator, value = part.strip().partition("=")
        if not separator or name != SESSION_COOKIE:
            continue
        for account in accounts["accounts"].values():
            session = account.get("session") or {}
            if session.get("sid") == value:
                return account
    return None


def sdk_identity(account):
    session = account["session"]
    username = account.get("username") or account.get("login") or account["uid"]
    return {
        "uid": account["uid"],
        "sid": session["sid"],
        "access_token": session["token"],
        "token": session["token"],
        "username": username,
        "nickname": username,
        "is_new": 0,
        "UID": account["uid"],
        "SID": session["sid"],
        "UNAME": username,
        "TOKEN": session["token"],
    }


def cookies_for(identity):
    return [
        ("QQWSID", identity["sid"]),
        ("QQWUID", identity["uid"]),
        ("QQWUNAME", identity["username"]),
        ("QQWTOKEN", identity["token"]),
    ]


def success(identity=None):
    data = {}
    body = {
        "status": 1,
        "code": 1,
        "error_code": 0,
        "msg": "success",
        "data": data,
        "package_info": {},
    }
    for key, value in (identity or {}).items():
        body[key] = value
        data[key] = value
    return body


def sdk_error(message, code=1):
    return {
        "status": 0,
        "code": 0,
        "error_code": int(code),
        "error_msg": str(message),
        "msg": str(message),
        "data": {},
        "package_info": {},
    }


def read_request_body(handler):
    length = handler.headers.get("Content-Length")
    if not length:
        return b""
    try:
        return handler.rfile.read(int(length))
    except (ValueError, OSError):
        return b""


def parse_request_body(raw):
    try:
        value = json.loads(raw)
        if isinstance(value, dict):
            return value
    except (json.JSONDecodeError, UnicodeDecodeError):
        pass
    try:
        form = urllib.parse.parse_qs(raw.decode("utf-8", "replace"))
        value = json.loads(form.get("payload", [""])[0])
    except (json.JSONDecodeError, UnicodeDecodeError):
        return None
    return value if isinstance(value, dict) else None


class SdkHandler(BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"

    def log_message(self, format, *arguments):
        return

    def do_POST(self):
        path = urllib.parse.urlsplit(self.path).path.rstrip("/")
        if path == "/server/mobile_api_new":
            self.handle_mobile_api()
            return
        if path == "/home_api/upload_sdk_logs":
            log("sdk upload_sdk_logs")
            self.write_json({"error_code": 0})
            return
        self.write_empty(404)

    def handle_mobile_api(self):
        body = parse_request_body(read_request_body(self))
        if body is None:
            log("sdk mid=malformed")
            self.write_json(success())
            return
        mid = str(body.get("mid", ""))
        log(f"sdk mid={mid}")
        base_mid = mid[:-2] if mid.endswith(".0") else mid
        payload = body.get("payload")
        if not isinstance(payload, dict):
            payload = {}
        with STATE_LOCK:
            if base_mid == REGISTER_MID:
                self.handle_register(payload)
                return
            if base_mid == LOGIN_MID:
                self.handle_login(payload)
                return
            if base_mid in (ANONYMOUS_MID, PACKAGE_INFO_MID):
                self.handle_anonymous(payload)
                return
        self.write_json(success())

    def handle_register(self, payload):
        login = str(payload.get("login_email", ""))
        password = str(payload.get("password", ""))
        repassword = str(payload.get("repassword", ""))
        if not login or not password or password != repassword:
            self.write_json(sdk_error("Invalid registration request"))
            return
        accounts = load_accounts()
        normalized = normalize_login(login)
        uid = accounts["logins"].get(normalized)
        existing = accounts["accounts"].get(uid) if uid else None
        if existing is not None:
            if isinstance(existing.get("password"), dict) and verify_password(
                existing["password"], password
            ):
                self.write_identity(
                    success(
                        {
                            "uid": existing["uid"],
                            "login_email": str(existing.get("login") or login),
                        }
                    )
                )
                return
            self.write_json(sdk_error("Account already exists"))
            return
        account = {
            "uid": str(uuid.uuid4()),
            "login": login,
            "username": login,
            "account_type": "normal",
            "created_at": int(time.time()),
            "password": password_record(password),
            "session": None,
        }
        accounts["accounts"][account["uid"]] = account
        accounts["logins"][normalized] = account["uid"]
        save_accounts(accounts)
        self.write_identity(
            success({"uid": account["uid"], "login_email": login})
        )

    def handle_login(self, payload):
        login = str(payload.get("login_email", ""))
        password = str(payload.get("password", ""))
        accounts = load_accounts()
        uid = accounts["logins"].get(normalize_login(login))
        account = accounts["accounts"].get(uid) if uid else None
        if account is None or account.get("account_type") == "guest":
            self.write_json(sdk_error("Invalid account or password"))
            return
        record = account.get("password")
        if not isinstance(record, dict) or not verify_password(record, password):
            self.write_json(sdk_error("Invalid account or password"))
            return
        if not ensure_session(accounts, account):
            self.write_error(503, "session unavailable")
            return
        identity = sdk_identity(account)
        identity["login_email"] = login
        self.write_identity(success(identity), cookies_for(identity))

    def handle_anonymous(self, payload):
        accounts = load_accounts()
        account = find_account_by_cookie(accounts, self.headers.get("Cookie"))
        if account is None:
            account = find_account_for_request(accounts, payload)
        if not ensure_session(accounts, account):
            self.write_error(503, "session unavailable")
            return
        identity = sdk_identity(account)
        self.write_identity(success(identity), cookies_for(identity))

    def write_identity(self, body, cookies=None):
        headers = [
            ("Set-Cookie", f"{name}={value}; Path=/") for name, value in cookies or []
        ]
        self.write_json(body, headers)

    def write_json(self, value, extra_headers=None):
        data = json.dumps(value, ensure_ascii=False).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Cache-Control", "no-cache, no-store")
        for name, header_value in extra_headers or []:
            self.send_header(name, header_value)
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def write_error(self, status, message):
        data = message.encode("utf-8")
        self.send_response(status)
        self.send_header("Content-Type", "text/plain; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def write_empty(self, status):
        self.send_response(status)
        self.send_header("Content-Length", "0")
        self.end_headers()


def main():
    if len(DIGEST_SECRET) < 16:
        raise SystemExit("sdk: GXB_CREDENTIAL_DIGEST_SECRET must be set")
    server = ThreadingHTTPServer((BIND_ADDRESS, LISTEN_PORT), SdkHandler)
    server.daemon_threads = True
    log(f"sdk listening on {BIND_ADDRESS}:{LISTEN_PORT}, accounts {ACCOUNTS_PATH}")
    server.serve_forever()


if __name__ == "__main__":
    main()
