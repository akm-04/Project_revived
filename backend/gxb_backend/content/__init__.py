"""Read-only effective-source content/config infrastructure."""

from .game_data_catalog import (
    AmbiguousContentReference,
    CatalogNamespace,
    ContentRef,
    GameDataCatalog,
    InvalidCatalogProvenance,
    ResolveContext,
    UnknownContentReference,
)
from .source_resolver import EffectiveSourceResolver, ResolvedSource

__all__ = [
    "AmbiguousContentReference",
    "CatalogNamespace",
    "ContentRef",
    "EffectiveSourceResolver",
    "GameDataCatalog",
    "InvalidCatalogProvenance",
    "ResolveContext",
    "ResolvedSource",
    "UnknownContentReference",
]
