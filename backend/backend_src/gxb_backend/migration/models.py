"""Typed, secret-conscious records for the Pass346 offline importer."""
from __future__ import annotations

from dataclasses import dataclass, field
from pathlib import Path
from typing import Any, Mapping

from gxb_backend.persistence.codec import PlayerTransformResult


@dataclass(frozen=True, slots=True)
class ManifestEntry:
    path: str
    size: int
    sha256: str


@dataclass(frozen=True, slots=True)
class LegacyAccount:
    account_uid: str
    account_type: str
    username: str
    login: str
    normalized_login: str
    created_at: int
    password_record: Mapping[str, Any] | None
    metadata: Mapping[str, Any]


@dataclass(frozen=True, slots=True)
class LegacyPlayer:
    player_id: int
    account_uid: str
    region_id: int
    source_path: str
    source_document: Mapping[str, Any]
    transformed: PlayerTransformResult


@dataclass(frozen=True, slots=True)
class Adjustment:
    kind: str
    subject: str
    source_value: int | str | None
    target_value: int | str
    reason: str


@dataclass(frozen=True)
class SourceInventory:
    root: Path
    entries: tuple[ManifestEntry, ...]
    content_root: str
    manifest_digest: str
    accounts: tuple[LegacyAccount, ...]
    players: tuple[LegacyPlayer, ...]
    region_next_player_ids: Mapping[int, int]
    next_account_uid: int
    session_file_count: int
    session_index_count: int
    warnings: tuple[str, ...] = ()
    adjustments: tuple[Adjustment, ...] = ()

    @property
    def counts(self) -> dict[str, int]:
        return {
            "files": len(self.entries),
            "accounts": len(self.accounts),
            "players": len(self.players),
            "sessions_retired": self.session_file_count,
            "session_index_entries_retired": self.session_index_count,
            "receipts": sum(len(p.transformed.receipts) for p in self.players),
            "mail": sum(len(p.transformed.mails) for p in self.players),
        }


@dataclass(frozen=True)
class TargetAccounting:
    counts: Mapping[str, int]
    digests: Mapping[str, str]
    invariant_results: Mapping[str, bool]
    mail_remaps: tuple[Mapping[str, Any], ...] = ()


@dataclass(frozen=True)
class MigrationOutcome:
    migration_run_id: str
    status: str
    source_content_root: str
    source_manifest_digest: str
    counts: Mapping[str, int]
    digests: Mapping[str, str]
    adjustments: tuple[Adjustment, ...]
    warnings: tuple[str, ...]
    mail_remaps: tuple[Mapping[str, Any], ...] = field(default_factory=tuple)
