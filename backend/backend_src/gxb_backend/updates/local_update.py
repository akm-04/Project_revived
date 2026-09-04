"""Version-aware MID2 scheduler with separated update lanes.

Pass299 canonical OTA invariants (retaining Pass294 separated-lane architecture)
==================
- ``assets`` lane: loud BULK_RESOURCE_BOOTSTRAP barriers only.
- ``code`` lane: normal cumulative CODE_ONLY Lua/table releases; silent default.
- ``catalog`` lane: rare loud CATALOG_MIGRATION releases.
- each logical release may have stock ``.001`` ... ``.NNN`` raw volumes.
- published releases are immutable and exact-gated by APK ``app_v`` + platform.
- release payloads are deep-verified once at startup/publish and thereafter MID2
  uses cheap file-stat fingerprints; a 1 GiB bootstrap is never re-hashed per
  client version-check request.

``update_manifest.json`` remains compatibility/operator metadata. Runtime
scheduling authority is ``release_registry.json``.
"""
from __future__ import annotations

import hashlib
import json
import re
import threading
from pathlib import Path, PurePosixPath
from typing import Any

from gxb_backend.config import Settings
from gxb_backend.updates.mid2_compat import evaluate_volume_plan, validate_declared_metrics

_RESOURCE_VERSION_RE = re.compile(r"^(\d+)\.(\d+)\.(\d+)$")
RELEASE_CODE_ONLY = "CODE_ONLY"
RELEASE_CATALOG_MIGRATION = "CATALOG_MIGRATION"
RELEASE_BULK_RESOURCE = "BULK_RESOURCE_BOOTSTRAP"
PUBLISHED = "PUBLISHED"
CANDIDATE = "CANDIDATE"
LANE_CODE = "code"
LANE_ASSETS = "assets"
LANE_CATALOG = "catalog"
_APPROVED_LANES = {LANE_CODE, LANE_ASSETS, LANE_CATALOG}

_VERIFY_LOCK = threading.RLock()
# key -> stat signature after a successful deep verification.
_VERIFIED_RELEASES: dict[str, tuple[tuple[str, int, int], ...]] = {}


def parse_resource_version(value: object) -> tuple[int, int, int] | None:
    text = str(value or "").strip()
    match = _RESOURCE_VERSION_RE.fullmatch(text)
    if not match:
        return None
    return tuple(int(part) for part in match.groups())


def _load_json(path: Path) -> Any:
    return json.loads(path.read_text(encoding="utf-8"))


def load_release_registry(settings: Settings) -> dict[str, Any] | None:
    path = settings.local_update_release_registry_path
    try:
        raw = _load_json(path)
    except FileNotFoundError:
        return None
    except Exception as exc:
        print(f"[UPDATE] invalid release registry {path}: {exc}")
        return None
    if not isinstance(raw, dict) or int(raw.get("schema_version") or 0) != 1:
        print(f"[UPDATE] unsupported release registry schema: {path}")
        return None
    if not isinstance(raw.get("tracks"), list):
        print(f"[UPDATE] release registry tracks must be a list: {path}")
        return None
    return raw


def _expected_lane(release_type: str) -> str:
    if release_type == RELEASE_BULK_RESOURCE:
        return LANE_ASSETS
    if release_type == RELEASE_CODE_ONLY:
        return LANE_CODE
    if release_type == RELEASE_CATALOG_MIGRATION:
        return LANE_CATALOG
    return ""


