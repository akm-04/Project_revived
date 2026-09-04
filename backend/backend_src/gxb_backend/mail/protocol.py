"""Stock/current mail wire-shape compatibility helpers (MID 368/369/370)."""
from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Iterable
from .models import MailAddress, MailRecord


def _positive_ids(raw: Any) -> tuple[int, ...]:
    if raw in (None, "", []): return ()
    values = raw if isinstance(raw,(list,tuple)) else str(raw).split("|")
    out=[]
    for value in values:
        text=str(value).strip()
        if not text: continue
        try: number=int(text)
        except (TypeError,ValueError) as exc: raise ValueError(f"invalid mail id {value!r}") from exc
        if number<=0: raise ValueError("mail ids must be positive")
        out.append(number)
    return tuple(sorted(set(out)))


def _bool_flag(raw: Any) -> bool:
    if raw is None: return False
    if isinstance(raw, bool): return raw
    if isinstance(raw, int) and not isinstance(raw, bool) and raw in (0,1): return bool(raw)
    text=str(raw).strip().lower()
    if text in {"0","false"}: return False
    if text in {"1","true"}: return True
    raise ValueError(f"invalid mail namespace flag {raw!r}")

def parse_single_address(request: dict[str, Any]) -> MailAddress:
    raw=request.get("id", request.get("mail_id"))
    if raw is None: raise ValueError("mail id is required")
    return MailAddress(_bool_flag(request.get("is_region",False)),int(raw))


def parse_onekey_addresses(request: dict[str, Any]) -> tuple[MailAddress, ...]:
    addresses=[*(MailAddress(False,x) for x in _positive_ids(request.get("normal_ids"))),*(MailAddress(True,x) for x in _positive_ids(request.get("region_ids")))]
    return tuple(sorted(set(addresses)))


def mailbox_snapshot(records: Iterable[MailRecord], *, total: int | None=None, new_mail_total: int | None=None) -> dict[str, Any]:
    rows=tuple(records)
    return {
        "mail_list":[row.to_wire() for row in rows],
        "total":int(len(rows) if total is None else total),
        "new_mail_total":int(sum(1 for row in rows if row.read_at is None) if new_mail_total is None else new_mail_total),
    }

@dataclass(frozen=True)
class MailReadOutcome:
    changed: bool
    is_new: int
    is_shown: int
    rewards: tuple[dict[str,Any],...]=()
    def to_wire(self)->dict[str,Any]:
        return {"changed":bool(self.changed),"is_new":int(self.is_new),"is_shown":int(self.is_shown),"rewards":[dict(x) for x in self.rewards]}


def onekey_response(*, awards: Iterable[dict[str,Any]], snapshot: dict[str,Any])->dict[str,Any]:
    return {"awards":[dict(x) for x in awards],"mail_list":dict(snapshot)}
