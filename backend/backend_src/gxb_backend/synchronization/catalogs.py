"""Immutable synchronization-foundation metadata bundle.

Wave A deliberately loads/validates metadata without changing gameplay behavior.
Later waves consume these descriptors for HTTP semantics, hydration/deferred
status, MessagePush preferences and authenticated realtime transport.
"""
from __future__ import annotations

import copy
import json
from dataclasses import dataclass
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping

from .compatibility_policy import SynchronizationCompatibilityPolicyRegistry


_STAGE3_CONTRACT_EXACT = frozenset({
    17, 49, 56, 81, 112, 115, 229, 289, 336, 352, 368, 384, 612, 624,
    780, 836, 2137, 2416, 2485, 2560, 2984,
})
_STAGE3_COMPATIBILITY_EXTRAS_EXACT = frozenset({176})
_STAGE3_ACCEPTED_EXACT = _STAGE3_CONTRACT_EXACT | _STAGE3_COMPATIBILITY_EXTRAS_EXACT
_DEFERRED_EXACT = frozenset({124, 530, 816, 822, 1152})
_SEMANTIC_CHANNELS_EXACT = frozenset({"economy_", "new_funcs_", "redmarks_"})
_MESSAGE_PUSH_IDS_EXACT = tuple(range(1, 13))


@dataclass(frozen=True)
class HydrationContractDescriptor:
    mid: int
    name: str
    bootstrap: str
    stage3_preserve: bool
    presentation: str
    singleflight: str
    mutation: str
    freshness: str
    raw: Mapping[str, Any]


@dataclass(frozen=True)
class BootstrapCompatibilityExtraDescriptor:
    mid: int
    name: str
    stage3_preserve: bool
    classification: str
    rule: str
    raw: Mapping[str, Any]


@dataclass(frozen=True)
class GlobalSemanticChannelDescriptor:
    channel: str
    canonical_owner: str
    stage_type: str
    merge: str
    profile_gate: str
    classification: str


@dataclass(frozen=True)
class DeferredStatusAdapterDescriptor:
    mid: int
    name: str
    mode: str
    policy_id: str
    hydration_mid: int
    mutation_fence: str
    adjacent_mutation_mids: tuple[int, ...]


@dataclass(frozen=True)
class RealtimeEventSchemaDescriptor:
    mid: int
    name: str
    direction: str
    owner_domain: str
    allowed_roles: tuple[str, ...]
    delivery_class: str
    schema_key: str
    enabled_in_wave_a: bool
    publication_enabled: bool


@dataclass(frozen=True)
class MessagePushSourceDescriptor:
    message_type: int
    title: str
    tip: str


def _load_json(path: Path) -> dict[str, Any]:
    raw = json.loads(Path(path).read_text(encoding="utf-8"))
    if not isinstance(raw, dict):
        raise ValueError(f"catalog root must be object: {path}")
    if int(raw.get("schema_version", 0) or 0) != 1:
        raise ValueError(f"unsupported catalog schema: {path}")
    return raw


