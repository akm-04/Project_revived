"""Corrected source/orphan-source SX/Soul Box catalog for Pass42.6.

Recovered/effective source owns the five static dropbox slots and the current
``partner.is_sx`` classification.  ``soul_casket.lua`` is retained as an
orphan server-like configuration snapshot whose partitions inform private
policy, but no top-level class probability is claimed as historical server
math.
"""
from __future__ import annotations

from dataclasses import dataclass
import json
from pathlib import Path
from typing import Any


@dataclass(frozen=True)
class SXSoulBoxItemRow:
    row_id: int
    item_id: int
    item_num: int
    weight: int
    roll_type: int


@dataclass(frozen=True)
class SXSoulBoxItemPool:
    dropbox_id: int
    rate_sum: int
    rows: tuple[SXSoulBoxItemRow, ...]


@dataclass(frozen=True)
class SXSoulBoxSoulCasketRow:
    source_row_id: int
    hero_table_id: int
    source_name: str
    soul_casket_type: int
    roll_num: str
    num_rate: str
    weight: int

    @property
    def positive(self) -> bool:
        return self.weight > 0

    def quantity_choices(self) -> tuple[int, ...]:
        values: list[int] = []
        for token in str(self.roll_num).split("|"):
            try:
                value = int(token)
            except (TypeError, ValueError):
                continue
            if value > 0:
                values.append(value)
        return tuple(values)

    def quantity_rates(self) -> tuple[int, ...]:
        values: list[int] = []
        for token in str(self.num_rate).split("|"):
            try:
                value = int(token)
            except (TypeError, ValueError):
                continue
            if value >= 0:
                values.append(value)
        return tuple(values)


@dataclass(frozen=True)
class SXSoulBoxSXCandidate:
    hero_table_id: int
    name: str
    stone_id: int
    native_star: int
    historical_type1_positive_weight: int | None
    historical_type1_source_row_id: int | None
    post_orphan_snapshot: bool


