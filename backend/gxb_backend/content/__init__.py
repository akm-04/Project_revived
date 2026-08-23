"""Read-only effective-source content/config infrastructure."""

from .consumable_effect_catalog import ConsumableEffectCatalog
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
    "ConsumableEffectCatalog",
    "ContentRef",
    "EffectiveSourceResolver",
    "GameDataCatalog",
    "InvalidCatalogProvenance",
    "ResolveContext",
    "ResolvedSource",
    "UnknownContentReference",
]
