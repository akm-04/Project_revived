"""Strict read-only discovery and immutable snapshot support for Pass299 JSON."""
from __future__ import annotations

import hashlib
import json
import os
import shutil
from pathlib import Path
from typing import Any, Iterable, Mapping

from gxb_backend.identity.credentials import PasswordCredentialService, normalize_login
from gxb_backend.persistence.codec import PlayerPayloadCodec, canonical_json_digest
from gxb_backend.state.defaults import default_player
from gxb_backend.state.player_database import JsonPlayerDatabase

from .models import Adjustment, LegacyAccount, LegacyPlayer, ManifestEntry, SourceInventory


class SourceConflict(RuntimeError):
    """A source contradiction that must block candidate activation."""


def _strict_json(path: Path) -> Any:
    def object_pairs(pairs: list[tuple[str, Any]]) -> dict[str, Any]:
        result: dict[str, Any] = {}
        for key, value in pairs:
            if key in result:
                raise ValueError(f"duplicate JSON key: {key}")
            result[key] = value
        return result
    try:
        with path.open("r", encoding="utf-8") as handle:
            return json.load(handle, object_pairs_hook=object_pairs)
    except Exception as exc:
        raise SourceConflict(f"strict JSON parse failed: {path}") from exc


def _required_dict(value: Any, label: str) -> dict[str, Any]:
    if not isinstance(value, dict):
        raise SourceConflict(f"{label} must be a JSON object")
    return value


def _positive_int(value: Any, label: str) -> int:
    if isinstance(value, bool):
        raise SourceConflict(f"{label} must be a positive integer")
    try:
        result = int(value)
    except (TypeError, ValueError) as exc:
        raise SourceConflict(f"{label} must be a positive integer") from exc
    if result <= 0:
        raise SourceConflict(f"{label} must be a positive integer")
    return result


def _manifest(root: Path) -> tuple[ManifestEntry, ...]:
    rows: list[ManifestEntry] = []
    for path in sorted(root.rglob("*"), key=lambda p: p.relative_to(root).as_posix()):
        if path.is_symlink():
            raise SourceConflict(f"source contains symbolic link: {path.relative_to(root)}")
        if not path.is_file():
            continue
        rel = path.relative_to(root).as_posix()
        digest = hashlib.sha256()
        size = 0
        with path.open("rb") as handle:
            for chunk in iter(lambda: handle.read(1024 * 1024), b""):
                digest.update(chunk)
                size += len(chunk)
        rows.append(ManifestEntry(rel, size, digest.hexdigest()))
    return tuple(rows)


def _manifest_digest(entries: Iterable[ManifestEntry]) -> str:
    return canonical_json_digest([{"path": x.path, "size": x.size, "sha256": x.sha256} for x in entries])


def _content_root(entries: Iterable[ManifestEntry]) -> str:
    digest = hashlib.sha256()
    for entry in entries:
        digest.update(entry.path.encode("utf-8"))
        digest.update(b"\0")
        digest.update(str(entry.size).encode("ascii"))
        digest.update(b"\0")
        digest.update(bytes.fromhex(entry.sha256))
        digest.update(b"\n")
    return digest.hexdigest()


