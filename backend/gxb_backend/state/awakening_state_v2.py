"""Generation-aware canonical Awakening mission aggregate state (Pass205 Stage A)."""
from __future__ import annotations

import copy
from typing import Any

from .player_state import PlayerState
from .unit_of_work import PlayerUnitOfWork


class AwakeningStateError(ValueError):
    pass


class AwakeningStateV2:
    SCHEMA_VERSION = 2
    HERO = 1
    HERO_TWICE = 2
    PET = 3  # Reserved only; Pet behavior remains future work.
    AWAKE_TYPES = (HERO, HERO_TWICE, PET)
    RECENT_LIMIT = 8

    def __init__(self, player: PlayerState, uow: PlayerUnitOfWork) -> None:
        self.player = player
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def normalize(self) -> tuple[dict[str, Any], bool]:
        raw = self.player.awakening_state
        root = raw if isinstance(raw, dict) else {}
        changed = root is not raw
        version = self._int(root.get("schema_version"), 1 if root else self.SCHEMA_VERSION)
        if version > self.SCHEMA_VERSION:
            raise AwakeningStateError(f"unsupported awakening_state schema {version}")

        if version <= 1:
            root, migrated = self._migrate_v1(root)
            changed = changed or migrated
        else:
            changed = self._normalize_v2(root) or changed

        self.player.awakening_state = root
        if changed and self.uow.active:
            self.uow.touch_slice("awakening_state")
            self.uow.request_save()
        return root, changed

    def _migrate_v1(self, source: dict[str, Any]) -> tuple[dict[str, Any], bool]:
        # Preserve unknown root extensions in-memory, but normalize every canonical
        # container. Canonical replacement persistence prevents stale pre-v2 nested
        # children from being resurrected on the next durable save.
        root = copy.deepcopy(source)
        active_raw = root.get("active") if isinstance(root.get("active"), dict) else {}
        active: dict[str, Any] = {}
        next_generation: dict[str, int] = {}
        for awake_type in self.AWAKE_TYPES:
            key = str(awake_type)
            rec = active_raw.get(key)
            if isinstance(rec, dict):
                migrated = copy.deepcopy(rec)
                generation = max(1, self._int(migrated.get("generation"), 1))
                migrated["generation"] = generation
                active[key] = migrated
                next_generation[key] = generation + 1
            elif rec is None and key in active_raw:
                active[key] = None
                next_generation[key] = 1
            else:
                next_generation[key] = 1
        root["schema_version"] = self.SCHEMA_VERSION
        root["next_generation"] = next_generation
        root["active"] = active
        root["recent_transitions"] = {str(v): [] for v in self.AWAKE_TYPES}
        root["recent_terminals"] = {str(v): [] for v in self.AWAKE_TYPES}
        root["event_entitlements"] = root.get("event_entitlements") if isinstance(root.get("event_entitlements"), dict) else {}
        return root, True

    def _normalize_v2(self, root: dict[str, Any]) -> bool:
        changed = False
        if self._int(root.get("schema_version"), 0) != self.SCHEMA_VERSION:
            root["schema_version"] = self.SCHEMA_VERSION
            changed = True

        active = root.get("active")
        if not isinstance(active, dict):
            active = {}
            root["active"] = active
            changed = True

        next_generation = root.get("next_generation")
        if not isinstance(next_generation, dict):
            next_generation = {}
            root["next_generation"] = next_generation
            changed = True

        for awake_type in self.AWAKE_TYPES:
            key = str(awake_type)
            rec = active.get(key)
            active_generation = 0
            if isinstance(rec, dict):
                active_generation = max(1, self._int(rec.get("generation"), 1))
                if self._int(rec.get("generation"), 0) != active_generation:
                    rec["generation"] = active_generation
                    changed = True
            nxt = max(1, self._int(next_generation.get(key), 1))
            if active_generation and nxt <= active_generation:
                nxt = active_generation + 1
            if self._int(next_generation.get(key), 0) != nxt:
                next_generation[key] = nxt
                changed = True

        for name in ("recent_transitions", "recent_terminals"):
            buckets = root.get(name)
            if not isinstance(buckets, dict):
                buckets = {}
                root[name] = buckets
                changed = True
            for awake_type in self.AWAKE_TYPES:
                key = str(awake_type)
                rows = buckets.get(key)
                if not isinstance(rows, list):
                    buckets[key] = []
                    changed = True
                elif len(rows) > self.RECENT_LIMIT:
                    buckets[key] = rows[-self.RECENT_LIMIT :]
                    changed = True

        if not isinstance(root.get("event_entitlements"), dict):
            root["event_entitlements"] = {}
            changed = True
        return changed

    def root(self) -> dict[str, Any]:
        return self.normalize()[0]

    def active(self, awake_type: Any) -> dict[str, Any] | None:
        root = self.root()
        rec = root["active"].get(str(self._int(awake_type)))
        return rec if isinstance(rec, dict) else None

    def set_active(self, awake_type: Any, record: dict[str, Any] | None) -> None:
        root = self.root()
        key = str(self._int(awake_type))
        root["active"][key] = copy.deepcopy(record) if record is not None else None
        self.uow.touch_slice("awakening_state")
        self.uow.request_save()

    def allocate_generation(self, awake_type: Any) -> int:
        if not self.uow.active:
            raise AwakeningStateError("Awakening generation allocation requires active PlayerUnitOfWork")
        root = self.root()
        key = str(self._int(awake_type))
        if self._int(key, 0) not in self.AWAKE_TYPES:
            raise AwakeningStateError(f"unsupported awake_type {awake_type}")
        value = max(1, self._int(root["next_generation"].get(key), 1))
        root["next_generation"][key] = value + 1
        self.uow.touch_slice("awakening_state")
        self.uow.request_save()
        return value

    def remember_transition(
        self,
        *,
        awake_type: Any,
        generation: Any,
        mission_id: Any,
        operation: str,
        replay_payload: dict[str, Any],
        request_fingerprint: str | None = None,
        terminal: bool = False,
    ) -> None:
        if not self.uow.active:
            raise AwakeningStateError("Awakening replay records require active PlayerUnitOfWork")
        root = self.root()
        key = str(self._int(awake_type))
        bucket_name = "recent_terminals" if terminal else "recent_transitions"
        rows = root[bucket_name].setdefault(key, [])
        rows.append({
            "generation": max(1, self._int(generation, 1)),
            "mission_id": self._int(mission_id),
            "operation": str(operation),
            "request_fingerprint": str(request_fingerprint) if request_fingerprint else None,
            "replay_payload": copy.deepcopy(replay_payload),
        })
        del rows[:-self.RECENT_LIMIT]
        self.uow.touch_slice("awakening_state")
        self.uow.request_save()

    def find_replay(
        self,
        *,
        awake_type: Any,
        generation: Any,
        mission_id: Any,
        operation: str,
        request_fingerprint: str | None = None,
        terminal: bool = False,
    ) -> dict[str, Any] | None:
        root = self.root()
        key = str(self._int(awake_type))
        bucket_name = "recent_terminals" if terminal else "recent_transitions"
        rows = root[bucket_name].get(key) or []
        generation_i = self._int(generation)
        mission_i = self._int(mission_id)
        for row in reversed(rows):
            if not isinstance(row, dict):
                continue
            if self._int(row.get("generation")) != generation_i or self._int(row.get("mission_id")) != mission_i:
                continue
            if str(row.get("operation") or "") != str(operation):
                continue
            old_fp = row.get("request_fingerprint")
            if request_fingerprint and old_fp and str(old_fp) != str(request_fingerprint):
                continue
            payload = row.get("replay_payload")
            return copy.deepcopy(payload) if isinstance(payload, dict) else None
        return None
    @staticmethod
    def _entitlement_key(awake_type: Any, mission_id: Any) -> str:
        try:
            return f"{int(awake_type)}:{int(mission_id)}"
        except (TypeError, ValueError):
            return "0:0"

    def event_entitlement(self, awake_type: Any, mission_id: Any) -> dict[str, Any] | None:
        row = self.root()["event_entitlements"].get(self._entitlement_key(awake_type, mission_id))
        return row if isinstance(row, dict) else None

    def set_event_entitlement(self, awake_type: Any, mission_id: Any, record: dict[str, Any]) -> None:
        if not self.uow.active:
            raise AwakeningStateError("Awakening entitlement mutation requires active PlayerUnitOfWork")
        root = self.root()
        root["event_entitlements"][self._entitlement_key(awake_type, mission_id)] = copy.deepcopy(record)
        self.uow.touch_slice("awakening_state")
        self.uow.request_save()

    def find_latest_replay(
        self, *, awake_type: Any, mission_id: Any, operation: str, terminal: bool = False
    ) -> dict[str, Any] | None:
        """Find the newest semantic replay when the stock wire carries no generation.

        Callers must apply their own current-state guard before using this helper.
        It exists for commit-then-response-loss retries of MID2737/2738 whose
        request body contains only mission_id/awake_type.
        """
        root = self.root(); key = str(self._int(awake_type))
        rows = root["recent_terminals" if terminal else "recent_transitions"].get(key) or []
        mission_i = self._int(mission_id)
        for row in reversed(rows):
            if not isinstance(row, dict): continue
            if self._int(row.get("mission_id")) != mission_i: continue
            if str(row.get("operation") or "") != str(operation): continue
            payload = row.get("replay_payload")
            return copy.deepcopy(payload) if isinstance(payload, dict) else None
        return None

