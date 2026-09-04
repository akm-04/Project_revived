"""Pass339 Identity/Session/Concurrency foundation contracts."""

from .contracts import (
    PlayerAggregateRecord,
    PlayerAggregateRepository,
    PostCommitEventBus,
    RequestRuntimeAdapter,
    ResourceTransaction,
    TransactionCoordinator,
    TransactionRequest,
)
from .database import DatabaseConfigurationError, DatabaseSettings, ProcessEngineProvider
from .legacy_adapter import LegacyRequestRuntimeAdapter
from .resource_keys import ResourceClass, ResourceKey, order_resource_keys, require_canonical_order

__all__ = [
    "DatabaseConfigurationError",
    "DatabaseSettings",
    "LegacyRequestRuntimeAdapter",
    "PlayerAggregateRecord",
    "PlayerAggregateRepository",
    "PostCommitEventBus",
    "ProcessEngineProvider",
    "RequestRuntimeAdapter",
    "ResourceClass",
    "ResourceKey",
    "ResourceTransaction",
    "TransactionCoordinator",
    "TransactionRequest",
    "order_resource_keys",
    "require_canonical_order",
]
