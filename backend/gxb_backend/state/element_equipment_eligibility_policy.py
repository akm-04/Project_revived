"""Pass187 pure source-shaped Element Equipment/Common eligibility policy."""
from __future__ import annotations
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef, GameDataCatalog
from gxb_backend.content.element_equipment_source_catalog import ElementEquipmentSourceCatalog
from .hero_equipment_repository import HeroEquipmentRepository
from .player_state import PlayerState


class ElementEquipmentEligibilityPolicy:
    MAX_HERO_COLOR = 16

    def __init__(
        self,
        player: PlayerState,
        source: ElementEquipmentSourceCatalog,
        game_data: GameDataCatalog,
        ordinary_equipment: HeroEquipmentRepository,
    ) -> None:
        self.player = player
        self.source = source
        self.game_data = game_data
        self.ordinary_equipment = ordinary_equipment

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def first_table_id(self, hero: dict[str, Any]) -> int:
        tid = self._int(hero.get("table_id"), 0)
        if tid <= 0:
            return 0
        row = self.game_data.maybe_get(ContentRef(CatalogNamespace.PARTNER, tid))
        if row is not None:
            first = self._int(row.get("first_table_id"), 0)
            return first if first > 0 else tid
        # Super-partner rows do not need lineage conversion for the Normal-Girl
        # P1 gate; preserve their current table id for legacy/source Super lanes.
        return tid

    def normal_common_eligible(self, hero: dict[str, Any], *, is_super: bool) -> bool:
        if is_super:
            # P1-I2 is the Normal-Girl Common retrofit. Effective src_64 exposes
            # a separate Super condition; preserve the previously accepted Super
            # Element plane rather than silently narrowing it in this wave.
            return True
        return (
            self._int(self.player.lev, 1) >= self._int(self.player.max_lev, 1)
            and self._int(hero.get("color"), 0) == self.MAX_HERO_COLOR
            and self.ordinary_equipment.ordinary_required_slots_complete(hero)
        )

    def position_accepts(self, hero: dict[str, Any], equip_row: dict[str, Any] | Any, position: Any) -> bool:
        pos = self._int(position, 0)
        etype = self._int(equip_row.get("equip_type"), 0) if hasattr(equip_row, "get") else 0
        if pos == 1:
            if etype not in (self.source.CORE, self.source.SP_CORE):
                return False
        elif pos in (2, 3, 4):
            if etype != self.source.NORMAL:
                return False
        else:
            return False
        restricted = self._int(equip_row.get("partner_id"), 0) if hasattr(equip_row, "get") else 0
        if etype == self.source.SP_CORE:
            return restricted > 0 and restricted == self.first_table_id(hero)
        return restricted == 0
