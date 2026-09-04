"""Shared immutable JSON helpers for Pass186 P1 source-derived catalogs."""
from __future__ import annotations
import copy, json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping

EXPECTED_SOURCE_SHA256 = "89f0f830508b92e5fff6ad53c6a9dae961a14042dbfdf5649008efb8353f5608"


def load_source_json(data_dir: Path, name: str) -> dict[str, Any]:
    raw = json.loads((Path(data_dir) / name).read_text(encoding="utf-8"))
    meta = raw.get("_meta")
    if not isinstance(meta, dict):
        raise ValueError(f"{name}: source metadata missing")
    if int(meta.get("schema_version", 0) or 0) != 1:
        raise ValueError(f"{name}: unsupported schema")
    if meta.get("source_resolution") != "effective_src64" or meta.get("epistemic_class") != "SOURCE_FACT_ONLY":
        raise ValueError(f"{name}: source authority drift")
    if meta.get("source_archive_sha256") != EXPECTED_SOURCE_SHA256:
        raise ValueError(f"{name}: effective asset authority drift")
    return raw


def freeze_rows(rows: Any, *, id_field: str = "id") -> Mapping[int, Mapping[str, Any]]:
    if not isinstance(rows, list):
        raise ValueError("source table rows missing")
    out: dict[int, Mapping[str, Any]] = {}
    for row in rows:
        if not isinstance(row, dict):
            raise ValueError("invalid source row")
        try:
            row_id = int(row.get(id_field, 0) or 0)
        except (TypeError, ValueError):
            raise ValueError("invalid source row id") from None
        if row_id <= 0 or row_id in out:
            raise ValueError(f"invalid/duplicate source row {row_id}")
        out[row_id] = MappingProxyType(copy.deepcopy(row))
    return MappingProxyType(out)
