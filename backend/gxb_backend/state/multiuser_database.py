"""Multi-user account/session/player persistence for v0.8.0.

The physical JSON layout follows Pass 22's logical ownership map while keeping
all writes inspectable and atomic.  It is intentionally small/local-server
infrastructure, not a claim about the original Carol Games SQL schema.
"""

from __future__ import annotations

import hashlib
import hmac
import json
import os
import secrets
import time
from dataclasses import asdict
from pathlib import Path
from typing import Any

from .account import AccountIdentity
from .defaults import default_account, default_player
from .hero_repository import HeroRepository
from .inventory_repository import InventoryRepository
from .player_database import JsonPlayerDatabase
from .player_state import PlayerState
from .profiles import apply_profile, make_fresh_player
from .world_repository import WorldRepository


SANDBOX_UID = "13371337"
SANDBOX_SID = "1993b58bfd1b93499ae19477b236d4a2"
SANDBOX_TOKEN = "local_token"
SANDBOX_LOGIN = "__anonymous_sandbox__"
SANDBOX_USERNAME = "AdminRoot"

PBKDF2_ITERATIONS = 200_000


def _now() -> int:
    return int(time.time())


def _normalize_login(value: Any) -> str:
    return str(value or "").strip().casefold()


def _atomic_write_json(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    tmp = path.with_suffix(path.suffix + ".tmp")
    tmp.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    os.replace(tmp, path)


def _load_json(path: Path, default: Any) -> Any:
    if not path.exists():
        return default
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except Exception:
        return default


def _password_record(password: str) -> dict[str, Any]:
    salt = secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, PBKDF2_ITERATIONS)
    return {
        "algorithm": "pbkdf2-sha256",
        "iterations": PBKDF2_ITERATIONS,
        "salt": salt.hex(),
        "hash": digest.hex(),
    }


def _verify_password(record: dict[str, Any], password: str) -> bool:
    try:
        if record.get("algorithm") != "pbkdf2-sha256":
            return False
        iterations = int(record.get("iterations", PBKDF2_ITERATIONS))
        salt = bytes.fromhex(str(record["salt"]))
        expected = bytes.fromhex(str(record["hash"]))
    except Exception:
        return False
    actual = hashlib.pbkdf2_hmac("sha256", password.encode("utf-8"), salt, iterations)
    return hmac.compare_digest(actual, expected)