def _release_structure(release: dict[str, Any]) -> dict[str, Any] | None:
    try:
        version = str(release["version"]).strip()
        package = str(release["package"]).strip()
        volume = int(release["volume"])
        size = int(release["size"])
        md5 = str(release["md5"]).strip().lower()
        silent = bool(release["silent"])
        release_type = str(release["release_type"]).strip()
        lane = str(release.get("lane") or "").strip()
    except Exception:
        return None
    if parse_resource_version(version) is None:
        return None
    if Path(package).name != package or "/" in package or "\\" in package:
        return None
    if volume <= 0 or size <= 0 or not re.fullmatch(r"[0-9a-f]{32}", md5):
        return None
    if release_type not in {RELEASE_CODE_ONLY, RELEASE_CATALOG_MIGRATION, RELEASE_BULK_RESOURCE}:
        return None
    expected_lane = _expected_lane(release_type)
    # Legacy Pass291/293 registry rows had no lane; keep read compatibility.
    if lane and (lane not in _APPROVED_LANES or lane != expected_lane):
        print(f"[UPDATE] refusing release {version}: lane={lane!r} expected={expected_lane!r}")
        return None
    if release_type in {RELEASE_CATALOG_MIGRATION, RELEASE_BULK_RESOURCE} and silent:
        print(f"[UPDATE] refusing silent barrier release {version} type={release_type}")
        return None
    contains_catalog = bool(release.get("contains_version_json", False))
    if release_type == RELEASE_CODE_ONLY and contains_catalog:
        print(f"[UPDATE] refusing CODE_ONLY release {version} that carries version.json")
        return None
    if release_type == RELEASE_CATALOG_MIGRATION and not contains_catalog:
        print(f"[UPDATE] refusing catalog migration {version} without version.json")
        return None
    if release_type == RELEASE_BULK_RESOURCE and contains_catalog:
        print(f"[UPDATE] refusing bulk resource bootstrap {version} that carries version.json")
        return None
    ota_generation = str(release.get("ota_generation") or "").strip()
    if release_type == RELEASE_BULK_RESOURCE and ota_generation:
        if not bool(release.get("contains_lazy_file", False)):
            print(f"[UPDATE] refusing canonical bulk resource bootstrap {version} without lazyFile.json")
            return None
        if str(release.get("bulk_lazy_state_mode") or "") != "POST_BULK_RECONCILED":
            print(f"[UPDATE] refusing canonical bulk resource bootstrap {version} without reconciled lazy-state metadata")
            return None
    out = dict(release)
    out["lane"] = lane
    return out


def _volume_paths(settings: Settings, release: dict[str, Any]) -> list[Path]:
    lane = str(release.get("lane") or "").strip()
    root = settings.local_update_dir / lane if lane else settings.local_update_dir
    package = str(release["package"])
    return [root / f"{package}.{idx:03d}" for idx in range(1, int(release["volume"]) + 1)]


def _release_cache_key(settings: Settings, release: dict[str, Any]) -> str:
    stable = {
        "root": str(settings.local_update_dir.resolve()),
        "version": str(release.get("version") or ""),
        "lane": str(release.get("lane") or ""),
        "package": str(release.get("package") or ""),
        "volume": int(release.get("volume") or 0),
        "size": int(release.get("size") or 0),
        "md5": str(release.get("md5") or "").lower(),
        "volume_files": release.get("volume_files") or [],
        "client_compatibility_profile": release.get("client_compatibility_profile"),
        "volume_size_float32_exact": release.get("volume_size_float32_exact"),
        "client_accounted_size": release.get("client_accounted_size"),
        "max_prefix_offset": release.get("max_prefix_offset"),
        "assembled_size_int32_safe": release.get("assembled_size_int32_safe"),
        "ota_generation": release.get("ota_generation"),
        "contains_lazy_file": release.get("contains_lazy_file"),
        "bulk_lazy_state_mode": release.get("bulk_lazy_state_mode"),
        "bulk_lazy_file_sha256": release.get("bulk_lazy_file_sha256"),
    }
    raw = json.dumps(stable, sort_keys=True, separators=(",", ":")).encode("utf-8")
    return hashlib.sha256(raw).hexdigest()


def _stat_signature(paths: list[Path]) -> tuple[tuple[str, int, int], ...] | None:
    rows: list[tuple[str, int, int]] = []
    for path in paths:
        try:
            st = path.stat()
        except FileNotFoundError:
            return None
        if not path.is_file():
            return None
        rows.append((str(path), int(st.st_size), int(st.st_mtime_ns)))
    return tuple(rows)