class SXSoulBoxSourceCatalog:
    DATA_FILE = "sx_soul_box_source_catalog.json"

    def __init__(self, data_dir: Path | str) -> None:
        path = Path(data_dir) / self.DATA_FILE
        try:
            raw = json.loads(path.read_text(encoding="utf-8"))
        except Exception as exc:
            raise RuntimeError(f"cannot load SX Soul Box source catalog {path}: {exc}") from exc
        if not isinstance(raw, dict):
            raise RuntimeError(f"invalid SX Soul Box source catalog: {path}")
        self.meta = dict(raw.get("_meta") or {})
        if int(self.meta.get("schema_version") or 0) != 2:
            raise RuntimeError("SX source catalog schema must be Pass42.6 schema2")
        self.source_summon_row = int(raw.get("source_summon_row") or 0)
        self.configured_result_count = int(raw.get("configured_result_count") or 0)
        self.static_pool_ids = tuple(int(v) for v in raw.get("static_pool_ids") or [])
        if self.source_summon_row != 4 or self.configured_result_count != 6 or len(self.static_pool_ids) != 5:
            raise RuntimeError("SX source identity/result topology drift")

        self._pools: dict[int, SXSoulBoxItemPool] = {}
        for row in raw.get("static_item_pools") or []:
            if not isinstance(row, dict):
                raise RuntimeError("SX static item pool row malformed")
            pool_id = int(row.get("dropbox_id") or 0)
            entries: list[SXSoulBoxItemRow] = []
            for entry in row.get("rows") or []:
                parsed = SXSoulBoxItemRow(
                    row_id=int(entry.get("row_id") or 0),
                    item_id=int(entry.get("item_id") or 0),
                    item_num=int(entry.get("item_num") or 0),
                    weight=int(entry.get("drop_rate") or 0),
                    roll_type=int(entry.get("roll_type") or 0),
                )
                if parsed.row_id <= 0 or parsed.item_id <= 0 or parsed.item_num <= 0 or parsed.weight <= 0:
                    raise RuntimeError(f"SX pool {pool_id} contains invalid row")
                entries.append(parsed)
            rate_sum = int(row.get("rate_sum") or 0)
            if pool_id <= 0 or pool_id in self._pools or not entries or sum(v.weight for v in entries) != rate_sum:
                raise RuntimeError(f"invalid SX item pool {pool_id}")
            self._pools[pool_id] = SXSoulBoxItemPool(pool_id, rate_sum, tuple(entries))
        if tuple(self._pools) != self.static_pool_ids:
            raise RuntimeError("SX static pool order/identity differs from recovered summon row")

        self._classes: dict[int, tuple[SXSoulBoxSoulCasketRow, ...]] = {}
        classes = raw.get("soul_casket_classes")
        if not isinstance(classes, dict):
            raise RuntimeError("SX source catalog lacks complete Soul-Casket partitions")
        for raw_type, payload in classes.items():
            if not isinstance(payload, dict):
                raise RuntimeError("SX Soul-Casket partition malformed")
            type_id = int(raw_type)
            rows: list[SXSoulBoxSoulCasketRow] = []
            for entry in payload.get("rows") or []:
                row = SXSoulBoxSoulCasketRow(
                    source_row_id=int(entry.get("source_row_id") or 0),
                    hero_table_id=int(entry.get("hero_table_id") or 0),
                    source_name=str(entry.get("source_name") or ""),
                    soul_casket_type=int(entry.get("soul_casket_type") or 0),
                    roll_num=str(entry.get("roll_num") or ""),
                    num_rate=str(entry.get("num_rate") or ""),
                    weight=int(entry.get("weight") or 0),
                )
                if row.source_row_id <= 0 or row.hero_table_id <= 0 or row.soul_casket_type != type_id or row.weight < 0:
                    raise RuntimeError(f"invalid SX Soul-Casket type{type_id} row")
                rows.append(row)
            if len(rows) != int(payload.get("row_count") or 0):
                raise RuntimeError(f"SX Soul-Casket type{type_id} row count drift")
            positive = tuple(row for row in rows if row.positive)
            if len(positive) != int(payload.get("positive_row_count") or 0):
                raise RuntimeError(f"SX Soul-Casket type{type_id} positive row count drift")
            if sum(row.weight for row in positive) != int(payload.get("positive_weight_sum") or 0):
                raise RuntimeError(f"SX Soul-Casket type{type_id} weight sum drift")
            self._classes[type_id] = tuple(rows)
        if set(self._classes) != {1, 2, 3, 4, 5, 6}:
            raise RuntimeError("SX source catalog must preserve Soul-Casket types1..6")
        if self.positive_class_rows(3) or self.positive_class_rows(4):
            raise RuntimeError("SX source catalog unexpectedly activates legacy type3/type4")

        roster = raw.get("current_sx_roster")
        if not isinstance(roster, dict) or str(roster.get("authority") or "") != "partner.is_sx==1":
            raise RuntimeError("SX source catalog lacks current partner.is_sx roster authority")
        candidates: list[SXSoulBoxSXCandidate] = []
        seen: set[int] = set()
        for entry in roster.get("rows") or []:
            if not isinstance(entry, dict):
                raise RuntimeError("SX current roster row malformed")
            raw_weight = entry.get("historical_type1_positive_weight")
            raw_row_id = entry.get("historical_type1_source_row_id")
            candidate = SXSoulBoxSXCandidate(
                hero_table_id=int(entry.get("hero_table_id") or 0),
                name=str(entry.get("name") or ""),
                stone_id=int(entry.get("stone_id") or 0),
                native_star=int(entry.get("native_star") or 0),
                historical_type1_positive_weight=(int(raw_weight) if raw_weight is not None else None),
                historical_type1_source_row_id=(int(raw_row_id) if raw_row_id is not None else None),
                post_orphan_snapshot=bool(entry.get("post_orphan_snapshot")),
            )
            if (
                candidate.hero_table_id <= 0
                or not candidate.name
                or candidate.stone_id <= 0
                or candidate.native_star != 3
                or candidate.hero_table_id in seen
            ):
                raise RuntimeError(f"invalid/duplicate current SX candidate {candidate.hero_table_id}")
            seen.add(candidate.hero_table_id)
            candidates.append(candidate)
        if len(candidates) != int(roster.get("candidate_count") or 0) or len(candidates) != 73:
            raise RuntimeError("current SX candidate count drift")
        self._sx_candidates = tuple(candidates)
        self._sx_by_id = {v.hero_table_id: v for v in candidates}

        defaults = raw.get("default_hotspots")
        if not isinstance(defaults, dict):
            raise RuntimeError("SX source catalog lacks private source-valid default hotspots")
        self.default_main_ids = tuple(int(v) for v in defaults.get("main_ids") or [])
        self.default_second_ids = tuple(int(v) for v in defaults.get("second_ids") or [])
        if len(self.default_main_ids) != 2 or len(set(self.default_main_ids)) != 2:
            raise RuntimeError("SX default main_ids must contain two distinct Girls")
        if len(self.default_second_ids) != 3:
            raise RuntimeError("SX default second_ids must contain three Girls")
        if any(not self.is_current_sx(v) for v in self.default_main_ids + self.default_second_ids):
            raise RuntimeError("SX default hotspots must all be current partner.is_sx Girls")

    def pool(self, dropbox_id: int) -> SXSoulBoxItemPool:
        try:
            return self._pools[int(dropbox_id)]
        except KeyError as exc:
            raise KeyError(int(dropbox_id)) from exc

    def class_rows(self, soul_casket_type: int) -> tuple[SXSoulBoxSoulCasketRow, ...]:
        try:
            return self._classes[int(soul_casket_type)]
        except KeyError as exc:
            raise KeyError(int(soul_casket_type)) from exc

    def positive_class_rows(self, soul_casket_type: int) -> tuple[SXSoulBoxSoulCasketRow, ...]:
        return tuple(row for row in self.class_rows(soul_casket_type) if row.positive)

    def sx_candidates(self) -> tuple[SXSoulBoxSXCandidate, ...]:
        return self._sx_candidates

    def sx_candidate(self, hero_table_id: Any) -> SXSoulBoxSXCandidate | None:
        try:
            return self._sx_by_id.get(int(hero_table_id))
        except (TypeError, ValueError):
            return None

    def is_current_sx(self, hero_table_id: Any) -> bool:
        return self.sx_candidate(hero_table_id) is not None
