"""Per-MID/transport response projection profiles installed by Pass70.

The Lua client has an optional global web envelope *and* endpoint-local response
callbacks.  Profiles therefore constrain what the generic ResponseProjector may
add; they never strip fields already returned by a legacy/domain handler during
the strangler migration.
"""
from __future__ import annotations

import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable


@dataclass(frozen=True)
class ProjectionProfile:
    profile_id: str
    transports: tuple[str, ...]
    mids: tuple[int, ...]
    labels: tuple[str, ...]
    global_fields: frozenset[str]
    domain_fields: tuple[str, ...]
    project_journal_resources: bool
    project_journal_stack_credits: bool
    local_inventory_reconciliation: bool
    preserve_handler_body: bool
    notes: str = ""

    @property
    def allows_economy(self) -> bool:
        return "economy_" in self.global_fields and self.project_journal_resources


class ProjectionProfileRegistry:
    """Read-only frozen profile registry.

    Resolution is MID-first, then label, then the WEB_GLOBAL_ENVELOPE default.
    Transport is retained as evidence/diagnostic metadata and prevents the
    RECHARGE push profile from being treated like an ordinary web response.
    """

    EXPECTED_PROFILE_IDS = frozenset({
        "WEB_GLOBAL_ENVELOPE",
        "CAMPAIGN_RESULT",
        "SKY_CITY_COUNTER",
        "PET_CAMPAIGN",
        "ILLUSION_SOLO",
        "ILLUSION_TEAM",
        "SHOP",
        "RECHARGE_PUSH",
    })

    def __init__(self, profiles: Iterable[ProjectionProfile], default_profile_id: str) -> None:
        rows = tuple(profiles)
        by_id = {row.profile_id: row for row in rows}
        if set(by_id) != set(self.EXPECTED_PROFILE_IDS):
            raise ValueError(f"projection profile drift: {sorted(by_id)}")
        if default_profile_id not in by_id:
            raise ValueError(f"unknown default projection profile: {default_profile_id}")
        self._profiles = rows
        self._by_id = by_id
        self._default = by_id[default_profile_id]
        self._by_mid: dict[int, ProjectionProfile] = {}
        self._by_label: dict[str, ProjectionProfile] = {}
        for row in rows:
            if row.profile_id == default_profile_id:
                continue
            for mid in row.mids:
                # Frozen profiles should not ambiguously claim one MID.
                if mid in self._by_mid and self._by_mid[mid] is not row:
                    raise ValueError(f"projection MID claimed twice: {mid}")
                self._by_mid[mid] = row
            for label in row.labels:
                key = str(label).strip().upper()
                if key:
                    self._by_label[key] = row

    @classmethod
    def load(cls, path: Path) -> "ProjectionProfileRegistry":
        raw = json.loads(Path(path).read_text(encoding="utf-8"))
        if int(raw.get("schema_version", 0)) != 1:
            raise ValueError("unsupported projection profile schema")
        rows = raw.get("profiles")
        if not isinstance(rows, list):
            raise ValueError("projection profiles must be a list")
        profiles: list[ProjectionProfile] = []
        for raw_row in rows:
            if not isinstance(raw_row, dict):
                continue
            profiles.append(ProjectionProfile(
                profile_id=str(raw_row.get("profile_id") or ""),
                transports=tuple(str(v) for v in raw_row.get("transports", []) if str(v)),
                mids=tuple(int(v) for v in raw_row.get("mids", [])),
                labels=tuple(str(v) for v in raw_row.get("labels", []) if str(v)),
                global_fields=frozenset(str(v) for v in raw_row.get("global_fields", []) if str(v)),
                domain_fields=tuple(str(v) for v in raw_row.get("domain_fields", []) if str(v)),
                project_journal_resources=bool(raw_row.get("project_journal_resources", False)),
                project_journal_stack_credits=bool(raw_row.get("project_journal_stack_credits", False)),
                local_inventory_reconciliation=bool(raw_row.get("local_inventory_reconciliation", False)),
                preserve_handler_body=bool(raw_row.get("preserve_handler_body", True)),
                notes=str(raw_row.get("notes") or ""),
            ))
        return cls(profiles, str(raw.get("default_profile_id") or "WEB_GLOBAL_ENVELOPE"))

    @classmethod
    def safe_default(cls) -> "ProjectionProfileRegistry":
        """Compatibility fallback used only if the data file cannot be loaded."""
        profiles = [ProjectionProfile(
            profile_id=profile_id,
            transports=("tcp_chat_or_push", "tcp/chat-routed", "server_event/native completion")
                if profile_id == "RECHARGE_PUSH" else ("engine_web",),
            mids=(36857,) if profile_id == "RECHARGE_PUSH" else (),
            labels=("RECHARGE",) if profile_id == "RECHARGE_PUSH" else (),
            global_fields=frozenset({"economy_", "new_funcs_", "server_time", "flag_", "extra_drops_", "act_item_change_", "redmarks_"}) if profile_id != "RECHARGE_PUSH" else frozenset(),
            domain_fields=(),
            project_journal_resources=profile_id != "RECHARGE_PUSH",
            project_journal_stack_credits=False,
            local_inventory_reconciliation=profile_id in {"PET_CAMPAIGN", "SHOP", "RECHARGE_PUSH"},
            preserve_handler_body=True,
            notes="built-in safe fallback",
        ) for profile_id in sorted(cls.EXPECTED_PROFILE_IDS)]
        return cls(profiles, "WEB_GLOBAL_ENVELOPE")

    def get(self, profile_id: str) -> ProjectionProfile:
        return self._by_id[str(profile_id)]

    def all(self) -> tuple[ProjectionProfile, ...]:
        return self._profiles

    @staticmethod
    def _transport_matches(profile: ProjectionProfile, transport: str | None) -> bool:
        if not transport or not profile.transports:
            return True
        value = str(transport).strip()
        return value in profile.transports

    def resolve(self, *, mid: Any, label: str | None = None, transport: str | None = None) -> ProjectionProfile:
        try:
            numeric_mid = int(mid)
        except (TypeError, ValueError):
            numeric_mid = -1
        row = self._by_mid.get(numeric_mid)
        if row is None and label:
            row = self._by_label.get(str(label).strip().upper())
        # RECHARGE is a transport-special nested event. Preserve that shape even
        # when observed on an unexpected diagnostic route rather than silently
        # downgrading it to the ordinary web envelope.
        if row is not None and row.profile_id == "RECHARGE_PUSH":
            return row
        if row is not None and not self._transport_matches(row, transport):
            row = None
        return row or self._default