def deep_verify_release(settings: Settings, release: dict[str, Any], *, log: bool = True) -> dict[str, Any] | None:
    """Deep-verify one release and prime the cheap runtime verification cache."""
    checked = _release_structure(release)
    if checked is None:
        return None
    paths = _volume_paths(settings, checked)
    signature = _stat_signature(paths)
    if signature is None:
        if log:
            print(f"[UPDATE] release {checked['version']} has missing volume(s); not advertised")
        return None
    declared = checked.get("volume_files") if isinstance(checked.get("volume_files"), list) else []
    by_idx = {int(r.get("index") or 0): r for r in declared if isinstance(r, dict)}
    total = 0
    actual_sizes: list[int] = []
    assembled_md5 = hashlib.md5()
    for idx, path in enumerate(paths, 1):
        row = by_idx.get(idx)
        actual_size = path.stat().st_size
        actual_sizes.append(int(actual_size))
        if row and actual_size != int(row.get("size") or -1):
            if log:
                print(f"[UPDATE] release {checked['version']} shard {idx} size mismatch")
            return None
        part_md5 = hashlib.md5(); part_sha = hashlib.sha256()
        with path.open("rb") as fh:
            for block in iter(lambda: fh.read(1024 * 1024), b""):
                total += len(block); assembled_md5.update(block)
                part_md5.update(block); part_sha.update(block)
        if row:
            if str(row.get("md5") or "").lower() != part_md5.hexdigest():
                if log: print(f"[UPDATE] release {checked['version']} shard {idx} MD5 mismatch")
                return None
            if str(row.get("sha256") or "").lower() != part_sha.hexdigest():
                if log: print(f"[UPDATE] release {checked['version']} shard {idx} SHA256 mismatch")
                return None
    if total != int(checked["size"]) or assembled_md5.hexdigest() != str(checked["md5"]).lower():
        if log:
            print(
                f"[UPDATE] release {checked['version']} assembled integrity mismatch "
                f"expected_size={checked['size']} actual_size={total} "
                f"expected_md5={checked['md5']} actual_md5={assembled_md5.hexdigest()}"
            )
        return None
    try:
        metrics = evaluate_volume_plan(actual_sizes, total)
        validate_declared_metrics(checked, metrics)
    except ValueError as exc:
        if log:
            print(f"[UPDATE] release {checked['version']} stock-client MID2 compatibility failure: {exc}")
        return None
    key = _release_cache_key(settings, checked)
    with _VERIFY_LOCK:
        _VERIFIED_RELEASES[key] = signature
    if log:
        print(f"[UPDATE] deep-verified release {checked['version']} lane={checked.get('lane') or 'legacy-root'} volumes={checked['volume']} bytes={total}")
    return checked


def _validate_release(settings: Settings, release: dict[str, Any]) -> dict[str, Any] | None:
    """Cheap request-path validation after startup deep verification.

    If the release was not primed yet, one caller performs a deep verification.
    If a shard's size/mtime changes later, the cache entry is invalidated and that
    one release is deep-verified again before it can be advertised.
    """
    checked = _release_structure(release)
    if checked is None:
        return None
    paths = _volume_paths(settings, checked)
    signature = _stat_signature(paths)
    if signature is None:
        print(f"[UPDATE] release {checked['version']} has missing volume(s); not advertised")
        return None
    # Cheap per-shard size contract before touching cache.
    declared = checked.get("volume_files") if isinstance(checked.get("volume_files"), list) else []
    by_idx = {int(r.get("index") or 0): r for r in declared if isinstance(r, dict)}
    if sum(row[1] for row in signature) != int(checked["size"]):
        print(f"[UPDATE] release {checked['version']} assembled stat-size mismatch; not advertised")
        return None
    for idx, sig in enumerate(signature, 1):
        meta = by_idx.get(idx)
        if meta and sig[1] != int(meta.get("size") or -1):
            print(f"[UPDATE] release {checked['version']} shard {idx} stat-size mismatch; not advertised")
            return None
    key = _release_cache_key(settings, checked)
    with _VERIFY_LOCK:
        if _VERIFIED_RELEASES.get(key) == signature:
            return checked
    return deep_verify_release(settings, checked, log=True)


def prime_release_integrity_cache(settings: Settings) -> dict[str, int]:
    """Deep-verify all published release artifacts once, before accepting clients."""
    registry = load_release_registry(settings)
    if registry is None:
        return {"verified": 0, "failed": 0}
    verified = failed = 0
    with _VERIFY_LOCK:
        _VERIFIED_RELEASES.clear()
    for track in registry.get("tracks", []):
        if not isinstance(track, dict) or not bool(track.get("enabled", True)):
            continue
        track_generation = str(track.get("ota_generation") or "").strip()
        for release in track.get("releases", []):
            if not isinstance(release, dict) or str(release.get("status") or "") != PUBLISHED:
                continue
            if track_generation and str(release.get("ota_generation") or "") != track_generation:
                continue
            if deep_verify_release(settings, release, log=True) is None:
                failed += 1
            else:
                verified += 1
    return {"verified": verified, "failed": failed}


