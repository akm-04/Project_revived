#!/usr/bin/env python3
"""Interactive operator controller for GXB EOL MID2 updates and legacy PNG donors.

Pass299 canonical stock-client-compatible separated-lane auto-update model
=========================
Runtime authority is ``local_assets/release_registry.json``. Published releases
are immutable history and MID2 selects the next compatible release/batch by
``app_v`` + platform + installed resource version.

Release classes:
- BULK_RESOURCE_BOOTSTRAP: rare loud barrier that packages exact-current recovered
  lazy assets into the writable physical layout and installs a reconciled root
  lazyFile.json for the post-bulk stock-client state. It carries no version.json
  and no Lua; it never reads old_res.
- CODE_ONLY: normal cumulative Lua/table OTA. Defaults silent and is structurally
  forbidden from carrying version.json.
- CATALOG_MIGRATION: future rare loud barrier that carries the complete version.json
  and atomically promotes an explicitly enabled legacy donor whitelist/resource catalog.

A catalog migration can *inherit the version of an unpublished CODE_ONLY
candidate* by rebuilding that candidate in-place as a loud catalog migration.
Once a version is published, it is immutable and a later catalog migration must
use the next version. This avoids needless double version bumps without ever
serving two different published payloads under one installed version.

Historical fallback is disabled by default in Pass293. Historical assets remain
deny-by-default under local_assets/old_res; merely placing a file there never
authorizes it. A future asset-rebuild cycle may re-enable the feature explicitly and
publish exact current path + MD5 + size + SHA256 provenance with a matching catalog
migration.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import shutil
import struct
import tempfile
import zipfile
from copy import deepcopy
from pathlib import Path, PurePosixPath
from typing import Any

from gxb_backend.updates.lazy_bootstrap import build_lazy_map
from gxb_backend.updates.mid2_compat import (
    CURRENT_STOCK_PROFILE,
    evaluate_volume_plan,
    plan_volume_sizes,
    validate_declared_metrics,
)

ROOT = Path(__file__).resolve().parent
LOCAL = ROOT / "local_assets"
UPDATES = LOCAL / "updates"
ASSET_UPDATES = UPDATES / "assets"
CODE_UPDATES = UPDATES / "code"
CATALOG_UPDATES = UPDATES / "catalog"
UPDATE_HISTORY = UPDATES / "history"
POLICY_DIR = LOCAL / "update_policy"
STAGING = LOCAL / "update_staging"
LEGACY_MANIFEST = LOCAL / "update_manifest.json"  # operator/backward metadata only
REGISTRY = LOCAL / "release_registry.json"
STATE = LOCAL / "update_controller_state.json"
AUTO_POLICY = LOCAL / "settings.json"
CURRENT_RES = LOCAL / "res"
OLD_RES = LOCAL / "old_res"

DATA = ROOT / "data" / "resource_catalog"
BASE_VERSION = DATA / "version_base_1.631.0.json"
ACTIVE_VERSION = DATA / "version_active.json"
ACTIVE_CATALOG = DATA / "resource_catalog.json"
ACTIVE_ALLOWLIST = DATA / "legacy_fallback_allowlist.json"
STAGED_ALLOWLIST = POLICY_DIR / "legacy_fallback_allowlist.staged.json"

VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
MD5_RE = re.compile(r"^[0-9a-f]{32}$")
SHA256_RE = re.compile(r"^[0-9a-f]{64}$")
CODE_ONLY = "CODE_ONLY"
CATALOG_MIGRATION = "CATALOG_MIGRATION"
BULK_RESOURCE = "BULK_RESOURCE_BOOTSTRAP"
PUBLISHED = "PUBLISHED"
CANDIDATE = "CANDIDATE"
DEFAULT_APP_V = "1.631.0"
DEFAULT_PLATFORM = 3
GIT_SAFE_VOLUME_BYTES = 99_000_000
APPROVED_UPDATE_LANES = {"assets", "code", "catalog"}


def release_lane(release_type: str) -> str:
    if release_type == BULK_RESOURCE:
        return "assets"
    if release_type == CODE_ONLY:
        return "code"
    if release_type == CATALOG_MIGRATION:
        return "catalog"
    raise ValueError(f"unsupported release type: {release_type}")


def lane_dir(lane: str) -> Path:
    if lane == "assets":
        return ASSET_UPDATES
    if lane == "code":
        return CODE_UPDATES
    if lane == "catalog":
        return CATALOG_UPDATES
    raise ValueError(f"unsupported update lane: {lane}")


def release_dir(release: dict[str, Any]) -> Path:
    lane = str(release.get("lane") or "").strip()
    return lane_dir(lane) if lane else UPDATES


def release_sidecar_path(release: dict[str, Any]) -> Path:
    return release_dir(release) / f"{release['package']}.release.json"


def load_json(path: Path, default: Any = None) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except FileNotFoundError:
        if default is not None:
            return deepcopy(default)
        raise


def write_json_atomic(path: Path, payload: Any) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, temp_name = tempfile.mkstemp(prefix=path.name + ".", suffix=".tmp", dir=str(path.parent))
    os.close(fd)
    tmp = Path(temp_name)
    try:
        tmp.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
        tmp.replace(path)
    finally:
        tmp.unlink(missing_ok=True)


def hash_file(path: Path, algo: str) -> str:
    h = hashlib.new(algo)
    with path.open("rb") as fh:
        for block in iter(lambda: fh.read(1024 * 1024), b""):
            h.update(block)
    return h.hexdigest()


def digest_json(payload: Any) -> str:
    raw = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def parse_version(value: str) -> tuple[int, int, int]:
    m = VERSION_RE.fullmatch(str(value).strip())
    if not m:
        raise ValueError("resource version must be exactly N.N.N")
    return tuple(int(x) for x in m.groups())


def next_version(value: str) -> str:
    major, minor, patch = parse_version(value)
    return f"{major}.{minor}.{patch + 1}"


def empty_allowlist() -> dict[str, Any]:
    return {
        "schema_version": 1,
        "status": "ACTIVE_RUNTIME_POLICY",
        "default_policy": "DENY_LEGACY_FALLBACK",
        "current_root": "local_assets/res",
        "legacy_root": "local_assets/old_res",
        "lookup_key": ["current_path", "catalog_md5"],
        "entries": [],
    }


def normalize_allowlist(payload: Any) -> dict[str, Any]:
    if not isinstance(payload, dict):
        raise ValueError("allowlist must be an object")
    if str(payload.get("default_policy") or "") != "DENY_LEGACY_FALLBACK":
        raise ValueError("allowlist default_policy must be DENY_LEGACY_FALLBACK")
    rows = payload.get("entries")
    if not isinstance(rows, list):
        raise ValueError("allowlist entries must be a list")
    seen: set[tuple[str, str]] = set()
    normalized = deepcopy(payload)
    normalized_rows = []
    for i, row in enumerate(rows):
        if not isinstance(row, dict):
            raise ValueError(f"allowlist row {i} is not an object")
        path = str(row.get("current_path") or "").replace("\\", "/").lstrip("/")
        rel = str(row.get("fallback_relpath") or "").replace("\\", "/").lstrip("/")
        md5 = str(row.get("donor_md5") or row.get("catalog_md5") or "").lower()
        sha = str(row.get("donor_sha256") or "").lower()
        if not path.startswith("res/web/") or ".." in PurePosixPath(path).parts:
            raise ValueError(f"unsafe current_path: {path!r}")
        if not rel or ".." in PurePosixPath(rel).parts:
            raise ValueError(f"unsafe fallback_relpath: {rel!r}")
        if not MD5_RE.fullmatch(md5) or not SHA256_RE.fullmatch(sha):
            raise ValueError(f"invalid donor hash on {path}")
        if str(row.get("catalog_md5") or md5).lower() != md5:
            raise ValueError(f"catalog_md5 != donor_md5 on {path}")
        try:
            size = int(row.get("donor_size"))
        except Exception as exc:
            raise ValueError(f"invalid donor_size on {path}") from exc
        key = (path, md5)
        if key in seen:
            raise ValueError(f"duplicate whitelist key: {key}")
        seen.add(key)
        copy = deepcopy(row)
        copy.update({
            "current_path": path,
            "catalog_md5": md5,
            "donor_md5": md5,
            "donor_sha256": sha,
            "donor_size": size,
            "catalog_size": size,
            "fallback_relpath": rel,
        })
        normalized_rows.append(copy)
    normalized["entries"] = sorted(normalized_rows, key=lambda r: (r["current_path"], r["catalog_md5"]))
    return normalized


def png_info(path: Path) -> tuple[int, int, int, int, int]:
    with path.open("rb") as fh:
        header = fh.read(33)
    if len(header) < 33 or header[:8] != b"\x89PNG\r\n\x1a\n" or header[12:16] != b"IHDR":
        raise ValueError("not a PNG")
    width, height, bit_depth, color_type, _compression, _filter, interlace = struct.unpack(">IIBBBBB", header[16:29])
    return width, height, bit_depth, color_type, interlace


def base_rows() -> list[dict[str, Any]]:
    payload = load_json(BASE_VERSION)
    if not isinstance(payload, list):
        raise ValueError(f"{BASE_VERSION} must be a JSON list")
    return payload


def base_by_path() -> dict[str, dict[str, Any]]:
    return {str(r.get("path") or ""): r for r in base_rows() if isinstance(r, dict) and r.get("path")}


def apply_overlay(allowlist: dict[str, Any]) -> list[dict[str, Any]]:
    rows = deepcopy(base_rows())
    index = {str(r.get("path") or ""): r for r in rows if isinstance(r, dict)}
    for entry in allowlist["entries"]:
        path = entry["current_path"]
        row = index.get(path)
        if row is None:
            raise ValueError(f"whitelist current path is absent from full base version.json: {path}")
        if int(row.get("force") or 0) != 0:
            raise ValueError(f"legacy fallback is allowed only for lazy force=0 rows: {path}")
        row["md5"] = entry["donor_md5"]
        row["size"] = int(entry["donor_size"])
    return rows


def build_reverse_catalog(version_rows: list[dict[str, Any]]) -> dict[str, Any]:
    entries = []
    for row in version_rows:
        if not isinstance(row, dict):
            continue
        path = str(row.get("path") or "").replace("\\", "/")
        md5 = str(row.get("md5") or "").lower()
        if not path.startswith("res/web/") or not MD5_RE.fullmatch(md5):
            continue
        entries.append({"path": path, "md5": md5, "size": int(row.get("size") or 0), "source": "version.json"})
    entries.sort(key=lambda r: (r["path"], r["md5"]))
    return {"_meta": {"generated_by": "update_controller.py", "version_entries": len(version_rows), "catalog_entries": len(entries)}, "entries": entries}


def validate_donors(allowlist: dict[str, Any], *, verbose: bool = True) -> tuple[int, list[str]]:
    problems: list[str] = []
    if allowlist["entries"] and not OLD_RES.is_dir():
        problems.append(f"old_res directory is missing: {OLD_RES}")
        return 0, problems
    valid = 0
    for entry in allowlist["entries"]:
        candidate = OLD_RES.joinpath(*PurePosixPath(entry["fallback_relpath"]).parts)
        if not candidate.is_file():
            problems.append(f"missing donor: {entry['current_path']} -> {candidate}")
            continue
        size = candidate.stat().st_size
        md5 = hash_file(candidate, "md5")
        sha = hash_file(candidate, "sha256")
        if size != int(entry["donor_size"]):
            problems.append(f"size mismatch: {candidate} expected={entry['donor_size']} actual={size}")
        elif md5 != entry["donor_md5"]:
            problems.append(f"md5 mismatch: {candidate} expected={entry['donor_md5']} actual={md5}")
        elif sha != entry["donor_sha256"]:
            problems.append(f"sha256 mismatch: {candidate} expected={entry['donor_sha256']} actual={sha}")
        else:
            valid += 1
    if verbose:
        print(f"[UPDATE-CONTROLLER] donor validation: valid={valid} problems={len(problems)}")
        for p in problems:
            print(f"  - {p}")
    return valid, problems




def configured_ota_generation() -> str:
    raw = load_json(AUTO_POLICY, default={})
    if not isinstance(raw, dict):
        return ""
    policy = raw.get("updates") if isinstance(raw.get("updates"), dict) else raw
    return str(policy.get("canonical_generation") or "").strip()


def _archive_registry_snapshot(registry: dict[str, Any], *, reason: str) -> Path:
    """Preserve detached runtime registry history before a canonical generation reset."""
    raw = json.dumps(registry, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
    digest = hashlib.sha256(raw).hexdigest()[:16]
    target = UPDATE_HISTORY / "registry" / f"release_registry.{digest}.json"
    if not target.exists():
        payload = deepcopy(registry)
        payload["archived_reason"] = reason
        write_json_atomic(target, payload)
    return target


def _archive_stale_same_version_artifacts(version: str, release_type: str, expected_generation: str) -> list[str]:
    """Move same-version artifacts from an older OTA generation out of active lanes.

    Pass299 deliberately reuses 1.631.1/1.631.2 after the updater was runtime
    reconciled. Old experimental bytes are not deleted; they are detached into
    local update history so a stale sidecar can never be mistaken for the
    canonical package.
    """
    if not expected_generation:
        return []
    lane = release_lane(release_type)
    root = lane_dir(lane)
    package = _expected_package(version, release_type)
    sidecar = root / f"{package}.release.json"
    if not sidecar.is_file():
        return []
    try:
        payload = load_json(sidecar, default={})
    except Exception:
        payload = {}
    if str(payload.get("ota_generation") or "") == expected_generation:
        return []
    digest = hash_file(sidecar, "sha256")[:16]
    dest = UPDATE_HISTORY / "artifacts" / f"{version}-{digest}" / lane
    dest.mkdir(parents=True, exist_ok=True)
    moved: list[str] = []
    for src in sorted(root.glob(package + ".*")):
        target = dest / src.name
        if target.exists():
            if hash_file(target, "sha256") != hash_file(src, "sha256"):
                raise ValueError(f"history collision while archiving stale OTA artifact: {target}")
            src.unlink()
        else:
            shutil.move(str(src), str(target))
        moved.append(str(target.relative_to(LOCAL)))
    return moved


def load_registry() -> dict[str, Any]:
    payload = load_json(REGISTRY)
    if not isinstance(payload, dict) or int(payload.get("schema_version") or 0) != 1:
        raise ValueError("release_registry.json schema is invalid")
    if not isinstance(payload.get("tracks"), list):
        raise ValueError("release_registry.json tracks must be a list")
    return payload


def current_track(registry: dict[str, Any] | None = None) -> dict[str, Any]:
    registry = registry or load_registry()
    for track in registry["tracks"]:
        if str(track.get("app_v") or "") == DEFAULT_APP_V and int(track.get("platform") or 0) == DEFAULT_PLATFORM:
            return track
    raise ValueError("current Android 1.631.0 update track is missing")


def releases_sorted(track: dict[str, Any]) -> list[dict[str, Any]]:
    rows = list(track.get("releases") or [])
    rows.sort(key=lambda r: parse_version(str(r.get("version") or "0.0.0")))
    return rows


def candidate_release(track: dict[str, Any]) -> dict[str, Any] | None:
    rows = [r for r in track.get("releases", []) if str(r.get("status") or "") == CANDIDATE]
    if len(rows) > 1:
        raise ValueError("only one operator candidate is supported per track")
    return rows[0] if rows else None


def track_base_version(track: dict[str, Any]) -> str:
    value = str(track.get("base_version") or DEFAULT_APP_V)
    parse_version(value)
    return value


def highest_version(track: dict[str, Any]) -> str:
    rows = releases_sorted(track)
    return str(rows[-1]["version"]) if rows else track_base_version(track)


def highest_published_version(track: dict[str, Any]) -> str:
    rows = [r for r in releases_sorted(track) if str(r.get("status") or "") == PUBLISHED]
    return str(rows[-1]["version"]) if rows else track_base_version(track)


def iter_sparse_overrides() -> list[tuple[Path, str]]:
    """Return cumulative current Lua/table OTA files, excluding resource catalogs."""
    out: list[tuple[Path, str]] = []
    for arch in ("src_32", "src_64"):
        base = LOCAL / arch
        if not base.is_dir():
            continue
        for path in sorted(base.rglob("*")):
            if not path.is_file():
                continue
            rel = path.relative_to(LOCAL).as_posix()
            if rel.endswith("/version.json") or rel in {"src_32/version.json", "src_64/version.json"}:
                continue
            out.append((path, rel))
    return out


def _current_asset_candidates(root: Path, catalog_path: str) -> list[Path]:
    parts = PurePosixPath(catalog_path).parts
    out: list[Path] = []
    def add(relparts: tuple[str, ...]) -> None:
        if not relparts:
            return
        candidate = root.joinpath(*relparts)
        if candidate not in out:
            out.append(candidate)
    add(parts)
    if parts and parts[0] == "res":
        add(parts[1:])
    if len(parts) >= 2 and parts[:2] == ("res", "web"):
        add(("res",) + parts[2:])
        add(parts[2:])
    return out


def _bulk_arcname(catalog_path: str) -> str:
    parts = PurePosixPath(catalog_path).parts
    if len(parts) < 3 or parts[:2] != ("res", "web"):
        raise ValueError(f"bulk bootstrap supports current lazy res/web paths only: {catalog_path}")
    return PurePosixPath("res", *parts[2:]).as_posix()


def collect_exact_bulk_assets(
    rows: list[dict[str, Any]],
    root: Path,
    *,
    min_files: int = 1,
    progress_every: int = 2000,
) -> tuple[list[tuple[Path, str]], dict[str, Any]]:
    """Collect exact-current lazy assets for a bulk writable bootstrap.

    Historical old_res is intentionally never consulted. The APK/base catalog MD5
    remains authority and archive names use the stock writable /web/ -> / alias.
    """
    if not root.is_dir():
        raise ValueError(f"current res directory is missing: {root}")
    files: list[tuple[Path, str]] = []
    missing: list[str] = []
    mismatch: list[dict[str, Any]] = []
    seen_arc: set[str] = set()
    considered = 0
    for row in rows:
        if not isinstance(row, dict) or int(row.get("force") or 0) != 0:
            continue
        path = str(row.get("path") or "").replace("\\", "/")
        md5 = str(row.get("md5") or "").lower()
        if not path.startswith("res/web/") or not MD5_RE.fullmatch(md5):
            continue
        considered += 1
        exact: Path | None = None
        mismatches_for_path: list[str] = []
        for candidate in _current_asset_candidates(root, path):
            if not candidate.is_file():
                continue
            actual = hash_file(candidate, "md5")
            if actual == md5:
                exact = candidate
                break
            mismatches_for_path.append(f"{candidate}:{actual}")
        if exact is None:
            if mismatches_for_path:
                mismatch.append({"path": path, "expected_md5": md5, "candidates": mismatches_for_path})
            else:
                missing.append(path)
            continue
        arcname = _bulk_arcname(path)
        if arcname in seen_arc:
            raise ValueError(f"bulk writable path collision after /web/ removal: {arcname}")
        seen_arc.add(arcname)
        files.append((exact, arcname))
        if progress_every and len(files) % progress_every == 0:
            print(f"[UPDATE-CONTROLLER] bulk exact assets {len(files):,}/{considered:,}")
    if len(files) < int(min_files):
        raise ValueError(f"bulk bootstrap exact asset count {len(files)} is below required minimum {min_files}")
    summary = {
        "catalog_lazy_considered": considered,
        "exact_files": len(files),
        "missing_files": len(missing),
        "mismatching_files": len(mismatch),
        "physical_bytes": sum(src.stat().st_size for src, _ in files),
        "path_policy": "res/web/... -> res/... writable alias",
        "historical_old_res_used": False,
        "missing_sample": missing[:100],
        "mismatch_sample": mismatch[:100],
    }
    return files, summary


def _remove_candidate_volumes(release: dict[str, Any] | None) -> None:
    if not release:
        return
    if str(release.get("status") or "") != CANDIDATE:
        raise ValueError("refusing to delete volumes for a published release")
    package = str(release.get("package") or "")
    out_dir = release_dir(release)
    for idx in range(1, int(release.get("volume") or 0) + 1):
        (out_dir / f"{package}.{idx:03d}").unlink(missing_ok=True)
    release_sidecar_path(release).unlink(missing_ok=True)


def _split_zip(
    assembled: Path,
    package: str,
    max_volume_bytes: int = GIT_SAFE_VOLUME_BYTES,
    *,
    out_dir: Path | None = None,
) -> tuple[int, int, str, str, list[dict[str, Any]]]:
    """Split one assembled ZIP into raw stock MID2 .001... fragments.

    The configured cap remains Git-safe, but fragment boundaries are planned
    through the current stock-client compatibility profile so every completed
    volume survives the native float32 progress bridge exactly and local
    assembly offsets stay within signed-int32 semantics.
    """
    data_size = assembled.stat().st_size
    md5 = hash_file(assembled, "md5")
    sha = hash_file(assembled, "sha256")
    chunk = int(max_volume_bytes or data_size)
    if chunk <= 0:
        chunk = data_size
    if chunk > GIT_SAFE_VOLUME_BYTES:
        raise ValueError(
            f"update shard cap {chunk:,} exceeds Git-safe maximum "
            f"{GIT_SAFE_VOLUME_BYTES:,} bytes"
        )
    out_dir = out_dir or UPDATES
    out_dir.mkdir(parents=True, exist_ok=True)
    planned_sizes = plan_volume_sizes(data_size, chunk)
    volume = len(planned_sizes)
    volume_files: list[dict[str, Any]] = []
    with assembled.open("rb") as src:
        for idx, planned_size in enumerate(planned_sizes, 1):
            target = out_dir / f"{package}.{idx:03d}"
            h_md5 = hashlib.md5(); h_sha = hashlib.sha256(); written = 0
            with target.open("wb") as dst:
                remaining = planned_size
                while remaining > 0:
                    block = src.read(min(1024 * 1024, remaining))
                    if not block:
                        break
                    dst.write(block); h_md5.update(block); h_sha.update(block)
                    written += len(block); remaining -= len(block)
            if written != planned_size:
                raise ValueError(
                    f"generated shard short write: {target} planned={planned_size} actual={written}"
                )
            if written > GIT_SAFE_VOLUME_BYTES:
                raise ValueError(f"generated shard exceeds Git-safe cap: {target} size={written}")
            volume_files.append({
                "index": idx, "name": target.name, "size": written,
                "md5": h_md5.hexdigest(), "sha256": h_sha.hexdigest(),
            })
    # Fail closed inside the splitter too; publication later repeats the same
    # compatibility check against the files actually written.
    evaluate_volume_plan([r["size"] for r in volume_files], data_size)
    return volume, data_size, md5, sha, volume_files


def _verify_release_volumes(release: dict[str, Any], *, deep: bool = True) -> None:
    package = str(release["package"])
    volume = int(release["volume"])
    out_dir = release_dir(release)
    declared = release.get("volume_files") if isinstance(release.get("volume_files"), list) else []
    by_idx = {int(r.get("index") or 0): r for r in declared if isinstance(r, dict)}
    size = 0
    h = hashlib.md5() if deep else None
    for idx in range(1, volume + 1):
        p = out_dir / f"{package}.{idx:03d}"
        if not p.is_file():
            raise ValueError(f"release volume missing: {p}")
        actual_size = p.stat().st_size
        if actual_size > GIT_SAFE_VOLUME_BYTES:
            raise ValueError(f"release volume exceeds Git-safe cap: {p} size={actual_size}")
        row = by_idx.get(idx)
        if row and actual_size != int(row.get("size") or -1):
            raise ValueError(f"release volume size differs from sidecar/registry: {p}")
        size += actual_size
        if deep:
            part_md5 = hashlib.md5(); part_sha = hashlib.sha256()
            with p.open("rb") as fh:
                for block in iter(lambda: fh.read(1024 * 1024), b""):
                    h.update(block); part_md5.update(block); part_sha.update(block)
            if row:
                if str(row.get("md5") or "").lower() != part_md5.hexdigest():
                    raise ValueError(f"release volume MD5 mismatch: {p}")
                if str(row.get("sha256") or "").lower() != part_sha.hexdigest():
                    raise ValueError(f"release volume SHA256 mismatch: {p}")
    if size != int(release["size"]):
        raise ValueError("release assembled size does not match registry")
    metrics = evaluate_volume_plan(
        [int((by_idx.get(i) or {}).get("size") or (out_dir / f"{package}.{i:03d}").stat().st_size) for i in range(1, volume + 1)],
        size,
    )
    validate_declared_metrics(release, metrics)
    if deep and h.hexdigest() != str(release["md5"]):
        raise ValueError("release assembled MD5 does not match registry")


def _write_release_sidecar(release: dict[str, Any]) -> None:
    payload = deepcopy(release)
    payload["sidecar_schema_version"] = 2
    payload["operator_note"] = "Immutable artifact provenance; filename alone is never sufficient authority."
    write_json_atomic(release_sidecar_path(release), payload)


def _candidate_version(track: dict[str, Any], release_type: str, requested: str | None, increment: bool, inherit_candidate: bool) -> str:
    existing = candidate_release(track)
    if requested:
        version = str(requested)
        parse_version(version)
        if existing and version != str(existing["version"]):
            if parse_version(version) <= parse_version(str(existing["version"])):
                raise ValueError("explicit candidate version must exceed existing candidate unless rebuilding same version")
        if parse_version(version) <= parse_version(highest_published_version(track)):
            raise ValueError("candidate version must be greater than every published release")
        return version
    if release_type == CATALOG_MIGRATION and inherit_candidate and existing and str(existing.get("release_type")) == CODE_ONLY:
        print(f"[UPDATE-CONTROLLER] coalescing unpublished CODE_ONLY {existing['version']} into CATALOG_MIGRATION at the SAME version")
        return str(existing["version"])
    if existing:
        # Rebuild an existing candidate at its version unless caller explicitly
        # asks for a fresh increment. This is safe because it is unpublished.
        if not increment:
            return str(existing["version"])
        return next_version(str(existing["version"]))
    return next_version(highest_published_version(track))


def build_release(
    release_type: str,
    *,
    version: str | None = None,
    increment: bool = False,
    silent: bool | None = None,
    volume_mib: float = 0,
    max_volume_bytes: int | None = None,
    inherit_candidate: bool = True,
    bulk_min_files: int = 25000,
) -> dict[str, Any]:
    release_type = release_type.upper()
    if release_type not in {CODE_ONLY, CATALOG_MIGRATION, BULK_RESOURCE}:
        raise ValueError("unsupported release type")
    registry = load_registry()
    track = current_track(registry)
    active = normalize_allowlist(load_json(ACTIVE_ALLOWLIST, default=empty_allowlist()))
    staged = normalize_allowlist(load_json(STAGED_ALLOWLIST, default=active))
    whitelist_changed = digest_json(active["entries"]) != digest_json(staged["entries"])

    if release_type == CODE_ONLY:
        if whitelist_changed:
            raise ValueError("staged whitelist differs from active: CODE_ONLY build refused; build a loud CATALOG_MIGRATION")
        if silent is None:
            silent = True
    elif release_type == CATALOG_MIGRATION:
        if silent is True:
            raise ValueError("CATALOG_MIGRATION is a loud barrier; silent mode is refused")
        silent = False
    else:
        if whitelist_changed or active["entries"] or staged["entries"]:
            raise ValueError("BULK_RESOURCE_BOOTSTRAP requires legacy fallback disabled with empty active/staged allowlists")
        if silent is True:
            raise ValueError("BULK_RESOURCE_BOOTSTRAP is a loud barrier; silent mode is refused")
        silent = False

    if max_volume_bytes is None:
        if volume_mib:
            requested = int(float(volume_mib) * 1024 * 1024)
            if requested > GIT_SAFE_VOLUME_BYTES:
                raise ValueError(
                    f"--volume-mib={volume_mib} produces {requested:,} bytes; "
                    f"Git-safe releases are capped at {GIT_SAFE_VOLUME_BYTES:,} bytes. "
                    "Use --volume-mb 99 (decimal) or omit the option."
                )
            max_volume_bytes = requested
        else:
            max_volume_bytes = GIT_SAFE_VOLUME_BYTES
    max_volume_bytes = int(max_volume_bytes)
    if max_volume_bytes <= 0 or max_volume_bytes > GIT_SAFE_VOLUME_BYTES:
        raise ValueError(f"max_volume_bytes must be between 1 and {GIT_SAFE_VOLUME_BYTES:,}")

    version = _candidate_version(track, release_type, version, increment, inherit_candidate)
    old_candidate = candidate_release(track)
    if old_candidate and str(old_candidate["version"]) != version and parse_version(version) <= parse_version(str(old_candidate["version"])):
        raise ValueError("new candidate must be monotonic")
    if parse_version(version) <= parse_version(highest_published_version(track)):
        raise ValueError("cannot rebuild or reuse a published version")

    bulk_summary: dict[str, Any] | None = None
    bulk_lazy_summary: dict[str, Any] | None = None
    bulk_lazy_sha256: str | None = None
    if release_type == BULK_RESOURCE:
        rows = base_rows()
        files, bulk_summary = collect_exact_bulk_assets(rows, CURRENT_RES, min_files=bulk_min_files)
        supplied_catalog_paths = {
            "res/web/" + arcname[len("res/"):]
            for _src, arcname in files
            if arcname.startswith("res/")
        }
        lazy_map, bulk_lazy_summary = build_lazy_map(rows, supplied_catalog_paths)
        if bulk_lazy_summary["supplied_exact_lazy_paths"] != bulk_summary["exact_files"]:
            raise ValueError(
                "bulk asset/lazy-state accounting mismatch: "
                f"exact_files={bulk_summary['exact_files']} "
                f"supplied_lazy={bulk_lazy_summary['supplied_exact_lazy_paths']}"
            )
        STAGING.mkdir(parents=True, exist_ok=True)
        write_json_atomic(STAGING / "lazyFile.json", lazy_map)
        bulk_lazy_sha256 = hash_file(STAGING / "lazyFile.json", "sha256")
        combined_summary = deepcopy(bulk_summary)
        combined_summary["lazy_state"] = bulk_lazy_summary
        combined_summary["lazy_file_sha256"] = bulk_lazy_sha256
        write_json_atomic(STAGING / "bulk_asset_bootstrap_summary.json", combined_summary)
    else:
        files = iter_sparse_overrides()
    contains_version_json = release_type == CATALOG_MIGRATION
    if contains_version_json:
        rows = apply_overlay(staged)
        reverse = build_reverse_catalog(rows)
        STAGING.mkdir(parents=True, exist_ok=True)
        write_json_atomic(STAGING / "version.json", rows)
        write_json_atomic(STAGING / "resource_catalog.json", reverse)
        staged_runtime_allowlist = deepcopy(staged)
        staged_runtime_allowlist["status"] = f"CANDIDATE_RUNTIME_POLICY_OTA_{version}"
        write_json_atomic(STAGING / "legacy_fallback_allowlist.json", staged_runtime_allowlist)

    lane = release_lane(release_type)
    out_dir = lane_dir(lane)
    out_dir.mkdir(parents=True, exist_ok=True)
    package = f"gxb-assets-{version}.zip" if release_type == BULK_RESOURCE else f"gxb-local-{version}.zip"
    fd, tmp_name = tempfile.mkstemp(prefix="gxb-update-", suffix=".zip", dir=str(out_dir))
    os.close(fd)
    tmp = Path(tmp_name)
    try:
        compression = zipfile.ZIP_STORED if release_type == BULK_RESOURCE else zipfile.ZIP_DEFLATED
        kwargs = {} if compression == zipfile.ZIP_STORED else {"compresslevel": 6}
        with zipfile.ZipFile(tmp, "w", compression=compression, **kwargs) as zf:
            for src, arcname in files:
                zf.write(src, arcname)
            if release_type == BULK_RESOURCE:
                zf.write(STAGING / "lazyFile.json", "lazyFile.json")
            if contains_version_json:
                zf.write(STAGING / "version.json", "src_32/version.json")
                zf.write(STAGING / "version.json", "src_64/version.json")
        # Only unpublished candidate volumes may be replaced. Published volumes
        # are immutable history and are never garbage-collected here.
        if old_candidate:
            _remove_candidate_volumes(old_candidate)
        volume, size, md5, sha, volume_files = _split_zip(
            tmp, package, max_volume_bytes, out_dir=out_dir
        )
    finally:
        tmp.unlink(missing_ok=True)

    release = {
        "version": version,
        "ota_generation": configured_ota_generation(),
        "status": CANDIDATE,
        "release_type": release_type,
        "silent": bool(silent),
        "package": package,
        "lane": lane,
        "volume": volume,
        "volume_files": volume_files,
        "max_volume_bytes": max_volume_bytes,
        "size": size,
        "md5": md5,
        "sha256": sha,
        **evaluate_volume_plan([int(row["size"]) for row in volume_files], size),
        "cumulative": release_type != BULK_RESOURCE,
        "contains_version_json": contains_version_json,
        "file_count": len(files) + (1 if release_type == BULK_RESOURCE else 0) + (2 if contains_version_json else 0),
        "asset_bootstrap": release_type == BULK_RESOURCE,
        "catalog_transaction": contains_version_json,
        "legacy_whitelist_changed": whitelist_changed if contains_version_json else False,
        "legacy_whitelist_entries": len(staged["entries"]) if contains_version_json else len(active["entries"]),
        "candidate_allowlist_sha256": digest_json(staged["entries"]) if contains_version_json else digest_json(active["entries"]),
        "note": (
            "Operator-built cumulative Lua/table CODE_ONLY candidate; contains no version.json."
            if release_type == CODE_ONLY
            else (
                "Operator-built loud catalog migration; cumulative Lua/table payload plus full version.json overlay."
                if release_type == CATALOG_MIGRATION
                else "Operator-built loud exact-current bulk asset bootstrap plus reconciled stock lazyFile.json; no Lua, no version.json, no old_res."
            )
        ),
    }
    if release_type == CODE_ONLY:
        release["source_fingerprint"] = _source_fingerprint(files)
    if bulk_summary is not None:
        release.update({
            "bulk_exact_files": bulk_summary["exact_files"],
            "bulk_missing_files": bulk_summary["missing_files"],
            "bulk_mismatching_files": bulk_summary["mismatching_files"],
            "bulk_physical_bytes": bulk_summary["physical_bytes"],
            "bulk_path_policy": bulk_summary["path_policy"],
            "contains_lazy_file": True,
            "bulk_lazy_state_mode": "POST_BULK_RECONCILED",
            "bulk_lazy_markers": int((bulk_lazy_summary or {}).get("retained_lazy_markers") or 0),
            "bulk_lazy_supplied_exact": int((bulk_lazy_summary or {}).get("supplied_exact_lazy_paths") or 0),
            "bulk_lazy_file_sha256": str(bulk_lazy_sha256 or ""),
        })
    track["releases"] = [r for r in track.get("releases", []) if str(r.get("status") or "") != CANDIDATE]
    track["releases"].append(release)
    track["releases"] = releases_sorted(track)
    write_json_atomic(REGISTRY, registry)
    _write_release_sidecar(release)

    # Legacy metadata mirrors the candidate but is NOT scheduling authority.
    legacy = {
        "enabled": False,
        "runtime_authority": "release_registry.json",
        "deprecated_single_manifest": True,
        **{k: release[k] for k in ("version", "package", "volume", "size", "md5", "silent", "release_type", "contains_version_json", "legacy_whitelist_changed", "legacy_whitelist_entries")},
        "note": "Operator summary only. MID2 scheduling authority is release_registry.json.",
    }
    write_json_atomic(LEGACY_MANIFEST, legacy)
    state = load_json(STATE, default={})
    state.update({
        "candidate_version": version,
        "candidate_release_type": release_type,
        "candidate_allowlist_sha256": release["candidate_allowlist_sha256"],
        "active_allowlist_sha256": digest_json(active["entries"]),
        "whitelist_changed": whitelist_changed,
        "candidate_silent": bool(silent),
        "candidate_volumes": volume,
        "registry_authority": "local_assets/release_registry.json",
    })
    write_json_atomic(STATE, state)
    print(f"[UPDATE-CONTROLLER] built candidate {version} type={release_type} silent={silent}")
    print(f"[UPDATE-CONTROLLER] package={package} volumes={volume} assembled_size={size} md5={md5}")
    if release_type == CATALOG_MIGRATION:
        print("[UPDATE-CONTROLLER] catalog migration remains UNPUBLISHED until publish/activate validates donor transaction")
    elif release_type == BULK_RESOURCE:
        print(f"[UPDATE-CONTROLLER] bulk exact assets={release['bulk_exact_files']:,} missing={release['bulk_missing_files']:,} mismatching={release['bulk_mismatching_files']:,}")
        print("[UPDATE-CONTROLLER] bulk asset bootstrap remains UNPUBLISHED until explicit publish")
    else:
        print("[UPDATE-CONTROLLER] CODE_ONLY remains UNPUBLISHED until explicit publish")
    return release


def publish_candidate(*, allow_external_assets: bool = False) -> dict[str, Any]:
    registry = load_registry()
    track = current_track(registry)
    release = candidate_release(track)
    if not release:
        raise ValueError("no candidate release exists")
    _verify_release_volumes(release)
    release_type = str(release["release_type"])
    policy = track.get("policy") if isinstance(track.get("policy"), dict) else {}
    required = policy.get("required_initial_barrier") if isinstance(policy, dict) else None
    if isinstance(required, dict):
        req_v = str(required.get("version") or "")
        req_t = str(required.get("release_type") or "")
        if parse_version(str(release["version"])) > parse_version(req_v):
            satisfied = any(
                str(r.get("status") or "") == PUBLISHED
                and str(r.get("version") or "") == req_v
                and str(r.get("release_type") or "") == req_t
                for r in track.get("releases", []) if isinstance(r, dict)
            )
            if not satisfied:
                raise ValueError(f"required initial barrier {req_v} {req_t} is not published; refusing to publish {release['version']}")
    if release_type == CATALOG_MIGRATION:
        candidate_allowlist = normalize_allowlist(load_json(STAGING / "legacy_fallback_allowlist.json"))
        desired_allowlist = normalize_allowlist(load_json(STAGED_ALLOWLIST, default=candidate_allowlist))
        expected_digest = str(release.get("candidate_allowlist_sha256") or "")
        if digest_json(candidate_allowlist["entries"]) != expected_digest or digest_json(desired_allowlist["entries"]) != expected_digest:
            raise ValueError("staged whitelist changed after this catalog candidate was built; rebuild before publish")
        if bool(release.get("silent")):
            raise ValueError("catalog migration cannot be silent")
        if not CURRENT_RES.is_dir():
            print(f"[UPDATE-CONTROLLER][WARN] current res directory absent: {CURRENT_RES}; local current asset serving will be unavailable")
        valid, problems = validate_donors(candidate_allowlist)
        if problems and not allow_external_assets:
            raise ValueError("catalog donor validation failed; publish refused (or use --allow-external-assets for an explicit external asset deployment)")
        if problems and allow_external_assets:
            print("[UPDATE-CONTROLLER][WARN] explicit external-asset mode bypasses local donor presence validation")
            for p in problems:
                print(f"  EXTERNAL-ASSET WARNING: {p}")
        # Promote the matching runtime resource transaction first. Registry is
        # written last, so MID2 cannot advertise hashes before gateway policy is ready.
        shutil.copy2(STAGING / "legacy_fallback_allowlist.json", ACTIVE_ALLOWLIST)
        shutil.copy2(STAGING / "resource_catalog.json", ACTIVE_CATALOG)
        shutil.copy2(STAGING / "version.json", ACTIVE_VERSION)
    else:
        valid = 0

    release["status"] = PUBLISHED
    write_json_atomic(REGISTRY, registry)
    _write_release_sidecar(release)
    legacy = load_json(LEGACY_MANIFEST, default={})
    if str(legacy.get("version") or "") == str(release["version"]):
        legacy["enabled"] = True
        legacy["published"] = True
        write_json_atomic(LEGACY_MANIFEST, legacy)
    state = load_json(STATE, default={})
    state.update({
        "last_published_version": release["version"],
        "candidate_version": None,
        "candidate_release_type": None,
        "active_allowlist_sha256": digest_json(normalize_allowlist(load_json(ACTIVE_ALLOWLIST, default=empty_allowlist()))["entries"]),
        "whitelist_changed": False if release_type == CATALOG_MIGRATION else state.get("whitelist_changed", False),
        "registry_authority": "local_assets/release_registry.json",
    })
    write_json_atomic(STATE, state)
    print(f"[UPDATE-CONTROLLER] PUBLISHED {release['version']} type={release_type} silent={release['silent']}")
    if release_type == CATALOG_MIGRATION:
        print(f"[UPDATE-CONTROLLER] active legacy entries={release['legacy_whitelist_entries']} locally_validated={valid}")
        print("[UPDATE-CONTROLLER] restart backend before smoke so ResourceGateway reloads promoted policy/catalog")
    return release


def add_icon(current_path: str, fallback_relpath: str) -> None:
    current_path = current_path.replace("\\", "/").lstrip("/")
    fallback_relpath = fallback_relpath.replace("\\", "/").lstrip("/")
    if not re.fullmatch(r"res/web/images/icon/[^/]+_icon\.png", current_path):
        raise ValueError("controller permits automatic donor staging only for res/web/images/icon/*_icon.png")
    if not fallback_relpath.lower().endswith(".png"):
        raise ValueError("legacy donor must be a PNG")
    base = base_by_path().get(current_path)
    if base is None or int(base.get("force") or 0) != 0:
        raise ValueError("current path must exist as a lazy force=0 row in authoritative full catalog")
    donor = OLD_RES.joinpath(*PurePosixPath(fallback_relpath).parts)
    if not donor.is_file():
        raise ValueError(f"donor not found: {donor}")
    width, height, bit_depth, color_type, interlace = png_info(donor)
    if (width, height) != (100, 100):
        raise ValueError(f"automatic numeric item-icon donor requires 100x100; got {width}x{height}")
    stem = donor.stem
    companions = [p for p in donor.parent.glob(stem + ".*") if p != donor and p.suffix.lower() in {".plist", ".atlas", ".json", ".csb", ".fnt"}]
    if companions:
        raise ValueError(f"donor appears coupled to metadata and cannot be auto-approved: {companions}")
    md5 = hash_file(donor, "md5")
    sha = hash_file(donor, "sha256")
    size = donor.stat().st_size
    staged = normalize_allowlist(load_json(STAGED_ALLOWLIST, default=load_json(ACTIVE_ALLOWLIST, default=empty_allowlist())))
    staged["entries"] = [r for r in staged["entries"] if r["current_path"] != current_path]
    staged["entries"].append({
        "current_path": current_path,
        "catalog_md5": md5,
        "catalog_size": size,
        "fallback_root_role": "legacy_old_res",
        "fallback_relpath": fallback_relpath,
        "donor_md5": md5,
        "donor_sha256": sha,
        "donor_size": size,
        "media_class": "standalone_numeric_item_icon_png",
        "width": width,
        "height": height,
        "png_bit_depth": bit_depth,
        "png_color_type": color_type,
        "png_interlace": interlace,
        "source_generation": "historical_operator_donor",
        "approval_basis": "explicit update_controller operator staging",
    })
    staged = normalize_allowlist(staged)
    staged["status"] = "STAGED_OPERATOR_POLICY_NOT_LIVE_UNTIL_CATALOG_MIGRATION_PUBLISH"
    write_json_atomic(STAGED_ALLOWLIST, staged)
    print(f"[UPDATE-CONTROLLER] staged donor {current_path} -> old_res/{fallback_relpath}")
    print("[UPDATE-CONTROLLER] next published change must be a loud CATALOG_MIGRATION")


def remove_icon(current_path: str) -> None:
    current_path = current_path.replace("\\", "/").lstrip("/")
    staged = normalize_allowlist(load_json(STAGED_ALLOWLIST, default=load_json(ACTIVE_ALLOWLIST, default=empty_allowlist())))
    before = len(staged["entries"])
    staged["entries"] = [r for r in staged["entries"] if r["current_path"] != current_path]
    if len(staged["entries"]) == before:
        raise ValueError(f"path not found in staged whitelist: {current_path}")
    staged["status"] = "STAGED_OPERATOR_POLICY_NOT_LIVE_UNTIL_CATALOG_MIGRATION_PUBLISH"
    write_json_atomic(STAGED_ALLOWLIST, normalize_allowlist(staged))
    print(f"[UPDATE-CONTROLLER] staged removal {current_path}; next published change must be loud catalog migration")


def _source_fingerprint(files: list[tuple[Path, str]]) -> str:
    """Content-address the sparse operator source set without depending on mtimes."""
    h = hashlib.sha256()
    for src, arcname in sorted(files, key=lambda x: x[1]):
        h.update(arcname.encode("utf-8")); h.update(b"\0")
        h.update(str(src.stat().st_size).encode("ascii")); h.update(b"\0")
        h.update(hash_file(src, "sha256").encode("ascii")); h.update(b"\n")
    return h.hexdigest()


def _find_release(track: dict[str, Any], version: str) -> dict[str, Any] | None:
    rows = [r for r in track.get("releases", []) if isinstance(r, dict) and str(r.get("version") or "") == version]
    if len(rows) > 1:
        raise ValueError(f"duplicate release version in registry: {version}")
    return rows[0] if rows else None


def _expected_package(version: str, release_type: str) -> str:
    return f"gxb-assets-{version}.zip" if release_type == BULK_RESOURCE else f"gxb-local-{version}.zip"


def _try_import_published_sidecar(
    registry: dict[str, Any], track: dict[str, Any], version: str, release_type: str,
    *, expected_generation: str = "",
) -> dict[str, Any] | None:
    lane = release_lane(release_type)
    probe = {"lane": lane, "package": _expected_package(version, release_type)}
    sidecar = release_sidecar_path(probe)
    if not sidecar.is_file():
        return None
    payload = load_json(sidecar)
    if not isinstance(payload, dict):
        return None
    if str(payload.get("version") or "") != version or str(payload.get("release_type") or "") != release_type:
        raise ValueError(f"release sidecar identity mismatch: {sidecar}")
    if str(payload.get("status") or "") != PUBLISHED:
        return None
    if expected_generation and str(payload.get("ota_generation") or "") != expected_generation:
        print(
            f"[UPDATE-AUTO] refusing stale sidecar {version}: ota_generation="
            f"{payload.get('ota_generation')!r} expected={expected_generation!r}"
        )
        return None
    if str(payload.get("lane") or "") != lane:
        raise ValueError(f"release sidecar lane mismatch: {sidecar}")
    _verify_release_volumes(payload, deep=True)
    track.setdefault("releases", []).append(payload)
    track["releases"] = releases_sorted(track)
    write_json_atomic(REGISTRY, registry)
    print(f"[UPDATE-AUTO] imported verified published sidecar {version} type={release_type}")
    return payload


def ensure_auto_releases(*, policy_path: Path = AUTO_POLICY) -> dict[str, Any]:
    """Ensure the configured stock-client update baseline exists.

    This is intentionally idempotent. Existing *published* immutable artifacts are
    deep-verified and skipped. Asset bootstrap is built only when the exact-current
    ``local_assets/res`` tree is available. If a published sidecar+shards were
    committed without ``res``, they are enough to restore registry authority.
    """
    raw_policy = load_json(policy_path, default={})
    if not isinstance(raw_policy, dict):
        raw_policy = {}
    # Pass294 settings.json is the operator-facing umbrella. Keep read
    # compatibility with the earlier flat update_policy.json schema.
    policy = raw_policy.get("updates") if isinstance(raw_policy.get("updates"), dict) else raw_policy
    if not bool(policy.get("enabled", True)) or not bool(policy.get("auto_ensure", True)):
        print("[UPDATE-AUTO] disabled by settings")
        return {"enabled": False, "actions": []}
    auto_publish = bool(policy.get("auto_publish", True))
    max_bytes = int(policy.get("max_volume_bytes") or GIT_SAFE_VOLUME_BYTES)
    if max_bytes <= 0 or max_bytes > GIT_SAFE_VOLUME_BYTES:
        raise ValueError(f"update policy max_volume_bytes must be <= {GIT_SAFE_VOLUME_BYTES:,}")
    asset_cfg = policy.get("asset_bootstrap") if isinstance(policy.get("asset_bootstrap"), dict) else {}
    code_cfg = policy.get("code_baseline") if isinstance(policy.get("code_baseline"), dict) else {}
    actions: list[str] = []

    registry = load_registry(); track = current_track(registry)
    configured_generation = str(policy.get("canonical_generation") or "").strip()
    reset_on_generation_mismatch = bool(policy.get("reset_active_registry_on_generation_mismatch", False))
    current_generation = str(registry.get("runtime_generation") or track.get("ota_generation") or "").strip()
    if configured_generation and reset_on_generation_mismatch and current_generation != configured_generation:
        archived = _archive_registry_snapshot(
            registry,
            reason=(
                f"Canonical OTA generation reset {current_generation or '<legacy>'} -> {configured_generation}; "
                "runtime release rows detached, bytes preserved separately/passmap provenance retained."
            ),
        )
        detached = len([r for r in track.get("releases", []) if isinstance(r, dict)])
        track["releases"] = []
        track["ota_generation"] = configured_generation
        registry["runtime_generation"] = configured_generation
        registry["reset_generation"] = (
            "Pass299 runtime-success canonical OTA numbering: 1.631.1 assets first, "
            "1.631.2+ cumulative Lua/code; older experimental generations detached."
        )
        write_json_atomic(REGISTRY, registry)
        actions.append(f"reset-ota-generation:{configured_generation}:detached={detached}")
        print(
            f"[UPDATE-AUTO] OTA generation reset -> {configured_generation}; "
            f"detached releases={detached}; archived registry={archived}"
        )
    elif configured_generation:
        track["ota_generation"] = configured_generation
        registry["runtime_generation"] = configured_generation

    # The registry is persistent deployment state. Canonical Pass299 may therefore
    # survive a code upgrade with an experimental required barrier. Reconcile
    # only the active routing policy after generation reset; historical release
    # evidence belongs in passmap/update_history rather than the live scheduler.
    if bool(asset_cfg.get("enabled", True)):
        configured_barrier_version = str(asset_cfg.get("version") or "1.631.1")
        parse_version(configured_barrier_version)
        track_policy = track.setdefault("policy", {})
        desired_barrier = {"version": configured_barrier_version, "release_type": BULK_RESOURCE}
        current_barrier = track_policy.get("required_initial_barrier")
        if current_barrier != desired_barrier:
            track_policy["required_initial_barrier"] = desired_barrier
            write_json_atomic(REGISTRY, registry)
            actions.append(f"update-required-barrier:{configured_barrier_version}")
            print(
                f"[UPDATE-AUTO] active required barrier policy -> {configured_barrier_version} "
                f"{BULK_RESOURCE} (published history preserved)"
            )

    def ensure_one(version: str, release_type: str, *, min_files: int = 25000) -> dict[str, Any] | None:
        nonlocal registry, track
        archived_stale = _archive_stale_same_version_artifacts(version, release_type, configured_generation)
        if archived_stale:
            actions.append(f"archive-stale-artifacts:{version}:{len(archived_stale)}")
            print(f"[UPDATE-AUTO] archived stale same-version artifacts for {version}: {len(archived_stale)} file(s)")
        existing = _find_release(track, version)
        if existing is not None and configured_generation and str(existing.get("ota_generation") or "") != configured_generation:
            raise ValueError(f"active registry release {version} belongs to stale OTA generation")
        if existing is None:
            existing = _try_import_published_sidecar(
                registry, track, version, release_type, expected_generation=configured_generation
            )
        if existing is not None and str(existing.get("status") or "") == PUBLISHED:
            if str(existing.get("release_type") or "") != release_type:
                raise ValueError(f"published {version} has wrong release type {existing.get('release_type')}")
            _verify_release_volumes(existing, deep=True)
            if any(int(r.get("size") or 0) > max_bytes for r in existing.get("volume_files", []) if isinstance(r, dict)):
                raise ValueError(f"published {version} contains a shard larger than policy cap; published bytes are immutable")
            print(f"[UPDATE-AUTO] {release_type} {version} present+verified -> skip")
            actions.append(f"skip:{version}")
            return existing
        if existing is not None and str(existing.get("status") or "") == CANDIDATE:
            # Rebuild stale pre-Pass294 candidates (notably 256 MiB Pass293 shards)
            # under the current Git-safe cap. Unpublished bytes are replaceable.
            stale = int(existing.get("max_volume_bytes") or GIT_SAFE_VOLUME_BYTES + 1) > max_bytes
            if stale:
                print(f"[UPDATE-AUTO] rebuilding unpublished stale candidate {version} under {max_bytes:,}-byte shard cap")
        if release_type == BULK_RESOURCE and not CURRENT_RES.is_dir():
            print(f"[UPDATE-AUTO][WARN] asset bootstrap {version} absent and current res directory missing: {CURRENT_RES}; leaving barrier unpublished")
            actions.append(f"warn-missing-res:{version}")
            return None
        if release_type == CODE_ONLY:
            required = track.get("policy", {}).get("required_initial_barrier", {}) if isinstance(track.get("policy"), dict) else {}
            req_v = str(required.get("version") or "") if isinstance(required, dict) else ""
            req_t = str(required.get("release_type") or "") if isinstance(required, dict) else ""
            req = _find_release(track, req_v) if req_v else None
            if req_v and (not req or str(req.get("status") or "") != PUBLISHED or str(req.get("release_type") or "") != req_t):
                print(f"[UPDATE-AUTO][WARN] code baseline {version} withheld until required barrier {req_v} is published")
                actions.append(f"withhold-code:{version}")
                return None
        built = build_release(
            release_type, version=version,
            silent=(True if release_type == CODE_ONLY else False),
            max_volume_bytes=max_bytes, bulk_min_files=min_files,
        )
        if not auto_publish:
            actions.append(f"build-candidate:{version}")
            registry = load_registry(); track = current_track(registry)
            return built
        published = publish_candidate()
        actions.append(f"build+publish:{version}")
        registry = load_registry(); track = current_track(registry)
        return published

    asset_release = None
    if bool(asset_cfg.get("enabled", True)):
        asset_version = str(asset_cfg.get("version") or "1.631.1")
        parse_version(asset_version)
        asset_release = ensure_one(asset_version, BULK_RESOURCE, min_files=int(asset_cfg.get("min_exact_files") or 25000))

    code_release = None
    if bool(code_cfg.get("enabled", True)):
        code_version = str(code_cfg.get("version") or "1.631.2")
        parse_version(code_version)
        code_release = ensure_one(code_version, CODE_ONLY)
        if code_release is not None:
            current_fp = _source_fingerprint(iter_sparse_overrides())
            recorded_fp = str(code_release.get("source_fingerprint") or "")
            if recorded_fp and recorded_fp != current_fp:
                print(
                    f"[UPDATE-AUTO][WARN] bundled Lua/table source differs from published {code_version}; "
                    "published bytes are immutable. Bump code_baseline.version before shipping this source change."
                )
                actions.append(f"warn-code-source-drift:{code_version}")

    return {
        "enabled": True, "actions": actions,
        "asset_version": (str(asset_release.get("version")) if asset_release else None),
        "code_version": (str(code_release.get("version")) if code_release else None),
        "max_volume_bytes": max_bytes, "auto_publish": auto_publish,
        "ota_generation": configured_generation,
    }


def show_status() -> None:
    registry = load_registry()
    track = current_track(registry)
    active = normalize_allowlist(load_json(ACTIVE_ALLOWLIST, default=empty_allowlist()))
    staged = normalize_allowlist(load_json(STAGED_ALLOWLIST, default=active))
    print("=== GXB UPDATE CONTROLLER STATUS ===")
    print(f"runtime scheduler authority : {REGISTRY}")
    print(f"track                       : app_v={track['app_v']} platform={track['platform']} base_version={track_base_version(track)} enabled={track.get('enabled', True)}")
    required = (track.get("policy") or {}).get("required_initial_barrier") if isinstance(track.get("policy"), dict) else None
    if isinstance(required, dict):
        print(f"required initial barrier    : {required.get('version')} {required.get('release_type')}")
    print(f"current res                 : {CURRENT_RES} {'OK' if CURRENT_RES.is_dir() else 'MISSING (warning only)'}")
    print(f"old_res                     : {OLD_RES} {'OK' if OLD_RES.is_dir() else 'MISSING (legacy fallback unavailable)'}")
    print(f"active whitelist entries    : {len(active['entries'])}")
    print(f"staged whitelist entries    : {len(staged['entries'])}")
    print(f"whitelist dirty             : {digest_json(active['entries']) != digest_json(staged['entries'])}")
    raw_settings = load_json(AUTO_POLICY, default={})
    auto = raw_settings.get("updates") if isinstance(raw_settings, dict) and isinstance(raw_settings.get("updates"), dict) else raw_settings
    if isinstance(auto, dict):
        print(f"auto ensure/publish         : {bool(auto.get('auto_ensure', True))}/{bool(auto.get('auto_publish', True))}")
        print(f"max update shard bytes      : {int(auto.get('max_volume_bytes') or GIT_SAFE_VOLUME_BYTES):,}")
        print(f"MID2 client profile         : {CURRENT_STOCK_PROFILE}")
    for r in releases_sorted(track):
        print(f" {r['version']} {r['status']:<9} {r['release_type']:<20} lane={r.get('lane', '?'):<7} silent={r['silent']} volumes={r['volume']} cumulative={r.get('cumulative', False)}")
    cand = candidate_release(track)
    print(f"suggested next version      : {next_version(str(cand['version']) if cand else highest_published_version(track))}")
    if cand and str(cand.get('release_type')) == CODE_ONLY and digest_json(active['entries']) != digest_json(staged['entries']):
        print(f"catalog coalesce available  : YES -> rebuild unpublished {cand['version']} as loud CATALOG_MIGRATION (no extra version bump)")


def list_entries(staged: bool = True) -> None:
    path = STAGED_ALLOWLIST if staged else ACTIVE_ALLOWLIST
    payload = normalize_allowlist(load_json(path, default=empty_allowlist()))
    print(f"{'STAGED' if staged else 'ACTIVE'} whitelist ({len(payload['entries'])} entries):")
    for i, row in enumerate(payload["entries"], 1):
        print(f" {i:3d}. {row['current_path']} -> old_res/{row['fallback_relpath']} md5={row['donor_md5']} size={row['donor_size']}")


def plan_client(client_v: str, app_v: str = DEFAULT_APP_V, platform: int = DEFAULT_PLATFORM) -> dict[str, Any]:
    # Import runtime scheduler lazily so controller can be copied as a standalone
    # operator tool while still testing the exact backend selection logic.
    from gxb_backend.config import Settings
    from gxb_backend.updates.local_update import select_update_plan
    settings = Settings(
        static_asset_root=LOCAL,
        local_update_release_registry_path=REGISTRY,
        local_update_dir=UPDATES,
    )
    req = {"v": client_v, "app_v": app_v, "platform": platform, "full": True}
    rows = select_update_plan(settings, req)
    out = {"client_v": client_v, "app_v": app_v, "platform": platform, "releases": [r["version"] for r in rows], "silent": (bool(rows[0]["silent"]) if rows else None)}
    if rows:
        print(f"PLAN: {'silent' if out['silent'] else 'LOUD'} -> {out['releases']}")
    else:
        print("PLAN: no update")
    return out


def interactive() -> int:
    while True:
        print("\nGXB update controller (Pass298 stock-client-compatible auto-update model)")
        print(" 1) Status / release history")
        print(" 2) Plan MID2 for a client version")
        print(" 3) List staged legacy whitelist")
        print(" 4) Add standalone 100x100 inventory icon donor")
        print(" 5) Remove donor from staged whitelist")
        print(" 6) Build normal CODE_ONLY candidate (silent default)")
        print(" 7) Build loud CATALOG_MIGRATION candidate")
        print(" 8) Publish current candidate")
        print(" 9) Validate staged donors")
        print("10) Build loud BULK_RESOURCE_BOOTSTRAP candidate from current res")
        print("11) Ensure configured startup baseline now")
        print(" 0) Exit")
        choice = input("Select: ").strip()
        try:
            if choice == "1": show_status()
            elif choice == "2": plan_client(input(f"Installed resource version [{track_base_version(current_track(load_registry()))}]: ").strip() or track_base_version(current_track(load_registry())))
            elif choice == "3": list_entries(True)
            elif choice == "4": add_icon(input("Current res/web/images/icon/..._icon.png: ").strip(), input("Donor relative to old_res: ").strip())
            elif choice == "5": remove_icon(input("Current path to remove: ").strip())
            elif choice == "6": build_release(CODE_ONLY, silent=True, increment=False)
            elif choice == "7": build_release(CATALOG_MIGRATION, silent=False, increment=False, inherit_candidate=True)
            elif choice == "8": publish_candidate()
            elif choice == "9":
                payload = normalize_allowlist(load_json(STAGED_ALLOWLIST, default=load_json(ACTIVE_ALLOWLIST, default=empty_allowlist())))
                validate_donors(payload)
            elif choice == "10":
                version = input("Asset bootstrap version [1.631.1]: ").strip() or "1.631.1"
                volume = input("Max shard MB (decimal) [99]: ").strip() or "99"
                build_release(BULK_RESOURCE, version=version, silent=False, max_volume_bytes=int(float(volume) * 1_000_000), bulk_min_files=25000)
            elif choice == "11":
                print(ensure_auto_releases(policy_path=AUTO_POLICY))
            elif choice == "0": return 0
            else: print("Unknown selection")
        except Exception as exc:
            print(f"ERROR: {exc}")


def build_candidate(version: str, silent: bool, enabled_after_build: bool = False) -> dict[str, Any]:
    """Pass289 compatibility wrapper. Dirty whitelist implies catalog build."""
    active = normalize_allowlist(load_json(ACTIVE_ALLOWLIST, default=empty_allowlist()))
    staged = normalize_allowlist(load_json(STAGED_ALLOWLIST, default=active))
    dirty = digest_json(active["entries"]) != digest_json(staged["entries"])
    if dirty and silent:
        raise ValueError("whitelist changed: this OTA MUST be loud; silent mode is refused")
    typ = CATALOG_MIGRATION if dirty else CODE_ONLY
    return build_release(typ, version=version, silent=silent, inherit_candidate=True)


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__)
    sub = ap.add_subparsers(dest="cmd")
    sub.add_parser("status")
    p_plan = sub.add_parser("plan")
    p_plan.add_argument("--client-v", default="1.631.24")
    p_plan.add_argument("--app-v", default=DEFAULT_APP_V)
    p_plan.add_argument("--platform", type=int, default=DEFAULT_PLATFORM)
    p_list = sub.add_parser("list")
    p_list.add_argument("--active", action="store_true")
    p_add = sub.add_parser("add-icon")
    p_add.add_argument("current_path"); p_add.add_argument("fallback_relpath")
    p_remove = sub.add_parser("remove"); p_remove.add_argument("current_path")
    p_build = sub.add_parser("build")
    p_build.add_argument("--type", choices=["code", "catalog", "asset"], default="code")
    p_build.add_argument("--version")
    p_build.add_argument("--increment", action="store_true")
    p_build.add_argument("--volume-mib", type=float, default=0, help="legacy binary-MiB option; refused if it exceeds the 99,000,000-byte Git-safe cap")
    p_build.add_argument("--volume-mb", type=float, default=99.0, help="maximum decimal MB per .001/.002 shard; default 99")
    p_build.add_argument("--no-inherit-candidate", action="store_true")
    p_build.add_argument("--bulk-min-files", type=int, default=25000)
    mode = p_build.add_mutually_exclusive_group(); mode.add_argument("--silent", action="store_true"); mode.add_argument("--loud", action="store_true")
    p_pub = sub.add_parser("publish"); p_pub.add_argument("--allow-external-assets", action="store_true")
    p_act = sub.add_parser("activate"); p_act.add_argument("--allow-external-assets", action="store_true")
    p_val = sub.add_parser("validate-donors"); p_val.add_argument("--active", action="store_true")
    sub.add_parser("ensure", help="auto-ensure configured asset bootstrap and silent code baseline")
    args = ap.parse_args()

    POLICY_DIR.mkdir(parents=True, exist_ok=True)
    if not STAGED_ALLOWLIST.is_file():
        write_json_atomic(STAGED_ALLOWLIST, load_json(ACTIVE_ALLOWLIST, default=empty_allowlist()))
    if not args.cmd: return interactive()
    if args.cmd == "status": show_status()
    elif args.cmd == "plan": plan_client(args.client_v, args.app_v, args.platform)
    elif args.cmd == "list": list_entries(not args.active)
    elif args.cmd == "add-icon": add_icon(args.current_path, args.fallback_relpath)
    elif args.cmd == "remove": remove_icon(args.current_path)
    elif args.cmd == "build":
        typ = CODE_ONLY if args.type == "code" else (CATALOG_MIGRATION if args.type == "catalog" else BULK_RESOURCE)
        silent: bool | None = True if args.silent else (False if args.loud else None)
        max_bytes = None if args.volume_mib else int(float(args.volume_mb) * 1_000_000)
        build_release(typ, version=args.version, increment=bool(args.increment), silent=silent, volume_mib=args.volume_mib, max_volume_bytes=max_bytes, inherit_candidate=not args.no_inherit_candidate, bulk_min_files=args.bulk_min_files)
    elif args.cmd in {"publish", "activate"}: publish_candidate(allow_external_assets=bool(args.allow_external_assets))
    elif args.cmd == "ensure":
        ensure_auto_releases(policy_path=AUTO_POLICY)
    elif args.cmd == "validate-donors":
        path = ACTIVE_ALLOWLIST if args.active else STAGED_ALLOWLIST
        payload = normalize_allowlist(load_json(path, default=empty_allowlist()))
        _valid, problems = validate_donors(payload)
        return 1 if problems else 0
    return 0


if __name__ == "__main__":
    try:
        raise SystemExit(main())
    except ValueError as exc:
        print(f"ERROR: {exc}")
        raise SystemExit(2)
