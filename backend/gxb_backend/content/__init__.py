"""Read-only effective-source content/config infrastructure."""

from .consumable_effect_catalog import ConsumableEffectCatalog
from .challenge_campaign_catalog import CHALLENGE_CAMPAIGN_TYPE, ChallengeCampaignCatalog
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
from .super_campaign_catalog import (
    SUPER_CAMPAIGN_TYPE,
    SUPER_FUNCTION_ID,
    SUPER_FUNCTION_LEVEL,
    SuperCampaignCatalog,
)

__all__ = [
    "AmbiguousContentReference",
    "CatalogNamespace",
    "CHALLENGE_CAMPAIGN_TYPE",
    "ChallengeCampaignCatalog",
    "ConsumableEffectCatalog",
    "ContentRef",
    "EffectiveSourceResolver",
    "GameDataCatalog",
    "InvalidCatalogProvenance",
    "ResolveContext",
    "ResolvedSource",
    "SUPER_CAMPAIGN_TYPE",
    "SUPER_FUNCTION_ID",
    "SUPER_FUNCTION_LEVEL",
    "SuperCampaignCatalog",
    "UnknownContentReference",
]


from .skin_source_catalog import SkinSourceCatalog