def _matching_track(registry: dict[str, Any], request: dict[str, Any]) -> dict[str, Any] | None:
    app_v = str(request.get("app_v") or "").strip()
    try:
        platform = int(request.get("platform") or request.get("p") or 0)
    except (TypeError, ValueError):
        platform = 0
    for track in registry.get("tracks", []):
        if not isinstance(track, dict) or not bool(track.get("enabled", True)):
            continue
        if str(track.get("app_v") or "").strip() != app_v:
            continue
        expected_platform = int(track.get("platform") or 0)
        if platform == expected_platform or (platform == 0 and bool(track.get("accept_missing_platform", False))):
            return track
    return None


def _pending_published(track: dict[str, Any], current: str) -> list[dict[str, Any]]:
    current_key = parse_resource_version(current)
    track_generation = str(track.get("ota_generation") or "").strip()
    rows: list[dict[str, Any]] = []
    for release in track.get("releases", []):
        if not isinstance(release, dict) or str(release.get("status") or "") != PUBLISHED:
            continue
        if track_generation and str(release.get("ota_generation") or "") != track_generation:
            continue
        key = parse_resource_version(release.get("version"))
        if key is None:
            continue
        if current_key is None or key > current_key:
            rows.append(release)
    rows.sort(key=lambda r: parse_resource_version(r["version"]) or (0, 0, 0))
    return rows


def select_update_plan(settings: Settings, request: dict[str, Any]) -> list[dict[str, Any]]:
    """Return the next source-compatible, mode-homogeneous release batch."""
    registry = load_release_registry(settings)
    if registry is None:
        return []
    track = _matching_track(registry, request)
    if track is None:
        log_update_event(
            settings, "no_matching_update_track",
            app_v=str(request.get("app_v") or ""),
            platform=request.get("platform", request.get("p")),
            current=str(request.get("v") or ""),
        )
        return []
    current = str(request.get("v") or "").strip()
    policy = track.get("policy") if isinstance(track.get("policy"), dict) else {}
    required = policy.get("required_initial_barrier") if isinstance(policy, dict) else None
    if isinstance(required, dict):
        required_version = str(required.get("version") or "").strip()
        required_type = str(required.get("release_type") or "").strip()
        required_key = parse_resource_version(required_version)
        current_key = parse_resource_version(current)
        if required_key is not None and (current_key is None or current_key < required_key):
            track_generation = str(track.get("ota_generation") or "").strip()
            matching = [
                r for r in track.get("releases", [])
                if isinstance(r, dict)
                and str(r.get("status") or "") == PUBLISHED
                and (not track_generation or str(r.get("ota_generation") or "") == track_generation)
                and str(r.get("version") or "") == required_version
                and str(r.get("release_type") or "") == required_type
            ]
            if len(matching) != 1:
                log_update_event(settings, "required_initial_barrier_unpublished", current=current, required_version=required_version, required_type=required_type)
                return []
            # Pass299: the active barrier remains a routing anchor, not merely a
            # publication prerequisite.  Clients below it jump directly to
            # that exact immutable release, bypassing superseded historical
            # experiments while preserving them as provenance.
            checked_barrier = _validate_release(settings, matching[0])
            if checked_barrier is None:
                log_update_event(settings, "required_initial_barrier_invalid", current=current, required_version=required_version, required_type=required_type)
                return []
            log_update_event(settings, "required_initial_barrier_direct_route", current=current, required_version=required_version, required_type=required_type)
            return [checked_barrier]
    pending = _pending_published(track, current)
    if not pending:
        return []

    first = pending[0]
    first_type = str(first.get("release_type") or "")
    first_silent = bool(first.get("silent", False))
    if first_type in {RELEASE_CATALOG_MIGRATION, RELEASE_BULK_RESOURCE}:
        batch = [first]
    else:
        contiguous: list[dict[str, Any]] = []
        for release in pending:
            if str(release.get("release_type") or "") != RELEASE_CODE_ONLY:
                break
            if bool(release.get("silent", False)) != first_silent:
                break
            contiguous.append(release)
        batch = [contiguous[-1]] if contiguous and all(bool(r.get("cumulative", False)) for r in contiguous) else contiguous[:]

    valid: list[dict[str, Any]] = []
    for release in batch:
        checked = _validate_release(settings, release)
        if checked is None:
            return []  # fail closed: never skip a missing/corrupt predecessor
        valid.append(checked)
    return valid


def _descriptor(settings: Settings, release: dict[str, Any]) -> dict[str, Any]:
    lane = str(release.get("lane") or "").strip()
    prefix = f"{lane}/" if lane else ""
    return {
        "version": str(release["version"]),
        "volume": int(release["volume"]),
        "size": int(release["size"]),
        "md5": str(release["md5"]),
        "resource": f"{settings.engine_base_url}/updates/{prefix}{release['package']}",
    }


