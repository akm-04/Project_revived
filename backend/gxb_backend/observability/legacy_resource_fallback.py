"""Explicit deny-by-default historical resource fallback policy.

Historical EOL assets are never general search roots.  A file under
``local_assets/old_res`` may be served only when an exact allowlist row binds
its current logical path and advertised MD5 to one exact historical file and
its frozen MD5/SHA256/size provenance.
"""
from __future__ import annotations

import hashlib
import json
import re
from dataclasses import dataclass
from pathlib import Path, PurePosixPath
from typing import Any

_MD5_RE = re.compile(r"^[0-9a-f]{32}$")
_SHA256_RE = re.compile(r"^[0-9a-f]{64}$")


def _safe_relpath(value: object) -> str:
    text = str(value or "").replace("\\", "/").lstrip("/")
    pure = PurePosixPath(text)
    if not text or ".." in pure.parts:
        return ""
    return text


@dataclass(frozen=True)
class LegacyFallbackEntry:
    current_path: str
    catalog_md5: str
    donor_md5: str
    donor_sha256: str
    donor_size: int
    fallback_relpath: str
    media_class: str = ""
    source_generation: str = ""

    @property
    def key(self) -> tuple[str, str]:
        return self.current_path, self.catalog_md5


class LegacyFallbackRegistry:
    """Load and validate the explicit historical-donor allowlist.

    Any malformed policy file fails closed.  A missing policy file means no
    historical fallback is authorized.
    """

    def __init__(self, path: Path) -> None:
        self.path = path
        self.entries: list[LegacyFallbackEntry] = []
        self.by_key: dict[tuple[str, str], LegacyFallbackEntry] = {}
        self.load_error = ""
        self._load()

    def _load(self) -> None:
        try:
            payload = json.loads(self.path.read_text(encoding="utf-8"))
        except FileNotFoundError:
            return
        except Exception as exc:
            self.load_error = f"{type(exc).__name__}: {exc}"
            return

        try:
            if not isinstance(payload, dict):
                raise ValueError("allowlist must be a JSON object")
            if str(payload.get("default_policy") or "") != "DENY_LEGACY_FALLBACK":
                raise ValueError("default_policy must be DENY_LEGACY_FALLBACK")
            rows = payload.get("entries")
            if not isinstance(rows, list):
                raise ValueError("entries must be a JSON array")

            seen: set[tuple[str, str]] = set()
            for index, row in enumerate(rows):
                if not isinstance(row, dict):
                    raise ValueError(f"entry {index} is not an object")
                current_path = _safe_relpath(row.get("current_path"))
                fallback_relpath = _safe_relpath(row.get("fallback_relpath"))
                catalog_md5 = str(row.get("catalog_md5") or "").lower()
                donor_md5 = str(row.get("donor_md5") or "").lower()
                donor_sha256 = str(row.get("donor_sha256") or "").lower()
                try:
                    donor_size = int(row.get("donor_size"))
                except (TypeError, ValueError):
                    donor_size = -1
                if not current_path.startswith("res/web/"):
                    raise ValueError(f"entry {index} has unsafe/non-current path: {current_path!r}")
                if not fallback_relpath:
                    raise ValueError(f"entry {index} has invalid fallback_relpath")
                if not _MD5_RE.fullmatch(catalog_md5) or not _MD5_RE.fullmatch(donor_md5):
                    raise ValueError(f"entry {index} has invalid MD5")
                if catalog_md5 != donor_md5:
                    raise ValueError(f"entry {index} catalog_md5 must equal donor_md5")
                if not _SHA256_RE.fullmatch(donor_sha256):
                    raise ValueError(f"entry {index} has invalid donor SHA256")
                if donor_size < 0:
                    raise ValueError(f"entry {index} has invalid donor_size")
                entry = LegacyFallbackEntry(
                    current_path=current_path,
                    catalog_md5=catalog_md5,
                    donor_md5=donor_md5,
                    donor_sha256=donor_sha256,
                    donor_size=donor_size,
                    fallback_relpath=fallback_relpath,
                    media_class=str(row.get("media_class") or ""),
                    source_generation=str(row.get("source_generation") or ""),
                )
                if entry.key in seen:
                    raise ValueError(f"duplicate allowlist key: {entry.key}")
                seen.add(entry.key)
                self.entries.append(entry)
                self.by_key[entry.key] = entry
        except Exception as exc:
            self.entries.clear()
            self.by_key.clear()
            self.load_error = f"{type(exc).__name__}: {exc}"

    def lookup(self, current_path: str, expected_md5: str) -> LegacyFallbackEntry | None:
        return self.by_key.get((_safe_relpath(current_path), str(expected_md5 or "").lower()))


def hash_file(path: Path, algorithm: str) -> str:
    digest = hashlib.new(algorithm)
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()
