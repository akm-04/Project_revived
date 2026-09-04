"""Immutable source-derived Horcrux/HUNQI content authority.

Pass166 H1 foundation; Pass167 H2 adds recovered limits; Pass169 H4 adds strengthening rules; Pass170 H5 adds Gods Trial drop/timing facts.
This catalog deliberately contains no private-server RNG or
compatibility policy; those live in HorcruxPolicyRegistry.
"""
from __future__ import annotations

import copy
import json
from pathlib import Path
from types import MappingProxyType
from typing import Any, Mapping

from .game_data_catalog import CatalogNamespace, ContentRef, GameDataCatalog


class HorcruxSourceCatalog:
    SCHEMA_VERSION = 4
    EXPECTED_MODELS = 54
    EXPECTED_TEMPLATES = 378
    EXPECTED_STRENGTH_ROWS = 90
    EXPECTED_TRIAL_STAGES = 42
    EXPECTED_TRIAL_POOLS = 84
    EXPECTED_TRIAL_DROP_ROWS = 3672

    def __init__(self, data_dir: Path, *, game_data: GameDataCatalog | None = None) -> None:
        self.path = Path(data_dir) / "horcrux_source_catalog.json"
        raw = json.loads(self.path.read_text(encoding="utf-8"))
        if not isinstance(raw, dict) or int(raw.get("schema_version", 0) or 0) != self.SCHEMA_VERSION:
            raise ValueError("invalid HorcruxSourceCatalog schema")
        meta = raw.get("_meta")
        if not isinstance(meta, dict) or meta.get("source_resolution") != "effective_src64":
            raise ValueError("HorcruxSourceCatalog is not effective_src64")
        if meta.get("epistemic_class") != "SOURCE_FACT_ONLY":
            raise ValueError("HorcruxSourceCatalog must remain source-fact-only")

        self._models = self._freeze_rows(raw.get("models"), id_field="id")
        self._templates = self._freeze_rows(raw.get("templates"), id_field="item_id")
        self._campaigns = self._freeze_rows(raw.get("campaigns"), id_field="id")
        suits = raw.get("suits")
        self._suits = self._freeze_rows(suits, id_field="id") if isinstance(suits, dict) else MappingProxyType({})
        strength = raw.get("strengthening")
        if not isinstance(strength, list):
            raise ValueError("Horcrux strengthening rows missing")
        self._strengthening = tuple(MappingProxyType(copy.deepcopy(dict(row))) for row in strength if isinstance(row, dict))
        ordered = raw.get("ordered_campaign_ids")
        if not isinstance(ordered, list):
            raise ValueError("Horcrux campaign ordering missing")
        self._ordered_campaign_ids = tuple(int(v) for v in ordered)
        limits = raw.get("limits")
        if not isinstance(limits, dict):
            raise ValueError("Horcrux source limits missing")
        self._limits = MappingProxyType(copy.deepcopy(limits))
        trial_rules = raw.get("trial_rules")
        if not isinstance(trial_rules, dict):
            raise ValueError("Gods Trial source rules missing")
        self._trial_rules = MappingProxyType(copy.deepcopy(trial_rules))
        raw_trial_pools = raw.get("trial_drop_pools")
        if not isinstance(raw_trial_pools, dict):
            raise ValueError("Gods Trial drop pools missing")
        trial_pools: dict[int, tuple[Mapping[str, Any], ...]] = {}
        for key, rows in raw_trial_pools.items():
            pool_id = int(key)
            if not isinstance(rows, list):
                raise ValueError(f"Gods Trial drop pool {pool_id} invalid")
            frozen_rows: list[Mapping[str, Any]] = []
            for ordinal, row in enumerate(rows, 1):
                if not isinstance(row, dict):
                    raise ValueError(f"Gods Trial drop pool {pool_id} row invalid")
                value = copy.deepcopy(dict(row))
                if int(value.get("dropbox_id", 0) or 0) != pool_id:
                    raise ValueError(f"Gods Trial drop pool key mismatch {pool_id}")
                if int(value.get("ordinal", 0) or 0) != ordinal:
                    raise ValueError(f"Gods Trial drop pool ordering mismatch {pool_id}/{ordinal}")
                frozen_rows.append(MappingProxyType(value))
            trial_pools[pool_id] = tuple(frozen_rows)
        self._trial_drop_pools = MappingProxyType(trial_pools)
        ordered_trial_pools = raw.get("ordered_trial_dropbox_ids")
        if not isinstance(ordered_trial_pools, list):
            raise ValueError("Gods Trial drop pool ordering missing")
        self._ordered_trial_dropbox_ids = tuple(int(v) for v in ordered_trial_pools)
        rules = raw.get("strengthening_rules")
        if not isinstance(rules, dict):
            raise ValueError("Horcrux strengthening rules missing")
        self._strengthening_rules = MappingProxyType(copy.deepcopy(rules))
        self._strengthening_by_star_level: dict[tuple[int, int], Mapping[str, Any]] = {}
        for row in self._strengthening:
            key = (int(row.get("star", 0) or 0), int(row.get("lv", 0) or 0))
            if key in self._strengthening_by_star_level:
                raise ValueError(f"duplicate Horcrux strengthening row {key}")
            self._strengthening_by_star_level[key] = row
        self._meta = MappingProxyType(copy.deepcopy(meta))
        self._validate(game_data)

    @staticmethod
    def _freeze_rows(raw: Any, *, id_field: str) -> Mapping[int, Mapping[str, Any]]:
        if not isinstance(raw, dict):
            raise ValueError("Horcrux catalog row map missing")
        rows: dict[int, Mapping[str, Any]] = {}
        for key, value in raw.items():
            if not isinstance(value, dict):
                raise ValueError(f"invalid Horcrux row {key}")
            row_id = int(key)
            if int(value.get(id_field, 0) or 0) != row_id:
                raise ValueError(f"Horcrux row key mismatch {key}")
            rows[row_id] = MappingProxyType(copy.deepcopy(dict(value)))
        return MappingProxyType(rows)

    def _validate(self, game_data: GameDataCatalog | None) -> None:
        if len(self._models) != self.EXPECTED_MODELS:
            raise ValueError(f"Horcrux model count mismatch: {len(self._models)}")
        if len(self._templates) != self.EXPECTED_TEMPLATES:
            raise ValueError(f"Horcrux template count mismatch: {len(self._templates)}")
        if len(self._strengthening) != self.EXPECTED_STRENGTH_ROWS:
            raise ValueError(f"Horcrux strengthening count mismatch: {len(self._strengthening)}")
        if len(self._campaigns) != self.EXPECTED_TRIAL_STAGES:
            raise ValueError(f"Gods Trial stage count mismatch: {len(self._campaigns)}")
        if len(self._trial_drop_pools) != self.EXPECTED_TRIAL_POOLS:
            raise ValueError(f"Gods Trial drop pool count mismatch: {len(self._trial_drop_pools)}")
        if sum(len(rows) for rows in self._trial_drop_pools.values()) != self.EXPECTED_TRIAL_DROP_ROWS:
            raise ValueError("Gods Trial drop row count mismatch")
        if set(self._ordered_campaign_ids) != set(self._campaigns):
            raise ValueError("Gods Trial campaign ordering mismatch")
        positions = tuple(sorted({int(row.get("pos", 0) or 0) for row in self._models.values()}))
        if positions != (1, 2, 3, 4, 5, 6):
            raise ValueError(f"Horcrux position set mismatch: {positions}")
        for item_id, row in self._templates.items():
            model_id = int(row.get("model_id", 0) or 0)
            if model_id not in self._models:
                raise ValueError(f"Horcrux template {item_id} references unknown model {model_id}")
            if game_data is not None:
                item = game_data.get(ContentRef(CatalogNamespace.ITEM, item_id))
                if int(item.get("type", 0) or 0) != 24:
                    raise ValueError(f"Horcrux template {item_id} is not ITEM type24")
        if sorted({int(row.get("day", 0) or 0) for row in self._campaigns.values()}) != list(range(1, 8)):
            raise ValueError("Gods Trial source days are not 1..7")
        referenced_pools: list[int] = []
        for cid in self._ordered_campaign_ids:
            row = self._campaigns[cid]
            referenced_pools.extend([int(row.get("init_dropbox", 0) or 0), int(row.get("dropbox", 0) or 0)])
        if tuple(referenced_pools) != self._ordered_trial_dropbox_ids:
            raise ValueError("Gods Trial drop pool ordering/reference drift")
        if set(referenced_pools) != set(self._trial_drop_pools):
            raise ValueError("Gods Trial drop pool reference set drift")
        if int(self._trial_rules.get("campaign_type", 0) or 0) != 79:
            raise ValueError("Gods Trial campaign type source drift")
        if {int(row.get("cost_type", 0) or 0) for row in self._campaigns.values()} != {42}:
            raise ValueError("Gods Trial Spirit Energy cost_type source drift")
        if {int(row.get("win_cost_num", 0) or 0) for row in self._campaigns.values()} != {20}:
            raise ValueError("Gods Trial win cost source drift")
        if {int(row.get("lose_cost_num", 0) or 0) for row in self._campaigns.values()} != {2}:
            raise ValueError("Gods Trial loss cost source drift")
        if int(self._limits.get("spirit_energy_minute", 0) or 0) != 360:
            raise ValueError("Gods Trial Spirit Energy interval source drift")
        if int(self._limits.get("spirit_energy_up_limit", 0) or 0) != 180:
            raise ValueError("Gods Trial Spirit Energy natural cap source drift")
        if int(self._limits.get("spirit_auto_limit", 0) or 0) != 10:
            raise ValueError("Gods Trial auto limit source drift")
        if int(self._limits.get("spirit_auto_time", 0) or 0) != 5:
            raise ValueError("Gods Trial auto time source drift")
        for pool_id, rows in self._trial_drop_pools.items():
            if not rows:
                raise ValueError(f"Gods Trial drop pool {pool_id} empty")
            for row in rows:
                item_id = int(row.get("item_id", 0) or 0)
                rate = int(row.get("increase_rate", -1) or 0)
                if item_id <= 0 or rate < 0:
                    raise ValueError(f"Gods Trial drop row invalid in pool {pool_id}")
                if game_data is not None:
                    game_data.get(ContentRef(CatalogNamespace.ITEM, item_id))
        if int(self._limits.get("spirit_program_limit", 0) or 0) != 20:
            raise ValueError("Horcrux collocation program limit source drift")
        if int(self._limits.get("spirit_num_limit", 0) or 0) != 2000:
            raise ValueError("Horcrux instance capacity source drift")
        if int(self._strengthening_rules.get("max_level", 0) or 0) != 15:
            raise ValueError("Horcrux max strengthening level source drift")
        if float(self._strengthening_rules.get("fodder_exp_rate", 0) or 0) != 0.6:
            raise ValueError("Horcrux fodder EXP rate source drift")
        if int(self._strengthening_rules.get("mana_per_exp", 0) or 0) != 25:
            raise ValueError("Horcrux strengthening Mana rate source drift")
        if tuple(int(v) for v in self._strengthening_rules.get("milestones", ())) != (3, 6, 9, 12, 15):
            raise ValueError("Horcrux strengthening milestones source drift")
        expected_strength_keys = {(star, lv) for star in range(1, 7) for lv in range(1, 16)}
        if set(self._strengthening_by_star_level) != expected_strength_keys:
            raise ValueError("Horcrux strengthening star/level grid drift")

    @property
    def metadata(self) -> Mapping[str, Any]:
        return self._meta

    @property
    def program_limit(self) -> int:
        return int(self._limits["spirit_program_limit"])

    @property
    def spirit_num_limit(self) -> int:
        return int(self._limits["spirit_num_limit"])

    @property
    def trial_campaign_type(self) -> int:
        return int(self._trial_rules["campaign_type"])

    @property
    def spirit_energy_interval_seconds(self) -> int:
        return int(self._limits["spirit_energy_minute"])

    @property
    def spirit_energy_natural_cap(self) -> int:
        return int(self._limits["spirit_energy_up_limit"])

    @property
    def spirit_auto_limit(self) -> int:
        return int(self._limits["spirit_auto_limit"])

    @property
    def spirit_auto_minutes(self) -> int:
        return int(self._limits["spirit_auto_time"])

    @property
    def max_strength_level(self) -> int:
        return int(self._strengthening_rules["max_level"])

    @property
    def fodder_exp_rate(self) -> float:
        return float(self._strengthening_rules["fodder_exp_rate"])

    @property
    def mana_per_strength_exp(self) -> int:
        return int(self._strengthening_rules["mana_per_exp"])

    @property
    def strengthening_milestones(self) -> tuple[int, ...]:
        return tuple(int(v) for v in self._strengthening_rules["milestones"])

    @property
    def ordered_campaign_ids(self) -> tuple[int, ...]:
        return self._ordered_campaign_ids

    def model(self, model_id: Any) -> Mapping[str, Any] | None:
        try:
            return self._models.get(int(model_id))
        except (TypeError, ValueError):
            return None

    def template(self, item_id: Any) -> Mapping[str, Any] | None:
        try:
            return self._templates.get(int(item_id))
        except (TypeError, ValueError):
            return None

    def campaign(self, campaign_id: Any) -> Mapping[str, Any] | None:
        try:
            return self._campaigns.get(int(campaign_id))
        except (TypeError, ValueError):
            return None

    def suit(self, suit_id: Any) -> Mapping[str, Any] | None:
        try:
            return self._suits.get(int(suit_id))
        except (TypeError, ValueError):
            return None

    def templates(self) -> tuple[int, ...]:
        return tuple(self._templates)

    def models(self) -> tuple[int, ...]:
        return tuple(self._models)

    def campaigns_for_day(self, day: Any) -> tuple[Mapping[str, Any], ...]:
        try:
            target = int(day)
        except (TypeError, ValueError):
            return ()
        return tuple(self._campaigns[cid] for cid in self._ordered_campaign_ids if int(self._campaigns[cid].get("day", 0) or 0) == target)

    def trial_drop_rows(self, dropbox_id: Any) -> tuple[Mapping[str, Any], ...]:
        try:
            pool_id = int(dropbox_id)
        except (TypeError, ValueError):
            return ()
        return self._trial_drop_pools.get(pool_id, ())

    @property
    def ordered_trial_dropbox_ids(self) -> tuple[int, ...]:
        return self._ordered_trial_dropbox_ids

    def strengthening_rows(self) -> tuple[Mapping[str, Any], ...]:
        return self._strengthening

    def strengthening_exp(self, star: Any, level: Any) -> int:
        try:
            key = (int(star), int(level))
        except (TypeError, ValueError):
            raise ValueError("invalid Horcrux strengthening star/level")
        row = self._strengthening_by_star_level.get(key)
        if row is None:
            raise ValueError(f"unknown Horcrux strengthening star/level {key}")
        return int(row.get("exp", 0) or 0)

    def strengthening_max_exp(self, star: Any, level: Any | None = None) -> int:
        try:
            star_i = int(star)
            level_i = self.max_strength_level if level is None else int(level)
        except (TypeError, ValueError):
            raise ValueError("invalid Horcrux strengthening star/level")
        level_i = min(max(0, level_i), self.max_strength_level)
        return sum(self.strengthening_exp(star_i, lv) for lv in range(1, level_i + 1))

    def strengthening_level_for_exp(self, star: Any, total_exp: Any) -> int:
        try:
            exp_i = max(0, int(total_exp))
            star_i = int(star)
        except (TypeError, ValueError):
            raise ValueError("invalid Horcrux strengthening EXP")
        cumulative = 0
        level = 0
        for lv in range(1, self.max_strength_level + 1):
            cumulative += self.strengthening_exp(star_i, lv)
            if cumulative <= exp_i:
                level = lv
            else:
                break
        return level