def log_update_event(settings: Settings, event: str, **fields: Any) -> None:
    row = {"event": event, **fields}
    try:
        import time
        row["ts"] = int(time.time())
        settings.runtime_log_dir.mkdir(parents=True, exist_ok=True)
        path = settings.runtime_log_dir / "local_update_events.jsonl"
        with path.open("a", encoding="utf-8") as fh:
            fh.write(json.dumps(row, ensure_ascii=False, separators=(",", ":")) + "\n")
    except Exception as exc:
        print(f"[UPDATE] log failed: {exc}")


def version_check_payload(settings: Settings, request: dict[str, Any]) -> dict[str, Any]:
    base = {"is_appstore": 0, "is_inapp": 0, "is_review": 0, "need_restart": 0}
    plan = select_update_plan(settings, request)
    if not plan:
        return base
    silent = bool(plan[0].get("silent", False))
    if any(bool(r.get("silent", False)) != silent for r in plan):
        print("[UPDATE] internal scheduler error: mixed silent/loud plan refused")
        return base
    descriptors = [_descriptor(settings, r) for r in plan]
    versions = [d["version"] for d in descriptors]
    print(
        f"[UPDATE] advertise current={str(request.get('v') or '')!r} "
        f"app_v={str(request.get('app_v') or '')!r} silent={silent} versions={versions}"
    )
    log_update_event(
        settings, "advertise_release_plan",
        current=str(request.get("v") or ""), app_v=str(request.get("app_v") or ""),
        platform=request.get("platform", request.get("p")), silent=silent, versions=versions,
        releases=[{
            "version": r["version"], "release_type": r["release_type"],
            "lane": r.get("lane", ""), "package": r["package"], "volume": int(r["volume"]),
        } for r in plan],
    )
    return {
        **base, "is_inapp": 1,
        # Source semantics: is_review skips UPDATE_PROMPT and starts update_().
        "is_review": 1 if silent else 0,
        "res": descriptors,
    }


def registry_summary(settings: Settings) -> dict[str, Any]:
    registry = load_release_registry(settings)
    if registry is None:
        return {"tracks": 0, "published": 0, "candidates": 0}
    published = candidates = 0
    for track in registry.get("tracks", []):
        for release in track.get("releases", []):
            status = str(release.get("status") or "")
            published += status == PUBLISHED
            candidates += status == CANDIDATE
    return {"tracks": len(registry.get("tracks", [])), "published": published, "candidates": candidates}


def resolve_volume(settings: Settings, asset: str) -> Path | None:
    """Resolve only approved update lanes (plus legacy one-component paths)."""
    raw = str(asset or "").strip().replace("\\", "/").lstrip("/")
    if not raw:
        return None
    parts = PurePosixPath(raw).parts
    if ".." in parts:
        return None
    if len(parts) == 1:
        # Backward read compatibility for pre-Pass294 published artifacts.
        if Path(parts[0]).name != parts[0]:
            return None
        path = settings.local_update_dir / parts[0]
    elif len(parts) == 2 and parts[0] in _APPROVED_LANES and Path(parts[1]).name == parts[1]:
        path = settings.local_update_dir / parts[0] / parts[1]
    else:
        return None
    root = settings.local_update_dir.resolve()
    try:
        resolved = path.resolve()
        resolved.relative_to(root)
    except (ValueError, OSError):
        return None
    return resolved if resolved.is_file() else None


def load_manifest(settings: Settings) -> dict[str, Any] | None:
    """Backward-compatible newest-published summary; registry remains authority."""
    registry = load_release_registry(settings)
    if registry is None:
        return None
    published: list[dict[str, Any]] = []
    for track in registry.get("tracks", []):
        for release in track.get("releases", []):
            if str(release.get("status") or "") == PUBLISHED:
                published.append(release)
    if not published:
        return None
    published.sort(key=lambda r: parse_resource_version(r.get("version")) or (0, 0, 0))
    latest = published[-1]
    return {
        "enabled": True, "version": latest["version"], "package": latest["package"],
        "lane": latest.get("lane", ""), "volume": latest["volume"], "size": latest["size"],
        "md5": latest["md5"], "silent": latest["silent"],
        "release_type": latest.get("release_type"), "note": latest.get("note", ""),
    }
