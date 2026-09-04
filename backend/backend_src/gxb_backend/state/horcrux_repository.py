"""Canonical player-owned unique Horcrux instance repository.

Pass166 H1 foundation. Unique instances live in PlayerState.spirit_list while
server-only allocator/collocation/Trial control state lives in horcrux_state.
This repository never owns Mana, Spirit Energy, ordinary stacks, Hero records,
or RNG policy.
"""
from __future__ import annotations

import copy
from typing import Any

from gxb_backend.content.horcrux_source_catalog import HorcruxSourceCatalog

from .hero_repository import HeroRepository
from .player_state import PlayerState
from .unit_of_work import UnitOfWork


class HorcruxRepositoryError(ValueError):
    pass


class HorcruxRepository:
    STATE_SCHEMA_VERSION = 1
    SIX_ZEROES = (0, 0, 0, 0, 0, 0)

    def __init__(
        self,
        player: PlayerState,
        source: HorcruxSourceCatalog,
        *,
        heroes: HeroRepository | None = None,
        uow: UnitOfWork | None = None,
    ) -> None:
        self.player = player
        self.source = source
        self.heroes = heroes
        self.uow = uow

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    @classmethod
    def _fixed_six(cls, value: Any) -> list[int]:
        values = list(value) if isinstance(value, (list, tuple)) else []
        out = [max(0, cls._int(v)) for v in values[:6]]
        while len(out) < 6:
            out.append(0)
        return out

    @classmethod
    def default_state(cls) -> dict[str, Any]:
        return {
            "schema_version": cls.STATE_SCHEMA_VERSION,
            "next_spirit_id": 1,
            "next_collocation_id": 1,
            "collocations": {},
            "trial": {
                "campaign_progress": {},
                "active_battle": {},
                "next_auto_run_id": 1,
                "auto": {
                    "status": "IDLE",
                    "run_id": 0,
                    "campaign_id": 0,
                    "times": 0,
                    "auto_start_time": 0,
                    "complete_at": 0,
                },
                "last_auto_collection": {},
            },
            "migration": {
                "schema_applied": True,
                "legacy_hunqi_start_info_nonempty_ignored": False,
            },
        }

    def _normalize_instances(self) -> tuple[list[dict[str, Any]], dict[int, dict[str, Any]]]:
        raw = self.player.spirit_list
        source_rows = raw if isinstance(raw, list) else []
        normalized: list[dict[str, Any]] = []
        by_id: dict[int, dict[str, Any]] = {}
        for value in source_rows:
            if not isinstance(value, dict):
                continue
            row = copy.deepcopy(value)
            spirit_id = self._int(row.get("spirit_id"), 0)
            if spirit_id <= 0 or spirit_id in by_id:
                # Unique identity is required by every recovered consumer. Keep
                # the first valid occurrence deterministically; malformed legacy
                # rows are non-authoritative and cannot safely participate.
                continue
            row["spirit_id"] = spirit_id
            if "table_id" in row:
                row["table_id"] = max(0, self._int(row.get("table_id"), 0))
            row["is_equip"] = max(0, self._int(row.get("is_equip"), 0))
            row["is_lock"] = 1 if self._int(row.get("is_lock"), 0) else 0
            row["collo_count"] = max(0, self._int(row.get("collo_count"), 0))
            by_id[spirit_id] = row
            normalized.append(row)
        return normalized, by_id

    def _source_position(self, row: dict[str, Any]) -> int:
        template = self.source.template(row.get("table_id"))
        if template is None:
            return 0
        model = self.source.model(template.get("model_id"))
        return self._int(model.get("pos"), 0) if model is not None else 0

    def _normalize_collocations(
        self, raw: Any, by_id: dict[int, dict[str, Any]]
    ) -> tuple[dict[str, dict[str, Any]], dict[str, Any]]:
        owned_ids = set(by_id)
        if not isinstance(raw, dict):
            rejected = {"raw_value": copy.deepcopy(raw)} if raw not in (None, {}) else {}
            return {}, rejected
        out: dict[str, dict[str, Any]] = {}
        rejected: dict[str, Any] = {}
        used_names: set[str] = set()
        for raw_key, value in sorted(raw.items(), key=lambda item: self._int(item[0], 2**31 - 1)):
            if not isinstance(value, dict):
                rejected[str(raw_key)] = copy.deepcopy(value)
                continue
            cid = self._int(value.get("id", raw_key), 0)
            name = str(value.get("name") or "").strip()
            refs = self._fixed_six(value.get("spirit_ids"))
            # Only activate shapes that are provably compatible with the final
            # six-reference design. Missing owned refs remain as zero; unknown
            # legacy extensions stay outside this canonical collocation map.
            if cid <= 0 or not name or len(name) > 10 or name in used_names:
                rejected[str(raw_key)] = copy.deepcopy(value)
                continue
            refs = [sid if sid in owned_ids else 0 for sid in refs]
            if len({sid for sid in refs if sid > 0}) != len([sid for sid in refs if sid > 0]):
                rejected[str(raw_key)] = copy.deepcopy(value)
                continue
            if any(
                sid > 0 and self._source_position(by_id[sid]) != idx
                for idx, sid in enumerate(refs, 1)
            ):
                rejected[str(raw_key)] = copy.deepcopy(value)
                continue
            out[str(cid)] = {"id": cid, "name": name, "spirit_ids": refs}
            used_names.add(name)
        return out, rejected

    @staticmethod
    def _normalize_campaign_progress(raw: Any) -> dict[str, dict[str, int]]:
        if not isinstance(raw, dict):
            return {}
        out: dict[str, dict[str, int]] = {}
        for key, value in raw.items():
            if not isinstance(value, dict):
                continue
            try:
                cid = int(key)
                count = max(0, int(value.get("win_count", 0) or 0))
            except (TypeError, ValueError):
                continue
            if cid > 0:
                out[str(cid)] = {"win_count": count}
        return out

    def _normalize_state(self, by_id: dict[int, dict[str, Any]], max_spirit_id: int) -> dict[str, Any]:
        owned_ids = set(by_id)
        raw = self.player.horcrux_state if isinstance(self.player.horcrux_state, dict) else {}
        state = copy.deepcopy(raw)
        state["schema_version"] = self.STATE_SCHEMA_VERSION
        state["next_spirit_id"] = max(1, self._int(state.get("next_spirit_id"), 1), max_spirit_id + 1)

        collocations, rejected_collocations = self._normalize_collocations(
            state.get("collocations"), by_id
        )
        state["collocations"] = collocations
        max_collocation_id = max((int(k) for k in collocations), default=0)
        state["next_collocation_id"] = max(
            1, self._int(state.get("next_collocation_id"), 1), max_collocation_id + 1
        )

        trial_raw = state.get("trial") if isinstance(state.get("trial"), dict) else {}
        trial = copy.deepcopy(trial_raw)
        trial["campaign_progress"] = self._normalize_campaign_progress(trial.get("campaign_progress"))
        active = trial.get("active_battle")
        trial["active_battle"] = copy.deepcopy(active) if isinstance(active, dict) else {}
        trial["next_auto_run_id"] = max(1, self._int(trial.get("next_auto_run_id"), 1))
        auto_raw = trial.get("auto") if isinstance(trial.get("auto"), dict) else {}
        status = str(auto_raw.get("status") or "IDLE").upper()
        if status not in {"IDLE", "RUNNING"}:
            status = "IDLE"
        trial["auto"] = {
            "status": status,
            "run_id": max(0, self._int(auto_raw.get("run_id"), 0)),
            "campaign_id": max(0, self._int(auto_raw.get("campaign_id"), 0)),
            "times": max(0, self._int(auto_raw.get("times"), 0)),
            "auto_start_time": max(0, self._int(auto_raw.get("auto_start_time"), 0)),
            "complete_at": max(0, self._int(auto_raw.get("complete_at"), 0)),
        }
        last = trial.get("last_auto_collection")
        trial["last_auto_collection"] = copy.deepcopy(last) if isinstance(last, dict) else {}
        state["trial"] = trial

        migration_raw = state.get("migration") if isinstance(state.get("migration"), dict) else {}
        migration = copy.deepcopy(migration_raw)
        migration["schema_applied"] = True
        migration["legacy_hunqi_start_info_nonempty_ignored"] = bool(
            migration.get("legacy_hunqi_start_info_nonempty_ignored")
        ) or bool(isinstance(self.player.hunqi_start_info, dict) and self.player.hunqi_start_info)
        if rejected_collocations:
            prior_rejected = migration.get("legacy_collocations_unactivated")
            preserved = copy.deepcopy(prior_rejected) if isinstance(prior_rejected, dict) else {}
            preserved.update(copy.deepcopy(rejected_collocations))
            migration["legacy_collocations_unactivated"] = preserved
        state["migration"] = migration
        return state

    def _reconcile_hero_equips(self, by_id: dict[int, dict[str, Any]]) -> bool:
        changed = False
        claimed: dict[int, int] = {}
        heroes = self.player.heroes if isinstance(self.player.heroes, dict) else {}
        ordered = sorted(
            heroes.items(),
            key=lambda item: (self._int(item[1].get("partner_id") if isinstance(item[1], dict) else item[0], 0), str(item[0])),
        )
        for key, hero in ordered:
            if not isinstance(hero, dict):
                continue
            partner_id = self._int(hero.get("partner_id", key), 0)
            old_slots = hero.get("spirit_equip")
            slots = self._fixed_six(old_slots)
            for idx, spirit_id in enumerate(slots):
                if spirit_id <= 0:
                    slots[idx] = 0
                    continue
                if spirit_id not in by_id or spirit_id in claimed or partner_id <= 0:
                    slots[idx] = 0
                    continue
                if self._source_position(by_id[spirit_id]) != idx + 1:
                    slots[idx] = 0
                    continue
                claimed[spirit_id] = partner_id
            if old_slots != slots:
                hero["spirit_equip"] = slots
                changed = True
            heroes[str(key)] = hero
        for spirit_id, row in by_id.items():
            # Source client uses is_equip as the owning partner_id, not a boolean.
            expected = claimed.get(spirit_id, 0)
            if self._int(row.get("is_equip"), 0) != expected:
                row["is_equip"] = expected
                changed = True
        return changed

    @staticmethod
    def _rebuild_collocation_counts(by_id: dict[int, dict[str, Any]], collocations: dict[str, dict[str, Any]]) -> bool:
        counts = {spirit_id: 0 for spirit_id in by_id}
        for row in collocations.values():
            refs = {int(v) for v in row.get("spirit_ids", []) if int(v or 0) > 0}
            for spirit_id in refs:
                if spirit_id in counts:
                    counts[spirit_id] += 1
        changed = False
        for spirit_id, row in by_id.items():
            expected = counts[spirit_id]
            try:
                current = int(row.get("collo_count", 0) or 0)
            except (TypeError, ValueError):
                current = 0
            if current != expected:
                row["collo_count"] = expected
                changed = True
        return changed

    def normalize(self) -> bool:
        """Apply H1 load-time migration/reconciliation without gameplay effects."""
        before_spirits = copy.deepcopy(self.player.spirit_list)
        before_state = copy.deepcopy(self.player.horcrux_state)
        before_heroes = copy.deepcopy(self.player.heroes)

        normalized, by_id = self._normalize_instances()
        self.player.spirit_list = normalized
        state = self._normalize_state(by_id, max(by_id, default=0))
        self.player.horcrux_state = state
        self._reconcile_hero_equips(by_id)
        self._rebuild_collocation_counts(by_id, state["collocations"])

        # Mirrors were updated in the same row objects already assigned to the
        # list. Compare full canonical surfaces after all reconciliation.
        return (
            before_spirits != self.player.spirit_list
            or before_state != self.player.horcrux_state
            or before_heroes != self.player.heroes
        )

    @property
    def state(self) -> dict[str, Any]:
        if not isinstance(self.player.horcrux_state, dict):
            raise HorcruxRepositoryError("horcrux_state is not initialized")
        return self.player.horcrux_state

    def all_instances(self) -> list[dict[str, Any]]:
        return [copy.deepcopy(row) for row in self.player.spirit_list if isinstance(row, dict)]

    def owned_count(self) -> int:
        return len([row for row in self.player.spirit_list if isinstance(row, dict) and self._int(row.get("spirit_id"), 0) > 0])

    def get(self, spirit_id: Any) -> dict[str, Any] | None:
        target = self._int(spirit_id, 0)
        if target <= 0:
            return None
        for row in self.player.spirit_list:
            if isinstance(row, dict) and self._int(row.get("spirit_id"), 0) == target:
                return row
        return None

    def _require_transaction(self) -> UnitOfWork:
        if self.uow is None or not self.uow.active:
            raise RuntimeError("Horcrux gameplay mutation requires active PlayerUnitOfWork")
        return self.uow

    def allocate_spirit_id(self) -> int:
        uow = self._require_transaction()
        state = self.state
        cursor = max(1, self._int(state.get("next_spirit_id"), 1))
        existing = {self._int(row.get("spirit_id"), 0) for row in self.player.spirit_list if isinstance(row, dict)}
        while cursor in existing:
            cursor += 1
        state["next_spirit_id"] = cursor + 1
        uow.mark_changed("horcrux_instances")
        return cursor

    def add_instance(self, instance: dict[str, Any]) -> dict[str, Any]:
        uow = self._require_transaction()
        row = copy.deepcopy(dict(instance))
        spirit_id = self._int(row.get("spirit_id"), 0)
        if spirit_id <= 0:
            spirit_id = self.allocate_spirit_id()
        if self.get(spirit_id) is not None:
            raise HorcruxRepositoryError(f"duplicate spirit_id {spirit_id}")
        table_id = self._int(row.get("table_id"), 0)
        if table_id <= 0 or self.source.template(table_id) is None:
            raise HorcruxRepositoryError(f"unknown Horcrux template {table_id}")
        row["spirit_id"] = spirit_id
        row["table_id"] = table_id
        row["is_equip"] = max(0, self._int(row.get("is_equip"), 0))
        row["is_lock"] = 1 if self._int(row.get("is_lock"), 0) else 0
        row["collo_count"] = max(0, self._int(row.get("collo_count"), 0))
        self.player.spirit_list.append(row)
        uow.mark_changed("horcrux_instances")
        return copy.deepcopy(row)

    def replace_instance(self, spirit_id: Any, instance: dict[str, Any]) -> dict[str, Any]:
        uow = self._require_transaction()
        target = self._int(spirit_id, 0)
        if target <= 0:
            raise HorcruxRepositoryError("invalid spirit_id")
        for idx, current in enumerate(self.player.spirit_list):
            if isinstance(current, dict) and self._int(current.get("spirit_id"), 0) == target:
                row = copy.deepcopy(dict(instance))
                row["spirit_id"] = target
                table_id = self._int(row.get("table_id"), 0)
                if table_id <= 0 or self.source.template(table_id) is None:
                    raise HorcruxRepositoryError(f"unknown Horcrux template {table_id}")
                self.player.spirit_list[idx] = row
                uow.mark_changed("horcrux_instances")
                return copy.deepcopy(row)
        raise HorcruxRepositoryError(f"unknown spirit_id {target}")

    def remove_instances(self, spirit_ids: list[int] | tuple[int, ...] | set[int]) -> list[dict[str, Any]]:
        uow = self._require_transaction()
        targets = {self._int(v, 0) for v in spirit_ids}
        targets.discard(0)
        removed: list[dict[str, Any]] = []
        kept: list[dict[str, Any]] = []
        for row in self.player.spirit_list:
            if isinstance(row, dict) and self._int(row.get("spirit_id"), 0) in targets:
                removed.append(copy.deepcopy(row))
            else:
                kept.append(row)
        if targets and {self._int(row.get("spirit_id"), 0) for row in removed} != targets:
            missing = targets - {self._int(row.get("spirit_id"), 0) for row in removed}
            raise HorcruxRepositoryError(f"unknown spirit_ids {sorted(missing)}")
        if removed:
            self.player.spirit_list = kept
            uow.mark_changed("horcrux_instances")
        return removed
    def set_lock(self, spirit_id: Any, locked: bool) -> dict[str, Any]:
        uow = self._require_transaction()
        row = self.get(spirit_id)
        if row is None:
            raise HorcruxRepositoryError(f"unknown spirit_id {self._int(spirit_id, 0)}")
        target = 1 if locked else 0
        if self._int(row.get("is_lock"), 0) != target:
            row["is_lock"] = target
            uow.mark_changed("horcrux_instances")
        return copy.deepcopy(row)

    def reconcile_runtime_mirrors(self) -> bool:
        """Rebuild derived equip/collocation mirrors after one H2 mutation."""
        uow = self._require_transaction()
        by_id = {
            self._int(row.get("spirit_id"), 0): row
            for row in self.player.spirit_list
            if isinstance(row, dict) and self._int(row.get("spirit_id"), 0) > 0
        }
        changed = self._reconcile_hero_equips(by_id)
        changed = self._rebuild_collocation_counts(by_id, self.state.get("collocations", {})) or changed
        if changed:
            uow.mark_changed("horcrux_instances")
        return changed

    def collocations(self) -> list[dict[str, Any]]:
        rows = self.state.get("collocations", {})
        if not isinstance(rows, dict):
            return []
        return [copy.deepcopy(rows[key]) for key in sorted(rows, key=lambda v: self._int(v, 2**31 - 1))]

    def get_collocation(self, collocation_id: Any) -> dict[str, Any] | None:
        cid = self._int(collocation_id, 0)
        if cid <= 0:
            return None
        row = self.state.get("collocations", {}).get(str(cid))
        return copy.deepcopy(row) if isinstance(row, dict) else None

    def save_collocation(self, row: dict[str, Any]) -> dict[str, Any]:
        uow = self._require_transaction()
        value = copy.deepcopy(dict(row))
        cid = self._int(value.get("id"), 0)
        if cid <= 0:
            raise HorcruxRepositoryError("invalid collocation id")
        collocations = self.state.setdefault("collocations", {})
        collocations[str(cid)] = value
        self.state["next_collocation_id"] = max(
            self._int(self.state.get("next_collocation_id"), 1), cid + 1
        )
        uow.mark_changed("horcrux_state")
        self.reconcile_runtime_mirrors()
        return copy.deepcopy(value)

    def allocate_collocation_id(self) -> int:
        uow = self._require_transaction()
        collocations = self.state.setdefault("collocations", {})
        cursor = max(1, self._int(self.state.get("next_collocation_id"), 1))
        while str(cursor) in collocations:
            cursor += 1
        self.state["next_collocation_id"] = cursor + 1
        uow.mark_changed("horcrux_state")
        return cursor

    def delete_collocation(self, collocation_id: Any) -> bool:
        uow = self._require_transaction()
        cid = self._int(collocation_id, 0)
        if cid <= 0:
            raise HorcruxRepositoryError("invalid collocation id")
        collocations = self.state.setdefault("collocations", {})
        existed = str(cid) in collocations
        if existed:
            del collocations[str(cid)]
            uow.mark_changed("horcrux_state")
            self.reconcile_runtime_mirrors()
        return existed

