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
from typing import Any, TYPE_CHECKING

from .account import AccountIdentity
from .defaults import default_account, default_player
from .player_database import JsonPlayerDatabase
from .player_state import PlayerState
from .profiles import apply_profile, make_fresh_player
from .skill_point_policy import SkillPointPolicy
from .commerce_service import CommerceEntitlementService
from .vip_policy import VipProgressionPolicy
from .vip_award_service import VipAwardService
from .maintenance_services import PlayerMaintenanceServices
from gxb_backend.content.item_stack_limit_catalog import ItemStackLimitCatalog

if TYPE_CHECKING:
    from .summon_featured_rotation import SummonFeaturedRotationPolicy


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
    JsonPlayerDatabase.atomic_write_json(path, payload)


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

    def __init__(
        self,
        root: Path,
        data_dir: Path,
        *,
        featured_rotation: "SummonFeaturedRotationPolicy | None" = None,
    ) -> None:
        self.root = Path(root)
        self.data_dir = Path(data_dir)
        self.featured_rotation = featured_rotation
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
                "schema": 2,
                "format": "GXB v0.9.0 canonical per-player state",
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
        existing = _load_json(path, None)
        if isinstance(existing, dict):
            payload = JsonPlayerDatabase.merge_preserving_extensions(existing, payload)
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

    def _apply_pass72_debug_inventory_seed(self, player: PlayerState) -> bool:
        """One-shot PRIVATE_SERVER_POLICY seed for the anonymous debug account.

        This is deliberately not a default-player rule and never applies to
        credential accounts. The migration marker prevents consumed test gear
        from being replenished on every load, so runtime probes still exercise
        real StackInventory deductions.
        """
        if str(getattr(player, "account_uid", "") or "") != SANDBOX_UID:
            return False
        path = self.data_dir / "debug_guest_inventory_seed.json"
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return False
        if not isinstance(payload, dict):
            return False
        meta = payload.get("_meta") if isinstance(payload.get("_meta"), dict) else {}
        marker = str(meta.get("migration_marker") or "pass72_debug_hero_inventory_seed_v1")
        state = player.persistence_state if isinstance(player.persistence_state, dict) else {}
        if state is not player.persistence_state:
            player.persistence_state = state
        migrations = state.setdefault("migrations", {})
        if not isinstance(migrations, dict):
            migrations = {}
            state["migrations"] = migrations
        if migrations.get(marker):
            return False

        minimum = max(1, int(payload.get("minimum_quantity", 1000) or 1000))
        ids = []
        for raw in payload.get("item_ids") or []:
            try:
                item_id = int(raw)
            except (TypeError, ValueError):
                continue
            if item_id > 0:
                ids.append(item_id)
        if not ids:
            return False

        if not isinstance(player.backpack_items, list):
            player.backpack_items = []
        by_id: dict[int, dict[str, Any]] = {}
        for row in player.backpack_items:
            if not isinstance(row, dict):
                continue
            try:
                item_id = int(row.get("table_id", 0) or 0)
            except (TypeError, ValueError):
                continue
            if item_id > 0:
                by_id[item_id] = row
        seeded = 0
        for item_id in sorted(set(ids)):
            row = by_id.get(item_id)
            if row is None:
                row = {"table_id": item_id, "item_num": minimum, "time": 0}
                player.backpack_items.append(row)
                by_id[item_id] = row
                seeded += 1
            else:
                try:
                    current = int(row.get("item_num", 0) or 0)
                except (TypeError, ValueError):
                    current = 0
                if current < minimum:
                    row["item_num"] = minimum
                    seeded += 1
        migrations[marker] = {
            "applied": 1,
            "minimum_quantity": minimum,
            "source_item_count": len(set(ids)),
            "rows_added_or_raised": seeded,
        }
        return True

    def _apply_pass73_debug_advanced_seed(self, player: PlayerState) -> bool:
        """One-shot Pass73 advanced-progression sandbox inventory seed."""
        if str(getattr(player, "account_uid", "") or "") != SANDBOX_UID:
            return False
        path = self.data_dir / "debug_guest_advanced_inventory_seed.json"
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return False
        if not isinstance(payload, dict):
            return False
        meta = payload.get("_meta") if isinstance(payload.get("_meta"), dict) else {}
        marker = str(meta.get("migration_marker") or "pass73_debug_advanced_progression_seed_v1")
        state = player.persistence_state if isinstance(player.persistence_state, dict) else {}
        if state is not player.persistence_state:
            player.persistence_state = state
        migrations = state.setdefault("migrations", {})
        if not isinstance(migrations, dict):
            migrations = {}; state["migrations"] = migrations
        if migrations.get(marker):
            return False
        minimum = max(1, int(payload.get("minimum_quantity", 1000) or 1000))
        ids=[]
        for raw in payload.get("item_ids") or []:
            try: item_id=int(raw)
            except (TypeError,ValueError): continue
            if item_id>0: ids.append(item_id)
        if not ids: return False
        if not isinstance(player.backpack_items, list): player.backpack_items=[]
        by_id={}
        for row in player.backpack_items:
            if not isinstance(row,dict): continue
            try: item_id=int(row.get("table_id",0) or 0)
            except (TypeError,ValueError): continue
            if item_id>0: by_id[item_id]=row
        seeded=0
        for item_id in sorted(set(ids)):
            row=by_id.get(item_id)
            if row is None:
                row={"table_id":item_id,"item_num":minimum,"time":0}; player.backpack_items.append(row); by_id[item_id]=row; seeded+=1
            else:
                try: current=int(row.get("item_num",0) or 0)
                except (TypeError,ValueError): current=0
                if current<minimum: row["item_num"]=minimum; seeded+=1
        migrations[marker]={"applied":1,"minimum_quantity":minimum,"source_item_count":len(set(ids)),"rows_added_or_raised":seeded}
        return True


    def _apply_pass99_debug_qa_consumables_seed(self, player: PlayerState) -> bool:
        """One-shot source-bounded QA seed for deterministic economy testing.

        This intentionally *may* add/raise the explicitly authorized QA rows,
        unlike Pass96's normalization-only repair. The migration marker makes
        it non-replenishing after the first successful load. Source item.stack
        remains the hard upper bound, so cap-99 foods seed to 90 rather than
        violating the inventory invariant with a requested 900.
        """
        if str(getattr(player, "account_uid", "") or "") != SANDBOX_UID:
            return False
        path = self.data_dir / "debug_guest_qa_consumables_pass99.json"
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return False
        if not isinstance(payload, dict):
            return False
        meta = payload.get("_meta") if isinstance(payload.get("_meta"), dict) else {}
        marker = str(meta.get("migration_marker") or "pass99_debug_qa_consumables_seed_v1")
        state = player.persistence_state if isinstance(player.persistence_state, dict) else {}
        if state is not player.persistence_state:
            player.persistence_state = state
        migrations = state.setdefault("migrations", {})
        if not isinstance(migrations, dict):
            migrations = {}
            state["migrations"] = migrations
        if migrations.get(marker):
            return False

        limits = ItemStackLimitCatalog(self.data_dir)
        if not isinstance(player.backpack_items, list):
            player.backpack_items = []
        by_id: dict[int, dict[str, Any]] = {}
        for row in player.backpack_items:
            if not isinstance(row, dict):
                continue
            try:
                item_id = int(row.get("table_id", 0) or 0)
            except (TypeError, ValueError):
                continue
            if item_id > 0:
                by_id[item_id] = row

        changed = 0
        seeded: dict[str, int] = {}
        for spec in payload.get("items") or []:
            if not isinstance(spec, dict):
                continue
            try:
                item_id = int(spec.get("item_id", 0) or 0)
                requested = max(0, int(spec.get("target_quantity", 0) or 0))
            except (TypeError, ValueError):
                continue
            if item_id <= 0 or requested <= 0:
                continue
            limit = limits.limit(item_id)
            if limit is None or limit <= 0:
                continue
            target = min(requested, limit)
            row = by_id.get(item_id)
            if row is None:
                row = {"table_id": item_id, "item_num": target, "time": 0}
                player.backpack_items.append(row)
                by_id[item_id] = row
                changed += 1
            else:
                try:
                    current = max(0, int(row.get("item_num", 0) or 0))
                except (TypeError, ValueError):
                    current = 0
                if current < target:
                    row["item_num"] = target
                    changed += 1
            seeded[str(item_id)] = target

        migrations[marker] = {
            "applied": 1,
            "policy": "one_shot_source_stack_bounded_qa_seed",
            "rows_added_or_raised": changed,
            "seeded_targets": seeded,
        }
        return True

    def _apply_pass96_debug_account_normalization(self, player: PlayerState) -> bool:
        """One-shot source-aware sandbox repair for end-game economy QA.

        Historical Pass72/73 seed markers are intentionally left untouched.
        This migration only lowers invalid persisted quantities; it never
        replenishes already-consumed items.
        """
        if str(getattr(player, "account_uid", "") or "") != SANDBOX_UID:
            return False
        path = self.data_dir / "debug_guest_normalization_pass96.json"
        try:
            payload = json.loads(path.read_text(encoding="utf-8"))
        except Exception:
            return False
        if not isinstance(payload, dict):
            return False
        meta = payload.get("_meta") if isinstance(payload.get("_meta"), dict) else {}
        marker = str(meta.get("migration_marker") or "pass96_debug_account_normalization_v1")
        state = player.persistence_state if isinstance(player.persistence_state, dict) else {}
        if state is not player.persistence_state:
            player.persistence_state = state
        migrations = state.setdefault("migrations", {})
        if not isinstance(migrations, dict):
            migrations = {}
            state["migrations"] = migrations
        if migrations.get(marker):
            return False

        academy = payload.get("academy") if isinstance(payload.get("academy"), dict) else {}
        player.lev = max(1, int(academy.get("lev", 100) or 100))
        player.exp = max(0, int(academy.get("exp", 579615) or 579615))
        player.max_lev = max(1, int(academy.get("max_lev", 100) or 100))
        player.max_energy = max(0, int(academy.get("max_energy", 160) or 160))

        headroom = payload.get("inventory_headroom") if isinstance(payload.get("inventory_headroom"), dict) else {}
        target_large = max(1, int(headroom.get("stack_at_least_999", 900) or 900))
        target_99 = max(1, int(headroom.get("stack_99", 90) or 90))
        ratio = max(1, min(100, int(headroom.get("other_positive_cap_ratio_percent", 90) or 90)))
        limits = ItemStackLimitCatalog(self.data_dir)
        changed_rows = 0
        examined_rows = 0
        if not isinstance(player.backpack_items, list):
            player.backpack_items = []
        for row in player.backpack_items:
            if not isinstance(row, dict):
                continue
            try:
                item_id = int(row.get("table_id", 0) or 0)
                current = int(row.get("item_num", 0) or 0)
            except (TypeError, ValueError):
                continue
            if item_id <= 0 or current <= 0:
                continue
            limit = limits.limit(item_id)
            if limit is None:
                continue
            examined_rows += 1
            if limit >= 999:
                target = min(limit, target_large)
            elif limit == 99:
                target = min(limit, target_99)
            else:
                target = max(1, min(limit, (limit * ratio) // 100))
            if current > target:
                row["item_num"] = target
                changed_rows += 1

        migrations[marker] = {
            "applied": 1,
            "academy": {
                "lev": player.lev,
                "exp": player.exp,
                "max_lev": player.max_lev,
                "max_energy": player.max_energy,
            },
            "inventory_rows_examined": examined_rows,
            "inventory_rows_lowered": changed_rows,
            "policy": "source_stack_headroom_no_replenish",
        }
        return True

    def _apply_pass75_debug_campaign_unlock(self, player: PlayerState) -> bool:
        """One-shot source-graph Campaign unlock for anonymous QA only."""
        if str(getattr(player, "account_uid", "") or "") != SANDBOX_UID:
            return False
        policy_path = self.data_dir / "debug_guest_campaign_unlock_pass75.json"
        source_path = self.data_dir / "pass75_campaign_ownership_meta.json"
        try:
            policy = json.loads(policy_path.read_text(encoding="utf-8"))
            source = json.loads(source_path.read_text(encoding="utf-8"))
        except Exception:
            return False
        if not isinstance(policy, dict) or not isinstance(source, dict):
            return False
        meta = policy.get("_meta") if isinstance(policy.get("_meta"), dict) else {}
        marker = str(meta.get("migration_marker") or "pass75_debug_campaign_unlock_v1")
        state = player.persistence_state if isinstance(player.persistence_state, dict) else {}
        if state is not player.persistence_state:
            player.persistence_state = state
        migrations = state.setdefault("migrations", {})
        if not isinstance(migrations, dict):
            migrations = {}; state["migrations"] = migrations
        if migrations.get(marker):
            return False

        if not isinstance(player.world_map, dict):
            player.world_map = {}
        campaigns = source.get("campaigns") if isinstance(source.get("campaigns"), dict) else {}
        counts = {}
        for key, ids_key, seed_star in (
            ("normal", "normal_campaign_ids", int(policy.get("normal_missing_stage_star", 1) or 1)),
            ("super", "super_campaign_ids", int(policy.get("super_missing_stage_star", 0) or 0)),
        ):
            raw_rows = player.world_map.get(key)
            rows = raw_rows if isinstance(raw_rows, list) else []
            by_id = {}
            for row in rows:
                if not isinstance(row, dict):
                    continue
                try: cid = int(row.get("campaign_id", 0) or 0)
                except (TypeError, ValueError): cid = 0
                if cid > 0: by_id[cid] = row
            added = 0
            for raw_id in source.get(ids_key) or []:
                try: cid = int(raw_id)
                except (TypeError, ValueError): continue
                if cid <= 0: continue
                source_row = campaigns.get(str(cid)) if isinstance(campaigns, dict) else {}
                daily = max(0, int((source_row or {}).get("daily_limit", 0) or 0))
                row = by_id.get(cid)
                if row is None:
                    row = {"campaign_id":cid,"star":max(0,min(3,seed_star)),"daily_limit":daily,"reset_count":0,"is_partner_drop":0}
                    rows.append(row); by_id[cid]=row; added += 1
                else:
                    # Unlock policy never reduces progress. NORMAL prerequisites
                    # need star>0 for MapWindow's Super gate; Super itself may
                    # remain unbeaten while still being present/clickable.
                    current = int(row.get("star", 0) or 0)
                    row["star"] = max(current, max(0,min(3,seed_star)))
                    if key == "super" and int(row.get("daily_limit", 0) or 0) <= 0:
                        row["daily_limit"] = daily
            player.world_map[key] = rows
            counts[key] = {"source_rows":len(source.get(ids_key) or []),"added":added}
        migrations[marker] = {"applied":1,"policy":"PRIVATE_SERVER_POLICY","counts":counts}
        return True

    def normalize_player(self, player: PlayerState, *, persist: bool) -> bool:
        changed = False
        if self._apply_pass72_debug_inventory_seed(player):
            changed = True
        if self._apply_pass73_debug_advanced_seed(player):
            changed = True
        if self._apply_pass75_debug_campaign_unlock(player):
            changed = True
        if self._apply_pass96_debug_account_normalization(player):
            changed = True
        if self._apply_pass99_debug_qa_consumables_seed(player):
            changed = True
        # Pass91: source SelfPlayer/VipRechargeWindow require a non-empty
        # one-based VIP1..VIP15 0/1 claim vector. The backend never implemented
        # MID657 before Pass91, so empty/missing legacy state safely means
        # "nothing claimed" rather than "unknown history".
        if VipAwardService.normalize_player_claims(player):
            changed = True
        # Pass87 Commerce authority normalization runs at the durable player-load
        # maintenance boundary. It is explicitly not a purchase transaction.
        commerce_policy = VipProgressionPolicy(self.data_dir)
        commerce = CommerceEntitlementService(player, commerce_policy)
        if commerce.maintenance_normalize():
            changed = True
        maintenance = PlayerMaintenanceServices(
            player, self.data_dir, featured_rotation=self.featured_rotation
        )
        if maintenance.player_progression.normalize_source_authority():
            changed = True
        # Pass128 legacy bridge: historical credential accounts could already be
        # level>=11 while Function31 remained guide_sensitive_unresolved. Repair
        # Function31 + first Super frontier coherently at player-load time, where
        # no NEW_FUNC_OPEN semantic event is emitted.
        if maintenance.elite_campaign_unlock.maintenance_reconcile():
            changed = True
        # Runtime v0.8.2 exposed a latent client crash in the unused Arena
        # invitation path whenever any economy_ event is processed. Migrate
        # credential players created by v0.8.0-v0.8.2 to the deferred-PvP
        # representation so existing server_state can be carried forward.
        if str(getattr(player, "account_uid", "") or "") != SANDBOX_UID:
            if player.invitation is not None or player.max_invitation is not None:
                player.invitation = None
                player.max_invitation = None
                player.invitation_time = 0
                changed = True

            # v0.8.0-v0.8.2 fresh credential players inherited the sandbox's
            # compatibility Energy=100. That value is a distinctive legacy
            # signature because Campaign stamina spending has never been active
            # for these accounts. Migrate it to source level-1 Energy=60 plus
            # source award_energy for every already-crossed player level. This
            # makes copied server_state coherent with SelfPlayer's level-up UI.
            if int(getattr(player, "energy", 0) or 0) == 100:
                economy = maintenance.economy
                migrated_energy = 60
                current_level = max(1, int(getattr(player, "lev", 1) or 1))
                for level in range(1, current_level):
                    migrated_energy += max(0, int(economy.player_level_meta(level).get("award_energy", 0) or 0))
                player.energy = migrated_energy
                level_meta = economy.player_level_meta(current_level)
                source_max_energy = int(level_meta.get("energy", 0) or 0)
                if source_max_energy > 0:
                    player.max_energy = source_max_energy
                player.energy_time = 0
                changed = True
        if maintenance.heroes.normalize():
            changed = True
        if maintenance.inventory.normalize():
            changed = True
        if maintenance.world.normalize():
            changed = True
        if maintenance.summon.normalize():
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
        # Pass 30.1 runtime-informed compatibility policy: the early Skill
        # tutorial expects a spendable pool before VIP purchasing is available.
        # Use the effective-source natural cap for the player's current VIP and
        # keep skill_time=0 as the full-pool/no-regeneration sentinel.
        SkillPointPolicy(player, self.data_dir).initialize_fresh_full_pool()
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
