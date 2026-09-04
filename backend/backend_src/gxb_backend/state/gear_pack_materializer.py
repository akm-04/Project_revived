"""Deterministic P0 materializer for source ``gift.equip`` Girl Gear Packs."""
from __future__ import annotations

from collections import Counter
import json
from pathlib import Path
from typing import Any

from gxb_backend.content import CatalogNamespace, ContentRef
from .reward_transaction_service import InventoryGrant


class GearPackMaterializationError(ValueError):
    pass


class GearPackMaterializer:
    """Materialize one recovered ``hero|selector`` gift directive.

    Compatibility policy V1 interprets selector as an inclusive ordinary color
    progression ceiling. Ordinary equipment multiplicity is preserved across
    stages; identical persistent Awakening/Blood-Awakening equipment is granted
    once because the source Hero transition retains those items across ordinary
    promotions instead of consuming them repeatedly.
    """

    POLICY_ID = "P0_GIFT_EQUIP_V1_CUMULATIVE_SELECTOR_SPECIAL_DEDUP"

    def __init__(self, data_dir: Path | str) -> None:
        raw=json.loads((Path(data_dir)/"hero_equipment_meta.json").read_text(encoding="utf-8"))
        self.partners=raw.get("partners") or {}
        self.items=raw.get("items") or {}

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try: return int(value)
        except (TypeError, ValueError): return default

    def _parse(self, raw_equip: str) -> tuple[int,int]:
        parts=str(raw_equip or "").split("|")
        if len(parts)!=2:
            raise GearPackMaterializationError("gift.equip must be hero|selector")
        hero_id=self._int(parts[0]); selector=self._int(parts[1])
        if hero_id<=0 or not 1<=selector<=16:
            raise GearPackMaterializationError("gift.equip hero/selector is invalid")
        return hero_id,selector

    def _is_persistent_special(self,item_id:int)->bool:
        row=self.items.get(str(item_id)) or {}
        return self._int(row.get("is_awaken_item"),0)>0 or self._int(row.get("is_bloodline_item"),0)>0

    def counts(self, raw_equip: str, *, copies: int = 1) -> dict[int,int]:
        if isinstance(copies,bool) or self._int(copies)<=0:
            raise GearPackMaterializationError("Gear Pack copies must be positive")
        hero_id,selector=self._parse(raw_equip)
        row=self.partners.get(str(hero_id)) or {}; stages=row.get("equip_lists") or {}
        if not isinstance(stages,dict):
            raise GearPackMaterializationError(f"Girl {hero_id} has no equipment source")
        counts:Counter[int]=Counter(); seen_special:set[int]=set()
        for stage in range(1,selector+1):
            values=stages.get(str(stage))
            if not isinstance(values,list) or len(values)!=6:
                raise GearPackMaterializationError(f"Girl {hero_id} stage {stage} lacks six equipment slots")
            for raw_item in values:
                item_id=self._int(raw_item)
                if item_id<=0:
                    continue
                if str(item_id) not in self.items:
                    raise GearPackMaterializationError(f"Girl {hero_id} stage {stage} has unknown equipment {item_id}")
                if self._is_persistent_special(item_id):
                    if item_id in seen_special: continue
                    seen_special.add(item_id)
                counts[item_id]+=1
        mul=self._int(copies)
        return {item_id:count*mul for item_id,count in counts.items() if count>0}

    def grants(self, raw_equip: str, *, copies: int = 1) -> tuple[InventoryGrant,...]:
        return tuple(
            InventoryGrant(ContentRef(CatalogNamespace.ITEM,item_id),count)
            for item_id,count in sorted(self.counts(raw_equip,copies=copies).items())
        )