class MigrationSourceReader:
    """Parse a quiesced server_state without using mutation-capable runtime APIs."""

    REQUIRED_INDEXES = (
        "account_by_login.json",
        "player_by_account_region.json",
        "session_by_token.json",
        "region_player_serial.json",
        "counters.json",
    )

    def inventory(self, root: Path) -> SourceInventory:
        root = Path(root).resolve()
        if not root.is_dir():
            raise SourceConflict(f"server_state root does not exist: {root}")
        for dirname in ("accounts", "sessions", "players", "indexes"):
            if not (root / dirname).is_dir():
                raise SourceConflict(f"missing required source directory: {dirname}")
        for filename in self.REQUIRED_INDEXES:
            if not (root / "indexes" / filename).is_file():
                raise SourceConflict(f"missing required source index: indexes/{filename}")

        before = _manifest(root)
        warnings = [f"unexpected temporary file: {x.path}" for x in before if x.path.endswith(".tmp")]
        unexpected = [x.path for x in before if not x.path.endswith(".json") and not x.path.endswith(".tmp")]
        if unexpected:
            warnings.extend(f"unexpected non-JSON file: {path}" for path in unexpected)

        account_index = _required_dict(_strict_json(root / "indexes/account_by_login.json"), "account login index")
        ownership_root = _required_dict(_strict_json(root / "indexes/player_by_account_region.json"), "ownership index")
        session_index = _required_dict(_strict_json(root / "indexes/session_by_token.json"), "session token index")
        region_serial = _required_dict(_strict_json(root / "indexes/region_player_serial.json"), "region serial index")
        counters = _required_dict(_strict_json(root / "indexes/counters.json"), "account counters")

        accounts = self._accounts(root, account_index)
        players = self._players(root, accounts, ownership_root)
        session_count, session_warnings = self._sessions(root, accounts, session_index)
        warnings.extend(session_warnings)
        region_next, region_adjustments = self._region_allocators(region_serial, players)
        next_uid, uid_adjustments = self._account_allocator(counters, accounts)

        after = _manifest(root)
        if before != after:
            raise SourceConflict("source tree changed while it was being inventoried")
        return SourceInventory(
            root=root,
            entries=before,
            content_root=_content_root(before),
            manifest_digest=_manifest_digest(before),
            accounts=accounts,
            players=players,
            region_next_player_ids=region_next,
            next_account_uid=next_uid,
            session_file_count=session_count,
            session_index_count=len(session_index),
            warnings=tuple(warnings),
            adjustments=tuple(region_adjustments + uid_adjustments),
        )

    def snapshot(self, source_root: Path, destination: Path) -> SourceInventory:
        source = self.inventory(source_root)
        destination = Path(destination).resolve()
        if destination.exists():
            raise SourceConflict(f"snapshot destination already exists: {destination}")
        if destination == source.root or source.root in destination.parents:
            raise SourceConflict("snapshot destination must not be inside the live source root")
        destination.mkdir(parents=True, mode=0o700)
        try:
            for entry in source.entries:
                src = source.root / entry.path
                dst = destination / entry.path
                dst.parent.mkdir(parents=True, exist_ok=True, mode=0o700)
                shutil.copyfile(src, dst, follow_symlinks=False)
                os.chmod(dst, 0o600)
            snap = self.inventory(destination)
            if snap.entries != source.entries or snap.content_root != source.content_root:
                raise SourceConflict("snapshot bytes do not match source manifest")
            # Detect a writer racing the copy even when individual files happened to copy cleanly.
            if _manifest(source.root) != source.entries:
                raise SourceConflict("live source changed during snapshot copy")
            return snap
        except Exception:
            # Deliberately leave partial evidence for operator inspection; never delete an
            # ambiguously targeted directory from migration code.
            raise

    def legacy_sandbox_fixture(self, path: Path) -> SourceInventory:
        """Strictly interpret the packaged singleton only for rehearsal/fallback."""
        path = Path(path).resolve()
        document = _required_dict(_strict_json(path), "legacy singleton")
        account_raw = _required_dict(document.get("account"), "legacy singleton account")
        player_raw = _required_dict(document.get("player"), "legacy singleton player")
        uid = str(account_raw.get("uid") or "")
        pid = _positive_int(player_raw.get("identity", {}).get("player_id"), "sandbox player_id")
        region = _positive_int(player_raw.get("identity", {}).get("region"), "sandbox region")
        if pid // 100_000 != region:
            raise SourceConflict("sandbox player_id does not encode its region")
        base = default_player()
        player = JsonPlayerDatabase.deserialize_player(player_raw, base)
        if str(player.account_uid) != uid or int(player.player_id) != pid or int(player.region) != region:
            raise SourceConflict("sandbox account/player typed identity mismatch")
        transformed = PlayerPayloadCodec.transform(player)
        entry = _manifest(path.parent)
        selected = tuple(x for x in entry if x.path == path.name)
        return SourceInventory(
            root=path.parent,
            entries=selected,
            content_root=_content_root(selected),
            manifest_digest=_manifest_digest(selected),
            accounts=(LegacyAccount(uid, "anonymous_sandbox", str(account_raw.get("username") or uid), "__anonymous_sandbox__", "__anonymous_sandbox__", 0, None, {"compatibility_profile": "established", "source": "legacy_singleton"}),),
            players=(LegacyPlayer(pid, uid, region, path.name, document, transformed),),
            region_next_player_ids={region: pid + 1},
            next_account_uid=20_000_001,
            session_file_count=1 if account_raw.get("sid") or account_raw.get("token") else 0,
            session_index_count=0,
            warnings=("legacy singleton fallback used; embedded bearer retired",),
        )

    @staticmethod
    def assert_stable(inventory: SourceInventory) -> None:
        current = _manifest(inventory.root)
        # A singleton fallback inventories only one file in a larger data directory.
        if len(inventory.entries) == 1 and (inventory.root / inventory.entries[0].path).is_file():
            current = tuple(x for x in current if x.path == inventory.entries[0].path)
        if current != inventory.entries or _content_root(current) != inventory.content_root:
            raise SourceConflict("immutable migration source no longer matches its sealed manifest")

    def _accounts(self, root: Path, account_index: Mapping[str, Any]) -> tuple[LegacyAccount, ...]:
        rows: list[LegacyAccount] = []
        seen_logins: dict[str, str] = {}
        files = sorted((root / "accounts").glob("*.json"))
        for path in files:
            raw = _required_dict(_strict_json(path), f"account {path.name}")
            uid = str(raw.get("uid") or "")
            if not uid or path.stem != uid:
                raise SourceConflict(f"account filename/uid mismatch: {path.name}")
            login = str(raw.get("login") or "")
            normalized = normalize_login(raw.get("normalized_login", login))
            if not normalized or normalized != normalize_login(login):
                raise SourceConflict(f"account normalized_login mismatch: {uid}")
            previous = seen_logins.setdefault(normalized, uid)
            if previous != uid:
                raise SourceConflict(f"duplicate normalized login: {normalized}")
            if str(account_index.get(normalized) or "") != uid:
                raise SourceConflict(f"account login index mismatch: {uid}")
            password = raw.get("password")
            if password is not None:
                password = _required_dict(password, f"account password {uid}")
                required = {"algorithm", "iterations", "salt", "hash"}
                if not required.issubset(password) or password.get("algorithm") != PasswordCredentialService.LEGACY_ALGORITHM:
                    raise SourceConflict(f"unsupported password verifier: {uid}")
                PasswordCredentialService.encode_legacy_pbkdf2(
                    iterations=_positive_int(password["iterations"], f"password iterations {uid}"),
                    salt_hex=str(password["salt"]),
                    hash_hex=str(password["hash"]),
                )
                try:
                    salt = bytes.fromhex(str(password["salt"])); digest = bytes.fromhex(str(password["hash"]))
                except ValueError as exc:
                    raise SourceConflict(f"malformed password verifier: {uid}") from exc
                if not salt or not digest:
                    raise SourceConflict(f"empty password verifier material: {uid}")
            metadata = dict(raw.get("metadata")) if isinstance(raw.get("metadata"), dict) else {}
            known = {"schema", "uid", "login", "normalized_login", "username", "account_type", "created_at", "password", "metadata"}
            extensions = {str(key): value for key, value in raw.items() if key not in known}
            if extensions:
                metadata["legacy_extensions"] = extensions
            rows.append(LegacyAccount(uid, str(raw.get("account_type") or "normal"), str(raw.get("username") or login or uid), login, normalized, int(raw.get("created_at") or 0), password, metadata))
        expected_index = {x.normalized_login: x.account_uid for x in rows}
        actual_index = {str(key): str(value) for key, value in account_index.items()}
        if actual_index != expected_index:
            raise SourceConflict("account login index is not an exact account-record projection")
        return tuple(rows)

    def _players(self, root: Path, accounts: tuple[LegacyAccount, ...], ownership_root: Mapping[str, Any]) -> tuple[LegacyPlayer, ...]:
        account_uids = {x.account_uid for x in accounts}
        expected: dict[tuple[str, int], int] = {}
        expected_pids: set[int] = set()
        for uid, region_map in ownership_root.items():
            if str(uid) not in account_uids:
                raise SourceConflict(f"ownership index references missing account: {uid}")
            region_map = _required_dict(region_map, f"ownership index account {uid}")
            for raw_region, raw_pid in region_map.items():
                region = _positive_int(raw_region, "ownership region")
                if region > 200:
                    raise SourceConflict(f"ownership index region is outside target catalog: {region}")
                pid = _positive_int(raw_pid, "ownership player_id")
                key = (str(uid), region)
                if key in expected or pid in expected_pids:
                    raise SourceConflict(f"duplicate account/region or player ownership: {uid}/{region}/{pid}")
                expected[key] = pid; expected_pids.add(pid)

        rows: list[LegacyPlayer] = []
        for path in sorted((root / "players").glob("*/player.json")):
            document = _required_dict(_strict_json(path), f"player {path}")
            meta = _required_dict(document.get("_meta"), f"player metadata {path}")
            player_body = _required_dict(document.get("player"), f"player payload {path}")
            identity = _required_dict(player_body.get("identity"), f"player identity {path}")
            pid = _positive_int(identity.get("player_id"), "player_id")
            uid = str(identity.get("account_uid") or "")
            region = _positive_int(identity.get("region"), "player region")
            if path.parent.name != str(pid) or str(meta.get("player_id")) != str(pid):
                raise SourceConflict(f"player path/metadata id mismatch: {path}")
            if str(meta.get("account_uid")) != uid or int(meta.get("region") or 0) != region:
                raise SourceConflict(f"player metadata/payload identity mismatch: {pid}")
            if uid not in account_uids or pid // 100_000 != region or expected.get((uid, region)) != pid:
                raise SourceConflict(f"player ownership/region contradiction: {pid}")
            player = JsonPlayerDatabase.deserialize_player(player_body, default_player())
            if int(player.player_id) != pid or str(player.account_uid) != uid or int(player.region) != region:
                raise SourceConflict(f"compatibility parser changed typed player identity: {pid}")
            transformed = PlayerPayloadCodec.transform(player)
            rows.append(LegacyPlayer(pid, uid, region, path.relative_to(root).as_posix(), document, transformed))
        if {x.player_id for x in rows} != expected_pids:
            raise SourceConflict("player files and account-region ownership index are not an exact set")
        return tuple(rows)

    def _sessions(self, root: Path, accounts: tuple[LegacyAccount, ...], token_index: Mapping[str, Any]) -> tuple[int, list[str]]:
        account_uids = {x.account_uid for x in accounts}
        sessions: dict[str, dict[str, Any]] = {}
        warnings: list[str] = []
        for path in sorted((root / "sessions").glob("*.json")):
            try:
                raw = _required_dict(_strict_json(path), f"session {path.name}")
            except SourceConflict:
                warnings.append(f"malformed legacy session retired: {path.name}")
                continue
            sid = str(raw.get("sid") or "")
            if not sid or sid != path.stem or str(raw.get("uid") or "") not in account_uids:
                warnings.append(f"incoherent legacy session retired: {path.name}")
                continue
            sessions[sid] = raw
        for _token, sid in token_index.items():
            if str(sid) not in sessions:
                warnings.append("legacy token index references a missing session; bearer retired")
        for sid, raw in sessions.items():
            token = raw.get("token")
            if token is not None and str(token_index.get(str(token)) or "") != sid:
                warnings.append(f"legacy session token index mismatch retired: {sid}")
        return len(list((root / "sessions").glob("*.json"))), warnings

    @staticmethod
    def _region_allocators(region_serial: Mapping[str, Any], players: tuple[LegacyPlayer, ...]) -> tuple[dict[int, int], list[Adjustment]]:
        observed: dict[int, int] = {}
        for player in players:
            observed[player.region_id] = max(observed.get(player.region_id, 0), player.player_id % 100_000)
        regions = set(observed) | {_positive_int(x, "region serial key") for x in region_serial}
        result: dict[int, int] = {}
        adjustments: list[Adjustment] = []
        for region in sorted(regions):
            if region > 200:
                raise SourceConflict(f"region serial is outside target catalog: {region}")
            source_serial = _positive_int(region_serial.get(str(region), 1), f"region {region} serial")
            target_serial = max(source_serial, observed.get(region, 0) + 1, 1)
            if target_serial > 100_000:
                raise SourceConflict(f"region {region} player namespace exhausted")
            result[region] = region * 100_000 + target_serial
            if target_serial != source_serial:
                adjustments.append(Adjustment("REGION_ALLOCATOR_LIFT", str(region), source_serial, target_serial, "cursor was behind observed durable player id"))
        return result, adjustments

    @staticmethod
    def _account_allocator(counters: Mapping[str, Any], accounts: tuple[LegacyAccount, ...]) -> tuple[int, list[Adjustment]]:
        source_next = _positive_int(counters.get("next_uid", 20_000_001), "next_uid")
        numeric = [int(x.account_uid) for x in accounts if x.account_uid.isdecimal() and int(x.account_uid) >= 20_000_001]
        target = max([source_next, 20_000_001, *(x + 1 for x in numeric)])
        adjustments = [] if target == source_next else [Adjustment("ACCOUNT_UID_SEQUENCE_LIFT", "account_uid_seq", source_next, target, "cursor was behind observed durable local account uid")]
        return target, adjustments