class SynchronizationCatalogs:
    """Validated immutable bundle loaded once by the composition root in later waves."""

    def __init__(
        self,
        *,
        compatibility: SynchronizationCompatibilityPolicyRegistry,
        hydration: Mapping[int, HydrationContractDescriptor],
        bootstrap_compatibility_extras: Mapping[int, BootstrapCompatibilityExtraDescriptor],
        semantic_channels: Mapping[str, GlobalSemanticChannelDescriptor],
        deferred_status: Mapping[int, DeferredStatusAdapterDescriptor],
        realtime_events: Mapping[int, RealtimeEventSchemaDescriptor],
        message_push: Mapping[int, MessagePushSourceDescriptor],
        source_metadata: Mapping[str, Any],
    ) -> None:
        self.compatibility = compatibility
        self._hydration = MappingProxyType(dict(hydration))
        self._bootstrap_compatibility_extras = MappingProxyType(dict(bootstrap_compatibility_extras))
        self._semantic_channels = MappingProxyType(dict(semantic_channels))
        self._deferred_status = MappingProxyType(dict(deferred_status))
        self._realtime_events = MappingProxyType(dict(realtime_events))
        self._message_push = MappingProxyType(dict(message_push))
        self.source_metadata = MappingProxyType(copy.deepcopy(dict(source_metadata)))
        self._validate_cross_references()

    @classmethod
    def load(cls, data_dir: Path) -> "SynchronizationCatalogs":
        root = Path(data_dir)
        compatibility = SynchronizationCompatibilityPolicyRegistry.load(
            root / "synchronization_compatibility_policy.json"
        )

        hydration_raw = _load_json(root / "hydration_contract_registry.json")
        rows = hydration_raw.get("contracts")
        if not isinstance(rows, list):
            raise ValueError("hydration registry requires contracts[]")
        hydration: dict[int, HydrationContractDescriptor] = {}
        for row in rows:
            if not isinstance(row, dict):
                raise ValueError("invalid hydration row")
            mid = int(row.get("mid", 0) or 0)
            if mid <= 0 or mid in hydration:
                raise ValueError(f"invalid/duplicate hydration MID {mid}")
            hydration[mid] = HydrationContractDescriptor(
                mid=mid,
                name=str(row.get("name") or ""),
                bootstrap=str(row.get("bootstrap") or "NONE"),
                stage3_preserve=bool(row.get("stage3_preserve", False)),
                presentation=str(row.get("presentation") or ""),
                singleflight=str(row.get("singleflight") or ""),
                mutation=str(row.get("mutation") or ""),
                freshness=str(row.get("freshness") or ""),
                raw=MappingProxyType(copy.deepcopy(row)),
            )
        if len(hydration) != int(hydration_raw.get("contract_count", -1)):
            raise ValueError("hydration contract_count drift")
        if len(hydration) != 37:
            raise ValueError(f"hydration census drift: {len(hydration)} != 37")

        extra_rows = hydration_raw.get("bootstrap_compatibility_extras", [])
        if not isinstance(extra_rows, list):
            raise ValueError("hydration registry bootstrap_compatibility_extras must be a list")
        bootstrap_extras: dict[int, BootstrapCompatibilityExtraDescriptor] = {}
        for row in extra_rows:
            if not isinstance(row, dict):
                raise ValueError("invalid bootstrap compatibility-extra row")
            mid = int(row.get("mid", 0) or 0)
            if mid <= 0 or mid in bootstrap_extras or mid in hydration:
                raise ValueError(f"invalid/duplicate bootstrap compatibility-extra MID {mid}")
            bootstrap_extras[mid] = BootstrapCompatibilityExtraDescriptor(
                mid=mid,
                name=str(row.get("name") or ""),
                stage3_preserve=bool(row.get("stage3_preserve", False)),
                classification=str(row.get("classification") or ""),
                rule=str(row.get("rule") or ""),
                raw=MappingProxyType(copy.deepcopy(row)),
            )

        semantic_raw = _load_json(root / "global_semantic_channel_registry.json")
        semantic_rows = semantic_raw.get("channels")
        if not isinstance(semantic_rows, list):
            raise ValueError("semantic channel registry requires channels[]")
        semantic: dict[str, GlobalSemanticChannelDescriptor] = {}
        for row in semantic_rows:
            if not isinstance(row, dict):
                raise ValueError("invalid semantic channel row")
            channel = str(row.get("channel") or "")
            if not channel or channel in semantic:
                raise ValueError(f"invalid/duplicate semantic channel {channel!r}")
            semantic[channel] = GlobalSemanticChannelDescriptor(
                channel=channel,
                canonical_owner=str(row.get("canonical_owner") or ""),
                stage_type=str(row.get("stage_type") or ""),
                merge=str(row.get("merge") or ""),
                profile_gate=str(row.get("profile_gate") or ""),
                classification=str(row.get("classification") or ""),
            )

        deferred_raw = _load_json(root / "deferred_ui_status_adapter_registry.json")
        deferred_rows = deferred_raw.get("adapters")
        if not isinstance(deferred_rows, list):
            raise ValueError("deferred adapter registry requires adapters[]")
        deferred: dict[int, DeferredStatusAdapterDescriptor] = {}
        for row in deferred_rows:
            if not isinstance(row, dict):
                raise ValueError("invalid deferred adapter row")
            mid = int(row.get("mid", 0) or 0)
            if mid <= 0 or mid in deferred:
                raise ValueError(f"invalid/duplicate deferred adapter MID {mid}")
            deferred[mid] = DeferredStatusAdapterDescriptor(
                mid=mid,
                name=str(row.get("name") or ""),
                mode=str(row.get("mode") or ""),
                policy_id=str(row.get("policy_id") or ""),
                hydration_mid=int(row.get("hydration_mid", mid) or mid),
                mutation_fence=str(row.get("mutation_fence") or ""),
                adjacent_mutation_mids=tuple(int(v) for v in row.get("adjacent_mutation_mids", []) if int(v) > 0),
            )

        realtime_raw = _load_json(root / "realtime_event_schema_registry.json")
        realtime_rows = realtime_raw.get("events")
        if not isinstance(realtime_rows, list):
            raise ValueError("realtime event schema registry requires events[]")
        realtime: dict[int, RealtimeEventSchemaDescriptor] = {}
        for row in realtime_rows:
            if not isinstance(row, dict):
                raise ValueError("invalid realtime event schema row")
            mid = int(row.get("mid", 0) or 0)
            if mid <= 0 or mid in realtime:
                raise ValueError(f"invalid/duplicate realtime event MID {mid}")
            direction = str(row.get("direction") or "")
            if direction not in {"client->server", "server->client", "bidirectional"}:
                raise ValueError(f"invalid realtime event direction for MID {mid}")
            realtime[mid] = RealtimeEventSchemaDescriptor(
                mid=mid,
                name=str(row.get("name") or ""),
                direction=direction,
                owner_domain=str(row.get("owner_domain") or ""),
                allowed_roles=tuple(str(v) for v in row.get("allowed_roles", []) if str(v)),
                delivery_class=str(row.get("delivery_class") or ""),
                schema_key=str(row.get("schema_key") or ""),
                enabled_in_wave_a=bool(row.get("enabled_in_wave_a", False)),
                publication_enabled=bool(row.get("publication_enabled", False)),
            )

        push_raw = _load_json(root / "message_push_source_catalog.json")
        push_rows = push_raw.get("message_types")
        if not isinstance(push_rows, list):
            raise ValueError("message push source catalog requires message_types[]")
        push: dict[int, MessagePushSourceDescriptor] = {}
        for row in push_rows:
            if not isinstance(row, dict):
                raise ValueError("invalid message push source row")
            message_type = int(row.get("message_type", 0) or 0)
            if message_type <= 0 or message_type in push:
                raise ValueError(f"invalid/duplicate message push type {message_type}")
            push[message_type] = MessagePushSourceDescriptor(
                message_type=message_type,
                title=str(row.get("title") or ""),
                tip=str(row.get("tip") or ""),
            )

        source_metadata = {
            "hydration": hydration_raw.get("source_metadata", {}),
            "message_push": push_raw.get("source_metadata", {}),
            "realtime": realtime_raw.get("source_metadata", {}),
        }
        return cls(
            compatibility=compatibility,
            hydration=hydration,
            bootstrap_compatibility_extras=bootstrap_extras,
            semantic_channels=semantic,
            deferred_status=deferred,
            realtime_events=realtime,
            message_push=push,
            source_metadata=source_metadata,
        )

    def _validate_cross_references(self) -> None:
        stage3_contracts = {mid for mid, row in self._hydration.items() if row.stage3_preserve}
        if stage3_contracts != set(_STAGE3_CONTRACT_EXACT):
            raise ValueError(
                "Stage3 hydration-contract allow-list drift "
                f"missing={sorted(_STAGE3_CONTRACT_EXACT - stage3_contracts)} "
                f"extra={sorted(stage3_contracts - _STAGE3_CONTRACT_EXACT)}"
            )
        stage3_extras = {
            mid for mid, row in self._bootstrap_compatibility_extras.items() if row.stage3_preserve
        }
        if stage3_extras != set(_STAGE3_COMPATIBILITY_EXTRAS_EXACT):
            raise ValueError(
                "Stage3 compatibility-extra allow-list drift "
                f"missing={sorted(_STAGE3_COMPATIBILITY_EXTRAS_EXACT - stage3_extras)} "
                f"extra={sorted(stage3_extras - _STAGE3_COMPATIBILITY_EXTRAS_EXACT)}"
            )
        if stage3_contracts | stage3_extras != set(_STAGE3_ACCEPTED_EXACT):
            raise ValueError("effective Stage3 allow-list drift")
        if set(self._semantic_channels) != set(_SEMANTIC_CHANNELS_EXACT):
            raise ValueError("global semantic channel census drift")
        if set(self._deferred_status) != set(_DEFERRED_EXACT):
            raise ValueError("deferred status adapter census drift")
        for mid, adapter in self._deferred_status.items():
            if adapter.hydration_mid not in self._hydration:
                raise ValueError(f"deferred adapter MID {mid} references missing hydration contract")
            self.compatibility.require(adapter.policy_id)
            if not adapter.mutation_fence:
                raise ValueError(f"deferred adapter MID {mid} lacks mutation fence metadata")
        if tuple(sorted(self._message_push)) != _MESSAGE_PUSH_IDS_EXACT:
            raise ValueError("MessagePush current-source ID census drift")
        # Historical Wave-A marker remains permanently false. Wave E separately
        # activates only source-shape-safe server publication descriptors; typed
        # generic notices still require an owning notice schema at runtime.
        enabled = [row.mid for row in self._realtime_events.values() if row.enabled_in_wave_a]
        if enabled:
            raise ValueError(f"Wave A must not enable realtime events: {enabled}")
        publication_enabled = {row.mid for row in self._realtime_events.values() if row.publication_enabled}
        if publication_enabled != {32784, 36854, 36855}:
            raise ValueError(
                "Wave E realtime publication allow-list drift "
                f"got={sorted(publication_enabled)}"
            )

    def hydration(self, mid: int) -> HydrationContractDescriptor | None:
        return self._hydration.get(int(mid))

    def hydration_rows(self) -> tuple[HydrationContractDescriptor, ...]:
        return tuple(self._hydration[mid] for mid in sorted(self._hydration))

    def stage3_contract_mids(self) -> tuple[int, ...]:
        return tuple(sorted(mid for mid, row in self._hydration.items() if row.stage3_preserve))

    def bootstrap_compatibility_extra_mids(self) -> tuple[int, ...]:
        return tuple(
            sorted(mid for mid, row in self._bootstrap_compatibility_extras.items() if row.stage3_preserve)
        )

    def stage3_mids(self) -> tuple[int, ...]:
        """Return the accepted effective Pass248 Stage3 detail allow-list exactly."""
        return tuple(sorted(set(self.stage3_contract_mids()) | set(self.bootstrap_compatibility_extra_mids())))

    def semantic_channel(self, channel: str) -> GlobalSemanticChannelDescriptor | None:
        return self._semantic_channels.get(str(channel))

    def semantic_channels(self) -> tuple[GlobalSemanticChannelDescriptor, ...]:
        return tuple(self._semantic_channels[key] for key in sorted(self._semantic_channels))

    def deferred_adapter(self, mid: int) -> DeferredStatusAdapterDescriptor | None:
        return self._deferred_status.get(int(mid))

    def deferred_adapters(self) -> tuple[DeferredStatusAdapterDescriptor, ...]:
        return tuple(self._deferred_status[mid] for mid in sorted(self._deferred_status))

    def realtime_event(self, mid: int) -> RealtimeEventSchemaDescriptor | None:
        return self._realtime_events.get(int(mid))

    def realtime_events(self) -> tuple[RealtimeEventSchemaDescriptor, ...]:
        return tuple(self._realtime_events[mid] for mid in sorted(self._realtime_events))

    def message_push_type(self, message_type: int) -> MessagePushSourceDescriptor | None:
        return self._message_push.get(int(message_type))

    def message_push_types(self) -> tuple[MessagePushSourceDescriptor, ...]:
        return tuple(self._message_push[mid] for mid in sorted(self._message_push))
