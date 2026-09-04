"""Horcrux deterministic lifecycle domain service.

Pass167 H2 activates lock/equip/collocation behavior; Pass169 H4 adds the
MID3089 strengthening orchestrator. Gods Trial battle settlement remains later.
"""
from __future__ import annotations

import copy
import hashlib
import json
from typing import Any

from .economy_ledger import EconomyLedger
from .hero_repository import HeroRepository
from .horcrux_enhancement import HorcruxEnhancementError, HorcruxEnhancementPlanner
from .horcrux_policy import HorcruxPolicyRegistry
from .horcrux_repository import HorcruxRepository, HorcruxRepositoryError
from .unit_of_work import OperationContext, UnitOfWork


class HorcruxServiceError(ValueError):
    pass


class HorcruxService:
    ENHANCE_RECEIPT_DOMAIN = "horcrux.enhance"
    ENHANCE_RECEIPT_MODE = "TARGET_SORTED_FODDER_PERMANENT"

    def __init__(
        self,
        repository: HorcruxRepository,
        heroes: HeroRepository,
        policy: HorcruxPolicyRegistry,
        uow: UnitOfWork,
        *,
        economy: EconomyLedger,
        enhancement: HorcruxEnhancementPlanner,
    ) -> None:
        self.repository = repository
        self.heroes = heroes
        self.policy = policy
        self.uow = uow
        self.economy = economy
        self.enhancement = enhancement

    @staticmethod
    def _int(value: Any, default: int = 0) -> int:
        try:
            return int(value)
        except (TypeError, ValueError):
            return default

    def owned_count(self) -> int:
        return self.repository.owned_count()

    def _context(self, mid: int, operation: str, key: str | None = None) -> OperationContext:
        return OperationContext(
            actor_player_id=str(self.repository.player.player_id),
            domain="horcrux", operation_name=operation, protocol_mid=mid,
            idempotency_key=key, idempotency_mode="POSTCONDITION" if key else "NONE",
        )

    def _hero(self, partner_id: Any) -> dict[str, Any]:
        pid = self._int(partner_id, 0)
        hero = self.heroes.get(pid)
        if pid <= 0 or hero is None:
            raise HorcruxServiceError(f"unknown partner_id {pid}")
        return hero

    def _position(self, spirit: dict[str, Any]) -> int:
        template = self.repository.source.template(spirit.get("table_id"))
        if template is None:
            raise HorcruxServiceError("Horcrux template missing")
        model = self.repository.source.model(template.get("model_id"))
        if model is None:
            raise HorcruxServiceError("Horcrux model missing")
        return self._int(model.get("pos"), 0)

    @staticmethod
    def _slots(hero: dict[str, Any]) -> list[int]:
        raw = hero.get("spirit_equip") if isinstance(hero.get("spirit_equip"), (list, tuple)) else []
        out=[]
        for v in list(raw)[:6]:
            try: out.append(max(0,int(v)))
            except (TypeError,ValueError): out.append(0)
        while len(out)<6: out.append(0)
        return out

    def _mark_heroes(self) -> None:
        self.uow.mark_changed("heroes")


    @staticmethod
    def _enhance_request(spirit_id: Any, spirit_ids: Any) -> tuple[int, tuple[int, ...], str, str]:
        try:
            target = int(spirit_id)
        except (TypeError, ValueError) as exc:
            raise HorcruxServiceError("invalid target spirit_id") from exc
        if target <= 0:
            raise HorcruxServiceError("invalid target spirit_id")
        if not isinstance(spirit_ids, (list, tuple)) or not spirit_ids:
            raise HorcruxServiceError("spirit_ids must be a nonempty list")
        fodder: list[int] = []
        for raw in spirit_ids:
            if isinstance(raw, bool):
                raise HorcruxServiceError("invalid fodder spirit_id")
            try:
                sid = int(raw)
            except (TypeError, ValueError) as exc:
                raise HorcruxServiceError("invalid fodder spirit_id") from exc
            if sid <= 0:
                raise HorcruxServiceError("invalid fodder spirit_id")
            fodder.append(sid)
        if len(set(fodder)) != len(fodder):
            raise HorcruxServiceError("duplicate fodder spirit_id")
        if target in fodder:
            raise HorcruxServiceError("target cannot be used as fodder")
        canonical = tuple(sorted(fodder))
        fodder_hash = hashlib.sha256(",".join(str(v) for v in canonical).encode("ascii")).hexdigest()
        key = f"enhance:{target}:{fodder_hash}"
        fingerprint = hashlib.sha256(
            json.dumps({"spirit_id": target, "spirit_ids": canonical}, separators=(",", ":"), sort_keys=True).encode("utf-8")
        ).hexdigest()
        return target, canonical, key, fingerprint

    def _enhance_replay(self, key: str, fingerprint: str) -> dict[str, Any] | None:
        receipt = self.uow.get_receipt(self.ENHANCE_RECEIPT_DOMAIN, key)
        if receipt is None:
            return None
        if str(receipt.get("status") or "") != "COMMITTED":
            raise HorcruxServiceError("enhancement receipt is not committed")
        if str(receipt.get("mode") or "") != self.ENHANCE_RECEIPT_MODE:
            raise HorcruxServiceError("enhancement receipt mode mismatch")
        old_fingerprint = str(receipt.get("request_fingerprint") or "")
        if old_fingerprint and old_fingerprint != fingerprint:
            raise HorcruxServiceError("enhancement receipt fingerprint conflict")
        payload = receipt.get("replay_payload")
        if not isinstance(payload, dict) or int(payload.get("spirit_id", 0) or 0) <= 0:
            raise HorcruxServiceError("enhancement receipt replay payload invalid")
        return copy.deepcopy(payload)

    def _enhance_preflight(self, target_id: int, fodder_ids: tuple[int, ...]):
        target = self.repository.get(target_id)
        if target is None:
            raise HorcruxServiceError(f"unknown spirit_id {target_id}")
        fodders: list[dict[str, Any]] = []
        for sid in fodder_ids:
            row = self.repository.get(sid)
            if row is None:
                raise HorcruxServiceError(f"unknown fodder spirit_id {sid}")
            if self._int(row.get("is_lock"), 0) != 0:
                raise HorcruxServiceError(f"fodder spirit_id {sid} is locked")
            if self._int(row.get("is_equip"), 0) != 0:
                raise HorcruxServiceError(f"fodder spirit_id {sid} is equipped")
            if self._int(row.get("collo_count"), 0) != 0:
                raise HorcruxServiceError(f"fodder spirit_id {sid} is referenced by a collocation")
            fodders.append(row)
        try:
            preview = self.enhancement.preview(target, fodders)
        except HorcruxEnhancementError as exc:
            raise HorcruxServiceError(str(exc)) from exc
        if self.economy.balance("mana") < preview.mana_cost:
            raise HorcruxServiceError("insufficient mana for Horcrux strengthening")
        return target, fodders, preview

    def strengthen(self, spirit_id: Any, spirit_ids: Any) -> dict[str, Any]:
        target_id, fodder_ids, key, fingerprint = self._enhance_request(spirit_id, spirit_ids)
        replay = self._enhance_replay(key, fingerprint)
        if replay is not None:
            return replay

        # Deterministic validation before the transaction avoids consuming
        # entropy for obvious failures. All state-sensitive checks repeat inside.
        self._enhance_preflight(target_id, fodder_ids)
        context = OperationContext(
            actor_player_id=str(self.repository.player.player_id),
            domain="horcrux",
            operation_name="strengthen",
            protocol_mid=3089,
            idempotency_key=key,
            idempotency_mode=self.ENHANCE_RECEIPT_MODE,
            request_fingerprint=fingerprint,
        )
        with self.uow.transaction(context):
            replay = self._enhance_replay(key, fingerprint)
            if replay is not None:
                return replay
            target, fodders, preview = self._enhance_preflight(target_id, fodder_ids)
            try:
                plan = self.enhancement.plan(target, fodders)
            except HorcruxEnhancementError as exc:
                raise HorcruxServiceError(str(exc)) from exc
            if plan.preview != preview:
                raise HorcruxServiceError("Horcrux strengthening preview drift")
            if self.economy.debit("mana", preview.mana_cost) is None:
                raise HorcruxServiceError("insufficient mana for Horcrux strengthening")
            self.repository.remove_instances(list(fodder_ids))
            updated = self.repository.replace_instance(target_id, plan.updated_target)
            self.uow.stage_receipt(
                domain=self.ENHANCE_RECEIPT_DOMAIN,
                operation="HUNQI_ENHANCE",
                key=key,
                mode=self.ENHANCE_RECEIPT_MODE,
                request_fingerprint=fingerprint,
                replay_payload=updated,
                retention_policy="CONSUMED_SPIRIT_IDS_PERMANENT",
            )
            return updated

    def lock(self, spirit_id: Any, *, locked: bool) -> dict[str, Any]:
        sid=self._int(spirit_id,0)
        if sid<=0: raise HorcruxServiceError("invalid spirit_id")
        mid=3090 if locked else 3091
        with self.uow.transaction(self._context(mid, "lock" if locked else "unlock", f"{sid}:{int(locked)}")):
            self.repository.set_lock(sid, locked)
        return {}

    def equip(self, partner_id: Any, spirit_id: Any, pos: Any) -> dict[str, Any]:
        pid=self._int(partner_id,0); sid=self._int(spirit_id,0); position=self._int(pos,0)
        if position not in range(1,7): raise HorcruxServiceError("pos must be 1..6")
        with self.uow.transaction(self._context(3094,"equip",f"{pid}:{position}:{sid}")):
            hero=self._hero(pid); slots=self._slots(hero)
            if sid>0:
                spirit=self.repository.get(sid)
                if spirit is None: raise HorcruxServiceError(f"unknown spirit_id {sid}")
                if self._position(spirit)!=position: raise HorcruxServiceError("Horcrux position mismatch")
                owner=self._int(spirit.get("is_equip"),0)
                if owner>0 and owner!=pid:
                    raise HorcruxServiceError("Horcrux is equipped by another Hero")
            if slots[position-1] != sid:
                slots[position-1]=sid
                hero["spirit_equip"]=slots
                self._mark_heroes()
                self.repository.reconcile_runtime_mirrors()
            return {"spirit_equip": copy.deepcopy(slots)}

    def one_key_unequip(self, partner_id: Any) -> dict[str, Any]:
        pid=self._int(partner_id,0)
        with self.uow.transaction(self._context(3095,"one_key_unequip",str(pid))):
            hero=self._hero(pid); slots=self._slots(hero)
            if any(slots):
                slots=[0,0,0,0,0,0]; hero["spirit_equip"]=slots; self._mark_heroes(); self.repository.reconcile_runtime_mirrors()
            return {"spirit_equip": copy.deepcopy(slots)}

    @staticmethod
    def _parse_collocation(value: Any) -> list[int]:
        raw = value if isinstance(value,(list,tuple)) else str(value or "").split("|")
        if len(raw)!=6: raise HorcruxServiceError("collocation must contain six slots")
        out=[]
        for v in raw:
            try: out.append(max(0,int(v)))
            except (TypeError,ValueError): raise HorcruxServiceError("invalid collocation spirit_id")
        nz=[v for v in out if v>0]
        if not nz: raise HorcruxServiceError("empty collocation is not allowed")
        if len(set(nz))!=len(nz): raise HorcruxServiceError("duplicate spirit_id in collocation")
        return out

    def _validate_collocation_refs(self, refs: list[int]) -> None:
        for idx,sid in enumerate(refs,1):
            if sid<=0: continue
            spirit=self.repository.get(sid)
            if spirit is None: raise HorcruxServiceError(f"unknown spirit_id {sid}")
            if self._position(spirit)!=idx: raise HorcruxServiceError(f"Horcrux {sid} position mismatch")

    def collocation_infos(self) -> list[dict[str, Any]]:
        result=[]
        for row in self.repository.collocations():
            result.append({"id":self._int(row.get("id"),0),"name":str(row.get("name") or ""),"collocation":[self._int(v,0) for v in row.get("spirit_ids",[])]})
        return result

    def save_collocation(self, *, name: Any, collocation: Any, collocation_id: Any=None) -> dict[str, int]:
        text=str(name or "").strip(); refs=self._parse_collocation(collocation); cid=self._int(collocation_id,0)
        if not text or len(text)>10: raise HorcruxServiceError("collocation name must be 1..10 characters")
        self._validate_collocation_refs(refs)
        with self.uow.transaction(self._context(3113,"save_collocation",f"{cid}:{text}:{'|'.join(map(str,refs))}")):
            rows=self.repository.collocations()
            if cid<=0:
                for row in rows:
                    if str(row.get("name"))==text:
                        if [self._int(v,0) for v in row.get("spirit_ids",[])]==refs:
                            return {"id":self._int(row.get("id"),0)}
                        raise HorcruxServiceError("duplicate collocation name")
                if len(rows) >= self.repository.source.program_limit:
                    raise HorcruxServiceError("collocation program limit reached")
                cid=self.repository.allocate_collocation_id()
            else:
                if self.repository.get_collocation(cid) is None: raise HorcruxServiceError("unknown collocation id")
                for row in rows:
                    if self._int(row.get("id"),0)!=cid and str(row.get("name"))==text:
                        raise HorcruxServiceError("duplicate collocation name")
            self.repository.save_collocation({"id":cid,"name":text,"spirit_ids":refs})
            return {"id":cid}

    def delete_collocation(self, collocation_id: Any) -> dict[str, Any]:
        cid=self._int(collocation_id,0)
        if cid<=0: raise HorcruxServiceError("invalid collocation id")
        with self.uow.transaction(self._context(3114,"delete_collocation",str(cid))):
            self.repository.delete_collocation(cid)
        return {}

    def apply_collocation(self, collocation_id: Any, partner_id: Any) -> dict[str, Any]:
        cid=self._int(collocation_id,0); pid=self._int(partner_id,0)
        with self.uow.transaction(self._context(3115,"apply_collocation",f"{cid}:{pid}")):
            target=self._hero(pid); row=self.repository.get_collocation(cid)
            if row is None: raise HorcruxServiceError("unknown collocation id")
            refs=[self._int(v,0) for v in row.get("spirit_ids",[])]; refs=(refs+[0]*6)[:6]
            self._validate_collocation_refs(refs)
            selected={v for v in refs if v>0}
            heroes=self.repository.player.heroes if isinstance(self.repository.player.heroes,dict) else {}
            changed=False
            for _key,hero in heroes.items():
                if not isinstance(hero,dict):
                    continue
                if self._int(hero.get("partner_id", _key), 0) == pid:
                    continue
                slots=self._slots(hero)
                new=[0 if sid in selected else sid for sid in slots]
                if new!=slots:
                    hero["spirit_equip"]=new
                    changed=True
            if self._slots(target)!=refs:
                target["spirit_equip"]=copy.deepcopy(refs); changed=True
            if changed:
                self._mark_heroes(); self.repository.reconcile_runtime_mirrors()
            return {}
