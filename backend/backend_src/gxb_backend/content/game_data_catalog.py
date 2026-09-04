"""Typed immutable catalog for source-derived game content metadata.

Numeric identifiers are never interpreted globally. Mutation callers supply a
field/API context plus an explicit namespace set, and resolution succeeds only
when exactly one allowed source table contains the identifier.
"""
from __future__ import annotations

import copy
import json
from dataclasses import dataclass
from enum import Enum
from pathlib import Path
from types import MappingProxyType
from typing import Any, Iterable, Mapping


class CatalogError(ValueError):
    pass


class UnknownContentReference(CatalogError):
    pass


class AmbiguousContentReference(CatalogError):
    pass


class InvalidCatalogProvenance(CatalogError):
    pass


class UnsupportedCatalogSchema(CatalogError):
    pass


class CatalogNamespace(str, Enum):
    ITEM = "item"
    PARTNER = "partner"
    SUPER_PARTNER = "super_partner"
    PET = "pet"
    CAMPAIGN = "campaign"
    MISSION = "mission"
    FUNCTION = "function"
    DROPBOX = "dropbox"
    MODEL = "model"
    SKILL_PRICE = "skill_price"


@dataclass(frozen=True)
class ContentRef:
    namespace: CatalogNamespace
    table_id: int

    def __post_init__(self) -> None:
        if int(self.table_id) <= 0:
            raise ValueError("ContentRef.table_id must be positive")


@dataclass(frozen=True)
class ResolveContext:
    field_name: str
    source_domain: str
    expected_namespaces: tuple[CatalogNamespace, ...]
    protocol_mid: int | None = None
    source_path: str | None = None

    @classmethod
    def create(
        cls,
        *,
        field_name: str,
        source_domain: str,
        expected_namespaces: Iterable[CatalogNamespace | str],
        protocol_mid: int | None = None,
        source_path: str | None = None,
    ) -> "ResolveContext":
        namespaces = tuple(CatalogNamespace(value) for value in expected_namespaces)
        if not field_name or not source_domain or not namespaces:
            raise ValueError("resolve context requires field_name, source_domain, and expected_namespaces")
        return cls(
            field_name=str(field_name),
            source_domain=str(source_domain),
            expected_namespaces=namespaces,
            protocol_mid=int(protocol_mid) if protocol_mid is not None else None,
            source_path=str(source_path) if source_path else None,
        )


