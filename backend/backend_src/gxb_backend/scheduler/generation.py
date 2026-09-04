"""Pass345 generic generation lifecycle service over domain-owned repositories.

There is intentionally no universal generation table. Each domain keeps typed
canonical rows and implements this repository protocol.
"""
from __future__ import annotations
from dataclasses import dataclass
from enum import StrEnum
from typing import Any, Mapping, Protocol
from gxb_backend.transactions.models import ReceiptKey
from gxb_backend.transactions.receipts import ReceiptRepository, canonical_request_fingerprint

class GenerationStage(StrEnum):
    PLANNED="PLANNED"; OPEN="OPEN"; FROZEN="FROZEN"; FINALIZING="FINALIZING"; FINALIZED="FINALIZED"; CLOSED="CLOSED"

@dataclass(frozen=True)
class GenerationRecord:
    domain:str; generation_id:str; stage:GenerationStage; state_version:int

class GenerationRepository(Protocol):
    def load_for_update(self, transaction:Any, generation_id:str)->GenerationRecord|None: ...
    def transition(self, transaction:Any, generation_id:str, *, expected_stage:GenerationStage, expected_state_version:int, next_stage:GenerationStage)->GenerationRecord: ...

class GenerationFinalizer(Protocol):
    def __call__(self, transaction:Any, generation:GenerationRecord)->Mapping[str,Any]: ...

class GenerationStateError(RuntimeError): pass

class GenerationLifecycleService:
    def __init__(self, repository:GenerationRepository, receipts:ReceiptRepository|None=None)->None:
        self.repository=repository; self.receipts=receipts or ReceiptRepository()
    def open_generation(self, transaction:Any, generation_id:str)->GenerationRecord:
        row=self.repository.load_for_update(transaction,generation_id)
        if row is None: raise LookupError(generation_id)
        if row.stage is GenerationStage.OPEN: return row
        if row.stage is not GenerationStage.PLANNED: raise GenerationStateError(f"cannot open {row.stage}")
        return self.repository.transition(transaction,generation_id,expected_stage=GenerationStage.PLANNED,expected_state_version=row.state_version,next_stage=GenerationStage.OPEN)

    def require_writable(self, transaction:Any, generation_id:str)->GenerationRecord:
        row=self.repository.load_for_update(transaction,generation_id)
        if row is None: raise LookupError(generation_id)
        if row.stage is not GenerationStage.OPEN: raise GenerationStateError(f"generation {generation_id} is {row.stage}, not OPEN")
        return row
    def freeze(self, transaction:Any, generation_id:str)->GenerationRecord:
        row=self.repository.load_for_update(transaction,generation_id)
        if row is None: raise LookupError(generation_id)
        if row.stage in {GenerationStage.FROZEN,GenerationStage.FINALIZING,GenerationStage.FINALIZED,GenerationStage.CLOSED}: return row
        if row.stage is not GenerationStage.OPEN: raise GenerationStateError(f"cannot freeze {row.stage}")
        return self.repository.transition(transaction,generation_id,expected_stage=GenerationStage.OPEN,expected_state_version=row.state_version,next_stage=GenerationStage.FROZEN)
    def finalize(self, transaction:Any, generation_id:str, finalizer:GenerationFinalizer)->Mapping[str,Any]:
        row=self.repository.load_for_update(transaction,generation_id)
        if row is None: raise LookupError(generation_id)
        key=ReceiptKey(resource_kind="generation",resource_key=f"{row.domain}:{row.generation_id}",domain=row.domain,operation="finalize_generation",idempotency_key=row.generation_id)
        fp=canonical_request_fingerprint({"domain":row.domain,"generation_id":row.generation_id})
        existing=self.receipts.get(transaction.connection,key)
        if existing is not None:
            if existing.request_fingerprint!=fp.hex(): raise GenerationStateError("finalization receipt fingerprint mismatch")
            return dict(existing.result)
        if row.stage is GenerationStage.FROZEN:
            row=self.repository.transition(transaction,generation_id,expected_stage=GenerationStage.FROZEN,expected_state_version=row.state_version,next_stage=GenerationStage.FINALIZING)
        elif row.stage is not GenerationStage.FINALIZING:
            raise GenerationStateError(f"cannot finalize {row.stage}")
        result=dict(finalizer(transaction,row))
        self.receipts.record_or_replay(transaction.connection,key=key,request_fingerprint=fp,result=result,retention_policy="GENERATION_PERMANENT")
        self.repository.transition(transaction,generation_id,expected_stage=GenerationStage.FINALIZING,expected_state_version=row.state_version,next_stage=GenerationStage.FINALIZED)
        return result

    def close(self, transaction:Any, generation_id:str)->GenerationRecord:
        row=self.repository.load_for_update(transaction,generation_id)
        if row is None: raise LookupError(generation_id)
        if row.stage is GenerationStage.CLOSED: return row
        if row.stage is not GenerationStage.FINALIZED: raise GenerationStateError(f"cannot close {row.stage}")
        return self.repository.transition(transaction,generation_id,expected_stage=GenerationStage.FINALIZED,expected_state_version=row.state_version,next_stage=GenerationStage.CLOSED)