class MultiUserDatabase:
    SCHEMA_VERSION = 1

    def __init__(self, root: Path, data_dir: Path) -> None:
        self.root = Path(root)
        self.data_dir = Path(data_dir)
        self.accounts_dir = self.root / "accounts"
        self.sessions_dir = self.root / "sessions"
        self.players_dir = self.root / "players"
        self.indexes_dir = self.root / "indexes"
        self.account_index_path = self.indexes_dir / "account_by_login.json"
        self.account_player_path = self.indexes_dir / "player_by_account_region.json"
        self.session_token_index_path = self.indexes_dir / "session_by_token.json"
        self.region_counter_path = self.indexes_dir / "region_player_serial.json"
        self.counters_path = self.indexes_dir / "counters.json"
        for path in (self.accounts_dir, self.sessions_dir, self.players_dir, self.indexes_dir):
            path.mkdir(parents=True, exist_ok=True)

    # ------------------------------------------------------------------
    # Account persistence
    # ------------------------------------------------------------------
    def account_path(self, uid: str) -> Path:
        return self.accounts_dir / f"{uid}.json"

    def load_account_record(self, uid: str) -> dict[str, Any] | None:
        data = _load_json(self.account_path(str(uid)), None)
        return data if isinstance(data, dict) else None

    def save_account_record(self, record: dict[str, Any]) -> None:
        _atomic_write_json(self.account_path(str(record["uid"])), record)

    def lookup_account_by_login(self, login: str) -> dict[str, Any] | None:
        index = _load_json(self.account_index_path, {})
        uid = index.get(_normalize_login(login)) if isinstance(index, dict) else None
        return self.load_account_record(str(uid)) if uid is not None else None

    def _index_account_login(self, login: str, uid: str) -> None:
        index = _load_json(self.account_index_path, {})
        if not isinstance(index, dict):
            index = {}
        index[_normalize_login(login)] = str(uid)
        _atomic_write_json(self.account_index_path, index)

    def _allocate_uid(self) -> str:
        counters = _load_json(self.counters_path, {})
        if not isinstance(counters, dict):
            counters = {}
        current = int(counters.get("next_uid", 20_000_001))
        while self.account_path(str(current)).exists() or str(current) == SANDBOX_UID:
            current += 1
        counters["next_uid"] = current + 1
        _atomic_write_json(self.counters_path, counters)
        return str(current)

    def ensure_sandbox_account(self) -> dict[str, Any]:
        existing = self.load_account_record(SANDBOX_UID)
        if existing:
            return existing
        record = {
            "schema": self.SCHEMA_VERSION,
            "uid": SANDBOX_UID,
            "login": SANDBOX_LOGIN,
            "normalized_login": SANDBOX_LOGIN,
            "username": SANDBOX_USERNAME,
            "account_type": "anonymous_sandbox",
            "created_at": _now(),
            "password": None,
            "metadata": {"compatibility_profile": "established"},
        }
        self.save_account_record(record)
        self._index_account_login(SANDBOX_LOGIN, SANDBOX_UID)
        return record

    def register_account(self, login: str, password: str) -> tuple[dict[str, Any] | None, str]:
        """Create an SDK credential account.

        Returns ``(record, status)`` where status is one of ``created``,
        ``existing_same_credentials`` or ``conflict``.  Treating an exact retry
        as idempotent is useful because the SDK may resend requests after a
        dropped response.
        """
        normalized = _normalize_login(login)
        existing = self.lookup_account_by_login(login)
        if existing:
            pwd = existing.get("password")
            if isinstance(pwd, dict) and _verify_password(pwd, password):
                return existing, "existing_same_credentials"
            return None, "conflict"

        uid = self._allocate_uid()
        record = {
            "schema": self.SCHEMA_VERSION,
            "uid": uid,
            "login": str(login),
            "normalized_login": normalized,
            "username": str(login),
            "account_type": "normal",
            "created_at": _now(),
            "password": _password_record(password),
            "metadata": {},
        }
        self.save_account_record(record)
        self._index_account_login(login, uid)
        return record, "created"

    def verify_credentials(self, login: str, password: str) -> dict[str, Any] | None:
        account = self.lookup_account_by_login(login)
        if not account or account.get("account_type") == "anonymous_sandbox":
            return None
        pwd = account.get("password")
        if not isinstance(pwd, dict) or not _verify_password(pwd, password):
            return None
        return account

    # ------------------------------------------------------------------
    # Sessions
    # ------------------------------------------------------------------
    def session_path(self, sid: str) -> Path:
        # Generated SIDs are hex. The fixed sandbox SID is also safe.
        return self.sessions_dir / f"{sid}.json"

    def issue_session(
        self,
        account: dict[str, Any],
        *,
        sid: str | None = None,
        token: str | None = None,
        device: dict[str, Any] | None = None,
    ) -> dict[str, Any]:
        sid = sid or secrets.token_hex(16)
        token = token or secrets.token_urlsafe(24)
        now = _now()
        record = {
            "schema": self.SCHEMA_VERSION,
            "sid": sid,
            "token": token,
            "uid": str(account["uid"]),
            "username": str(account.get("username") or account.get("login") or account["uid"]),
            "issued_at": now,
            "last_used_at": now,
            "revoked": False,
            "device": dict(device or {}),
        }
        _atomic_write_json(self.session_path(sid), record)
        token_index = _load_json(self.session_token_index_path, {})
        if not isinstance(token_index, dict):
            token_index = {}
        token_index[token] = sid
        _atomic_write_json(self.session_token_index_path, token_index)
        return record

    def ensure_sandbox_session(self) -> dict[str, Any]:
        session = self.resolve_session(sid=SANDBOX_SID, token=SANDBOX_TOKEN, touch=False)
        if session:
            return session
        account = self.ensure_sandbox_account()
        return self.issue_session(account, sid=SANDBOX_SID, token=SANDBOX_TOKEN)

    def resolve_session(
        self,
        *,
        sid: str | None = None,
        token: str | None = None,
        touch: bool = True,
    ) -> dict[str, Any] | None:
        record: dict[str, Any] | None = None
        if sid:
            raw = _load_json(self.session_path(str(sid)), None)
            if isinstance(raw, dict):
                record = raw
        elif token:
            token_index = _load_json(self.session_token_index_path, {})
            session_sid = token_index.get(str(token)) if isinstance(token_index, dict) else None
            if session_sid:
                raw = _load_json(self.session_path(str(session_sid)), None)
                if isinstance(raw, dict):
                    record = raw

        if not record or record.get("revoked"):
            return None
        if sid and str(record.get("sid")) != str(sid):
            return None
        if token and str(record.get("token")) != str(token):
            return None
        if touch:
            record["last_used_at"] = _now()
            _atomic_write_json(self.session_path(str(record["sid"])), record)
        return record

    @staticmethod
    def identity_from_session(session: dict[str, Any]) -> AccountIdentity:
        return AccountIdentity(
            uid=str(session.get("uid", "")),
            sid=str(session.get("sid", "")),
            token=str(session.get("token", "")),
            username=str(session.get("username", session.get("uid", ""))),
        )

    # ------------------------------------------------------------------
    # Player ownership/indexes
    # ------------------------------------------------------------------
    def player_path(self, player_id: str) -> Path:
        return self.players_dir / str(player_id) / "player.json"

    def _account_player_index(self) -> dict[str, dict[str, str]]:
        raw = _load_json(self.account_player_path, {})
        if not isinstance(raw, dict):
            return {}
        out: dict[str, dict[str, str]] = {}
        for uid, mapping in raw.items():
            if isinstance(mapping, dict):
                out[str(uid)] = {str(region): str(pid) for region, pid in mapping.items()}
        return out

    def player_id_for_account_region(self, uid: str, region: int) -> str | None:
        mapping = self._account_player_index().get(str(uid), {})
        value = mapping.get(str(int(region)))
        return str(value) if value is not None else None

    def set_account_region_player(self, uid: str, region: int, player_id: str) -> None:
        index = self._account_player_index()
        index.setdefault(str(uid), {})[str(int(region))] = str(player_id)
        _atomic_write_json(self.account_player_path, index)

    def move_account_region_player(self, uid: str, old_region: int, new_region: int, player_id: str) -> None:
        index = self._account_player_index()
        mapping = index.setdefault(str(uid), {})
        old_key = str(int(old_region))
        if mapping.get(old_key) == str(player_id):
            mapping.pop(old_key, None)
        mapping[str(int(new_region))] = str(player_id)
        _atomic_write_json(self.account_player_path, index)

    def account_player_ids(self, uid: str) -> list[str]:
        mapping = self._account_player_index().get(str(uid), {})
        return [str(pid) for _region, pid in sorted(mapping.items(), key=lambda kv: int(kv[0]))]

    def region_player_count(self, region: int) -> int:
        region_s = str(int(region))
        return sum(1 for mapping in self._account_player_index().values() if mapping.get(region_s))

    def _allocate_player_id(self, region: int) -> str:
        region = int(region)
        counters = _load_json(self.region_counter_path, {})
        if not isinstance(counters, dict):
            counters = {}
        serial = max(1, int(counters.get(str(region), 1)))

        # Player IDs observed throughout Lua encode region in the high digits;
        # e.g. xyd.getPlayerRegion() effectively derives region from /100000.
        while True:
            player_id = str(region * 100_000 + serial)
            if not self.player_path(player_id).exists():
                break
            serial += 1
        counters[str(region)] = serial + 1
        _atomic_write_json(self.region_counter_path, counters)
        return player_id

    def save_player(self, player: PlayerState) -> None:
        path = self.player_path(str(player.player_id))
        payload = {
            "_meta": {
                "schema": 1,
                "format": "GXB v0.8.0 canonical per-player state",
                "player_id": str(player.player_id),
                "account_uid": str(player.account_uid),
                "region": int(player.region),
                "notes": [
                    "This file owns game progress for one stable player_id.",
                    "SDK credentials/sessions live under data/server_state/accounts and sessions.",
                    "Do not key progress by device_id or SID/token.",
                ],
            },
            "player": JsonPlayerDatabase.serialize_player(player),
        }
        _atomic_write_json(path, payload)

    def load_player(self, player_id: str) -> PlayerState | None:
        path = self.player_path(str(player_id))
        data = _load_json(path, None)
        if not isinstance(data, dict):
            return None
        base = default_player()
        player = JsonPlayerDatabase.deserialize_player(data.get("player") or {}, base)
        if self.normalize_player(player, persist=False):
            self.save_player(player)
        return player

    def normalize_player(self, player: PlayerState, *, persist: bool) -> bool:
        changed = False
        if HeroRepository(player, data_dir=self.data_dir).normalize():
            changed = True
        if InventoryRepository(player).normalize():
            changed = True
        if WorldRepository(player, self.data_dir, inventory=InventoryRepository(player)).normalize():
            changed = True
        raw_guides = player.guide_function_ids
        normalized_guides: dict[str, int] = {}
        if isinstance(raw_guides, dict):
            for key, value in raw_guides.items():
                try:
                    gid, state = int(key), int(value)
                except (TypeError, ValueError):
                    continue
                if gid > 0 and state != 0:
                    normalized_guides[str(gid)] = state
        elif isinstance(raw_guides, list):
            for value in raw_guides:
                try:
                    gid = int(value)
                except (TypeError, ValueError):
                    continue
                if gid > 0:
                    normalized_guides[str(gid)] = 1
        if raw_guides != normalized_guides:
            player.guide_function_ids = normalized_guides
            changed = True
        if changed and persist:
            self.save_player(player)
        return changed

    def create_fresh_player(self, *, uid: str, region: int, region_name: str) -> PlayerState:
        player_id = self._allocate_player_id(region)
        player = make_fresh_player(
            account_uid=str(uid),
            player_id=player_id,
            region=int(region),
            region_name=str(region_name),
        )
        self.normalize_player(player, persist=False)
        self.save_player(player)
        self.set_account_region_player(uid, region, player_id)
        return player

    def import_legacy_sandbox(
        self,
        legacy_player_db: Path | None,
        *,
        profile: str,
        legacy_state_path: Path | None = None,
    ) -> PlayerState:
        """Import the v0.7 singleton once without changing its semantics."""
        self.ensure_sandbox_account()
        self.ensure_sandbox_session()

        # If a sandbox mapping already exists, the multi-user store is already
        # authoritative and the legacy file becomes migration-only.
        index = self._account_player_index().get(SANDBOX_UID, {})
        if index:
            for player_id in index.values():
                player = self.load_player(player_id)
                if player is not None:
                    return player

        base_account = default_account()
        base_player = apply_profile(default_player(), profile)
        account = base_account
        player = base_player
        source: Path | None = None
        if legacy_player_db and Path(legacy_player_db).exists():
            source = Path(legacy_player_db)
        elif legacy_state_path and Path(legacy_state_path).exists():
            source = Path(legacy_state_path)

        if source is not None:
            try:
                account, player = JsonPlayerDatabase(source).load(base_account, base_player)
                print(f"[MULTIUSER] importing singleton sandbox from {source}")
            except Exception as exc:
                print(f"[MULTIUSER] legacy sandbox import failed {source}: {exc}; using established defaults")

        player.account_uid = SANDBOX_UID
        player.token = SANDBOX_TOKEN
        self.normalize_player(player, persist=False)
        self.save_player(player)
        self.set_account_region_player(SANDBOX_UID, int(player.region), str(player.player_id))
        self._seed_region_serial_from_player(player)
        return player

    def _seed_region_serial_from_player(self, player: PlayerState) -> None:
        try:
            pid = int(player.player_id)
            encoded_region = pid // 100_000
            serial = pid % 100_000
        except Exception:
            return
        if encoded_region <= 0 or serial <= 0:
            return
        counters = _load_json(self.region_counter_path, {})
        if not isinstance(counters, dict):
            counters = {}
        current = int(counters.get(str(encoded_region), 1))
        if serial + 1 > current:
            counters[str(encoded_region)] = serial + 1
            _atomic_write_json(self.region_counter_path, counters)

    def sandbox_player(self) -> PlayerState:
        mapping = self._account_player_index().get(SANDBOX_UID, {})
        for player_id in mapping.values():
            player = self.load_player(player_id)
            if player is not None:
                return player
        raise RuntimeError("sandbox player is not initialized")

    def player_summary(self, player: PlayerState) -> dict[str, Any]:
        try:
            numeric_id = int(player.player_id)
        except (TypeError, ValueError):
            numeric_id = 0
        return {
            "id": numeric_id,
            "player_id": numeric_id,
            "name": str(player.player_name or ""),
            "region": int(player.region),
            "lev": int(player.lev),
            "vip": int(player.vip),
            "avatar_id": int(player.avatar_id),
            "avatar_frame_id": int(player.avatar_frame_id),
            "conquer_lev": int(player.conquer_lev),
            "conquer_loop_id": int(player.conquer_loop_id),
        }
