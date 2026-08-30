"""Synchronization-foundation immutable metadata and validators."""

from .catalogs import (
    DeferredStatusAdapterDescriptor,
    GlobalSemanticChannelDescriptor,
    HydrationContractDescriptor,
    MessagePushSourceDescriptor,
    RealtimeEventSchemaDescriptor,
    SynchronizationCatalogs,
)
from .hydration import HydrationShapeValidator, HydrationSnapshotAssembler
from .deferred_ui_status import DeferredUiStatusAdapterService, DeferredStatusMutationFenceValidator
from .compatibility_policy import (
    SynchronizationCompatibilityPolicy,
    SynchronizationCompatibilityPolicyRegistry,
)

__all__ = [
    "DeferredStatusAdapterDescriptor",
    "GlobalSemanticChannelDescriptor",
    "HydrationContractDescriptor",
    "MessagePushSourceDescriptor",
    "RealtimeEventSchemaDescriptor",
    "SynchronizationCatalogs",
    "HydrationShapeValidator",
    "HydrationSnapshotAssembler",
    "DeferredUiStatusAdapterService",
    "DeferredStatusMutationFenceValidator",
    "SynchronizationCompatibilityPolicy",
    "SynchronizationCompatibilityPolicyRegistry",
]
