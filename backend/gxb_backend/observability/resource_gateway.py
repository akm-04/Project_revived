"""EOL lazy-resource gateway for the original GXB AssetDownload pipeline.

The client constructs lazy resource URLs as::

    xyd.resDownloadUrl .. basename .. "." .. expected_md5

It intentionally drops the original directory.  The gateway therefore uses a
catalog derived from the client's ``version.json``/``lazyFile.json`` to reverse
map ``basename + md5`` back to one or more source resource paths.  Configured archive roots may be walked by directory name to discover multiple ``res`` trees, but discovered ``res`` subtrees are pruned immediately. Resource files are checked lazily on demand; the server never indexes or hashes the large payload at startup.

If a matching local file is found, its MD5 is verified before it is served.  A
missing or mismatching file is logged and returned as 404.  Fabricated/dummy
bytes are deliberately not served because the source client verifies the MD5 of
every downloaded lazy asset and would immediately retry a dummy forever.
"""

from __future__ import annotations

import hashlib
import io
import json
from collections import deque
import mimetypes
import re
import threading
import time
import zipfile
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any, Iterable

from flask import Request, make_response, send_file

from gxb_backend.config import Settings


_MD5_SUFFIX_RE = re.compile(r"^(?P<name>.+)\.(?P<md5>[0-9a-fA-F]{32})$")


@dataclass(frozen=True)
class ResourceEntry:
    path: str
    md5: str
    size: int = 0
    source: str = ""
    lazy_missing_snapshot: bool = False

    @property
    def basename(self) -> str:
        return PurePosixPath(self.path).name

    @property
    def request_asset(self) -> str:
        return f"{self.basename}.{self.md5}"


class ResourceCatalog:
    """Small in-memory reverse index; no local asset scan is required."""

    def __init__(self, catalog_path: Path) -> None:
        self.catalog_path = catalog_path
        self.entries: list[ResourceEntry] = []
        self.by_request_asset: dict[str, list[ResourceEntry]] = {}
        self.by_path: dict[str, ResourceEntry] = {}
        self.load_error = ""
        self._load()

    @staticmethod
    def _valid_path(value: Any) -> str:
        path = str(value or "").replace("\\", "/").lstrip("/")
        pure = PurePosixPath(path)
        if not path or ".." in pure.parts:
            return ""
        return path

    @staticmethod
    def _entry_from_row(row: dict[str, Any], source: str = "") -> ResourceEntry | None:
        path = ResourceCatalog._valid_path(row.get("path"))
        md5 = str(row.get("md5") or "").lower()
        if not path or not re.fullmatch(r"[0-9a-f]{32}", md5):
            return None
        try:
            size = int(row.get("size") or 0)
        except (TypeError, ValueError):
            size = 0
        return ResourceEntry(
            path=path,
            md5=md5,
            size=max(size, 0),
            source=str(row.get("source") or source),
            lazy_missing_snapshot=bool(row.get("lazy_missing_snapshot", False)),
        )

    def _iter_rows(self, payload: Any) -> Iterable[ResourceEntry]:
        # Normalized Stage 4A.4 catalog.
        if isinstance(payload, dict) and isinstance(payload.get("entries"), list):
            for row in payload["entries"]:
                if isinstance(row, dict):
                    entry = self._entry_from_row(row, "resource_catalog.json")
                    if entry:
                        yield entry
            return

        # Raw version.json format: list of rows.
        if isinstance(payload, list):
            for row in payload:
                if isinstance(row, dict):
                    entry = self._entry_from_row(row, "version.json")
                    if entry:
                        yield entry
            return

        # Raw lazyFile.json format: key -> JSON-encoded row.
        if isinstance(payload, dict):
            for raw in payload.values():
                row: Any = raw
                if isinstance(raw, str):
                    try:
                        row = json.loads(raw)
                    except Exception:
                        continue
                if isinstance(row, dict):
                    row = dict(row)
                    row.setdefault("lazy_missing_snapshot", True)
                    entry = self._entry_from_row(row, "lazyFile.json")
                    if entry:
                        yield entry

    def _load(self) -> None:
        try:
            payload = json.loads(self.catalog_path.read_text(encoding="utf-8"))
            seen: set[tuple[str, str]] = set()
            for entry in self._iter_rows(payload):
                key = (entry.path, entry.md5)
                if key in seen:
                    continue
                seen.add(key)
                self.entries.append(entry)
                self.by_request_asset.setdefault(entry.request_asset, []).append(entry)
                self.by_path[entry.path] = entry
        except Exception as exc:
            self.load_error = f"{type(exc).__name__}: {exc}"

    def lookup(self, requested_asset: str) -> list[ResourceEntry]:
        return list(self.by_request_asset.get(requested_asset, ()))

    def lookup_path(self, catalog_path: str) -> ResourceEntry | None:
        return self.by_path.get(self._valid_path(catalog_path))


