"""Authoritative SummonState/MID56 projection contract.

Pass41.1 centralizes the fields that the server owns for classic Vending state
without inventing the unrecovered reset/rotation algorithms.  The contract is
read-only with respect to player state: normalization/mutation remains owned by
``SummonRepository`` and later family-specific services.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class SummonStateField:
    name: str
    kind: str
    required: bool


@dataclass(frozen=True)
class SummonTimerPolicy:
    family: str
    free_time_field: str | None
    free_count_field: str | None
    period_seconds: int | None
    configured_free_count: int | None
    server_reset_rule: str | None


class SummonStateContract:
    """Load source-backed state metadata and project the stock MID56 shape."""

    DATA_FILE = "summon_state_policy.json"

    def __init__(self, data_dir: Path | str) -> None:
        self.data_dir = Path(data_dir)
        path = self.data_dir / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:  # pragma: no cover - startup guard
            raise RuntimeError(f"cannot load summon state policy {path}: {exc}") from exc
        if not isinstance(raw, dict) or not isinstance(raw.get("mid56_fields"), list):
            raise RuntimeError(f"invalid summon state policy: {path}")
        self.meta = dict(raw.get("_meta") or {})
        self._fields: list[SummonStateField] = []
        seen: set[str] = set()
        for row in raw["mid56_fields"]:
            if not isinstance(row, dict):
                raise RuntimeError(f"invalid MID56 field row in {path}")
            name = str(row.get("name") or "")
            kind = str(row.get("kind") or "")
            if not name or not kind or name in seen:
                raise RuntimeError(f"invalid/duplicate MID56 field {name!r} in {path}")
            seen.add(name)
            self._fields.append(SummonStateField(name, kind, bool(row.get("required"))))
        self._families = dict(raw.get("families") or {})

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def fields(self) -> tuple[SummonStateField, ...]:
        return tuple(self._fields)

    def timer_policy(self, family: str) -> SummonTimerPolicy | None:
        row = self._families.get(str(family))
        if not isinstance(row, dict):
            return None
        return SummonTimerPolicy(
            family=str(family),
            free_time_field=(str(row["free_time_field"]) if row.get("free_time_field") else None),
            free_count_field=(str(row["free_count_field"]) if row.get("free_count_field") else None),
            period_seconds=(self._int(row.get("period_seconds")) if row.get("period_seconds") is not None else None),
            configured_free_count=(
                self._int(row.get("configured_free_count"))
                if row.get("configured_free_count") is not None
                else None
            ),
            server_reset_rule=(str(row["server_reset_rule"]) if row.get("server_reset_rule") else None),
        )

    def project(self, state: dict[str, Any]) -> dict[str, Any]:
        if not isinstance(state, dict):
            raise RuntimeError("summon state must be an object before MID56 projection")
        payload: dict[str, Any] = {}
        for field in self._fields:
            value = state.get(field.name)
            if field.kind == "positive_int_list":
                raw = value if isinstance(value, list) else []
                payload[field.name] = [self._int(v) for v in raw if self._int(v) > 0]
            elif field.kind == "positive_int":
                parsed = self._int(value, 0)
                if field.required or parsed > 0:
                    payload[field.name] = max(0, parsed)
            elif field.kind == "nonnegative_int":
                payload[field.name] = max(0, self._int(value, 0))
            else:  # pragma: no cover - startup policy should reject before use
                raise RuntimeError(f"unsupported summon state field kind {field.kind!r}")
        return payload