class GameDataCatalog:
    SCHEMA_VERSION = 1

    def __init__(self, payload: Mapping[str, Any], *, source_path: Path | None = None) -> None:
        meta = payload.get("_meta") if isinstance(payload, Mapping) else None
        if not isinstance(meta, Mapping):
            raise InvalidCatalogProvenance("catalog metadata missing")
        if int(meta.get("schema_version", 0) or 0) != self.SCHEMA_VERSION:
            raise UnsupportedCatalogSchema(f"unsupported game-data catalog schema: {meta.get('schema_version')!r}")
        if meta.get("source_resolution") != "effective_merged":
            raise InvalidCatalogProvenance("catalog is not stamped source_resolution=effective_merged")
        source_files = meta.get("source_files")
        if not isinstance(source_files, Mapping) or not source_files:
            raise InvalidCatalogProvenance("catalog source_files provenance missing")
        for relative, row in source_files.items():
            if not isinstance(relative, str) or not isinstance(row, Mapping):
                raise InvalidCatalogProvenance("invalid catalog source_files row")
            if not row.get("layer") or not row.get("sha256"):
                raise InvalidCatalogProvenance(f"incomplete provenance for {relative}")

        raw_namespaces = payload.get("namespaces")
        if not isinstance(raw_namespaces, Mapping):
            raise UnsupportedCatalogSchema("catalog namespaces object missing")

        tables: dict[CatalogNamespace, Mapping[int, Mapping[str, Any]]] = {}
        for namespace in CatalogNamespace:
            raw_rows = raw_namespaces.get(namespace.value, {})
            if not isinstance(raw_rows, Mapping):
                raise UnsupportedCatalogSchema(f"namespace {namespace.value} is not an object")
            rows: dict[int, Mapping[str, Any]] = {}
            for raw_id, raw_row in raw_rows.items():
                try:
                    table_id = int(raw_id)
                except (TypeError, ValueError):
                    raise UnsupportedCatalogSchema(f"non-numeric id in {namespace.value}: {raw_id!r}")
                if table_id <= 0 or not isinstance(raw_row, Mapping):
                    continue
                rows[table_id] = MappingProxyType(copy.deepcopy(dict(raw_row)))
            tables[namespace] = MappingProxyType(rows)

        self._tables = MappingProxyType(tables)
        self._meta = MappingProxyType(copy.deepcopy(dict(meta)))
        self.source_path = Path(source_path) if source_path is not None else None

    @classmethod
    def load(cls, path: Path) -> "GameDataCatalog":
        path = Path(path)
        payload = json.loads(path.read_text(encoding="utf-8"))
        if not isinstance(payload, dict):
            raise UnsupportedCatalogSchema("catalog JSON root must be an object")
        return cls(payload, source_path=path)

    @property
    def metadata(self) -> Mapping[str, Any]:
        return self._meta

    @staticmethod
    def _coerce_ref(ref: ContentRef) -> ContentRef:
        return ContentRef(CatalogNamespace(ref.namespace), int(ref.table_id))

    def maybe_get(self, ref: ContentRef) -> Mapping[str, Any] | None:
        resolved = self._coerce_ref(ref)
        return self._tables[resolved.namespace].get(resolved.table_id)

    def get(self, ref: ContentRef) -> Mapping[str, Any]:
        resolved = self._coerce_ref(ref)
        row = self.maybe_get(resolved)
        if row is None:
            raise UnknownContentReference(f"unknown {resolved.namespace.value} id {resolved.table_id}")
        return row

    def exists(self, ref: ContentRef) -> bool:
        return self.maybe_get(ref) is not None

    def iter_namespace(self, namespace: CatalogNamespace | str) -> tuple[ContentRef, ...]:
        selected = CatalogNamespace(namespace)
        return tuple(ContentRef(selected, table_id) for table_id in self._tables[selected])

    def lookup_all(self, table_id: Any) -> tuple[ContentRef, ...]:
        try:
            target = int(table_id)
        except (TypeError, ValueError):
            return ()
        if target <= 0:
            return ()
        return tuple(
            ContentRef(namespace, target)
            for namespace in CatalogNamespace
            if target in self._tables[namespace]
        )

    def resolve(self, context: ResolveContext, table_id: Any) -> ContentRef:
        try:
            target = int(table_id)
        except (TypeError, ValueError) as exc:
            raise UnknownContentReference(
                f"{context.source_domain}.{context.field_name}: non-numeric content id {table_id!r}"
            ) from exc
        if target <= 0:
            raise UnknownContentReference(
                f"{context.source_domain}.{context.field_name}: invalid content id {target}"
            )
        candidates = [
            ContentRef(namespace, target)
            for namespace in context.expected_namespaces
            if target in self._tables[namespace]
        ]
        if not candidates:
            expected = ",".join(ns.value for ns in context.expected_namespaces)
            raise UnknownContentReference(
                f"{context.source_domain}.{context.field_name} id {target} not found in [{expected}]"
            )
        if len(candidates) != 1:
            names = ",".join(ref.namespace.value for ref in candidates)
            raise AmbiguousContentReference(
                f"{context.source_domain}.{context.field_name} id {target} is ambiguous across [{names}]"
            )
        return candidates[0]

    def row(self, namespace: CatalogNamespace | str, table_id: Any) -> Mapping[str, Any]:
        return self.get(ContentRef(CatalogNamespace(namespace), int(table_id)))
