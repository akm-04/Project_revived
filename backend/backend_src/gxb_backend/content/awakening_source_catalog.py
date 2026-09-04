"""Immutable effective-src64 Awakening/Blood-Awakening source authority.

Pass205 Stage A.  This catalog contains SOURCE_FACT_ONLY data and no EOL
compatibility policy or mutable player state.
"""
from __future__ import annotations

import copy
import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping

from .p1_source_common import EXPECTED_SOURCE_SHA256


class AwakeningSourceCatalog:
    SCHEMA_VERSION = 1
    HERO = 1
    HERO_TWICE = 2
    EXPECTED_COUNTS = {
        "ordinary_rows": 465,
        "ordinary_stage1": 164,
        "ordinary_stage2": 164,
        "ordinary_aux_stage_minus1": 137,
        "ordinary_route_campaign": 131,
        "ordinary_route_occult": 22,
        "ordinary_route_event_outlier": 11,
        "blood_rows": 162,
        "blood_stage1": 81,
        "blood_stage2": 81,
        "blood_route_campaign": 74,
        "blood_route_event_outlier": 7,
    }

    def __init__(self, data_dir: Path) -> None:
        self.path = Path(data_dir) / "awakening_source_catalog.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        if int(raw.get("schema_version", 0) or 0) != self.SCHEMA_VERSION:
            raise ValueError("invalid AwakeningSourceCatalog schema")
        meta = raw.get("_meta")
        if not isinstance(meta, dict):
            raise ValueError("AwakeningSourceCatalog metadata missing")
        if meta.get("source_resolution") != "effective_src64":
            raise ValueError("AwakeningSourceCatalog must resolve effective_src64")
        if meta.get("epistemic_class") != "SOURCE_FACT_ONLY":
            raise ValueError("AwakeningSourceCatalog must remain source-fact-only")
        if meta.get("source_archive_sha256") != EXPECTED_SOURCE_SHA256:
            raise ValueError("AwakeningSourceCatalog asset authority drift")
        if int(meta.get("effective_src64_file_count", 0) or 0) != 4370:
            raise ValueError("AwakeningSourceCatalog src_64 census drift")
        counts = raw.get("counts")
        if not isinstance(counts, dict) or {k: int(counts.get(k, -1)) for k in self.EXPECTED_COUNTS} != self.EXPECTED_COUNTS:
            raise ValueError("AwakeningSourceCatalog route/mission census drift")

        self._meta = self._freeze_value(meta)
        self._counts = MappingProxyType({k: int(v) for k, v in counts.items()})
        self._ordinary = self._freeze_map(raw.get("ordinary"))
        self._blood = self._freeze_map(raw.get("blood"))
        self._ordinary_stage1 = self._freeze_map(raw.get("ordinary_stage1_routes"))
        self._blood_stage1 = self._freeze_map(raw.get("blood_stage1_routes"))
        self._dropboxes = self._freeze_row_lists(raw.get("special_dropboxes"))
        self._validate_cross_refs()

    @classmethod
    def _freeze_value(cls, value: Any) -> Any:
        if isinstance(value, dict):
            return MappingProxyType({k: cls._freeze_value(v) for k, v in copy.deepcopy(value).items()})
        if isinstance(value, list):
            return tuple(cls._freeze_value(v) for v in copy.deepcopy(value))
        if isinstance(value, tuple):
            return tuple(cls._freeze_value(v) for v in value)
        return copy.deepcopy(value)

    @classmethod
    def _freeze_map(cls, raw: Any) -> Mapping[int, Mapping[str, Any]]:
        if not isinstance(raw, dict):
            raise ValueError("Awakening source row map missing")
        out: dict[int, Mapping[str, Any]] = {}
        for key, row in raw.items():
            if not isinstance(row, dict):
                raise ValueError(f"invalid Awakening source row {key}")
            rid = int(key)
            if int(row.get("id", row.get("mission_id", 0)) or 0) != rid:
                raise ValueError(f"Awakening source row key mismatch {key}")
            out[rid] = cls._freeze_value(row)
        return MappingProxyType(out)

    @classmethod
    def _freeze_row_lists(cls, raw: Any) -> Mapping[int, tuple[Mapping[str, Any], ...]]:
        if not isinstance(raw, dict):
            raise ValueError("Awakening special dropboxes missing")
        out: dict[int, tuple[Mapping[str, Any], ...]] = {}
        for key, rows in raw.items():
            did = int(key)
            if not isinstance(rows, list):
                raise ValueError(f"invalid Awakening dropbox {did}")
            out[did] = tuple(cls._freeze_value(dict(row)) for row in rows if isinstance(row, dict))
        return MappingProxyType(out)

    def _validate_cross_refs(self) -> None:
        if len(self._ordinary) != self.EXPECTED_COUNTS["ordinary_rows"] or len(self._blood) != self.EXPECTED_COUNTS["blood_rows"]:
            raise ValueError("Awakening source mission map size drift")
        if len(self._ordinary_stage1) != 164 or len(self._blood_stage1) != 81:
            raise ValueError("Awakening source stage-one map size drift")
        for route_map, awake_type in ((self._ordinary_stage1, self.HERO), (self._blood_stage1, self.HERO_TWICE)):
            for mission_id, route in route_map.items():
                if int(route.get("awake_type", 0) or 0) != awake_type:
                    raise ValueError(f"Awakening route type mismatch {mission_id}")
                route_class = str(route.get("route_class") or "")
                if route_class not in {"CAMPAIGN", "OCCULT", "EVENT_OUTLIER"}:
                    raise ValueError(f"Awakening route class invalid {mission_id}")
                for campaign in route.get("campaigns") or ():
                    did = int(campaign.get("dropbox_id", 0) or 0)
                    if did > 0 and did not in self._dropboxes:
                        raise ValueError(f"Awakening dropbox reference missing {mission_id}/{did}")
        ordinary_routes = [str(v.get("route_class")) for v in self._ordinary_stage1.values()]
        blood_routes = [str(v.get("route_class")) for v in self._blood_stage1.values()]
        if ordinary_routes.count("CAMPAIGN") != 131 or ordinary_routes.count("OCCULT") != 22 or ordinary_routes.count("EVENT_OUTLIER") != 11:
            raise ValueError("ordinary Awakening route partition drift")
        if blood_routes.count("CAMPAIGN") != 74 or blood_routes.count("EVENT_OUTLIER") != 7:
            raise ValueError("Blood Awakening route partition drift")

    @property
    def metadata(self) -> Mapping[str, Any]:
        return self._meta

    @property
    def counts(self) -> Mapping[str, int]:
        return self._counts

    def rows(self, awake_type: Any) -> Mapping[int, Mapping[str, Any]]:
        value = int(awake_type)
        if value == self.HERO:
            return self._ordinary
        if value == self.HERO_TWICE:
            return self._blood
        return MappingProxyType({})

    def mission(self, mission_id: Any, awake_type: Any | None = None) -> Mapping[str, Any] | None:
        try:
            mid = int(mission_id)
        except (TypeError, ValueError):
            return None
        if awake_type is not None:
            return self.rows(awake_type).get(mid)
        return self._ordinary.get(mid) or self._blood.get(mid)

    def stage1_route(self, mission_id: Any, awake_type: Any) -> Mapping[str, Any] | None:
        try:
            mid = int(mission_id)
            atype = int(awake_type)
        except (TypeError, ValueError):
            return None
        if atype == self.HERO:
            return self._ordinary_stage1.get(mid)
        if atype == self.HERO_TWICE:
            return self._blood_stage1.get(mid)
        return None

    def dropbox(self, dropbox_id: Any) -> tuple[Mapping[str, Any], ...]:
        try:
            return self._dropboxes.get(int(dropbox_id), ())
        except (TypeError, ValueError):
            return ()
