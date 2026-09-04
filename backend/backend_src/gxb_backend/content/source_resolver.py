"""Pass-32.5 effective writable-over-APK source resolver.

This module is intentionally filesystem-only and contains no gameplay logic.
Metadata generators use it so every source-derived artifact resolves the same
effective ``src_64`` view and records provenance consistently.
"""
from __future__ import annotations

import hashlib
from dataclasses import dataclass
from pathlib import Path


@dataclass(frozen=True)
class ResolvedSource:
    relative_path: str
    path: Path
    layer: str
    sha256: str

    def manifest_row(self) -> dict[str, str]:
        return {
            "relative_path": self.relative_path,
            "layer": self.layer,
            "sha256": self.sha256,
        }


class EffectiveSourceResolver:
    """Resolve writable ``src_64`` files before APK baseline files."""

    SOURCE_RESOLUTION = "effective_merged"
    SOURCE_PRECEDENCE = "writable_hot_update_over_apk_baseline"

    def __init__(self, apk_root: Path, writable_root: Path | None = None) -> None:
        self.apk_root = Path(apk_root)
        self.writable_root = Path(writable_root) if writable_root is not None else None

    @staticmethod
    def _sha256(path: Path) -> str:
        digest = hashlib.sha256()
        with path.open("rb") as fh:
            for chunk in iter(lambda: fh.read(1024 * 1024), b""):
                digest.update(chunk)
        return digest.hexdigest()

    def resolve(self, relative_path: str) -> ResolvedSource:
        relative = str(relative_path).replace("\\", "/").lstrip("/")
        if not relative or relative.startswith("../") or "/../" in f"/{relative}/":
            raise ValueError(f"invalid effective source path: {relative_path!r}")

        if self.writable_root is not None:
            candidate = self.writable_root / relative
            if candidate.is_file():
                return ResolvedSource(
                    relative_path=relative,
                    path=candidate,
                    layer="writable_hot_update",
                    sha256=self._sha256(candidate),
                )

        candidate = self.apk_root / relative
        if candidate.is_file():
            return ResolvedSource(
                relative_path=relative,
                path=candidate,
                layer="apk_baseline",
                sha256=self._sha256(candidate),
            )
        raise FileNotFoundError(f"effective source file not found: {relative}")