def _discover_res_roots(search_roots: Iterable[Path], max_depth: int) -> tuple[Path, ...]:
    """Discover multiple Android ``res`` trees without scanning their files."""
    found: list[Path] = []
    seen: set[str] = set()

    def add(path: Path) -> None:
        try:
            key = str(path.resolve())
        except Exception:
            key = str(path)
        if key not in seen:
            seen.add(key)
            found.append(path)

    for configured in search_roots:
        root = configured.expanduser()
        if not root.exists() or not root.is_dir():
            continue
        # Preserve Stage 4A.4 direct-root behavior.
        add(root)
        if root.name.lower() == "res":
            continue

        queue = deque([(root, 0)])
        walked: set[str] = set()
        while queue:
            current, depth = queue.popleft()
            try:
                current_key = str(current.resolve())
            except Exception:
                current_key = str(current)
            if current_key in walked:
                continue
            walked.add(current_key)
            if depth >= max(0, max_depth):
                continue
            try:
                children = [child for child in current.iterdir() if child.is_dir()]
            except (OSError, PermissionError):
                continue

            res_children = [child for child in children if child.name.lower() == "res"]
            if res_children:
                for child in res_children:
                    add(child)
                # Android/hot-update roots place res beside src_32/src_64. Once
                # a direct res child is found, do not crawl those sibling source
                # trees merely to search for another res directory deeper down.
                continue

            for child in children:
                queue.append((child, depth + 1))
    return tuple(found)


def _discover_zip_archives(search_roots: Iterable[Path], max_depth: int) -> tuple[Path, ...]:
    """Discover ZIP/APK containers by filename only; payload bytes stay untouched."""
    found: list[Path] = []
    seen: set[str] = set()

    def add(path: Path) -> None:
        try:
            key = str(path.resolve())
        except Exception:
            key = str(path)
        if key not in seen:
            seen.add(key)
            found.append(path)

    for configured in search_roots:
        root = configured.expanduser()
        if root.is_file() and root.suffix.lower() in {".zip", ".apk"}:
            add(root)
            continue
        if not root.exists() or not root.is_dir():
            continue
        queue = deque([(root, 0)])
        walked: set[str] = set()
        while queue:
            current, depth = queue.popleft()
            try:
                current_key = str(current.resolve())
            except Exception:
                current_key = str(current)
            if current_key in walked:
                continue
            walked.add(current_key)
            try:
                children = list(current.iterdir())
            except (OSError, PermissionError):
                continue
            for child in children:
                if child.is_file() and child.suffix.lower() in {".zip", ".apk"}:
                    add(child)
            if depth >= max(0, max_depth):
                continue
            directories = [child for child in children if child.is_dir()]
            # Do not descend into an extracted res payload tree merely to look
            # for nested archives; ZIP files beside it were already recorded.
            for child in directories:
                if child.name.lower() != "res":
                    queue.append((child, depth + 1))
    return tuple(found)


class ResourceGateway:
    def __init__(self, settings: Settings) -> None:
        self.settings = settings
        self.log_root: Path = settings.runtime_log_dir
        self.log_root.mkdir(parents=True, exist_ok=True)
        self.catalog = ResourceCatalog(settings.resource_catalog_path)
        self.configured_asset_roots = settings.asset_roots
        self.asset_roots = _discover_res_roots(
            self.configured_asset_roots,
            settings.asset_discovery_depth,
        )
        self.asset_archives = _discover_zip_archives(
            self.configured_asset_roots,
            settings.asset_discovery_depth,
        )
        self._archive_errors: list[dict[str, str]] = []
        self._archive_index = self._build_archive_index()
        self._lock = threading.RLock()
        self._seen: dict[str, dict[str, Any]] = {}
        self._md5_cache: dict[tuple[str, int, int], str] = {}

        if self.catalog.load_error:
            print(f"[RESOURCE] catalog load failed: {self.catalog.load_error}")
        else:
            print(
                f"[RESOURCE] catalog={self.catalog.catalog_path} "
                f"entries={len(self.catalog.entries)} request_keys={len(self.catalog.by_request_asset)}"
            )
        if self.configured_asset_roots:
            print("[RESOURCE] configured roots: " + ", ".join(str(path) for path in self.configured_asset_roots))
            print("[RESOURCE] effective roots: " + (", ".join(str(path) for path in self.asset_roots) or "(none found)"))
            print(
                "[RESOURCE] ZIP/APK archives: "
                + (", ".join(str(path) for path in self.asset_archives) or "(none found)")
                + f"; indexed resource paths={len(self._archive_index)}"
            )
            if not self.asset_roots and not self.asset_archives:
                print(
                    "[RESOURCE][WARN] no usable asset store found. "
                    f"Normal path is {settings.static_asset_root / 'res'}; "
                    "resource gateway will remain audit/log-only until files are placed there."
                )
        else:
            print("[RESOURCE][WARN] no resource roots configured; gateway is log/audit-only")
        self._write_root_discovery()

    @staticmethod
    def _canonical_archive_member(member_name: str) -> str:
        pure = PurePosixPath(str(member_name).replace("\\", "/").lstrip("/"))
        parts = pure.parts
        lowered = [part.lower() for part in parts]
        try:
            index = lowered.index("res")
        except ValueError:
            return ""
        candidate = "/".join(parts[index:])
        return ResourceCatalog._valid_path(candidate)

    def _catalog_paths_for_archive_member(self, member_name: str) -> list[str]:
        """Map one archive member onto current and legacy catalog layouts.

        Current hot-update metadata names resources under ``res/web/...``. Older
        captured APK/data trees commonly store the identical payload under
        ``res/...`` without the ``web`` directory.  Keep both layouts valid and
        let the existing MD5 verification decide whether an older copy is the
        exact resource requested by the current client.
        """
        canonical = self._canonical_archive_member(member_name)
        if not canonical:
            return []

        candidates = [canonical]
        if canonical.startswith("res/") and not canonical.startswith("res/web/"):
            candidates.append("res/web/" + canonical[len("res/"):])

        return [path for path in candidates if path in self.catalog.by_path]

    def _build_archive_index(self) -> dict[str, list[tuple[Path, str, int]]]:
        """Index ZIP central-directory names using current + legacy res aliases."""
        index: dict[str, list[tuple[Path, str, int]]] = {}
        for archive in self.asset_archives:
            try:
                with zipfile.ZipFile(archive, "r") as zf:
                    for info in zf.infolist():
                        if info.is_dir():
                            continue
                        for catalog_path in self._catalog_paths_for_archive_member(info.filename):
                            index.setdefault(catalog_path, []).append((archive, info.filename, int(info.file_size)))
            except Exception as exc:
                self._archive_errors.append({"archive": str(archive), "error": f"{type(exc).__name__}: {exc}"})
        return index

    @staticmethod
    def _read_archive_member(archive: Path, member_name: str) -> bytes:
        with zipfile.ZipFile(archive, "r") as zf:
            return zf.read(member_name)

    @staticmethod
    def _archive_uri(archive: Path, member_name: str) -> str:
        return f"zip://{archive}!/{member_name}"

    @staticmethod
    def _split_asset(asset: str) -> tuple[str, str]:
        match = _MD5_SUFFIX_RE.match(asset)
        if not match:
            return asset, ""
        return match.group("name"), match.group("md5").lower()

    @staticmethod
    def _candidate_paths(root: Path, catalog_path: str) -> list[Path]:
        """Return exact candidates for both current and legacy resource layouts.

        Current metadata uses ``res/web/foo``. Community/older captures may be:
        ``<root>/res/web/foo`` (current), ``<root>/web/foo`` when root is res, or
        ``<root>/res/foo`` / ``<root>/foo`` for the older flat-res layout. MD5
        verification remains authoritative, so trying the legacy alias cannot
        silently substitute a wrong-version payload.
        """
        parts = PurePosixPath(catalog_path).parts
        candidates: list[Path] = []

        def add(relative_parts: tuple[str, ...]) -> None:
            if not relative_parts:
                return
            candidate = root.joinpath(*relative_parts)
            if candidate not in candidates:
                candidates.append(candidate)

        add(parts)
        if parts and parts[0] == "res":
            add(parts[1:])

        if len(parts) >= 2 and parts[:2] == ("res", "web"):
            # Legacy captures removed the intermediate web directory entirely.
            add(("res",) + parts[2:])
            add(parts[2:])

        return candidates

    @staticmethod
    def _file_md5(path: Path) -> str:
        digest = hashlib.md5()
        with path.open("rb") as fh:
            for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def _verified_md5(self, path: Path) -> str:
        stat = path.stat()
        key = (str(path.resolve()), stat.st_mtime_ns, stat.st_size)
        cached = self._md5_cache.get(key)
        if cached:
            return cached
        value = self._file_md5(path)
        self._md5_cache[key] = value
        return value

    def _append_event(self, record: dict[str, Any]) -> None:
        path = self.log_root / "resource_requests.jsonl"
        with path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(record, ensure_ascii=False, default=str, separators=(",", ":")) + "\n")

    def _write_summary(self) -> None:
        path = self.log_root / "resource_gateway_summary.json"
        tmp = path.with_suffix(path.suffix + ".tmp")
        payload = {
            "generated_at": int(time.time()),
            "resource_base": self.settings.res_download_url,
            "catalog_path": str(self.catalog.catalog_path),
            "catalog_entries": len(self.catalog.entries),
            "catalog_error": self.catalog.load_error,
            "configured_asset_roots": [str(path) for path in self.configured_asset_roots],
            "asset_roots": [str(path) for path in self.asset_roots],
            "asset_archives": [str(path) for path in self.asset_archives],
            "archive_index_paths": len(self._archive_index),
            "unique_requests": len(self._seen),
            "requests": sorted(self._seen.values(), key=lambda item: (item["first_seen"], item["requested_asset"])),
        }
        tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2, default=str) + "\n", encoding="utf-8")
        tmp.replace(path)

    def _record(self, req: Request, requested_asset: str, outcome: dict[str, Any]) -> None:
        now = int(time.time())
        basename, expected_md5 = self._split_asset(requested_asset)
        with self._lock:
            existing = self._seen.get(requested_asset)
            status = str(outcome.get("status") or "unknown")
            if existing is None:
                record = {
                    "ts": now,
                    "kind": "asset_download",
                    "requested_asset": requested_asset,
                    "basename": basename,
                    "expected_md5": expected_md5,
                    "method": req.method,
                    "remote_addr": req.remote_addr or "",
                    "user_agent": req.headers.get("User-Agent", ""),
                    "first_seen": now,
                    "last_seen": now,
                    "count": 1,
                    **outcome,
                }
                self._seen[requested_asset] = record
                self._append_event(record)
            else:
                existing["last_seen"] = now
                existing["count"] = int(existing.get("count", 0)) + 1
                old_status = existing.get("status")
                # Keep the latest resolution details in the summary.
                for key, value in outcome.items():
                    existing[key] = value
                if old_status != status or existing["count"] in {10, 100, 1000}:
                    self._append_event({"ts": now, "kind": "asset_download_update", **existing})
            self._write_summary()

    def _write_root_discovery(self) -> None:
        path = self.log_root / "resource_root_discovery.json"
        tmp = path.with_suffix(path.suffix + ".tmp")
        payload = {
            "generated_at": int(time.time()),
            "configured_roots": [str(p) for p in self.configured_asset_roots],
            "effective_roots": [str(p) for p in self.asset_roots],
            "archives": [str(p) for p in self.asset_archives],
            "archive_index_paths": len(self._archive_index),
            "archive_errors": self._archive_errors,
            "discovery_depth": self.settings.asset_discovery_depth,
            "note": "Directory discovery prunes res payload trees. Current res/web paths and legacy flat res paths are both tried; MD5 verification selects valid copies. ZIP/APK discovery indexes central-directory names only; member bytes are read/MD5-checked only for exact requested or audited catalog paths.",
        }
        tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        tmp.replace(path)

    def inspect_catalog_path(self, catalog_path: str) -> dict[str, Any]:
        """Resolve one original catalog path without requiring a client GET."""
        entry = self.catalog.lookup_path(catalog_path)
        if entry is None:
            return {
                "path": catalog_path,
                "status": "catalog_miss",
                "expected_md5": "",
                "lazy_missing_snapshot": False,
                "resolved_path": "",
                "candidate_paths": [],
            }

        candidates: list[str] = []
        mismatches: list[dict[str, Any]] = []
        for root in self.asset_roots:
            for candidate in self._candidate_paths(root, entry.path):
                candidates.append(str(candidate))
                if not candidate.is_file():
                    continue
                try:
                    actual_md5 = self._verified_md5(candidate) if self.settings.resource_verify_md5 else entry.md5
                    size = candidate.stat().st_size
                except Exception as exc:
                    mismatches.append({"path": str(candidate), "error": f"{type(exc).__name__}: {exc}"})
                    continue
                if self.settings.resource_verify_md5 and actual_md5 != entry.md5:
                    mismatches.append({"path": str(candidate), "actual_md5": actual_md5, "actual_size": size})
                    continue
                return {
                    "path": entry.path,
                    "status": "present",
                    "expected_md5": entry.md5,
                    "requested_asset": entry.request_asset,
                    "expected_size": entry.size,
                    "lazy_missing_snapshot": entry.lazy_missing_snapshot,
                    "resolved_path": str(candidate),
                    "actual_size": size,
                    "candidate_paths": candidates,
                }

        archive_candidates: list[str] = []
        for archive, member_name, member_size in self._archive_index.get(entry.path, []):
            uri = self._archive_uri(archive, member_name)
            archive_candidates.append(uri)
            try:
                data = self._read_archive_member(archive, member_name)
                actual_md5 = hashlib.md5(data).hexdigest() if self.settings.resource_verify_md5 else entry.md5
            except Exception as exc:
                mismatches.append({"path": uri, "error": f"{type(exc).__name__}: {exc}"})
                continue
            if self.settings.resource_verify_md5 and actual_md5 != entry.md5:
                mismatches.append({"path": uri, "actual_md5": actual_md5, "actual_size": len(data)})
                continue
            return {
                "path": entry.path,
                "status": "present",
                "expected_md5": entry.md5,
                "requested_asset": entry.request_asset,
                "expected_size": entry.size,
                "lazy_missing_snapshot": entry.lazy_missing_snapshot,
                "resolved_path": uri,
                "actual_size": len(data),
                "candidate_paths": candidates,
                "archive_candidates": archive_candidates,
            }

        status = "roots_unconfigured" if not self.configured_asset_roots else ("md5_mismatch" if mismatches else "local_file_missing")
        return {
            "path": entry.path,
            "status": status,
            "expected_md5": entry.md5,
            "requested_asset": entry.request_asset,
            "expected_size": entry.size,
            "lazy_missing_snapshot": entry.lazy_missing_snapshot,
            "resolved_path": "",
            "candidate_paths": candidates,
            "archive_candidates": archive_candidates,
            "mismatches": mismatches,
        }

    def _missing_response(self, status: str, requested_asset: str):
        response = make_response(f"GXB resource gateway: {status}: {requested_asset}\n", 404)
        response.headers["Cache-Control"] = "no-store"
        response.headers["X-GXB-Resource-Gateway"] = "1"
        response.headers["X-GXB-Resource-Status"] = status
        return response

    def capture(self, req: Request, asset: str):
        requested_asset = asset.lstrip("/")
        basename, expected_md5 = self._split_asset(requested_asset)
        entries = self.catalog.lookup(requested_asset)

        if not entries:
            outcome = {
                "status": "catalog_miss",
                "catalog_paths": [],
                "resolved_path": "",
            }
            self._record(req, requested_asset, outcome)
            print(f"[RESOURCE] catalog miss: {requested_asset}")
            return self._missing_response("catalog_miss", requested_asset)

        catalog_paths = [entry.path for entry in entries]
        candidate_strings: list[str] = []
        mismatches: list[dict[str, Any]] = []

        for entry in entries:
            for root in self.asset_roots:
                for candidate in self._candidate_paths(root, entry.path):
                    candidate_strings.append(str(candidate))
                    if not candidate.is_file():
                        continue
                    try:
                        stat = candidate.stat()
                        actual_md5 = self._verified_md5(candidate) if self.settings.resource_verify_md5 else expected_md5
                    except Exception as exc:
                        mismatches.append({
                            "path": str(candidate),
                            "error": f"{type(exc).__name__}: {exc}",
                        })
                        continue

                    if self.settings.resource_verify_md5 and actual_md5 != expected_md5:
                        mismatches.append({
                            "path": str(candidate),
                            "actual_size": stat.st_size,
                            "actual_md5": actual_md5,
                        })
                        continue

                    outcome = {
                        "status": "served",
                        "catalog_paths": catalog_paths,
                        "selected_catalog_path": entry.path,
                        "expected_size": entry.size,
                        "actual_size": stat.st_size,
                        "resolved_path": str(candidate),
                        "candidate_paths": candidate_strings,
                    }
                    self._record(req, requested_asset, outcome)
                    print(f"[RESOURCE] served {requested_asset} <- {candidate}")
                    guessed_type, _encoding = mimetypes.guess_type(entry.path)
                    response = send_file(
                        candidate,
                        mimetype=guessed_type or "application/octet-stream",
                        conditional=True,
                        max_age=0,
                    )
                    response.headers["X-GXB-Resource-Gateway"] = "1"
                    response.headers["X-GXB-Resource-Status"] = "served"
                    response.headers["X-GXB-Catalog-Path"] = entry.path
                    return response

        archive_candidates: list[str] = []
        for entry in entries:
            for archive, member_name, member_size in self._archive_index.get(entry.path, []):
                uri = self._archive_uri(archive, member_name)
                archive_candidates.append(uri)
                try:
                    data = self._read_archive_member(archive, member_name)
                    actual_md5 = hashlib.md5(data).hexdigest() if self.settings.resource_verify_md5 else expected_md5
                except Exception as exc:
                    mismatches.append({"path": uri, "error": f"{type(exc).__name__}: {exc}"})
                    continue
                if self.settings.resource_verify_md5 and actual_md5 != expected_md5:
                    mismatches.append({"path": uri, "actual_size": len(data), "actual_md5": actual_md5})
                    continue
                outcome = {
                    "status": "served",
                    "catalog_paths": catalog_paths,
                    "selected_catalog_path": entry.path,
                    "expected_size": entry.size,
                    "actual_size": len(data),
                    "resolved_path": uri,
                    "candidate_paths": candidate_strings,
                    "archive_candidates": archive_candidates,
                }
                self._record(req, requested_asset, outcome)
                print(f"[RESOURCE] served {requested_asset} <- {uri}")
                guessed_type, _encoding = mimetypes.guess_type(entry.path)
                response = send_file(
                    io.BytesIO(data),
                    mimetype=guessed_type or "application/octet-stream",
                    download_name=entry.basename,
                    conditional=False,
                    max_age=0,
                )
                response.headers["X-GXB-Resource-Gateway"] = "1"
                response.headers["X-GXB-Resource-Status"] = "served"
                response.headers["X-GXB-Catalog-Path"] = entry.path
                return response

        if not self.asset_roots and not self.asset_archives:
            status = "asset_roots_unconfigured"
        elif mismatches:
            status = "md5_mismatch"
        else:
            status = "local_file_missing"

        outcome = {
            "status": status,
            "catalog_paths": catalog_paths,
            "resolved_path": "",
            "candidate_paths": candidate_strings,
            "archive_candidates": archive_candidates,
            "mismatches": mismatches,
        }
        self._record(req, requested_asset, outcome)
        print(f"[RESOURCE] {status}: {requested_asset} -> {catalog_paths}")
        return self._missing_response(status, requested_asset)
